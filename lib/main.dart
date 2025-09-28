import 'package:flutter/material.dart';

void main() {
  // Flutter widget binding'i başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulamayı çalıştır
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        appBar: AppBar(
          title: Text('iOS Minimum Test'),
        ),
        body: Center(
          child: Text(
            'Merhaba iOS!',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
