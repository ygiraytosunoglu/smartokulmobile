import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/constants.dart'; // AppColors için

class TeacherStudentsMealScreen extends StatefulWidget {
  final String teacherTckn;

  const TeacherStudentsMealScreen({super.key, required this.teacherTckn});

  @override
  _TeacherStudentsMealScreenState createState() =>
      _TeacherStudentsMealScreenState();
}

class _TeacherStudentsMealScreenState extends State<TeacherStudentsMealScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> studentsMeals = [];
  Map<String, Map<String, int>> mealStatuses = {};

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
      final url = Uri.parse(
          "${globals.serverAdrr}/api/student/getStudentsMealByParentOrTeacher"
              "?schoolId=${globals.globalSchoolId}&tckn=${widget.teacherTckn}&insertDate=${_today()}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            studentsMeals =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
            mealStatuses = {};
            for (var student in studentsMeals) {
              final tckn = student["StudentTCKN"]?.toString() ?? "";
              final dataStr =
                  student["Data"]?.toString().padLeft(3, '0') ?? "000";
              mealStatuses[tckn] = {
                "sabah": int.tryParse(dataStr[0]) ?? 0,
                "ogle": int.tryParse(dataStr[1]) ?? 0,
                "ikindi": int.tryParse(dataStr[2]) ?? 0,
                "uyku": dataStr.length > 3 ? int.tryParse(dataStr[3]) ?? 0 : 0,
              };
            }
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Hata: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildMealRow(String tckn, String mealName, String mealKey) {
    final selected = mealStatuses[tckn]?[mealKey] ?? 0;
    return Row(
      children: [
        SizedBox(width: 60, child: Text(mealName, style: const TextStyle(fontSize: 14))),
        ...mealEmojis.entries.map((entry) {
          final index = entry.key;
          final emoji = entry.value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  mealStatuses[tckn]![mealKey] = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  border: index == selected
                      ? Border.all(color: Colors.orangeAccent, width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(
                        fontSize: 22,
                        color: index == selected
                            ? Colors.orangeAccent
                            : Colors.grey),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> student) {
    final name = student["StudentName"]?.toString() ?? "Bilinmiyor";
    final tckn = student["StudentTCKN"]?.toString() ?? "";
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildMealRow(tckn, "Sabah", "sabah"),
            const SizedBox(height: 4),
            _buildMealRow(tckn, "Öğle", "ogle"),
            const SizedBox(height: 4),
            _buildMealRow(tckn, "İkindi", "ikindi"),
            const SizedBox(height: 4),
            _buildMealRow(tckn, "Uyku", "uyku"),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAllMeals() async {
    setState(() => isLoading = true);
    try {
      final insertDate = _today();
      for (var entry in mealStatuses.entries) {
        final tckn = entry.key;
        final data = entry.value;
        final dataStr =
            "${data["sabah"]}${data["ogle"]}${data["ikindi"]}${data["uyku"]}";
        final url = Uri.parse(
            "${globals.serverAdrr}/api/student/addMeal"
                "?schoolId=${globals.globalSchoolId}"
                "&studentTckn=$tckn"
                "&insertDate=$insertDate"
                "&data=$dataStr");
        final response = await http.get(url);
        if (response.statusCode != 200) {
          debugPrint(
              "❌ Kaydetme hatası ($tckn): ${response.statusCode} - ${response.body}");
        }
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Tüm yemekler kaydedildi")));
    } catch (e) {
      debugPrint("❌ SaveAll Exception: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("❌ Kaydetme hatası")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const
        Text(
            "Yemek/Uyku Bilgileri",
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : studentsMeals.isEmpty
              ? const Center(
              child: Text("Bu öğretmene ait öğrenci bulunamadı."))
              : Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchStudentsMeals,
                  child: ListView.builder(
                    itemCount: studentsMeals.length,
                    itemBuilder: (context, index) {
                      return _buildMealCard(studentsMeals[index]);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: _saveAllMeals,
                  icon: const Icon(Icons.save),
                  label: const Text("Tümünü Kaydet"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
