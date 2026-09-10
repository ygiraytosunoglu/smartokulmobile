
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../models/meal_model.dart';
import '../globals.dart' as globals;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

bool isLoading = false;

class TeacherStudentsMealScreen extends StatefulWidget {
  final String teacherTckn;

  const TeacherStudentsMealScreen({super.key, required this.teacherTckn});

  @override
  _TeacherStudentsMealScreenState createState() => _TeacherStudentsMealScreenState();
}

class _TeacherStudentsMealScreenState extends State<TeacherStudentsMealScreen> {
  AppLocalizations get t => AppLocalizations.of(context)!;

  Future<MealModel?>? futureMeal;

  Map<int, Map<String, Map<String, int>>> studentMealSelections = {};
  Map<int, int> studentSleepSelection = {};
  Map<int, String> studentSleepNotes = {};
  Map<int, int> studentMoodSelection = {};
  Map<int, bool> studentAllEaten = {};

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
  List<String> get mealChoices => [
    t.didNotEat,
    t.ateLittle,
    t.ateAll
  ];
  final List<String> moodEmojis = ["😊", "😢", "😴", "😌", "😡"];
/*
  final List<String> mealChoices = ["Yemedi", "Az Yedi", "Tamamını Yedi"];

  final List<String> sleepChoices = ["Uyumadı", "Az Uyudu", "Uyudu"];
  final List<String> moodChoices = ["Mutlu", "Üzgün", "Yorgun", "Huzurlu", "Sinirli"];
  final List<String> moodEmojis = ["😊", "😢", "😴", "😌", "😡"];
  final List<String> mealKeys = ["Kahvaltı", "Öğle", "İkindi"];
*/
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void setAllMealsEaten(int studentIndex, MealModel? meal) {
    if (meal == null) return;

    studentMealSelections.putIfAbsent(studentIndex, () => {});

    final meals = {
      t.breakfast: meal.meal1,
      t.lunch: meal.meal2,
      t.snack: meal.meal3,
    };

    meals.forEach((mealName, items) {
      studentMealSelections[studentIndex]!.putIfAbsent(mealName, () => {});

      for (var item in items) {
        studentMealSelections[studentIndex]![mealName]![item] = 2; // Tamamını Yedi
      }
    });
  }

  Widget buildAllEatenCheckbox(int studentIndex, MealModel? meal) {
    bool value = studentAllEaten[studentIndex] ?? false;

    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (val) {
            setState(() {
              studentAllEaten[studentIndex] = val ?? false;

              if (val == true) {
                setAllMealsEaten(studentIndex, meal);
              }
            });
          },
        ),
         Text(
          t.ateAll,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  void _loadData() async {
    String fixedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());//"2025-11-01";
    futureMeal = ApiService.getMealList(widget.teacherTckn, fixedDate);

    final insertDate = fixedDate;
    final url = Uri.parse(
        "${globals.serverAdrr}/api/student/getStudentsMealByParentOrTeacher"
            "?schoolId=${globals.globalSchoolId}&tckn=${globals.kullaniciTCKN}&insertDate=$insertDate"
    );

    try {
      final response = await ApiService.authClient.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> savedData = response.body.isNotEmpty
            ? (response.body.startsWith('[') ? jsonDecode(response.body) : [])
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
                    final key = kv[0];
                    final value = int.tryParse(kv[1]) ?? 0;
                    studentMealSelections[i]![mealKeys[j]]![key] = value;
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
      } else {
        debugPrint("❌ Önceki yemek verisi yüklenemedi: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Önceki yemek verisi yüklenirken hata: $e");
    }
  }

