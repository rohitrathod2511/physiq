import 'package:flutter_test/flutter_test.dart';
import 'package:physiq/services/calorie_calculator_service.dart';

void main() {
  group('CalorieCalculator', () {
    test('calculates running calories correctly', () {
      // MET 6.0 * 3.5 * 70kg / 200 * 30min = 220.5
      final cals = CalorieCalculator.calculateCalories(
        exerciseType: 'run',
        intensity: 'low',
        durationMinutes: 30,
        weightKg: 70, met: null,
      );
      expect(cals, 220.5);
    });

    test('calculates weightlifting calories correctly', () {
      // MET 5.0 * 3.5 * 80kg / 200 * 45min = 315.0
      final cals = CalorieCalculator.calculateCalories(
        exerciseType: 'weightlifting',
        intensity: 'medium',
        durationMinutes: 45,
        weightKg: 80, met: null,
      );
      expect(cals, 315.0);
    });

    test('fallbacks to generic if type unknown', () {
      // Generic Medium MET 5.0
      final cals = CalorieCalculator.calculateCalories(
        exerciseType: 'unknown_sport',
        intensity: 'medium',
        durationMinutes: 60,
        weightKg: 60,
      );
      // 5.0 * 3.5 * 60 / 200 * 60 = 315
      expect(cals, 315.0);
    });

    test('handles specific exercise keys without intensity suffix', () {
      // Push ups MET 8.0
      final cals = CalorieCalculator.calculateCalories(
        exerciseType: 'push_ups',
        intensity: 'any', // Should be ignored for direct key match
        durationMinutes: 10,
        weightKg: 70,
      );
      // 8.0 * 3.5 * 70 / 200 * 10 = 98
      expect(cals, 98.0);
    });
  });
}
