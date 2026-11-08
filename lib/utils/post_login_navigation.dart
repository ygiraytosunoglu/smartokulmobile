import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/screens/change_password_screen.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import 'package:smart_okul_mobile/screens/kvkk_screen.dart';
import 'package:smart_okul_mobile/screens/student_notification_screen.dart';
import 'package:smart_okul_mobile/utils/pin_policy.dart';

/// Sadece veli: MenuTanim'da Anons varsa anons ekranı, yoksa ana sayfa.
bool parentHasAnonsMenu() {
  if (globals.globalKullaniciTipi != 'P') return false;
  return globals.menuListesi.any(
    (m) => m.trim().toLowerCase() == 'anons',
  );
}

void navigateParentOrHome(BuildContext context) {
  if (!context.mounted) return;
  if (parentHasAnonsMenu()) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentNotificationScreen()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

Future<void> navigateAfterSuccessfulLogin(
  BuildContext context, {
  String? currentPin,
}) async {
  var pin = currentPin ?? '';
  if (pin.isEmpty) {
    final prefs = await SharedPreferences.getInstance();
    pin = prefs.getString('sifre') ?? '';
  }
  if (!context.mounted) return;

  if (globals.mustChangePin || isDefaultPin(pin)) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          tckn: globals.kullaniciTCKN.isNotEmpty
              ? globals.kullaniciTCKN
              : globals.orjKullaniciTCKN,
          currentPin: pin,
          forced: true,
        ),
      ),
    );
    return;
  }

  if (globals.kvkk == '1') {
    // Veli: Anons menüsü varsa anons, yoksa ana sayfa. Diğer roller: ana sayfa.
    navigateParentOrHome(context);
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KvkkScreen()),
    );
  }
}
