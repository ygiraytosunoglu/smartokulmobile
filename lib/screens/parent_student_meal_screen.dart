import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../models/meal_model.dart';
import '../globals.dart' as globals;

import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class ParentStudentsMealScreen extends StatefulWidget {
  final String parentTckn;

  const ParentStudentsMealScreen({super.key, required this.parentTckn});

  @override
  _ParentStudentsMealScreenState createState() => _ParentStudentsMealScreenState();
}

class _ParentStudentsMealScreenState extends State<ParentStudentsMealScreen> {
  AppLocalizations get t => AppLocalizations.of(context)!;
  Future<MealModel?>? futureMeal;

  Map<int, Map<String, Map<String, int>>> studentMealSelections = {};
  Map<int, int> studentSleepSelection = {};
  Map<int, String> studentSleepNotes = {};
  Map<int, int> studentMoodSelection = {};


  List<String> get mealKeys => [t.breakfast, t.lunch, t.snack];
  List<String> get moodChoices => [
    t.moodHappy,
    t.moodSad,
    t.moodTired,
    t.moodPeaceful,
    t.moodAngry
  ];
  List<String> get sleepChoices => [
    t.sleepNone,
    t.sleepLittle,
    t.sleepSlept
  ];
  final List<String> moodEmojis = ["??", "??", "??", "??", "??"];
  //final List<String> moodChoices = ["Mutlu", "�zg�n", "Yorgun", "Huzurlu", "Sinirli"];
  //final List<String> sleepChoices = ["Uyumad�", "Az Uyudu", "Uyudu"];
//  final List<String> mealKeys = [t.breakfast, t.lunch, t.snack];//["Kahvalt�", "��le", "�kindi"];

  /*List<String> moodChoices = [
    t.moodHappy,
    t.moodSad,
    t.moodTired,
    t.moodPeaceful,
    t.moodAngry
  ];

  List<String> sleepChoices = [
    t.sleepNone,
    t.sleepLittle,
    t.sleepSlept
  ];*/


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
      final response = await ApiService.authClient.get(url);
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
      debugPrint("? Veri y�kleme hatas�: $e");
    }
  }

  // ? ���n eleman� sadece okunabilir g�sterilir
  Widget buildMealItemReadOnly(int studentIndex, String mealName, String itemName) {
    int selected = studentMealSelections[studentIndex]?[mealName]?[itemName] ?? 0;
   // List<String> mealChoices = ["Yemedi", "Az Yedi", "Tamam�n� Yedi"];
    List<String> mealChoices = [
      t.didNotEat,
      t.ateLittle,
      t.ateAll
    ];
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

  // ? Yemek kartlar� a��k �ekilde
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
         Text(
         // "Duygu Durumu: ",
          "${t.moodTitle}: ",
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
             Text(
             // "Uyku: ",
              "${t.sleepTitle}: ",
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
          "A��klama: ${note.trim().isEmpty ? "-" : note}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)

        ),*/
        Text.rich(
          TextSpan(
            children: [
               TextSpan(
                text: "${t.description}: ",//"A��klama: ",
                style: TextStyle(
                  fontWeight: FontWeight.bold, // ?? sadece bu k�s�m bold
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: note.trim().isEmpty ? "-" : note,
                style: const TextStyle(
                  fontWeight: FontWeight.normal, // ?? a��klama i�eri�i normal
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
    //String studentName = student['Name'] ?? '��renci';

    String studentName = student['Name'] ?? t.studentDefaultName;

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
             /* buildMealList(studentIndex, "Kahvalt�", meal.meal1),
              buildMealList(studentIndex, "��le", meal.meal2),
              buildMealList(studentIndex, "�kindi", meal.meal3),*/
              buildMealList(studentIndex, t.breakfast, meal.meal1),
              buildMealList(studentIndex, t.lunch, meal.meal2),
              buildMealList(studentIndex, t.snack, meal.meal3)
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
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        //title: Text("G�nl�k Bilgilendirme"),
        title: Text(t.dailyInfoTitle),
      ),
      body: FutureBuilder<MealModel?>(
        future: futureMeal,
        builder: (context, snapshot) {

          // Sadece ilk y�klemede spinner g�ster
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
