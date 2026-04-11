class HealthScoreResult {
  final double score;
  final String label;

  const HealthScoreResult({
    required this.score,
    required this.label,
  });
}

HealthScoreResult calculateHealthScore(
  Map<String, dynamic>? userData, {
  DateTime? referenceDate,
}) {
  if (userData == null) {
    return const HealthScoreResult(score: 0, label: 'Poor');
  }

  final heightCm = _readDouble(userData, ['heightCm', 'height']);
  final currentWeightKg = _readDouble(userData, [
    'currentWeight',
    'weightKg',
    'weight',
  ]);
  final targetWeightKg = _readDouble(userData, [
    'targetWeightKg',
    'targetWeight',
    'goalWeightKg',
  ]);
  final goalType = _normalizeGoal(
    _readString(userData, ['goalType', 'goal']),
  );
  final activityLevel = _normalizeActivityLevel(
    _readString(userData, ['activityLevel']),
  );
  final age = _readAge(userData, referenceDate: referenceDate);

  final isIncomplete =
      heightCm == null ||
      currentWeightKg == null ||
      targetWeightKg == null ||
      goalType == null ||
      activityLevel == null ||
      age == null ||
      heightCm <= 0 ||
      currentWeightKg <= 0 ||
      targetWeightKg <= 0;

  if (isIncomplete) {
    return const HealthScoreResult(score: 0, label: 'Poor');
  }

  final heightM = heightCm / 100;
  final bmi = currentWeightKg / (heightM * heightM);
  final targetBmi = targetWeightKg / (heightM * heightM);
  final weightDifferenceKg = (currentWeightKg - targetWeightKg).abs();

  final total =
      _bmiScore(bmi) +
      _goalGapScore(weightDifferenceKg) +
      _goalFeasibilityScore(
        goalType: goalType,
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        targetBmi: targetBmi,
      ) +
      _ageScore(age) +
      _activityBonus(activityLevel);

  final normalizedScore = ((total / 11) * 10).clamp(0.0, 10.0);
  final score = double.parse(normalizedScore.toStringAsFixed(1));

  return HealthScoreResult(
    score: score,
    label: _labelForScore(score),
  );
}

double _bmiScore(double bmi) {
  if (bmi >= 18.5 && bmi <= 24.9) {
    return 4;
  }
  if ((bmi >= 25 && bmi <= 29.9) || (bmi >= 17 && bmi < 18.5)) {
    return 3;
  }
  if ((bmi >= 30 && bmi <= 34.9) || (bmi >= 16 && bmi < 17)) {
    return 2;
  }
  return 1;
}

double _goalGapScore(double weightDifferenceKg) {
  if (weightDifferenceKg <= 2) {
    return 3;
  }
  if (weightDifferenceKg <= 7) {
    return 2;
  }
  if (weightDifferenceKg <= 15) {
    return 1;
  }
  return 0.5;
}

double _goalFeasibilityScore({
  required String goalType,
  required double currentWeightKg,
  required double targetWeightKg,
  required double targetBmi,
}) {
  final weightDelta = targetWeightKg - currentWeightKg;
  final absoluteDelta = weightDelta.abs();
  final isDirectionValid = switch (goalType) {
    'gain' => weightDelta >= 0,
    'lose' => weightDelta <= 0,
    'maintain' => absoluteDelta <= 2,
    _ => false,
  };

  if (!isDirectionValid) {
    return 0.5;
  }

  if (goalType == 'maintain') {
    return absoluteDelta <= 2 ? 2 : 1;
  }

  final targetIsHealthy = targetBmi >= 18.5 && targetBmi <= 24.9;
  final targetIsNearHealthy = targetBmi >= 17 && targetBmi <= 29.9;

  if (absoluteDelta <= 8 && targetIsHealthy) {
    return 2;
  }
  if (absoluteDelta <= 15 && targetIsNearHealthy) {
    return 1;
  }
  return 0.5;
}

double _ageScore(int age) {
  if (age >= 18 && age <= 35) {
    return 1;
  }
  if (age >= 36 && age <= 50) {
    return 0.7;
  }
  if (age >= 51) {
    return 0.5;
  }
  return 0.3;
}

double _activityBonus(String activityLevel) {
  return switch (activityLevel) {
    'sedentary' => 0.3,
    'athletic' => 1,
    _ => 0.6,
  };
}

String _labelForScore(double score) {
  if (score >= 8.5) {
    return 'Excellent';
  }
  if (score >= 6.5) {
    return 'Good';
  }
  if (score >= 4) {
    return 'Average';
  }
  return 'Poor';
}

double? _readDouble(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) {
      continue;
    }
    final normalized = value.toString().trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

int? _readInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

int? _readAge(
  Map<String, dynamic> data, {
  DateTime? referenceDate,
}) {
  final directAge = _readInt(data, ['age']);
  if (directAge != null) {
    return directAge;
  }

  final now = referenceDate ?? DateTime.now();
  final dateOfBirth = _parseDateOfBirth(data);
  if (dateOfBirth == null) {
    return null;
  }

  var age = now.year - dateOfBirth.year;
  final hasHadBirthday =
      now.month > dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
  if (!hasHadBirthday) {
    age -= 1;
  }
  return age;
}

DateTime? _parseDateOfBirth(Map<String, dynamic> data) {
  final rawValue = data['dateOfBirth'] ?? data['dob'] ?? data['birthDate'];
  if (rawValue is DateTime) {
    return rawValue;
  }
  if (rawValue is String) {
    return DateTime.tryParse(rawValue);
  }

  final year = _readInt(data, ['birthYear']);
  if (year == null) {
    return null;
  }

  final month = _readInt(data, ['birthMonth']) ?? 1;
  final day = _readInt(data, ['birthDay']) ?? 1;

  final safeMonth = month.clamp(1, 12);
  final safeDay = day.clamp(1, _daysInMonth(year, safeMonth));
  return DateTime(year, safeMonth, safeDay);
}

int _daysInMonth(int year, int month) {
  final monthStart = month == 12
      ? DateTime(year + 1, 1, 1)
      : DateTime(year, month + 1, 1);
  return monthStart.subtract(const Duration(days: 1)).day;
}

String? _normalizeGoal(String? goal) {
  final normalized = goal?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('gain')) {
    return 'gain';
  }
  if (normalized.contains('lose') || normalized.contains('loss')) {
    return 'lose';
  }
  if (normalized.contains('maintain')) {
    return 'maintain';
  }
  return null;
}

String? _normalizeActivityLevel(String? activityLevel) {
  final normalized = activityLevel?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('sedentary')) {
    return 'sedentary';
  }
  if (normalized.contains('athletic') ||
      normalized.contains('very active') ||
      normalized.contains('intense')) {
    return 'athletic';
  }
  if (normalized.contains('active')) {
    return 'active';
  }
  return 'active';
}
