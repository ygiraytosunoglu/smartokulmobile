import 'conversation_item.dart';

class DersItem {
  final int id;
  final String ad;

  DersItem({required this.id, required this.ad});

  factory DersItem.fromJson(Map json) {
    return DersItem(
      id: jsonInt(json, 'id') ?? 0,
      ad: jsonString(json, 'ad') ??
          jsonString(json, 'dersAdi') ??
          jsonString(json, 'name') ??
          '',
    );
  }
}

class DersTema {
  final int id;
  final int? dersId;
  final int? sinifSeviye;
  final String ad;

  DersTema({
    required this.id,
    this.dersId,
    this.sinifSeviye,
    required this.ad,
  });

  factory DersTema.fromJson(Map json) {
    return DersTema(
      id: jsonInt(json, 'id') ?? 0,
      dersId: jsonInt(json, 'dersId'),
      sinifSeviye: jsonInt(json, 'sinifSeviye'),
      ad: jsonString(json, 'ad') ?? '',
    );
  }
}

class DersKazanim {
  final int id;
  final String ad;

  DersKazanim({required this.id, required this.ad});

  factory DersKazanim.fromJson(Map json) {
    return DersKazanim(
      id: jsonInt(json, 'id') ?? 0,
      ad: jsonString(json, 'ad') ?? '',
    );
  }
}

class DersKonu {
  final int id;
  final int? temaId;
  final String ad;
  final int? sinifSeviye;
  final List<DersKazanim> kazanimlar;
  final String kazanim;

  DersKonu({
    required this.id,
    this.temaId,
    required this.ad,
    this.sinifSeviye,
    this.kazanimlar = const [],
    this.kazanim = '',
  });

  factory DersKonu.fromJson(Map json) {
    final raw = jsonField(json, 'kazanimlar');
    final list = <DersKazanim>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(DersKazanim.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final birlesik = jsonString(json, 'kazanim') ?? '';
    return DersKonu(
      id: jsonInt(json, 'id') ?? 0,
      temaId: jsonInt(json, 'temaId'),
      ad: jsonString(json, 'ad') ?? '',
      sinifSeviye: jsonInt(json, 'sinifSeviye'),
      kazanimlar: list,
      kazanim: birlesik,
    );
  }
}
