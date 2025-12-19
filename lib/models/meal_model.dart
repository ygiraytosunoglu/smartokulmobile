class MealModel {
  final List<String> meal1;
  final List<String> meal2;
  final List<String> meal3;

  MealModel({
    required this.meal1,
    required this.meal2,
    required this.meal3,
  });

  // Json parse, tip güvenli
  factory MealModel.fromJson(Map<String, dynamic> json) {
    List<String> parseMeal(String? data) {
      if (data == null || data.isEmpty) return [];
      return data.split('/').map((e) => e.trim()).toList();
    }

    return MealModel(
      meal1: parseMeal(json['mealData1']),
      meal2: parseMeal(json['mealData2']),
      meal3: parseMeal(json['mealData3']),
    );
  }
}
