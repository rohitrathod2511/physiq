class WeightEntry {
  final String id;
  final double weightKg;
  final DateTime date;
  final DateTime loggedAt;

  WeightEntry({
    required this.id,
    required this.weightKg,
    required this.date,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weightKg': weightKg,
      'date': date.toIso8601String(),
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] ?? '',
      weightKg: (map['weightKg'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      loggedAt: DateTime.parse(map['loggedAt']),
    );
  }
}
