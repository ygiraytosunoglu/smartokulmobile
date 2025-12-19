import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'package:smart_okul_mobile/constants.dart' as constants;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tcknController = TextEditingController();
  final _telNoController = TextEditingController();
  final _newPassword1Controller = TextEditingController();
  final _newPassword2Controller = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      // Şifre eşleşme kontrolü
      if (_newPassword1Controller.text.trim() !=
          _newPassword2Controller.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifreler birbiriyle eşleşmiyor')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        /*await _apiService.validatePerson(
          _tcknController.text.trim(),
          _newPassword1Controller.text.trim(),
        );*/

       bool resp= await _apiService.updatePin(_tcknController.text.trim(),
           '0'+ _telNoController.text.trim(),
            _newPassword1Controller.text.trim() );
        if(resp) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şifre başarıyla değiştirildi')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şifre değiştirme başarısız: ${e.toString()}'),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 👈 ARKA PLAN RENGİ
      appBar: AppBar(
        title: const Text(
          'Şifremi Unuttum',
          textAlign: TextAlign.center,
          style: AppStyles.titleLarge,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // TCKN
              TextFormField(
                controller: _tcknController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı No',
                  border: OutlineInputBorder(),
                  filled: true,                 // 👈 ZORUNLU
                  fillColor: AppColors.surface,      // 👈 ARKA PLAN
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kullanıcı No gerekli';
                  }
                  if (value.length != 11) {
                    return 'Kullanıcı No 11 haneli olmalı';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Kullanıcı No sadece rakamlardan oluşmalı';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Telefon
              TextFormField(
                controller: _telNoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                  filled: true,                 // 👈 ZORUNLU
                  fillColor: AppColors.surface,      // 👈 ARKA PLAN
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon numarası gerekli';
                  }
                  if (!RegExp(r'^[1-9][0-9]{9}$').hasMatch(value)) {
                    return 'Telefon 10 haneli olmalı ve 0 ile başlamamalı';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Yeni Şifre 1
              TextFormField(
                controller: _newPassword1Controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                  filled: true,                 // 👈 ZORUNLU
                  fillColor: AppColors.surface,      // 👈 ARKA PLAN
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yeni şifre gerekli';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Yeni Şifre 2
              TextFormField(
                controller: _newPassword2Controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  border: OutlineInputBorder(),
                  filled: true,                 // 👈 ZORUNLU
                  fillColor: AppColors.surface,      // 👈 ARKA PLAN
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yeni şifre tekrarı gerekli';
                  }
                  if (value != _newPassword1Controller.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              /*ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: AppStyles.buttonStyle,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Şifremi Değiştir'),
              ),*/
              SizedBox(
                width: double.infinity,   // 👈 TAM GENİŞLİK
                height: 56,               // 👈 YÜKSEKLİK
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: AppStyles.buttonStyle,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text('Şifremi Değiştir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tcknController.dispose();
    _telNoController.dispose();
    _newPassword1Controller.dispose();
    _newPassword2Controller.dispose();
    super.dispose();
  }
}
