class CalorieCalculator {
  /// Calculates calories burned using the formula:
  /// Calories = MET * Weight(kg) * Duration(hours)
  static double calculateCalories({
    required double met,
    required double weightKg,
    required int durationMinutes,
  }) {
    final double durationHours = durationMinutes / 60.0;
    return met * weightKg * durationHours;
  }
}
