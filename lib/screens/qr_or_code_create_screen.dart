import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import '../constants.dart';
import '../services/api_service.dart';

class QrOrCodeCreateScreen extends StatefulWidget {
  const QrOrCodeCreateScreen({super.key});

  @override
  State<QrOrCodeCreateScreen> createState() => _QrOrCodeCreateScreenState();
}

class _QrOrCodeCreateScreenState extends State<QrOrCodeCreateScreen> {
  final TextEditingController _receiverController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? generatedValue;
  bool isQr = false;
  bool isLoading = false;

  @override
  void dispose() {
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text("Karekod / Kod Oluştur"),
      ),
      body: Container(
        height: double.infinity, // 💡 ekranın tamamını kapla
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Alacak Kişi",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _receiverController,
                            decoration: InputDecoration(
                              hintText: "Kişi adını giriniz",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Bu alan zorunludur";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.qr_code),
                                label: const Text("QR Oluştur"),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                  if (_formKey.currentState!.validate()) {
                                    _createQr();
                                  }
                                },
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.numbers),
                                label: const Text("Kod Oluştur"),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                  if (_formKey.currentState!.validate()) {
                                    _createCode();
                                  }
                                },
                              ),
                            ],
                          ),
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (generatedValue != null) _buildResultCard(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Oluşturulan Sonuç",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          isQr
              ? QrImageView(
            data: generatedValue!,
            size: 200,
            version: QrVersions.auto,
          )
              : SelectableText(
            generatedValue!,
            style: const TextStyle(
              fontSize: 28,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
                icon: const Icon(Icons.copy),
                label: const Text("Kopyala"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: generatedValue!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kopyalandı")),
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.share),
                label: const Text("Paylaş"),
                onPressed: () {
                  Share.share(generatedValue!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createQr() async {
    if (_receiverController.text.trim().isEmpty) return;

    setState(() => isLoading = true);
    final otp = await ApiService.generateOtp(
        globals.kullaniciTCKN, _receiverController.text.trim());

    setState(() {
      isLoading = false;
      if (otp != null) {
        generatedValue = otp;
        isQr = true;
      }
    });
  }

  Future<void> _createCode() async {
    if (_receiverController.text.trim().isEmpty) return;

    setState(() => isLoading = true);
    final otp = await ApiService.generateOtp(
        globals.kullaniciTCKN, _receiverController.text.trim());

    setState(() {
      isLoading = false;
      if (otp != null) {
        generatedValue = otp;
        isQr = false;
      }
    });
  }
}


/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import '../constants.dart';
import '../services/api_service.dart'; // 🔹 OTP servisini içe al

class QrOrCodeCreateScreen extends StatefulWidget {
  const QrOrCodeCreateScreen({super.key});

  @override
  State<QrOrCodeCreateScreen> createState() => _QrOrCodeCreateScreenState();
}

class _QrOrCodeCreateScreenState extends State<QrOrCodeCreateScreen> {
  final TextEditingController _receiverController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? generatedValue;
  bool isQr = false;
  bool isLoading = false;

  @override
  void dispose() {
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text("Karekod / Kod Oluştur"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Alacak Kişi",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _receiverController,
                          decoration: InputDecoration(
                            hintText: "Kişi adını giriniz",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Bu alan zorunludur";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.qr_code),
                              label: const Text("QR Oluştur"),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                if (_formKey.currentState!.validate()) {
                                  _createQr();
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.numbers),
                              label: const Text("Kod Oluştur"),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                if (_formKey.currentState!.validate()) {
                                  _createCode();
                                }
                              },
                            ),
                          ],
                        ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (generatedValue != null) _buildResultCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Oluşturulan Sonuç",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          isQr
              ? QrImageView(
            data: generatedValue!,
            size: 200,
            version: QrVersions.auto,
          )
              : SelectableText(
            generatedValue!,
            style: const TextStyle(
              fontSize: 28,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
                icon: const Icon(Icons.copy),
                label: const Text("Kopyala"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: generatedValue!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kopyalandı")),
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.share),
                label: const Text("Paylaş"),
                onPressed: () {
                  Share.share(generatedValue!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /*Future<void> _sendToServer(String type, String value) async {
    final receiver = _receiverController.text.trim();
    final url = Uri.parse("${globals.serverAdrr}/api/qr/save");

    final body = {
      "schoolId": globals.globalSchoolId ?? 1,
      "receiver": receiver,
      "type": type,
      "value": value,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sunucuya kaydedildi ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sunucu hatası ❌ (${response.statusCode})")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sunucuya gönderilemedi ❌")),
      );
    }
  }*/

  // 🔹 QR oluşturma: OTP servisini çağırır ve sonucu QR olarak gösterir
  Future<void> _createQr() async {
    if (_receiverController.text.trim().isEmpty) return;

    setState(() => isLoading = true);
    final otp = await ApiService.generateOtp(globals.kullaniciTCKN, _receiverController.text.trim()); // tckn test değeri

    print("OTP olusan kod:"+otp.toString());

    setState(() {
      isLoading = false;
      if (otp != null) {
        generatedValue = otp;
        isQr = true;
      }
    });

   // if (otp != null) _sendToServer("QR", otp);
  }

  // 🔹 Kod oluşturma: OTP servisini çağırır ama QR değil düz metin olarak gösterir
  Future<void> _createCode() async {
    if (_receiverController.text.trim().isEmpty) return;

    setState(() => isLoading = true);
    final otp = await ApiService.generateOtp(globals.kullaniciTCKN, _receiverController.text.trim());

    setState(() {
      isLoading = false;
      if (otp != null) {
        generatedValue = otp;
        isQr = false;
      }
    });

   // if (otp != null) _sendToServer("CODE", otp);
  }
}
*/