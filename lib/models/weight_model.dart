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
      // Store dates as ISO strings AND timestamps to support legacy/different query styles if needed, 
      // but primary source for range query is often timestamp in standard Firestore usage.
      // However, current repository uses string comparison. 
      // User request mandates: "Query must be: .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))"
      // So we MUST store 'date' as Timestamp for that query to work efficiently with native types.
      'date': date, // Cloud Firestore automatically handles DateTime as Timestamp
      'loggedAt': loggedAt,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    // Handle both Timestamp and String for backward compatibility/safeguard
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val != null && val.runtimeType.toString().contains('Timestamp')) {
        // Timestamp from cloud_firestore
        return (val as dynamic).toDate();
      }
      return DateTime.now();
    }

    return WeightEntry(
      id: map['id'] ?? '',
      weightKg: (map['weightKg'] ?? 0).toDouble(),
      date: parseDate(map['date']),
      loggedAt: parseDate(map['loggedAt']),
    );
  }
}
