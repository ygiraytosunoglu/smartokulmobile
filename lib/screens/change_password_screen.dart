import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_okul_mobile/constants.dart';
import 'package:smart_okul_mobile/screens/login_screen.dart';
import 'package:smart_okul_mobile/services/api_service.dart';
import 'package:smart_okul_mobile/utils/error_translator.dart';
import 'package:smart_okul_mobile/utils/pin_policy.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String tckn;
  final String currentPin;
  final bool forced;

  const ChangePasswordScreen({
    super.key,
    required this.tckn,
    required this.currentPin,
    this.forced = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.forced && widget.currentPin.isNotEmpty) {
      _currentPasswordController.text = widget.currentPin;
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().changePin(
        tckn: widget.tckn,
        currentPin: _currentPasswordController.text,
        yeniPin: _newPasswordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sifre', _newPasswordController.text);
      await ApiService.clearToken();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre güncellendi. Lütfen tekrar giriş yapın.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translateError(e.toString(), context))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forced,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Şifre Değiştir', style: AppStyles.titleLarge),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          automaticallyImplyLeading: !widget.forced,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (widget.forced) ...[
                  const Text(
                    'İlk girişte şifrenizi değiştirmeniz gerekmektedir.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  pinPolicyMessage,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                if (!widget.forced)
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mevcut Şifre',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mevcut şifre giriniz';
                      }
                      return null;
                    },
                  ),
                if (!widget.forced) const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: validateNewPin,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _changePassword,
                          style: AppStyles.buttonStyle,
                          child: const Text('Şifreyi Değiştir'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
