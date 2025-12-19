import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/constants.dart'; // AppColors için

class ParentStudentsMealScreen extends StatefulWidget {
  final String parentTckn;

  const ParentStudentsMealScreen({super.key, required this.parentTckn});

  @override
  _ParentStudentsMealScreenState createState() =>
      _ParentStudentsMealScreenState();
}

class _ParentStudentsMealScreenState extends State<ParentStudentsMealScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> studentsMeals = [];

  final Map<int, String> mealEmojis = {
    0: "❓",
    1: "😞",
    2: "😐",
    3: "😊",
  };

  @override
  void initState() {
    super.initState();
    _fetchStudentsMeals();
  }

  String _today() => DateTime.now().toIso8601String().split("T").first;

  Future<void> _fetchStudentsMeals() async {
    setState(() => isLoading = true);

    try {
      final insertDate = _today();
      final url = Uri.parse(
          "${globals.serverAdrr}/api/student/getStudentsMealByParentOrTeacher"
              "?schoolId=${globals.globalSchoolId}&tckn=${globals.kullaniciTCKN}&insertDate=$insertDate");

      final response = await http.get(url);

      print("response:$response");
      print("response.body:${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            studentsMeals =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      } else {
        debugPrint("❌ API Hatası: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Hata: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildMealRow(String mealName, int status) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            "$mealName:",
            style: const TextStyle(fontSize: 16),
          ),
        ),
        ...mealEmojis.entries.map((entry) {
          final index = entry.key;
          final emoji = entry.value;
          final isSelected = index == status;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.orangeAccent, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 28,
                    color: isSelected ? Colors.orangeAccent : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = student["StudentName"]?.toString() ?? "Bilinmiyor";
    final dataStr = student["Data"]?.toString().padLeft(4, '0') ?? "0000";

    final mealStatus = {
      "sabah": int.tryParse(dataStr[0]) ?? 0,
      "ogle": int.tryParse(dataStr[1]) ?? 0,
      "ikindi": int.tryParse(dataStr[2]) ?? 0,
      "uyku": int.tryParse(dataStr[3]) ?? 0,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildMealRow("Sabah", mealStatus["sabah"] ?? 0),
            const SizedBox(height: 8),
            _buildMealRow("Öğle", mealStatus["ogle"] ?? 0),
            const SizedBox(height: 8),
            _buildMealRow("İkindi", mealStatus["ikindi"] ?? 0),
            const SizedBox(height: 8),
            _buildMealRow("Uyku", mealStatus["uyku"] ?? 0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const
        Text(
            "Öğrencilerin Yemek Bilgisi",
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background.withOpacity(0.8),
              AppColors.background.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : studentsMeals.isEmpty
                    ? const Center(
                  child: Text("Öğrenci bulunamadı."),
                )
                    : ListView.builder(
                  itemCount: studentsMeals.length,
                  itemBuilder: (context, index) {
                    return _buildStudentCard(studentsMeals[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/constants.dart'; // AppColors için

class ParentStudentsMealScreen extends StatefulWidget {
  final String parentTckn;

  const ParentStudentsMealScreen({super.key, required this.parentTckn});

  @override
  _ParentStudentsMealScreenState createState() =>
      _ParentStudentsMealScreenState();
}

class _ParentStudentsMealScreenState extends State<ParentStudentsMealScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> studentsMeals = [];

  final Map<int, String> mealEmojis = {
    0: "❓",
    1: "😞",
    2: "😐",
    3: "😊",
  };

  @override
  void initState() {
    super.initState();
    _fetchStudentsMeals();
  }

  String _today() => DateTime.now().toIso8601String().split("T").first;

  Future<void> _fetchStudentsMeals() async {
    setState(() => isLoading = true);

    try {
      final insertDate = _today();
      final url = Uri.parse(
          "${globals.serverAdrr}/api/student/getStudentsMealByParentOrTeacher"
              "?schoolId=${globals.globalSchoolId}&tckn=${globals.kullaniciTCKN}&insertDate=$insertDate");

      final response = await http.get(url);

      print("response:$response");
      print("response.body:${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            studentsMeals =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      } else {
        debugPrint("❌ API Hatası: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Hata: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildMealRow(String mealName, int status) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            "$mealName:",
            style: const TextStyle(fontSize: 16),
          ),
        ),
        ...mealEmojis.entries.map((entry) {
          final index = entry.key;
          final emoji = entry.value;
          final isSelected = index == status;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.orangeAccent, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 28,
                    color: isSelected ? Colors.orangeAccent : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = student["StudentName"]?.toString() ?? "Bilinmiyor";
    final dataStr = student["Data"]?.toString().padLeft(4, '0') ?? "0000";

    final mealStatus = {
      "sabah": int.tryParse(dataStr[0]) ?? 0,
      "ogle": int.tryParse(dataStr[1]) ?? 0,
      "ikindi": int.tryParse(dataStr[2]) ?? 0,
      "uyku": int.tryParse(dataStr[3]) ?? 0,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildMealRow("Sabah", mealStatus["sabah"] ?? 0),
            const SizedBox(height: 8),
            _buildMealRow("Öğle", mealStatus["ogle"] ?? 0),
            const SizedBox(height: 8),
            _buildMealRow("İkindi", mealStatus["ikindi"] ?? 0),
            const SizedBox(height: 8),
            _buildMealRow("Uyku", mealStatus["uyku"] ?? 0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text("Öğrencilerin Yemek/Uyku Bilgisi"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : studentsMeals.isEmpty
                    ? const Center(
                  child: Text("Öğrenci bulunamadı."),
                )
                    : ListView.builder(
                  itemCount: studentsMeals.length,
                  itemBuilder: (context, index) {
                    return _buildStudentCard(studentsMeals[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
