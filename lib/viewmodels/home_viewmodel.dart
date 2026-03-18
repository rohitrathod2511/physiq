import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/services/user_repository.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/services/exercise_service.dart';
import 'package:physiq/models/exercise_log_model.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
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
  StreamSubscription<Map<String, dynamic>>? _dailySummarySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _recentMealsSubscription;
  StreamSubscription<List<ExerciseLog>>? _recentWorkoutsSubscription;
  StreamSubscription<dynamic>? _userSubscription;

  HomeViewModel(
    this._firestoreService,
    this._userRepository,
    this._exerciseService,
  ) : super(
        HomeState(
          // Initialize with empty data to prevent infinite loading
          dailySummary: {
            'caloriesConsumed': 0,
            'proteinConsumed': 0,
            'fatConsumed': 0,
            'carbsConsumed': 0,
            'caloriesGoal': 2000, // Default
          },
        ),
      ) {
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
    fetchRecentMeals(uid, date: state.selectedDate);
    fetchRecentWorkouts(uid, date: state.selectedDate);

    // Listen to user profile for currentPlan
    _userSubscription?.cancel();
    _userSubscription = _userRepository.streamUser(uid).listen((user) {
      if (user != null && user.currentPlan != null) {
        state = state.copyWith(currentPlan: user.currentPlan);
      }
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
      fetchRecentMeals(uid, date: date);
      fetchRecentWorkouts(uid, date: date);
    }
  }

  void fetchDailySummary(DateTime date, String uid) {
    _dailySummarySubscription?.cancel();
    _dailySummarySubscription = _firestoreService
        .streamDailySummary(uid, date)
        .listen((data) {
      state = state.copyWith(dailySummary: data);
    });
  }

  void fetchRecentMeals(String uid, {DateTime? date}) {
    _recentMealsSubscription?.cancel();
    _recentMealsSubscription = _firestoreService
        .streamMealsForDate(uid, date ?? state.selectedDate)
        .listen((data) {
      state = state.copyWith(recentMeals: data);
    });
  }

  void fetchRecentWorkouts(String uid, {DateTime? date}) {
    _recentWorkoutsSubscription?.cancel();
    _recentWorkoutsSubscription = _exerciseService
        .getLogsForDate(uid, date ?? state.selectedDate)
        .listen((logs) {
      state = state.copyWith(recentWorkouts: logs);
    });
  }

  // --- DELETE METHODS ---

  void deleteMealLocally(String mealId) {
    if (state.recentMeals == null) return;

    // 1. Remove from local list
    final updatedMeals = state.recentMeals!
        .where((m) => m['id'] != mealId)
        .toList();

    // 2. Recalculate summary from the NEW list to ensure UI updates instantly
    _recalculateTotalsFromLocal(updatedMeals, state.recentWorkouts ?? []);

    state = state.copyWith(recentMeals: updatedMeals);
  }

  Future<void> deleteMealFirebase(String mealId, DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.deleteMeal(uid, mealId, date);
    // Stream listener in FirestoreService will handle the final "official" update
  }

  void deleteExerciseLocally(String logId) {
    if (state.recentWorkouts == null) return;

    // 1. Remove from local list
    final updatedWorkouts = state.recentWorkouts!
        .where((w) => w.id != logId)
        .toList();

    // 2. Recalculate summary
    _recalculateTotalsFromLocal(state.recentMeals ?? [], updatedWorkouts);

    state = state.copyWith(recentWorkouts: updatedWorkouts);
  }

  Future<void> deleteExerciseFirebase(String logId, DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _exerciseService.deleteExercise(uid, logId, date);
  }

  void _recalculateTotalsFromLocal(
    List<Map<String, dynamic>> meals,
    List<ExerciseLog> exercises,
  ) {
    // 1. Use FOLD for Meals (Macros)
    final double totalCalories = meals.fold(
      0.0,
      (sum, m) => sum + _toDoubleSafe(m['calories']),
    );
    final double totalProtein = meals.fold(
      0.0,
      (sum, m) => sum + _toDoubleSafe(m['proteinG'] ?? m['protein']),
    );
    final double totalCarbs = meals.fold(
      0.0,
      (sum, m) => sum + _toDoubleSafe(m['carbsG'] ?? m['carbs']),
    );
    final double totalFat = meals.fold(
      0.0,
      (sum, m) => sum + _toDoubleSafe(m['fatG'] ?? m['fat'] ?? m['fats']),
    );

    // 2. Use FOLD for Exercises (Burn)
    final double totalBurn = exercises.fold(
      0.0,
      (sum, e) => sum + e.calories,
    );

    final updatedSummary = Map<String, dynamic>.from(state.dailySummary ?? {});
    updatedSummary['calories'] = totalCalories;
    updatedSummary['protein'] = totalProtein;
    updatedSummary['carbs'] = totalCarbs;
    updatedSummary['fat'] = totalFat;
    updatedSummary['caloriesBurned'] = totalBurn;
    updatedSummary['exerciseCalories'] = totalBurn;

    state = state.copyWith(dailySummary: updatedSummary);
  }

  double _toDoubleSafe(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
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
    fetchStreak(uid);
  }

  Future<void> deleteMeal(String mealId, DateTime date) async {
    deleteMealLocally(mealId);
    await deleteMealFirebase(mealId, date);
  }

  Future<void> deleteExercise(String logId, DateTime date) async {
    deleteExerciseLocally(logId);
    await deleteExerciseFirebase(logId, date);
  }

  @override
  void dispose() {
    _dailySummarySubscription?.cancel();
    _recentMealsSubscription?.cancel();
    _recentWorkoutsSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
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
