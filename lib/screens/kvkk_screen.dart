import 'package:flutter/material.dart';
import '../constants.dart';
import '../globals.dart' as globals;
import '../services/api_service.dart';
import 'home_screen.dart';
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

      if (response== "ok") {
        // Başarılı yanıt
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Başarısız yanıt
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
        title: const
        Text(
            "KVKK Metni",
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  globals.kvkkMetni ?? "KVKK metni bulunamadı.",
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _onayla,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      "Okudum, Anladım, Onaylıyorum",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _vazgec,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Vazgeç"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
