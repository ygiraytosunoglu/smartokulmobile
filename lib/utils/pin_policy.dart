const String pinPolicyMessage =
    'Yeni şifre en az 8 karakter olmalı; en az bir harf ve bir rakam içermelidir.';

/// Okul varsayılan / ilk şifre — bu PIN ile ana ekrana girilmez.
bool isDefaultPin(String pin) {
  final p = pin.trim();
  return p == '0000' || p == '00000' || p == '000000';
}

bool isValidPin(String pin) {
  if (pin.length < 8) return false;
  final hasLetter = RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(pin);
  final hasDigit = RegExp(r'[0-9]').hasMatch(pin);
  return hasLetter && hasDigit;
}

String? validateNewPin(String? value) {
  if (value == null || value.isEmpty) return 'Yeni şifre giriniz';
  if (!isValidPin(value)) return pinPolicyMessage;
  return null;
}
