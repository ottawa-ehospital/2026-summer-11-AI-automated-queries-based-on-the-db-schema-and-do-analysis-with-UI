import 'dart:typed_data';

class NutritionModelCapabilities {
  const NutritionModelCapabilities({
    required this.supportsImageInput,
    required this.provider,
    required this.model,
    this.reason,
  });

  final bool supportsImageInput;
  final String provider;
  final String model;
  final String? reason;

  factory NutritionModelCapabilities.fromJson(Map<String, dynamic> json) {
    return NutritionModelCapabilities(
      supportsImageInput: json['supportsImageInput'] == true,
      provider: json['provider']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      reason: json['reason']?.toString(),
    );
  }
}

class NutritionHealth {
  const NutritionHealth({required this.imageAnalysis});

  final NutritionModelCapabilities imageAnalysis;

  factory NutritionHealth.fromJson(Map<String, dynamic> json) {
    return NutritionHealth(
      imageAnalysis: NutritionModelCapabilities.fromJson(
        (json['imageAnalysis'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }
}

class NutritionalBreakdown {
  const NutritionalBreakdown({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.totalSodium,
    required this.totalSugar,
  });

  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final double totalSodium;
  final double totalSugar;

  factory NutritionalBreakdown.zero() {
    return const NutritionalBreakdown(
      totalCalories: 0,
      totalProtein: 0,
      totalFat: 0,
      totalCarbs: 0,
      totalSodium: 0,
      totalSugar: 0,
    );
  }

  factory NutritionalBreakdown.fromJson(Map<String, dynamic> json) {
    double read(String key) =>
        double.tryParse(json[key]?.toString() ?? '') ?? 0;
    return NutritionalBreakdown(
      totalCalories: read('totalCalories'),
      totalProtein: read('totalProtein'),
      totalFat: read('totalFat'),
      totalCarbs: read('totalCarbs'),
      totalSodium: read('totalSodium'),
      totalSugar: read('totalSugar'),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalCalories': totalCalories,
    'totalProtein': totalProtein,
    'totalFat': totalFat,
    'totalCarbs': totalCarbs,
    'totalSodium': totalSodium,
    'totalSugar': totalSugar,
  };
}

class PersonalizedInsights {
  const PersonalizedInsights({
    required this.risks,
    required this.warnings,
    required this.positives,
  });

  final List<String> risks;
  final List<String> warnings;
  final List<String> positives;

  factory PersonalizedInsights.empty() {
    return const PersonalizedInsights(risks: [], warnings: [], positives: []);
  }

  factory PersonalizedInsights.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) => (json[key] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    return PersonalizedInsights(
      risks: list('risks'),
      warnings: list('warnings'),
      positives: list('positives'),
    );
  }

  Map<String, dynamic> toJson() => {
    'risks': risks,
    'warnings': warnings,
    'positives': positives,
  };
}

class NutritionAnalysisResult {
  const NutritionAnalysisResult({
    required this.patientId,
    required this.dishName,
    required this.portionSize,
    required this.ingredients,
    required this.nutritionalBreakdown,
    required this.insights,
    required this.finalVerdict,
    required this.finalVerdictReasoning,
    required this.isFood,
    required this.modelCapabilities,
  });

  final int patientId;
  final String dishName;
  final String portionSize;
  final List<String> ingredients;
  final NutritionalBreakdown nutritionalBreakdown;
  final PersonalizedInsights insights;
  final String finalVerdict;
  final String finalVerdictReasoning;
  final bool isFood;
  final NutritionModelCapabilities modelCapabilities;

  factory NutritionAnalysisResult.fromJson(Map<String, dynamic> json) {
    return NutritionAnalysisResult(
      patientId: int.tryParse(json['patientId']?.toString() ?? '') ?? 0,
      dishName: json['dishName']?.toString() ?? '',
      portionSize: json['portionSize']?.toString() ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      nutritionalBreakdown: NutritionalBreakdown.fromJson(
        (json['nutritionalBreakdown'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      insights: PersonalizedInsights.fromJson(
        (json['insights'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      finalVerdict: json['finalVerdict']?.toString() ?? '',
      finalVerdictReasoning: json['finalVerdictReasoning']?.toString() ?? '',
      isFood: json['isFood'] != false,
      modelCapabilities: NutritionModelCapabilities.fromJson(
        (json['modelCapabilities'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }

  Map<String, dynamic> toMealJson() => {
    'patientId': patientId,
    'dishName': dishName,
    'portionSize': portionSize,
    'ingredients': ingredients,
    'nutritionalBreakdown': nutritionalBreakdown.toJson(),
    'insights': insights.toJson(),
    'finalVerdict': finalVerdict,
    'isFood': isFood,
  };
}

class MealLogRecord {
  const MealLogRecord({
    required this.patientId,
    required this.dishName,
    required this.portionSize,
    required this.ingredients,
    required this.nutritionalBreakdown,
    required this.risks,
    required this.warnings,
    required this.positives,
    this.logId,
    this.loggedAt,
  });

  final Object? logId;
  final int patientId;
  final String? loggedAt;
  final String dishName;
  final String portionSize;
  final List<String> ingredients;
  final NutritionalBreakdown nutritionalBreakdown;
  final List<String> risks;
  final List<String> warnings;
  final List<String> positives;

  factory MealLogRecord.fromJson(Map<String, dynamic> json) {
    return MealLogRecord(
      logId: json['logId'],
      patientId: int.tryParse(json['patientId']?.toString() ?? '') ?? 0,
      loggedAt: json['loggedAt']?.toString(),
      dishName: json['dishName']?.toString() ?? '',
      portionSize: json['portionSize']?.toString() ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      nutritionalBreakdown: NutritionalBreakdown.fromJson(
        (json['nutritionalBreakdown'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      risks: (json['risks'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      positives: (json['positives'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class DailySummary {
  const DailySummary({
    required this.patientId,
    required this.date,
    required this.totals,
  });

  final int patientId;
  final String date;
  final NutritionalBreakdown totals;

  factory DailySummary.empty(int patientId) {
    return DailySummary(
      patientId: patientId,
      date: DateTime.now().toIso8601String().split('T').first,
      totals: NutritionalBreakdown.zero(),
    );
  }

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      patientId: int.tryParse(json['patientId']?.toString() ?? '') ?? 0,
      date: json['date']?.toString() ?? '',
      totals: NutritionalBreakdown.fromJson(
        (json['totals'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }
}

class NutritionGoals {
  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  factory NutritionGoals.defaults() {
    return const NutritionGoals(
      calories: 2000,
      protein: 120,
      carbs: 250,
      fat: 70,
    );
  }

  factory NutritionGoals.fromJson(Map<String, dynamic> json) {
    int read(String key, int fallback) =>
        int.tryParse(json[key]?.toString() ?? '') ?? fallback;
    return NutritionGoals(
      calories: read('calories', 2000),
      protein: read('protein', 120),
      carbs: read('carbs', 250),
      fat: read('fat', 70),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}

class PickedMealImage {
  const PickedMealImage({
    required this.name,
    this.path,
    this.bytes,
    this.mimeType,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;
  final String? mimeType;

  bool get hasPath => path != null && path!.isNotEmpty;
}
