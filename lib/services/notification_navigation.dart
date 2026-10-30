import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/main.dart' show navigatorKey;
import '../globals.dart' as globals;
import '../screens/grup_mesaj_detay_screen.dart';
import '../screens/mesaj_ana_screen.dart';
import '../screens/mesaj_ana_screen_m.dart';

/// FCM / yerel bildirim tıklanınca mesaj listesi veya grup sohbetine gider.
class NotificationNavigation {
  static int? _parseGroupId(Map<String, dynamic> data) {
    for (final key in data.keys) {
      final lower = key.toLowerCase();
      if (lower == 'groupid' || lower == 'grupid') {
        return int.tryParse('${data[key]}');
      }
    }
    return null;
  }

  static String? _parseGroupName(Map<String, dynamic> data) {
    for (final key in data.keys) {
      final lower = key.toLowerCase();
      if (lower == 'name' || lower == 'grupadi' || lower == 'groupname') {
        final v = data[key]?.toString();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  static void openFromPush(Map<String, dynamic> data) {
    if (globals.kullaniciTCKN.isEmpty) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (globals.globalKullaniciTipi == 'M') {
        nav.push(MaterialPageRoute(builder: (_) => const MesajAnaScreenM()));
        return;
      }

      final groupId = _parseGroupId(data);
      if (groupId != null) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => GrupMesajDetayScreen(
              groupId: groupId,
              groupName: _parseGroupName(data) ?? 'Grup',
              tckn: globals.kullaniciTCKN,
            ),
          ),
        );
        return;
      }

      nav.push(
        MaterialPageRoute(
          builder: (_) => MesajAnaScreen(tckn: globals.kullaniciTCKN),
        ),
      );
    });
  }
}
