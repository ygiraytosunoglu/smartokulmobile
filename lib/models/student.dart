class Student {
  final String name;
  final String tckn;
  final String? photoUrl;
  final int? classId;
  final String className;

  Student({
    required this.name,
    required this.tckn,
    this.photoUrl,
    this.classId,
    this.className = '',
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final classId = json['classId'] ??
        json['ClassId'] ??
        json['sinifId'] ??
        json['SinifId'];
    final className = (json['className'] ??
            json['ClassName'] ??
            json['sinifAd'] ??
            json['SinifAd'] ??
            json['sinifAdi'] ??
            '')
        .toString();
    return Student(
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      tckn: (json['tckn'] ?? json['TCKN'] ?? '').toString(),
      photoUrl: json['photoUrl']?.toString(),
      classId: classId is int
          ? classId
          : int.tryParse(classId?.toString().split('.').first ?? ''),
      className: className,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'TCKN': tckn,
      'photoUrl': photoUrl,
      'ClassId': classId,
      'ClassName': className,
    };
  }
}
