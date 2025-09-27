import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Konum extends StatefulWidget {
  const Konum({super.key});

  @override
  State<Konum> createState() => KonumState();


}

class KonumState extends State<Konum> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocationScreen(),
    );
  }

}
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _konumBilgisi = "Konum bilgisi bekleniyor...";
  @override
  void initState() {
    super.initState();
    print("konum bilgisi-1");
    _konumAl();
  }

  Future<void> _konumAl() async {
    bool servisAktif = await Geolocator.isLocationServiceEnabled();
    if (!servisAktif) {
      setState(() {
        _konumBilgisi = "Konum servisi kapalı.";
      });
      return;
    }

    LocationPermission izinDurumu = await Geolocator.checkPermission();
    if (izinDurumu == LocationPermission.denied) {
      izinDurumu = await Geolocator.requestPermission();
      if (izinDurumu == LocationPermission.denied) {
        setState(() {
          _konumBilgisi = "Konum izni reddedildi.";
        });
        return;
      }
    }

    if(izinDurumu == LocationPermission.deniedForever){
      setState(() {
        _konumBilgisi = "Konum izni kalıcı olarak reddedildi.";
      });
      return;
    }

    Position konum = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _konumBilgisi = "Enlem: ${konum.latitude}, Boylam: ${konum.longitude}";

    });
    print("konum bilgisi:"+_konumBilgisi);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Konum Bilgisi"),
      ),
      body: Center(
        child: Text(_konumBilgisi),
      ),
    );
  }
}