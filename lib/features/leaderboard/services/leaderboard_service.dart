import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiq/features/leaderboard/models/daily_activity_model.dart';
import 'package:physiq/features/leaderboard/models/leaderboard_user_model.dart';

enum LeaderboardActivityType { meal, workout, water }

class LeaderboardService {
  LeaderboardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int mealTargetPoints = 40;
  static const int workoutPoints = 30;
  static const int waterPoints = 10;
  static const int streakBonusPoints = 20;
  static const int streakThresholdScore = 50;
  static const int maxDailyScore = 100;
  static const int defaultMealTargetPerDay = 3;
  static const int leaderboardDisplayLimit = 100;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _dailyActivityCollection =>
      _firestore.collection('daily_activity');

  int calculateDailyScore({
    required int mealsLogged,
    required int mealTarget,
    required bool workoutLogged,
    required bool waterTargetHit,
    required int streakCount,
  }) {
    var score = 0;
    if (mealsLogged >= mealTarget) {
      score += mealTargetPoints;
    }
    if (workoutLogged) {
      score += workoutPoints;
    }
    if (waterTargetHit) {
      score += waterPoints;
    }
    if (streakCount >= 1) {
      score += streakBonusPoints;
    }
    if (score > maxDailyScore) {
      return maxDailyScore;
    }
    if (score < 0) {
      return 0;
    }
    return score;
  }

