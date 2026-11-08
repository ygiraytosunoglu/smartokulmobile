import 'package:flutter/material.dart';
import '../constants.dart';
import '../globals.dart' as globals;
import '../services/api_service.dart';
import '../utils/post_login_navigation.dart';
import 'login_screen.dart';

class KvkkScreen extends StatefulWidget {
  const KvkkScreen({super.key});

  @override
  State<KvkkScreen> createState() => _KvkkScreenState();
}

class _KvkkScreenState extends State<KvkkScreen> {
  bool _loading = false;
  final ApiService _apiService = ApiService();

  Future<void> _onayla() async {
    setState(() => _loading = true);

    try {
      final response = await _apiService.kvkkEkle(globals.orjKullaniciTCKN);

      if (response == "ok") {
        if (!mounted) return;
        globals.kvkk = '1';
        // Veli + Anons menüsü → anons; aksi halde ana sayfa
        navigateParentOrHome(context);
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _vazgec() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "KVKK Metni",
          textAlign: TextAlign.center,
          style: AppStyles.titleLarge,
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    globals.kvkkMetni.isNotEmpty
                        ? globals.kvkkMetni
                        : "KVKK metni bulunamadı.",
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _onayla,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        "Okudum, Anladım, Onaylıyorum",
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _vazgec,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: const Text("Vazgeç"),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
