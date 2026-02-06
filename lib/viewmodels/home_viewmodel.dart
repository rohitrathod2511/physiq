import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/services/user_repository.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/services/exercise_service.dart';
import 'package:physiq/models/exercise_log_model.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());


final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(
    ref.watch(firestoreServiceProvider),
    ref.watch(userRepositoryProvider),
    ExerciseService(),
  );
});

class HomeViewModel extends StateNotifier<HomeState> {
  final FirestoreService _firestoreService;
  final UserRepository _userRepository;
  final ExerciseService _exerciseService;

  HomeViewModel(this._firestoreService, this._userRepository, this._exerciseService)
      : super(HomeState(
          // Initialize with empty data to prevent infinite loading
          dailySummary: {
            'caloriesConsumed': 0,
            'proteinConsumed': 0,
            'fatConsumed': 0,
            'carbsConsumed': 0,
            'caloriesGoal': 2000, // Default
          },
        )) {
    // Listen to Auth Changes to handle sign-in/out
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _init(user.uid);
      } else {
         // Reset to guest defaults if logged out
         // Or keep existing state. For now, doing nothing is safer than clearing.
      }
    });
  }

  void _init(String uid) {
    fetchDailySummary(state.selectedDate, uid);
    fetchRecentMeals(uid);
    
    // Listen to user profile for currentPlan
    _userRepository.streamUser(uid).listen((user) {
      if (user != null && user.currentPlan != null) {
        state = state.copyWith(currentPlan: user.currentPlan);
      }
    });

    // Listen to Recent Workouts
    _exerciseService.getRecentLogs(uid).listen((logs) {
      state = state.copyWith(recentWorkouts: logs);
      fetchStreak(uid);
    });
    
    // Fetch Streak
    fetchStreak(uid);
  }

  Future<void> fetchStreak(String uid) async {
    final s = await _firestoreService.calculateStreak(uid);
    state = state.copyWith(streak: s);
  }

  Future<void> logWater(int amountMl) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.logWater(uid, amountMl, state.selectedDate);
      // No need to fetchDailySummary here, the stream from _init/selectDate handles updates
      fetchStreak(uid); 
    }
  }

  Future<void> updateWaterGoal(int goalMl) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateWaterGoal(uid, goalMl, state.selectedDate);
      fetchDailySummary(state.selectedDate, uid);
    }
  }

  void selectDate(DateTime date) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    state = state.copyWith(selectedDate: date);
    if (uid != null) {
      fetchDailySummary(date, uid);
    }
  }

  void fetchDailySummary(DateTime date, String uid) {
    _firestoreService.streamDailySummary(uid, date).listen((data) {
      state = state.copyWith(dailySummary: data);
    });
  }

  void fetchRecentMeals(String uid) {
    _firestoreService.fetchRecentMeals(uid).then((data) {
      state = state.copyWith(recentMeals: data);
    });
  }

  void updateCurrentPlan(Map<String, dynamic> plan) {
    state = state.copyWith(currentPlan: plan);
  }

  void openAddMenu() {
    // Logic to open add menu
  }

  void openCalendar() {
    // Logic to open calendar
  }

  Future<void> logMeal(MealModel meal) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestoreService.logMeal(uid, meal.toMap(), meal.timestamp);
    
    // Refresh recent meals
    fetchRecentMeals(uid);
    // Refresh daily summary (will trigger stream listener or new fetch)
    fetchDailySummary(state.selectedDate, uid);
    // Refresh streak
    fetchStreak(uid);
  }
}

class HomeState {
  final DateTime selectedDate;
  final Map<String, dynamic>? dailySummary;
  final List<Map<String, dynamic>>? recentMeals;
  final bool isPremium;
  final Map<String, dynamic>? currentPlan;
  final List<ExerciseLog>? recentWorkouts;
  final int streak;

  HomeState({
    DateTime? selectedDate,
    this.dailySummary,
    this.recentMeals,
    this.isPremium = false,
    this.currentPlan,
    this.recentWorkouts,
    this.streak = 0,
  }) : selectedDate = selectedDate ?? DateTime.now();

  HomeState copyWith({
    DateTime? selectedDate,
    Map<String, dynamic>? dailySummary,
    List<Map<String, dynamic>>? recentMeals,
    bool? isPremium,
    Map<String, dynamic>? currentPlan,
    List<ExerciseLog>? recentWorkouts,
    int? streak,
  }) {
    return HomeState(
      selectedDate: selectedDate ?? this.selectedDate,
      dailySummary: dailySummary ?? this.dailySummary,
      recentMeals: recentMeals ?? this.recentMeals,
      isPremium: isPremium ?? this.isPremium,
      currentPlan: currentPlan ?? this.currentPlan,
      recentWorkouts: recentWorkouts ?? this.recentWorkouts,
      streak: streak ?? this.streak,
    );
  }
}
