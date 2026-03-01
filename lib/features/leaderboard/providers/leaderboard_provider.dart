import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/features/leaderboard/models/daily_activity_model.dart';
import 'package:physiq/features/leaderboard/models/leaderboard_user_model.dart';
import 'package:physiq/features/leaderboard/services/leaderboard_service.dart';

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService();
});

final leaderboardTop100Provider =
    StreamProvider.autoDispose<List<LeaderboardUser>>((ref) {
      final service = ref.watch(leaderboardServiceProvider);
      return service.watchTopLeaderboard();
    });

final todayDailyActivityProvider = FutureProvider.autoDispose
    .family<DailyActivityModel?, String>((ref, uid) {
      final service = ref.watch(leaderboardServiceProvider);
      return service.fetchTodayActivity(uid);
    });

final leaderboardActionsProvider = Provider<LeaderboardActions>((ref) {
  final service = ref.watch(leaderboardServiceProvider);
  return LeaderboardActions(service);
});

class LeaderboardActions {
  const LeaderboardActions(this._service);

  final LeaderboardService _service;

  Future<void> ensureLeaderboardUser(String uid) {
    return _service.ensureUserLeaderboardFields(uid);
  }

  Future<void> syncDailyBoundary(String uid) {
    return _service.syncDailyResetIfNeeded(uid);
  }

  Future<DailyActivityModel> onMealLogged(
    String uid, {
    int mealTargetPerDay = LeaderboardService.defaultMealTargetPerDay,
  }) {
    return _service.logMealActivity(
      uid: uid,
      mealTargetPerDay: mealTargetPerDay,
    );
  }

  Future<DailyActivityModel> onWorkoutLogged(
    String uid, {
    int mealTargetPerDay = LeaderboardService.defaultMealTargetPerDay,
  }) {
    return _service.logWorkoutActivity(
      uid: uid,
      mealTargetPerDay: mealTargetPerDay,
    );
  }

  Future<DailyActivityModel> onWaterTargetHit(
    String uid, {
    int mealTargetPerDay = LeaderboardService.defaultMealTargetPerDay,
  }) {
    return _service.logWaterTargetHit(
      uid: uid,
      mealTargetPerDay: mealTargetPerDay,
    );
  }
}
