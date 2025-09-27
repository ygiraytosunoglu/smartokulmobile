class Student {
  final String name;
  final String tckn;
  final String? photoUrl;

  Student({
    required this.name,
    required this.tckn,
    this.photoUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['Name'] ?? '',
      tckn: json['TCKN'] ?? '',
      photoUrl: json['photoUrl'], // Opsiyonel olabilir
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'TCKN': tckn,
      'photoUrl': photoUrl,
    };
  }
}
