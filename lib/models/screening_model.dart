import 'dart:convert';

class ScreeningModel {
  final String id;
  final String userId;
  final String userName;
  final int age;
  final String gender;
  final double weight; // kg
  final double height; // cm
  final double bmi;
  final double waistCircumference; // cm
  final bool physicalActivity; // >= 30 min / day
  final bool dietFruitsVeg; // eats veggies/fruits daily
  final bool hypertensionHistory;
  final bool highGlucoseHistory;
  final String familyDiabetesHistory; // 'none', 'second_degree', 'first_degree'
  final List<String> symptoms;
  final String riskLevel; // 'Rendah', 'Sedang', 'Tinggi', 'Sangat Tinggi'
  final double riskScore; // 0 - 100
  final List<String> decisionPath;
  final List<String> recommendations;
  final List<String> dietRecommendations;
  final List<String> lifestyleRecommendations;
  final DateTime createdAt;

  ScreeningModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.waistCircumference,
    required this.physicalActivity,
    required this.dietFruitsVeg,
    required this.hypertensionHistory,
    required this.highGlucoseHistory,
    required this.familyDiabetesHistory,
    required this.symptoms,
    required this.riskLevel,
    required this.riskScore,
    required this.decisionPath,
    required this.recommendations,
    required this.dietRecommendations,
    required this.lifestyleRecommendations,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'waist_circumference': waistCircumference,
      'physical_activity': physicalActivity,
      'diet_fruits_veg': dietFruitsVeg,
      'hypertension_history': hypertensionHistory,
      'high_glucose_history': highGlucoseHistory,
      'family_diabetes_history': familyDiabetesHistory,
      'symptoms': jsonEncode(symptoms),
      'risk_level': riskLevel,
      'risk_score': riskScore,
      'decision_path': jsonEncode(decisionPath),
      'recommendations': jsonEncode(recommendations),
      'diet_recommendations': jsonEncode(dietRecommendations),
      'lifestyle_recommendations': jsonEncode(lifestyleRecommendations),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ScreeningModel.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          return value.split(',').map((e) => e.trim()).toList();
        }
      }
      return [];
    }

    return ScreeningModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      userName: map['user_name']?.toString() ?? 'Pasien',
      age: int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      gender: map['gender']?.toString() ?? 'Laki-laki',
      weight: double.tryParse(map['weight']?.toString() ?? '0') ?? 0.0,
      height: double.tryParse(map['height']?.toString() ?? '0') ?? 0.0,
      bmi: double.tryParse(map['bmi']?.toString() ?? '0') ?? 0.0,
      waistCircumference:
          double.tryParse(map['waist_circumference']?.toString() ?? '0') ?? 0.0,
      physicalActivity: map['physical_activity'] == true ||
          map['physical_activity']?.toString() == 'true',
      dietFruitsVeg: map['diet_fruits_veg'] == true ||
          map['diet_fruits_veg']?.toString() == 'true',
      hypertensionHistory: map['hypertension_history'] == true ||
          map['hypertension_history']?.toString() == 'true',
      highGlucoseHistory: map['high_glucose_history'] == true ||
          map['high_glucose_history']?.toString() == 'true',
      familyDiabetesHistory:
          map['family_diabetes_history']?.toString() ?? 'none',
      symptoms: parseList(map['symptoms']),
      riskLevel: map['risk_level']?.toString() ?? 'Rendah',
      riskScore: double.tryParse(map['risk_score']?.toString() ?? '0') ?? 0.0,
      decisionPath: parseList(map['decision_path']),
      recommendations: parseList(map['recommendations']),
      dietRecommendations: parseList(map['diet_recommendations']),
      lifestyleRecommendations: parseList(map['lifestyle_recommendations']),
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ScreeningModel.fromJson(String source) =>
      ScreeningModel.fromMap(jsonDecode(source));
}
