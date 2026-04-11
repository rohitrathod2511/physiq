import 'package:flutter_test/flutter_test.dart';
import 'package:physiq/utils/health_score_calculator.dart';

void main() {
  group('calculateHealthScore', () {
    final referenceDate = DateTime(2026, 4, 11);

    test('returns a higher score for healthier onboarding inputs', () {
      final strongProfile = calculateHealthScore({
        'birthYear': 1996,
        'birthMonth': 4,
        'birthDay': 1,
        'gender': 'Male',
        'heightCm': 175.0,
        'weightKg': 72.0,
        'targetWeightKg': 70.0,
        'goal': 'Lose Weight',
        'activityLevel': 'Athletic',
      }, referenceDate: referenceDate);

      final weakProfile = calculateHealthScore({
        'birthYear': 1961,
        'birthMonth': 1,
        'birthDay': 1,
        'gender': 'Male',
        'heightCm': 160.0,
        'weightKg': 110.0,
        'targetWeightKg': 80.0,
        'goal': 'Lose Weight',
        'activityLevel': 'Sedentary',
      }, referenceDate: referenceDate);

      expect(strongProfile.score, 10.0);
      expect(strongProfile.label, 'Excellent');
      expect(weakProfile.score, 2.5);
      expect(weakProfile.label, 'Poor');
      expect(strongProfile.score, greaterThan(weakProfile.score));
    });

    test('supports ISO dateOfBirth input', () {
      final result = calculateHealthScore({
        'dateOfBirth': '1990-06-15',
        'gender': 'Female',
        'heightCm': 168.0,
        'weightKg': 64.0,
        'targetWeightKg': 62.0,
        'goal': 'Maintain Weight',
        'activityLevel': 'Lightly active',
      }, referenceDate: referenceDate);

      expect(result.score, greaterThan(0));
      expect(result.label, isNotEmpty);
    });

    test('returns a safe fallback when required fields are missing', () {
      final result = calculateHealthScore({
        'birthYear': 1998,
        'weightKg': 70.0,
      }, referenceDate: referenceDate);

      expect(result.score, 0);
      expect(result.label, 'Poor');
    });
  });
}
