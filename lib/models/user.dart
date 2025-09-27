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

class User {
  final int id;
  final String name;
  final String telNo;
  final String tckn;
  final String type;
  final int schoolId;
  final String konumEnlem;
  final String konumBoylam;
  final int mesafeLimit;
  final String schoolName;
  final List<Student> students;

  User({
    required this.id,
    required this.name,
    required this.telNo,
    required this.tckn,
    required this.type,
    required this.schoolId,
    required this.konumEnlem,
    required this.konumBoylam,
    required this.mesafeLimit,
    required this.schoolName,
    required this.students,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var studentList = <Student>[];
    if (json['Students'] != null) {
      studentList = List<Map<String, dynamic>>.from(json['Students'])
          .map((studentJson) => Student.fromJson(studentJson))
          .toList();
    }
    return User(
      id: json['Id'] ?? 0,
      name: json['Name'] ?? '',
      telNo: json['TelNo'] ?? '',
      tckn: json['TCKN'] ?? '',
      type: json['Type'] ?? '',
      schoolId: json['SchoolId'] ?? 0,
      konumEnlem: json['KonumEnlem'] ?? '',
      konumBoylam: json['KonumBoylam'] ?? '',
      mesafeLimit: json['MesafeLimit'] ?? 0,
      schoolName: json['SchoolName'] ?? '',
      students: studentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'TelNo': telNo,
      'TCKN': tckn,
      'Type': type,
      'SchoolId': schoolId,
      'KonumEnlem': konumEnlem,
      'KonumBoylam': konumBoylam,
      'MesafeLimit': mesafeLimit,
      'SchoolName': schoolName,
      'Students': students.map((s) => s.toJson()).toList(),
    };
  }
}


/*class User {
  final String tckn;
  final String name;
  final String surname;
  final String? email;
  final String? phone;
  final String? classname;
  final String photourl;

  User({
    required this.tckn,
    required this.name,
    required this.surname,
    this.email,
    this.phone,
    this.classname,
    required this.photourl
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      tckn: json['tckn'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      classname: json['classname'] as String?,
      photourl: json['photourl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tckn': tckn,
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'classname': classname,
      'photourl': photourl,
    };
  }
} */