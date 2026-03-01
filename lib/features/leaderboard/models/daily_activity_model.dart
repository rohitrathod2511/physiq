import 'package:cloud_firestore/cloud_firestore.dart';

class DailyActivityModel {
  final String id;
  final String userId;
  final Timestamp date;
  final int mealsLogged;
  final bool workoutLogged;
  final bool waterTargetHit;
  final int dailyScore;
  final int streakCount;
  final bool scoreAddedToTotal;
  final Timestamp createdAt;

  const DailyActivityModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealsLogged,
    required this.workoutLogged,
    required this.waterTargetHit,
    required this.dailyScore,
    required this.streakCount,
    required this.scoreAddedToTotal,
    required this.createdAt,
  });

  factory DailyActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final now = Timestamp.now();
    return DailyActivityModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      date: _asTimestamp(data['date']) ?? now,
      mealsLogged: _asInt(data['mealsLogged']),
      workoutLogged: data['workoutLogged'] == true,
      waterTargetHit: data['waterTargetHit'] == true,
      dailyScore: _asInt(data['dailyScore']),
      streakCount: _asInt(data['streakCount']),
      scoreAddedToTotal: data['scoreAddedToTotal'] == true,
      createdAt: _asTimestamp(data['createdAt']) ?? now,
    );
  }

  factory DailyActivityModel.createDefault({
    required String userId,
    required DateTime now,
    int streakCount = 0,
  }) {
    return DailyActivityModel(
      id: buildDocumentId(userId, now),
      userId: userId,
      date: Timestamp.fromDate(startOfDay(now)),
      mealsLogged: 0,
      workoutLogged: false,
      waterTargetHit: false,
      dailyScore: 0,
      streakCount: streakCount,
      scoreAddedToTotal: false,
      createdAt: Timestamp.fromDate(now),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'date': date,
      'mealsLogged': mealsLogged,
      'workoutLogged': workoutLogged,
      'waterTargetHit': waterTargetHit,
      'dailyScore': dailyScore,
      'streakCount': streakCount,
      'scoreAddedToTotal': scoreAddedToTotal,
      'createdAt': createdAt,
    };
  }

  DailyActivityModel copyWith({
    String? id,
    String? userId,
    Timestamp? date,
    int? mealsLogged,
    bool? workoutLogged,
    bool? waterTargetHit,
    int? dailyScore,
    int? streakCount,
    bool? scoreAddedToTotal,
    Timestamp? createdAt,
  }) {
    return DailyActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mealsLogged: mealsLogged ?? this.mealsLogged,
      workoutLogged: workoutLogged ?? this.workoutLogged,
      waterTargetHit: waterTargetHit ?? this.waterTargetHit,
      dailyScore: dailyScore ?? this.dailyScore,
      streakCount: streakCount ?? this.streakCount,
      scoreAddedToTotal: scoreAddedToTotal ?? this.scoreAddedToTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool isLockedForEdits(DateTime now) {
    final created = createdAt.toDate().toUtc();
    return now.toUtc().difference(created).inHours >= 24;
  }

  static String buildDocumentId(String userId, DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${userId}_$yyyy$mm$dd';
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static Timestamp? _asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }
}
