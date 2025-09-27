import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiServiceUser {
  static const String baseUrl = 'https://your-api.com/api';

  static Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Kullanıcılar alınamadı');
    }
  }

  static Future<bool> changePassword(String tckn, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$tckn/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'password': newPassword}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> uploadPhoto(String tckn, String filePath) async {
    final uri = Uri.parse('$baseUrl/users/$tckn/upload-photo');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));

    final response = await request.send();
    return response.statusCode == 200;
  }
}
