import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/constants.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: API ile şifre değiştirme işlemi yapılacak
    await Future.delayed(const Duration(seconds: 2)); // Simülasyon

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Şifre başarıyla değiştirildi!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:
      Text(
          'Şifre Değiştir',
          textAlign: TextAlign.center,
          style: AppStyles.titleLarge
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Mevcut şifre giriniz';
                  return null;
                },
              ),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Yeni şifre giriniz';
                  if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
                validator: (value) {
                  if (value != _newPasswordController.text) return 'Şifreler eşleşmiyor';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _changePassword,
                child: const Text('Şifreyi Değiştir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
