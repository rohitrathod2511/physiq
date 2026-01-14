import 'dart:math';

class PlanGenerator {
  /// Generates a plan based on the user's profile.
  /// Returns a map containing the calculated values and the arithmetic trace.
  /// Generates a plan based on the user's profile.
  static Map<String, dynamic> generatePlan({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required double activityMultiplier,
    required String goal, // 'gain', 'lose', 'maintain'
    double? targetWeightKg,
    int? timeframeMonths,
  }) {
    final trace = StringBuffer();
    trace.writeln('Profile: $gender, $age, $heightCm cm, $weightKg kg, activity $activityMultiplier, goal $goal');

    // 1. BMR Calculation (Mifflin-St Jeor)
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
    int bmrRounded = bmr.round();
    trace.writeln('BMR: $bmrRounded');

    // 2. TDEE Calculation
    double tdee = bmr * activityMultiplier;
    int tdeeRounded = tdee.round();
    trace.writeln('TDEE: $tdeeRounded');

    // 3. Goal-Based Daily Calories
    double dailyCalories = tdee;
    
    // Default timeframe if missing
    final int months = timeframeMonths ?? 6;
    final double target = targetWeightKg ?? weightKg;
    
    // Weight diff
    double weightDiff = target - weightKg;
    double totalCalorieDiff = weightDiff * 7700;
    int days = months * 30;
    if (days < 30) days = 30; // Safety floor
    double dailyAdjustment = totalCalorieDiff / days;
    
    trace.writeln('Target: $target, Diff: $weightDiff, TotalCalDiff: $totalCalorieDiff, Days: $days, DailyAdj: $dailyAdjustment');

    if (goal.toLowerCase().contains('gain')) {
      dailyCalories = tdee + dailyAdjustment;
    } else if (goal.toLowerCase().contains('lose')) {
      dailyCalories = tdee - dailyAdjustment.abs();
    } else {
      dailyCalories = tdee;
    }

    // Safety Limits
    double minCalories = (gender.toLowerCase() == 'male') ? 1500 : 1200;
    
    // Max deficit/surplus constraint (+/- 1000)
    // We check the difference from TDEE
    double diffFromTDEE = dailyCalories - tdee;
    if (diffFromTDEE > 1000) {
      dailyCalories = tdee + 1000;
    } else if (diffFromTDEE < -1000) {
      dailyCalories = tdee - 1000;
    }

    // Absolute floor check
    if (dailyCalories < minCalories) {
      dailyCalories = minCalories;
    }
    
    int goalCaloriesRounded = dailyCalories.round();
    trace.writeln('Final Goal Calories: $goalCaloriesRounded');

    // 4. Macronutrients (Protein-First Approach)
    // Protein
    // protein_g = currentWeight * 2
    double proteinG = weightKg * 2;
    int proteinGRounded = proteinG.round();
    double proteinCal = proteinGRounded * 4.0;
    
    // Fat
    // fat_kcal = dailyCalories * 0.25
    double fatCal = goalCaloriesRounded * 0.25;
    double fatG = fatCal / 9.0;
    int fatGRounded = fatG.round();
    
    // Carbs
    // carb_kcal = dailyCalories - (protein_kcal + fat_kcal)
    double carbsCal = goalCaloriesRounded - (proteinCal + fatCal);
    if (carbsCal < 0) carbsCal = 0; // Safety
    double carbsG = carbsCal / 4.0;
    int carbsGRounded = carbsG.round();
    
    trace.writeln('Macros: P: $proteinGRounded g, F: $fatGRounded g, C: $carbsGRounded g');

    return {
      'bmr': bmrRounded,
      'tdee': tdeeRounded,
      'calories': goalCaloriesRounded, // Standard key 'calories' as per request structure
      'goalCalories': goalCaloriesRounded, // Keep for compatibility if needed
      'protein': proteinGRounded,
      'fat': fatGRounded,
      'carbs': carbsGRounded,
      // Also provide the 'G' keys if referenced by UI
      'proteinG': proteinGRounded,
      'fatG': fatGRounded,
      'carbsG': carbsGRounded,
      'source': 'calculated',
      'updatedAt': DateTime.now().toIso8601String(),
      'trace': trace.toString(),
    };
  }

  /// Generates a plan locally using the provided profile map.
  static Map<String, dynamic> generateLocalPlan(Map<String, dynamic> profile) {
    final String gender = profile['gender'] ?? 'male';
    final int birthYear = profile['birthYear'] ?? 2000;
    final int age = DateTime.now().year - birthYear;
    final double heightCm = (profile['heightCm'] as num?)?.toDouble() ?? 170.0;
    final double weightKg = (profile['weightKg'] as num?)?.toDouble() ?? 70.0;
    final String activityLevel = profile['activityLevel'] ?? 'Active';
    final String goal = profile['goal'] ?? 'Maintain';
    final double? targetWeightKg = (profile['targetWeightKg'] as num?)?.toDouble();
    final int? timeframeMonths = profile['timeframeMonths'];

    double activityMultiplier;
    // Map ONLY to the 3 allowed levels. Fallback to Active (1.55) if unknown.
    // "Sedentary" -> 1.2
    // "Active" -> 1.55
    // "Athletic" -> 1.9
    
    // Note: The UI might have other strings ("Moderately active", etc). 
    // We map them to the closest buckets or default to Active.
    String level = activityLevel.toLowerCase();
    if (level.contains('sedentary') || level.contains('no workout')) {
      activityMultiplier = 1.2;
    } else if (level.contains('athletic') || level.contains('6-7')) {
      activityMultiplier = 1.9;
    } else {
      // Default / Active / 3-5 days
      activityMultiplier = 1.55; 
    }

    return generatePlan(
      gender: gender,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      activityMultiplier: activityMultiplier,
      goal: goal,
      targetWeightKg: targetWeightKg,
      timeframeMonths: timeframeMonths,
    );
  }
}
