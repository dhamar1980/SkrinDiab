import 'package:flutter_test/flutter_test.dart';
import 'package:skrin_diab/services/decision_tree_service.dart';

void main() {
  group('Decision Tree Service & Clinical Calculations Tests', () {
    test('calculateBMI calculates correct BMI', () {
      final bmi = DecisionTreeService.calculateBMI(70, 168);
      expect(bmi, 24.8); // 70 / (1.68 * 1.68) = 24.8
    });

    test('getBMICategory returns correct Asian-Pacific classifications', () {
      expect(DecisionTreeService.getBMICategory(17.5),
          'Berat Badan Kurang (Underweight)');
      expect(
          DecisionTreeService.getBMICategory(21.0), 'Berat Badan Normal');
      expect(DecisionTreeService.getBMICategory(24.0),
          'Kelebihan Berat Badan (Overweight)');
      expect(DecisionTreeService.getBMICategory(28.5), 'Obesitas');
    });

    test('checkCentralObesity follows PERKENI gender cut-offs', () {
      // Male cut-off is >= 90 cm
      expect(DecisionTreeService.checkCentralObesity('Laki-laki', 89), false);
      expect(DecisionTreeService.checkCentralObesity('Laki-laki', 90), true);

      // Female cut-off is >= 80 cm
      expect(DecisionTreeService.checkCentralObesity('Perempuan', 79), false);
      expect(DecisionTreeService.checkCentralObesity('Perempuan', 80), true);
    });

    test('Decision Tree classifies Very High Risk for active hyperglycemia & 4P symptoms',
        () {
      final result = DecisionTreeService.evaluateDiabetesRisk(
        age: 50,
        gender: 'Laki-laki',
        weight: 80,
        height: 165,
        waistCircumference: 95,
        physicalActivity: false,
        dietFruitsVeg: false,
        hypertensionHistory: true,
        highGlucoseHistory: true, // Prior high glucose history
        familyDiabetesHistory: 'first_degree',
        symptoms: [
          'Sering haus berlebihan (Polidipsia)',
          'Sering buang air kecil di malam hari (Poliuria)',
        ],
      );

      expect(result.riskLevel, 'Sangat Tinggi');
      expect(result.riskScore, greaterThan(80.0));
      expect(result.decisionPath.isNotEmpty, true);
      expect(result.recommendations.isNotEmpty, true);
      expect(result.dietRecommendations.isNotEmpty, true);
    });

    test('Decision Tree classifies Low Risk for normal profile young patient',
        () {
      final result = DecisionTreeService.evaluateDiabetesRisk(
        age: 22,
        gender: 'Perempuan',
        weight: 50,
        height: 160,
        waistCircumference: 68,
        physicalActivity: true,
        dietFruitsVeg: true,
        hypertensionHistory: false,
        highGlucoseHistory: false,
        familyDiabetesHistory: 'none',
        symptoms: [],
      );

      expect(result.riskLevel, 'Rendah');
      expect(result.riskScore, lessThan(30.0));
    });
  });
}
