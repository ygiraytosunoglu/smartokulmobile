import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../models/meal_model.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class MealScreen extends StatefulWidget {
  final String tckn;

  MealScreen({required this.tckn});

  @override
  _MealScreenState createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  DateTime selectedDate = DateTime.now();
  Future<MealModel?>? futureMeal;

  //final List<String> gunler = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
  //final List<String> aylar = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"];

  late final List<DateTime> days;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    days = _generateDays();
    _scrollController = ScrollController();

    // Bugün seçili ve scroll yapılacak index
    final todayIndex = days.indexWhere((d) => DateUtils.isSameDay(d, DateTime.now()));
    if (todayIndex != -1) {
      // Liste başına scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(todayIndex * 76.0); // 70 + margin yaklaşık
      });
    }

    _loadData();
  }

  void _loadData() {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    futureMeal = ApiService.getMealList(widget.tckn, formattedDate);
    setState(() {});
  }

  List<DateTime> _generateDays() {
    DateTime start = DateTime.now().subtract(const Duration(days: 30));
    return List.generate(61, (i) => start.add(Duration(days: i)));
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = DateUtils.isSameDay(day, selectedDate);
        //  final gunAdi = gunler[day.weekday % 7];
        //  final ayAdi = aylar[day.month - 1];
          final locale = Localizations.localeOf(context).toString();

          final gunAdi = DateFormat.E(locale).format(day);     // Pzt / Mon
          final ayAdi = DateFormat.MMM(locale).format(day);    // Oca / Jan

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = day;
              });
              _loadData();
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gunAdi,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day} $ayAdi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildMealList(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ...items.map(
              (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              "• $e",
              style: const TextStyle(fontSize: 16, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title:  Text(
          AppLocalizations.of(context)!.mealScreenTitle,
          style: AppStyles.titleLarge,
        ),
      ),
      body: Column(
        children: [
          _buildHorizontalCalendar(),
          Expanded(
            child: FutureBuilder<MealModel?>(
              future: futureMeal,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return  Center(child: Text(AppLocalizations.of(context)!.mealNotFound, style: TextStyle(color: AppColors.primary)));
                }

                final meal = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SizedBox(
                    width: double.infinity, // 👈 ekranın tamamı
                    child: Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // 👈 sadece yazı kadar uzasın
                          children: [
                            Text(
                              DateFormat('dd.MM.yyyy').format(selectedDate),                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Divider(),
                            buildMealList(AppLocalizations.of(context)!.mealBreakfast, meal.meal1),
                            buildMealList(AppLocalizations.of(context)!.mealLunch, meal.meal2),
                            buildMealList(AppLocalizations.of(context)!.mealSnack, meal.meal3),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