  Widget buildMealItem(int studentIndex, String mealName, String itemName) {
    int currentSelection = studentMealSelections[studentIndex]?[mealName]?[itemName] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(itemName, style: const TextStyle(fontSize: 14, color: AppColors.primary)),
        DropdownButton<int>(
          value: currentSelection,
          items: List.generate(mealChoices.length, (index) {
            return DropdownMenuItem<int>(
              value: index,
              child: Text(mealChoices[index], style: const TextStyle(fontSize: 12)),
            );
          }),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              studentMealSelections.putIfAbsent(studentIndex, () => {});
              studentMealSelections[studentIndex]!.putIfAbsent(mealName, () => {});
              studentMealSelections[studentIndex]![mealName]![itemName] = value;
            });
          },
        ),
      ],
    );
  }

  Widget buildMealList(int studentIndex, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        ...items.map((e) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildMealItem(studentIndex, title.replaceAll(":", ""), e),
          ),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget buildMoodSection(int studentIndex) {
    int currentMood = studentMoodSelection[studentIndex] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text("Duygu Durumu:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: List.generate(moodChoices.length, (index) {
            return ChoiceChip(
              label: Text("${moodEmojis[index]} ${moodChoices[index]}", style: const TextStyle(fontSize: 12)),
              selected: index == currentMood,
              selectedColor: AppColors.primary.withOpacity(0.2),
              onSelected: (_) {
                setState(() {
                  studentMoodSelection[studentIndex] = index;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget buildSleepSection(int studentIndex) {
    int currentSelection = studentSleepSelection[studentIndex] ?? -1;
    String note = studentSleepNotes[studentIndex] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text("Uyku:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: List.generate(sleepChoices.length, (index) {
            return ChoiceChip(
              label: Text(sleepChoices[index], style: const TextStyle(fontSize: 12)),
              selected: index == currentSelection,
              selectedColor: AppColors.primary.withOpacity(0.2),
              onSelected: (_) {
                setState(() {
                  studentSleepSelection[studentIndex] = index;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: note),
          decoration: const InputDecoration(
            labelText: "Açıklama",
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold, // 👈 sadece label kalın
            ),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (val) {
            studentSleepNotes[studentIndex] = val;
          },
        ),

        buildMoodSection(studentIndex),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildStudentCard(
      int studentIndex,
      Map<String, dynamic> student,
      MealModel? meal,
      ) {
    String studentName = student['Name'] ?? t.student;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 ÖĞRENCİ ADI (HER KARTTA)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                studentName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: buildAllEatenCheckbox(studentIndex, meal),
            ),
            if (meal != null) ...[
              ExpansionTile(
                title:  Text(
                  t.breakfast,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                children: meal.meal1
                    .map((e) => buildMealItem(studentIndex, "Kahvaltı", e))
                    .toList(),
              ),

              ExpansionTile(
                title:  Text(
                  t.lunch,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                children: meal.meal2
                    .map((e) => buildMealItem(studentIndex, "Öğle", e))
                    .toList(),
              ),

              ExpansionTile(
                title:  Text(
                  t.snack,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                children: meal.meal3
                    .map((e) => buildMealItem(studentIndex, "İkindi", e))
                    .toList(),
              ),
            ],

            // 🔹 HER ZAMAN GÖSTERİLEN ALAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: buildSleepSection(studentIndex),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAllMeals() async {
    bool hataVar = false; // 👈 hataVar
    setState(() => isLoading = true);

    try {
      final insertDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (int i = 0; i < globals.globalOgrenciListesi.length; i++) {
        final student = globals.globalOgrenciListesi[i];
        final tckn = student['TCKN'];

        final mealDataStr = mealKeys.map((meal) {
          final items = studentMealSelections[i]?[meal] ?? {};
          return items.entries.map((e) => "${e.key}:${e.value}").join(',');
        }).join('|');

        final sleep = studentSleepSelection[i] ?? 0;
        final moodIndex = studentMoodSelection[i] ?? 0;
        final mood = moodChoices[moodIndex];
        final note = studentSleepNotes[i] ?? "";

        final finalDataStr = "$mealDataStr|$sleep|$mood|$note";

        print("finalDataStr:"+finalDataStr);
        final url = Uri.parse(
            "${globals.serverAdrr}/api/student/addMeal"
                "?schoolId=${globals.globalSchoolId}"
                "&studentTckn=$tckn"
                "&insertDate=$insertDate"
                "&data=$finalDataStr"
        );

        final response = await ApiService.authClient.get(url);

        if (response.statusCode != 200) {
          hataVar = true;
          debugPrint("❌ Kaydetme hatası ($tckn): ${response.statusCode} - ${response.body}");
        //  ScaffoldMessenger.of(context)
         //     .showSnackBar(const SnackBar(content: Text("❌ Kaydetme hatası")));
        }
        }
      }
      catch (e) {
      debugPrint("❌ SaveAll Exception: $e");
     // ScaffoldMessenger.of(context)
       //   .showSnackBar(const SnackBar(content: Text("❌ Kaydetme hatası")));
    } finally {
      setState(() => isLoading = false);
    }

    if (!hataVar) {
      ScaffoldMessenger.of(context)
          .showSnackBar( SnackBar(content: Text("✅ "+t.savedAll)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar( SnackBar(content: Text("❌ "+t.saveError )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title:  Text(t.dailyInfoTitle, style: AppStyles.titleLarge),
      ),
      body: FutureBuilder<MealModel?>(
        future: futureMeal,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

         /* if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Yemek listesi bulunamadı.", style: TextStyle(color: AppColors.primary)));
          }  final meal = snapshot.data!;*/
          final MealModel? meal =
          snapshot.connectionState == ConnectionState.done
              ? snapshot.data
              : null;




          if (globals.globalOgrenciListesi.isEmpty) {
            return  Center(child: Text(t.studentNotFound, style: TextStyle(color: AppColors.primary)));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: globals.globalOgrenciListesi.length,
                  itemBuilder: (context, index) {
                    final student = globals.globalOgrenciListesi[index];
                    return buildStudentCard(index, student, meal);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        child:  Text(t.cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveAllMeals,
                        style: AppStyles.buttonStyle,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            :  Text(t.save),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
