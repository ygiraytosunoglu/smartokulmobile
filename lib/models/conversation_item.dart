/// ASP.NET camelCase / PascalCase farkını yutan alan okuyucu.
dynamic jsonField(Map json, String name) {
  final target = name.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toString().toLowerCase() == target) return entry.value;
  }
  return null;
}

int? jsonInt(Map json, String name) {
  final v = jsonField(json, name);
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().split('.').first);
}

bool jsonBool(Map json, String name, {bool fallback = false}) {
  final v = jsonField(json, name);
  if (v == true || v == 1 || v == '1' || v == 'true' || v == 'True') return true;
  if (v == false || v == 0 || v == '0' || v == 'false' || v == 'False') {
    return false;
  }
  return fallback;
}

DateTime? jsonDate(Map json, String name) {
  final v = jsonField(json, name);
  if (v == null || v.toString().isEmpty) return null;
  return DateTime.tryParse(v.toString());
}

String? jsonString(Map json, String name) {
  final v = jsonField(json, name);
  if (v == null) return null;
  final s = v.toString();
  return s;
}

class ConversationItem {
  final bool isGroup;
  final int? groupId;
  final String? tckn;
  final String name;
  final String? studentName;
  final int isRead;
  final DateTime? lastMessageDate;

  ConversationItem({
    required this.isGroup,
    this.groupId,
    this.tckn,
    required this.name,
    this.studentName,
    required this.isRead,
    this.lastMessageDate,
  });

  factory ConversationItem.fromJson(Map json) {
    final name = jsonString(json, 'name') ?? '';
    final student = jsonString(json, 'studentName');
    return ConversationItem(
      isGroup: jsonBool(json, 'isGroup'),
      groupId: jsonInt(json, 'groupId') ?? jsonInt(json, 'grupId'),
      tckn: jsonString(json, 'tckn'),
      name: name,
      studentName: (student == null || student.isEmpty) ? null : student,
      isRead: _parseIsRead(json),
      lastMessageDate: jsonDate(json, 'lastMessageDate'),
    );
  }

  /// GetMessageableContacts yanıtı → henüz sohbeti olmayan veli satırı.
  factory ConversationItem.fromContactJson(Map json) {
    final name = jsonString(json, 'name') ?? '';
    final student = jsonString(json, 'studentName');
    return ConversationItem(
      isGroup: false,
      tckn: jsonString(json, 'tckn'),
      name: name,
      studentName: (student == null || student.isEmpty) ? null : student,
      isRead: 1,
      lastMessageDate: null,
    );
  }

  static int _parseIsRead(Map json) {
    final v = jsonField(json, 'isRead');
    if (v == null) return 1;
    if (v is bool) return v ? 1 : 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 1;
  }

  bool get isUnread => isRead == 0;
}

/// 1:1 ve grup mesajını mevcut balon alanlarıyla hizalar (ek + saat dahil).
Map<String, dynamic> normalizeChatMessage(Map json) {
  final insert = jsonString(json, 'insertDate') ??
      DateTime.now().toIso8601String();
  final hasAtt = jsonBool(json, 'hasAttachment') ||
      (jsonString(json, 'dosyaUrl') ?? '').isNotEmpty ||
      (jsonString(json, 'dosyaAdi') ?? '').isNotEmpty;
  return {
    'Id': jsonInt(json, 'id'),
    'GrupId': jsonInt(json, 'grupId') ?? jsonInt(json, 'groupId'),
    'GonderenId': jsonInt(json, 'gonderenId'),
    'GonderenAdi': jsonString(json, 'gonderenAdi') ?? '',
    'GonderenTCKN': jsonString(json, 'gonderenTCKN') ??
        jsonString(json, 'gonderenTckn') ??
        '',
    'GonderenTCKNFull': jsonString(json, 'gonderenTCKNFull') ??
        jsonString(json, 'gonderenTcknFull') ??
        '',
    'AlanTCKN': jsonString(json, 'alanTCKN') ?? jsonString(json, 'alanTckn') ?? '',
    'Baslik': jsonString(json, 'baslik') ?? '',
    'Data': jsonString(json, 'data') ?? '',
    'InsertDate': insert,
    'Saat': jsonString(json, 'saat') ?? '',
    'Tarih': jsonString(json, 'tarih') ?? '',
    'HasAttachment': hasAtt,
    'DosyaAdi': jsonString(json, 'dosyaAdi') ?? '',
    'DosyaTipi': jsonString(json, 'dosyaTipi') ?? '',
    'DosyaBoyut': jsonInt(json, 'dosyaBoyut'),
    'EkTuru': jsonString(json, 'ekTuru') ?? '',
    'DosyaUrl': jsonString(json, 'dosyaUrl') ?? '',
  };
}