  Future<void> ensureUserLeaderboardFields(String uid, {DateTime? now}) async {
    final timestampNow = Timestamp.fromDate(now ?? DateTime.now());
    final todayTimestamp = Timestamp.fromDate(
      DailyActivityModel.startOfDay(now ?? DateTime.now()),
    );
    final userRef = _usersCollection.doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final updates = <String, dynamic>{};

      if (!_isNumeric(data['totalScore'])) {
        updates['totalScore'] = 0;
      }
      if (!_isNumeric(data['streakCount'])) {
        updates['streakCount'] = 0;
      }
      if (!_isTimestamp(data['lastActiveDate'])) {
        updates['lastActiveDate'] = timestampNow;
      }
      if (!_isTimestamp(data['lastScoreUpdateDate'])) {
        updates['lastScoreUpdateDate'] = todayTimestamp;
      }

      if (updates.isNotEmpty) {
        transaction.set(userRef, updates, SetOptions(merge: true));
      }
    });
  }

  Future<void> syncDailyResetIfNeeded(String uid, {DateTime? now}) async {
    final eventTime = now ?? DateTime.now();
    final todayStart = DailyActivityModel.startOfDay(eventTime);
    final userRef = _usersCollection.doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final lastScoreUpdateDate = _asDateTime(data['lastScoreUpdateDate']);

      if (lastScoreUpdateDate == null ||
          !_isSameCalendarDate(lastScoreUpdateDate, eventTime)) {
        transaction.set(userRef, <String, dynamic>{
          'lastScoreUpdateDate': Timestamp.fromDate(todayStart),
        }, SetOptions(merge: true));
      }
    });
  }

  /// Optional one-time migration helper.
  /// Run this from an admin-only path to ensure existing users are included
  /// in the orderBy leaderboard query (Firestore excludes docs missing fields).
  Future<int> backfillMissingLeaderboardFields({int pageSize = 400}) async {
    var updatedCount = 0;
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (true) {
      var query = _usersCollection
          .orderBy(FieldPath.documentId)
          .limit(pageSize);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final page = await query.get();
      if (page.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (final doc in page.docs) {
        final updates = _missingUserFieldDefaults(doc.data(), DateTime.now());
        if (updates.isEmpty) {
          continue;
        }
        batch.set(doc.reference, updates, SetOptions(merge: true));
        updatedCount += 1;
      }
      await batch.commit();

      lastDoc = page.docs.last;
      if (page.docs.length < pageSize) {
        break;
      }
    }

    return updatedCount;
  }

  Future<DailyActivityModel> logMealActivity({
    required String uid,
    int mealTargetPerDay = defaultMealTargetPerDay,
    DateTime? now,
  }) {
    return _recordActivity(
      uid: uid,
      activityType: LeaderboardActivityType.meal,
      mealTargetPerDay: mealTargetPerDay,
      now: now,
    );
  }

  Future<DailyActivityModel> logWorkoutActivity({
    required String uid,
    int mealTargetPerDay = defaultMealTargetPerDay,
    DateTime? now,
  }) {
    return _recordActivity(
      uid: uid,
      activityType: LeaderboardActivityType.workout,
      mealTargetPerDay: mealTargetPerDay,
      now: now,
    );
  }

  Future<DailyActivityModel> logWaterTargetHit({
    required String uid,
    int mealTargetPerDay = defaultMealTargetPerDay,
    DateTime? now,
  }) {
    return _recordActivity(
      uid: uid,
      activityType: LeaderboardActivityType.water,
      mealTargetPerDay: mealTargetPerDay,
      now: now,
    );
  }

  Stream<List<LeaderboardUser>> watchTopLeaderboard({
    int limit = leaderboardDisplayLimit,
  }) {
    // Firestore index required:
    // collection: users
    // fields: totalScore DESC, streakCount DESC
    return _usersCollection
        .orderBy('totalScore', descending: true)
        .orderBy('streakCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .asMap()
              .entries
              .map((entry) {
                final provisionalRank = entry.key + 1;
                return LeaderboardUser.fromFirestore(
                  entry.value,
                  provisionalRank: provisionalRank,
                );
              })
              .toList(growable: false);
        });
  }

  Future<DailyActivityModel?> fetchTodayActivity(
    String uid, {
    DateTime? now,
  }) async {
    final eventTime = now ?? DateTime.now();
    final docId = DailyActivityModel.buildDocumentId(uid, eventTime);
    final snapshot = await _dailyActivityCollection.doc(docId).get();
    if (!snapshot.exists) {
      return null;
    }
    return DailyActivityModel.fromFirestore(snapshot);
  }

  Future<DailyActivityModel> _recordActivity({
    required String uid,
    required LeaderboardActivityType activityType,
    required int mealTargetPerDay,
    DateTime? now,
  }) async {
    final eventTime = now ?? DateTime.now();
    final mealTarget = mealTargetPerDay < 1 ? 1 : mealTargetPerDay;
    final todayStart = DailyActivityModel.startOfDay(eventTime);
    final dailyId = DailyActivityModel.buildDocumentId(uid, eventTime);

    final userRef = _usersCollection.doc(uid);
    final dailyRef = _dailyActivityCollection.doc(dailyId);

    return _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data() ?? <String, dynamic>{};

      final currentTotalScore = _asInt(userData['totalScore']);
      final currentUserStreak = _asInt(userData['streakCount']);
      final userDefaults = _missingUserFieldDefaults(userData, eventTime);
      final lastScoreUpdateDate = _asDateTime(userData['lastScoreUpdateDate']);
      if (lastScoreUpdateDate == null ||
          !_isSameCalendarDate(lastScoreUpdateDate, eventTime)) {
        userDefaults['lastScoreUpdateDate'] = Timestamp.fromDate(todayStart);
      }

      final dailySnapshot = await transaction.get(dailyRef);
      final currentDaily = dailySnapshot.exists
          ? DailyActivityModel.fromFirestore(dailySnapshot)
          : DailyActivityModel.createDefault(
              userId: uid,
              now: eventTime,
              streakCount: currentUserStreak,
            );

      if (currentDaily.isLockedForEdits(eventTime)) {
        throw StateError('Daily activity is locked after 24 hours.');
      }

      var mealsLogged = currentDaily.mealsLogged;
      var workoutLogged = currentDaily.workoutLogged;
      var waterTargetHit = currentDaily.waterTargetHit;

      if (activityType == LeaderboardActivityType.meal) {
        mealsLogged = (mealsLogged + 1).clamp(0, mealTarget);
      } else if (activityType == LeaderboardActivityType.workout) {
        workoutLogged = true;
      } else if (activityType == LeaderboardActivityType.water) {
        waterTargetHit = true;
      }

      final previousDailyScore = currentDaily.dailyScore;
      final streakCountForBonus = currentDaily.streakCount;
      final recalculatedDailyScore = calculateDailyScore(
        mealsLogged: mealsLogged,
        mealTarget: mealTarget,
        workoutLogged: workoutLogged,
        waterTargetHit: waterTargetHit,
        streakCount: streakCountForBonus,
      );

      final updatedStreakCount = _calculateNextStreakCount(
        previousDailyScore: previousDailyScore,
        newDailyScore: recalculatedDailyScore,
        currentUserStreak: currentUserStreak,
      );

      final scoreAlreadyAdded = currentDaily.scoreAddedToTotal;
      final scoreIncrement = scoreAlreadyAdded
          ? recalculatedDailyScore - previousDailyScore
          : recalculatedDailyScore;
      final safeIncrement = scoreIncrement < 0 ? 0 : scoreIncrement;
      final updatedTotalScore = currentTotalScore + safeIncrement;

      final updatedDaily = currentDaily.copyWith(
        id: dailyId,
        userId: uid,
        date: Timestamp.fromDate(todayStart),
        mealsLogged: mealsLogged,
        workoutLogged: workoutLogged,
        waterTargetHit: waterTargetHit,
        dailyScore: recalculatedDailyScore,
        streakCount: updatedStreakCount,
        scoreAddedToTotal:
            scoreAlreadyAdded ||
            recalculatedDailyScore > 0 ||
            previousDailyScore > 0,
      );

      transaction.set(
        dailyRef,
        updatedDaily.toFirestore(),
        SetOptions(merge: true),
      );

      final userUpdates = <String, dynamic>{
        ...userDefaults,
        'totalScore': updatedTotalScore,
        'streakCount': updatedStreakCount,
        'lastActiveDate': Timestamp.fromDate(eventTime),
        'lastScoreUpdateDate': Timestamp.fromDate(todayStart),
      };
      transaction.set(userRef, userUpdates, SetOptions(merge: true));

      return updatedDaily;
    });
  }

  int _calculateNextStreakCount({
    required int previousDailyScore,
    required int newDailyScore,
    required int currentUserStreak,
  }) {
    if (newDailyScore >= streakThresholdScore) {
      if (previousDailyScore >= streakThresholdScore) {
        return currentUserStreak;
      }
      return currentUserStreak + 1;
    }
    return 0;
  }

  Map<String, dynamic> _missingUserFieldDefaults(
    Map<String, dynamic> data,
    DateTime now,
  ) {
    final updates = <String, dynamic>{};
    if (!_isNumeric(data['totalScore'])) {
      updates['totalScore'] = 0;
    }
    if (!_isNumeric(data['streakCount'])) {
      updates['streakCount'] = 0;
    }
    if (!_isTimestamp(data['lastActiveDate'])) {
      updates['lastActiveDate'] = Timestamp.fromDate(now);
    }
    if (!_isTimestamp(data['lastScoreUpdateDate'])) {
      updates['lastScoreUpdateDate'] = Timestamp.fromDate(
        DailyActivityModel.startOfDay(now),
      );
    }
    return updates;
  }

  static bool _isNumeric(dynamic value) => value is num;

  static bool _isTimestamp(dynamic value) => value is Timestamp;

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static bool _isSameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
