import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../models/meal_model.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;

class ParentStudentsMealScreen extends StatefulWidget {
  final String parentTckn;

  const ParentStudentsMealScreen({super.key, required this.parentTckn});

  @override
  _ParentStudentsMealScreenState createState() => _ParentStudentsMealScreenState();
}

class _ParentStudentsMealScreenState extends State<ParentStudentsMealScreen> {
  Future<MealModel?>? futureMeal;

  Map<int, Map<String, Map<String, int>>> studentMealSelections = {};
  Map<int, int> studentSleepSelection = {};
  Map<int, String> studentSleepNotes = {};
  Map<int, int> studentMoodSelection = {};

  final List<String> moodChoices = ["Mutlu", "Üzgün", "Yorgun", "Huzurlu", "Sinirli"];
  final List<String> moodEmojis = ["😊", "😢", "😴", "😌", "😡"];
  final List<String> sleepChoices = ["Uyumadı", "Az Uyudu", "Uyudu"];
  final List<String> mealKeys = ["Kahvaltı", "Öğle", "İkindi"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    String fixedDate =DateFormat('yyyy-MM-dd').format(DateTime.now());// "2025-11-01";
    futureMeal = ApiService.getMealList(widget.parentTckn, fixedDate);

    final insertDate = fixedDate;
    final url = Uri.parse(
        "${globals.serverAdrr}/api/student/getStudentsMealByParentOrTeacher"
            "?schoolId=${globals.globalSchoolId}&tckn=${globals.kullaniciTCKN}&insertDate=$insertDate"
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> savedData =
        response.body.isNotEmpty && response.body.startsWith('[')
            ? jsonDecode(response.body)
            : [];

        for (int i = 0; i < globals.globalOgrenciListesi.length; i++) {
          final student = globals.globalOgrenciListesi[i];
          final tckn = student['TCKN'];

          final studentRecord = savedData.firstWhere(
                (element) => element['StudentTCKN'] == tckn,
            orElse: () => null,
          );

          if (studentRecord != null) {
            final dataStr = studentRecord['Data'] as String;
            final parts = dataStr.split('|');

            if (parts.length >= 6) {
              studentMealSelections[i] = {};
              for (int j = 0; j < mealKeys.length; j++) {
                final mealItems = parts[j].split(',');
                studentMealSelections[i]![mealKeys[j]] = {};
                for (var item in mealItems) {
                  if (item.contains(':')) {
                    final kv = item.split(':');
                    studentMealSelections[i]![mealKeys[j]]![kv[0]] =
                        int.tryParse(kv[1]) ?? 0;
                  }
                }
              }

              studentSleepSelection[i] = int.tryParse(parts[3]) ?? -1;

              final moodIdx = moodChoices.indexOf(parts[4]);
              studentMoodSelection[i] = moodIdx >= 0 ? moodIdx : -1;

              studentSleepNotes[i] = parts[5].trim().isEmpty ? "-" : parts[5];

            }
          }
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("❌ Veri yükleme hatası: $e");
    }
  }

  // ✔ Öğün elemanı sadece okunabilir gösterilir
  Widget buildMealItemReadOnly(int studentIndex, String mealName, String itemName) {
    int selected = studentMealSelections[studentIndex]?[mealName]?[itemName] ?? 0;
    List<String> mealChoices = ["Yemedi", "Az Yedi", "Tamamını Yedi"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(itemName,
            style: const TextStyle(fontSize: 14, color: AppColors.primary)),
        Text(
          mealChoices[selected],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        )
      ],
    );
  }

  // ✔ Yemek kartları açık şekilde
  Widget buildMealList(int studentIndex, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 6),
        ...items.map((e) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildMealItemReadOnly(studentIndex, title, e),
          ),
        )),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildMoodSection(int studentIndex) {
    int index = studentMoodSelection[studentIndex] ?? -1;

    return Row(
      children: [
        const Text(
          "Duygu Durumu: ",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          (index < 0 || index >= moodChoices.length)
              ? "-"
              : "${moodEmojis[index]} ${moodChoices[index]}",
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget buildSleepSection(int studentIndex) {
    int index = studentSleepSelection[studentIndex] ?? -1;
    String note = studentSleepNotes[studentIndex] ?? "-";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Uyku: ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              (index < 0 || index >= sleepChoices.length)
                  ? "-"
                  : sleepChoices[index],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 6),
        /*Text(
          "Açıklama: ${note.trim().isEmpty ? "-" : note}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)

        ),*/
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: "Açıklama: ",
                style: TextStyle(
                  fontWeight: FontWeight.bold, // 👈 sadece bu kısım bold
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: note.trim().isEmpty ? "-" : note,
                style: const TextStyle(
                  fontWeight: FontWeight.normal, // 👈 açıklama içeriği normal
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget buildStudentCard(int studentIndex, Map<String, dynamic> student, MealModel? meal) {
    String studentName = student['Name'] ?? 'Öğrenci';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(studentName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),

            if (meal != null) ...[
              buildMealList(studentIndex, "Kahvaltı", meal.meal1),
              buildMealList(studentIndex, "Öğle", meal.meal2),
              buildMealList(studentIndex, "İkindi", meal.meal3),
            ],


            buildSleepSection(studentIndex),
            const SizedBox(height: 12),

            buildMoodSection(studentIndex),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text("Günlük Bilgilendirme"),
      ),
      body: FutureBuilder<MealModel?>(
        future: futureMeal,
        builder: (context, snapshot) {

          // Sadece ilk yüklemede spinner göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final meal = snapshot.data; // null olabilir
          final filteredStudents = globals.globalOgrenciListesi
              .where((s) => s['TCKN'] == globals.studentTckn)
              .toList();

          return ListView.builder(
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];

              // Orijinal listedeki index'i bul
              final originalIndex =
              globals.globalOgrenciListesi.indexOf(student);

              return buildStudentCard(
                originalIndex,
                student,
                meal,
              );
            },

          );
        },
      ),

    );
  }
}