Map<String, dynamic> normalizeGroupMessage(Map json) =>
    normalizeChatMessage(json);

class GroupMember {
  final String name;
  final String? tckn;
  final String? type;

  GroupMember({required this.name, this.tckn, this.type});

  factory GroupMember.fromJson(Map json) {
    final merged = Map<String, dynamic>.from(json);
    for (final key in ['person', 'kisi', 'uye', 'user', 'member', 'ogretmen', 'veli']) {
      final nested = jsonField(json, key);
      if (nested is Map) {
        merged.addAll(Map<String, dynamic>.from(nested));
      }
    }
    final name = jsonString(merged, 'name') ??
        jsonString(merged, 'ad') ??
        jsonString(merged, 'adi') ??
        jsonString(merged, 'gonderenAdi') ??
        jsonString(merged, 'fullName') ??
        jsonString(merged, 'personName') ??
        jsonString(merged, 'adSoyad') ??
        jsonString(merged, 'adsoyad') ??
        '';
    final tckn = jsonString(merged, 'tckn') ??
        jsonString(merged, 'tcknFull') ??
        jsonString(merged, 'gonderenTCKNFull') ??
        jsonString(merged, 'gonderenTckn') ??
        jsonString(merged, 'tcknOrig');
    var type = jsonString(merged, 'type') ??
        jsonString(merged, 'tip') ??
        jsonString(merged, 'kullaniciTipi') ??
        jsonString(merged, 'role') ??
        jsonString(merged, 'personType');
    if ((type == null || type.isEmpty) && tckn != null && tckn.contains('_')) {
      type = tckn.split('_').last;
    }
    return GroupMember(
      name: name.trim().isEmpty ? 'Üye' : name.trim(),
      tckn: tckn,
      type: type,
    );
  }

  String get typeLabel {
    switch ((type ?? '').toUpperCase()) {
      case 'T':
      case 'OGRETMEN':
      case 'TEACHER':
        return 'Öğretmen';
      case 'P':
      case 'VELI':
      case 'PARENT':
        return 'Veli';
      case 'M':
      case 'MUDUR':
      case 'MANAGER':
        return 'Müdür';
      default:
        return '';
    }
  }
}

bool _looksLikeMemberMap(Map json) {
  return jsonString(json, 'tckn') != null ||
      jsonString(json, 'ad') != null ||
      jsonString(json, 'name') != null ||
      jsonString(json, 'adi') != null ||
      jsonString(json, 'adSoyad') != null ||
      jsonField(json, 'person') != null ||
      jsonField(json, 'kisi') != null;
}

List<dynamic> extractMemberList(dynamic data) {
  if (data is String) return [];
  if (data is List) {
    if (data.isEmpty) return data;
    if (data.first is Map) {
      final first = Map<String, dynamic>.from(data.first as Map);
      final nested = _memberArrayFromMap(first);
      if (nested != null) {
        // Liste grup özetleri; her gruptaki üyeleri burada ayıklamayız.
        return data;
      }
      return data;
    }
    return data;
  }
  if (data is Map) {
    final fromKey = _memberArrayFromMap(Map<String, dynamic>.from(data));
    if (fromKey != null) return fromKey;
    for (final value in data.values) {
      final nested = extractMemberList(value);
      if (nested.isNotEmpty && nested.first is Map && _looksLikeMemberMap(Map<String, dynamic>.from(nested.first as Map))) {
        return nested;
      }
    }
  }
  return [];
}

List<dynamic>? _memberArrayFromMap(Map<String, dynamic> map) {
  for (final key in [
    'uyeler',
    'members',
    'uyeList',
    'memberList',
    'kisiler',
    'people',
    'mesajGrupUyeler',
    'grupUyeler',
    'uyeListesi',
    'memberListesi',
    'items',
    'data',
    'result',
  ]) {
    final v = jsonField(map, key);
    if (v is List) return v;
  }
  return null;
}

/// /api/mesaj-grup/list cevabından ilgili grubun üyelerini çıkarır.
List<dynamic> extractMembersFromGroupList(dynamic data, int grupId) {
  List list;
  if (data is List) {
    list = data;
  } else if (data is Map) {
    list = extractMemberList(data);
  } else {
    return [];
  }

  for (final item in list) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final id = jsonInt(map, 'id') ??
        jsonInt(map, 'grupId') ??
        jsonInt(map, 'groupId');
    if (id != grupId) continue;
    final inner = _memberArrayFromMap(map);
    if (inner != null) return inner;
  }

  if (list.isNotEmpty && list.first is Map) {
    final first = Map<String, dynamic>.from(list.first as Map);
    if (_looksLikeMemberMap(first) &&
        jsonInt(first, 'groupId') == null &&
        jsonField(first, 'isGroup') == null) {
      return list;
    }
  }
  return [];
}
