import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;

class QRScanOrManualScreen extends StatefulWidget {
  const QRScanOrManualScreen({super.key});

  @override
  State<QRScanOrManualScreen> createState() => _QRScanOrManualScreenState();
}

class _QRScanOrManualScreenState extends State<QRScanOrManualScreen>
    with SingleTickerProviderStateMixin {
  // Tab Controller
  late TabController _tabController;

  // QR Scanner
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedData;

  // Manual OTP
 // final TextEditingController _tcknController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Verification State
  bool isVerifying = false;
  String? verifyMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    controller?.dispose();
    //_tcknController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // QR Tarayıcı
  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    ctrl.scannedDataStream.listen((scanData) {
      if (scannedData == null) {
        setState(() {
          scannedData = scanData.code;
        });
        controller?.pauseCamera();
        _verifyScannedData(scanData.code ?? "");
      }
    });
  }

  Future<void> _verifyScannedData(String data) async {
    setState(() {
      isVerifying = true;
      verifyMessage = null;
    });

    try {
      // QR format: TCKN=12345678901;OTP=ABC123
      final parts = data.split(';');
      //String? tckn;
      String? otp;

      for (var p in parts) {
        /*if (p.startsWith('TCKN=')) {
          tckn = p.replaceFirst('TCKN=', '').trim();
        } else */
        if (p.startsWith('OTP=')) {
          otp = p.replaceFirst('OTP=', '').trim();
        }
      }

      if (//tckn == null ||
          otp == null) {
        setState(() {
          verifyMessage = "Geçersiz QR kod formatı ❌";
          isVerifying = false;
        });
        return;
      }


      final result = await ApiService.verifyOtp(globals.kullaniciTCKN, otp);

     /* if (result != null && result.isNotEmpty) {
        for (var person in result) {
          print("TCKN: ${person['TCKN']} - Ad: ${person['PersonName']}");
        }
      }*/
      setState(() {
        isVerifying = false;
        if (result != null && result.isNotEmpty) {
          verifyMessage = "✅ Kod Doğrulandı: ${result[0]['LogName']}";
        } else {
          verifyMessage = "❌ OTP geçersiz veya süresi dolmuş";
        }
      });
    } catch (e) {
      setState(() {
        isVerifying = false;
        verifyMessage = "Hata: $e";
      });
    }
  }

  // Manuel OTP doğrulama
  Future<void> _verifyManualOtp() async {
    //final tckn = _tcknController.text.trim();
    final otp = _otpController.text.trim();

    if (//tckn.isEmpty ||
        otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP boş olamaz")),
      );
      return;
    }

    setState(() {
      isVerifying = true;
      verifyMessage = null;
    });

    final result = await ApiService.verifyOtp(globals.kullaniciTCKN, otp);

    setState(() {
      isVerifying = false;
      if (result != null && result.isNotEmpty) {
        verifyMessage = "✅ Kod Doğrulandı: ${result[0]['LogName']}";
      } else {
        verifyMessage = "❌ OTP geçersiz veya süresi dolmuş";
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR / Kod Doğrulama"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: "QR Oku"),
            Tab(icon: Icon(Icons.keyboard), text: "Kod Gir"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // QR Tab
          Container(
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
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 4,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: scannedData == null
                          ? const Center(
                        child: Text(
                          "Lütfen kamerayı bir QR koda doğru tutun",
                          style:
                          TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SelectableText(
                            scannedData!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isVerifying)
                            const CircularProgressIndicator()
                          else if (verifyMessage != null)
                            Text(
                              verifyMessage!,
                              style: TextStyle(
                                fontSize: 16,
                                color: verifyMessage!.contains("✅")
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                icon: const Icon(Icons.copy),
                                label: const Text("Kopyala"),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: scannedData!));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                      content:
                                      Text("Kod panoya kopyalandı")));
                                },
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                                icon: const Icon(Icons.share),
                                label: const Text("Paylaş"),
                                onPressed: () {
                                  Share.share(scannedData!);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text("Tekrar Tara"),
                            onPressed: () {
                              setState(() {
                                scannedData = null;
                                verifyMessage = null;
                              });
                              controller?.resumeCamera();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Manual OTP Tab
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /*TextField(
                  controller: _tcknController,
                  decoration: InputDecoration(
                    labelText: "TCKN",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),*/
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: "OTP Kod",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.check),
                  label: const Text("Doğrula"),
                  onPressed: isVerifying ? null : _verifyManualOtp,
                ),
                const SizedBox(height: 16),
                if (isVerifying) const CircularProgressIndicator(),
                if (verifyMessage != null)
                  Text(
                    verifyMessage!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: verifyMessage!.contains("✅")
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../constants.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedData;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    ctrl.scannedDataStream.listen((scanData) {
      if (scannedData == null) {
        setState(() {
          scannedData = scanData.code;
        });
        controller?.pauseCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Kod Oku"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
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
          child: Column(
            children: [
              const SizedBox(height: 24),
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: scannedData == null
                      ? const Center(
                    child: Text(
                      "Lütfen kamerayı bir QR koda doğru tutun",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Okunan Kod:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        scannedData!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            icon: const Icon(Icons.copy),
                            label: const Text("Kopyala"),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: scannedData!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Kod panoya kopyalandı"),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            icon: const Icon(Icons.share),
                            label: const Text("Paylaş"),
                            onPressed: () {
                              Share.share(scannedData!);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("Tekrar Tara"),
                        onPressed: () {
                          setState(() => scannedData = null);
                          controller?.resumeCamera();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
