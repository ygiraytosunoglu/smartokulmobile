class UserModel {
  final int id;
  final String name;
  final String telNo;
  final String tckn;
  final int schoolId;

  UserModel({
    required this.id,
    required this.name,
    required this.telNo,
    required this.tckn,
    required this.schoolId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['Id'] ?? 0,
      name: json['Name'] ?? '',
      telNo: json['TelNo'] ?? '',
      tckn: json['TCKN'] ?? '',
      schoolId: json['SchoolId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'TelNo': telNo,
      'TCKN': tckn,
      'SchoolId': schoolId,
    };
  }
}