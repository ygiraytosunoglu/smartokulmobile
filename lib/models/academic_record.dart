import 'conversation_item.dart';

enum AcademicRecordType { ozelDers, etut }

class AcademicRecord {
  final int? id;
  final int? okulId;
  final int? studentPersonId;
  final String studentName;
  final String studentTckn;
  final String studentTcknOrig;
  final String createdByName;
  final DateTime? tarih;
  final String saat;
  final String ders;
  final String konu;
  final String aciklama;
  final int? dersId;
  final int? temaId;
  final int? konuId;
  final int? sinifSeviye;
  final String tema;
  final String kazanim;
  final int? soruSayisi;
  final int? dogruSayisi;
  final int? yanlisSayisi;

  AcademicRecord({
    this.id,
    this.okulId,
    this.studentPersonId,
    this.studentName = '',
    this.studentTckn = '',
    this.studentTcknOrig = '',
    this.createdByName = '',
    this.tarih,
    this.saat = '',
    this.ders = '',
    this.konu = '',
    this.aciklama = '',
    this.dersId,
    this.temaId,
    this.konuId,
    this.sinifSeviye,
    this.tema = '',
    this.kazanim = '',
    this.soruSayisi,
    this.dogruSayisi,
    this.yanlisSayisi,
  });

  factory AcademicRecord.fromJson(Map json) {
    return AcademicRecord(
      id: jsonInt(json, 'id'),
      okulId: jsonInt(json, 'okulId'),
      studentPersonId: jsonInt(json, 'studentPersonId'),
      studentName: jsonString(json, 'studentName') ?? '',
      studentTckn: jsonString(json, 'studentTckn') ?? '',
      studentTcknOrig: jsonString(json, 'studentTcknOrig') ?? '',
      createdByName: jsonString(json, 'createdByName') ?? '',
      tarih: jsonDate(json, 'tarih'),
      saat: jsonString(json, 'saat') ?? '',
      ders: jsonString(json, 'ders') ?? '',
      konu: jsonString(json, 'konu') ?? '',
      aciklama: jsonString(json, 'aciklama') ?? '',
      dersId: jsonInt(json, 'dersId'),
      temaId: jsonInt(json, 'temaId'),
      konuId: jsonInt(json, 'konuId'),
      sinifSeviye: jsonInt(json, 'sinifSeviye'),
      tema: jsonString(json, 'tema') ?? '',
      kazanim: jsonString(json, 'kazanim') ?? '',
      soruSayisi: jsonInt(json, 'soruSayisi'),
      dogruSayisi: jsonInt(json, 'dogruSayisi'),
      yanlisSayisi: jsonInt(json, 'yanlisSayisi'),
    );
  }

  String get tarihYazi {
    if (tarih == null) return '';
    final d = tarih!.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  String get saatYazi {
    final s = saat.trim();
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  String get etutOzet {
    if (soruSayisi == null && dogruSayisi == null && yanlisSayisi == null) {
      return '';
    }
    return 'S:${soruSayisi ?? 0}  D:${dogruSayisi ?? 0}  Y:${yanlisSayisi ?? 0}';
  }

  List<String> get kazanimSatirlari => kazanim
      .split(RegExp(r'[\r\n]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}
