import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/models/user_model.dart';
import 'package:physiq/models/weight_model.dart';
import 'package:physiq/models/progress_photo_model.dart';
import 'package:physiq/services/progress_repository.dart';
import 'package:physiq/services/user_repository.dart';

final progressViewModelProvider = StateNotifierProvider<ProgressViewModel, ProgressState>((ref) {
  return ProgressViewModel(
    ref.read(progressRepositoryProvider),
    ref.read(userRepositoryProvider),
  );
});

class ProgressState {
  final bool isLoading;
  final double currentWeight;
  final double goalWeight;
  final double initialWeight;
  final double height; // stored in cm
  final String goalType; // normalized: 'gain', 'loss', 'maintain'
  final List<WeightEntry> weightHistory;
  final List<ProgressPhoto> photos;
  final String selectedRange;

  ProgressState({
    this.isLoading = true,
    this.currentWeight = 0,
    this.goalWeight = 0,
    this.initialWeight = 0,
    this.height = 170,
    this.goalType = 'loss',
    this.weightHistory = const [],
    this.photos = const [],
    this.selectedRange = '3M',
  });

  ProgressState copyWith({
    bool? isLoading,
    double? currentWeight,
    double? goalWeight,
    double? initialWeight,
    double? height,
    String? goalType,
    List<WeightEntry>? weightHistory,
    List<ProgressPhoto>? photos,
    String? selectedRange,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      currentWeight: currentWeight ?? this.currentWeight,
      goalWeight: goalWeight ?? this.goalWeight,
      initialWeight: initialWeight ?? this.initialWeight,
      height: height ?? this.height,
      goalType: goalType ?? this.goalType,
      weightHistory: weightHistory ?? this.weightHistory,
      photos: photos ?? this.photos,
      selectedRange: selectedRange ?? this.selectedRange,
    );
  }
  
  double get progressPercent {
    final start = initialWeight;
    final end = goalWeight;
    final current = currentWeight;

    // Safety
    if (start <= 0 || end <= 0) return 0;
    
    // Normalized check
    if (goalType == 'maintain') {
      const tolerance = 5.0; 
      double diff = (current - end).abs();
      double p = 1.0 - (diff / tolerance);
      return p.clamp(0.0, 1.0);
    }
    
    if (goalType == 'gain') {
      // Gain: from start to end
      if (end <= start) return 0; // target must be > start
      double p = (current - start) / (end - start);
      return p.clamp(0.0, 1.0);
    }
    
    // Loss
    if (start <= end) return 0; // target must be < start for loss
    double p = (start - current) / (start - end);
    return p.clamp(0.0, 1.0);
  }
  
  double get bmi {
    if (height <= 0) return 0;
    double heightM = height / 100.0; 
    return currentWeight / (heightM * heightM);
  }
  
  String get bmiCategory {
    final val = bmi;
    if (val < 18.5) return 'Underweight';
    if (val < 24.9) return 'Healthy';
    if (val < 29.9) return 'Overweight';
    return 'Obese';
  }
}

class ProgressViewModel extends StateNotifier<ProgressState> {
  final ProgressRepository _repository;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userDocSubscription;

  ProgressViewModel(this._repository, this._userRepository) : super(ProgressState()) {
    // 1. Listen to Auth Changes (Login/Logout/Switch)
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _init(user.uid);
      } else {
        // Clear state on logout to prevent leaks
        state = ProgressState(); 
        _userDocSubscription?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _init(String uid) {
    // 2. Initial Load
    loadData();

    // 3. Listen to User Document Changes (Settings updates sync)
    _userDocSubscription?.cancel();
    _userDocSubscription = _userRepository.streamUser(uid).listen((userModel) {
      if (userModel != null) {
        // When user profile updates (goal, weight, height in Settings),
        // we reload data to ensure sync.
        // We pass the userModel directly to avoid extra fetches and race conditions.
        loadData(user: userModel);
      }
    });
  }

  // Normalize raw strings from Firebase
  String _normalizeGoalType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('gain')) return 'gain';
    if (lower.contains('maintain')) return 'maintain';
    return 'loss'; // Default to loss
  }

  Future<void> loadData({UserModel? user}) async {
    // We'll only set isLoading if history is empty (first load)
    if (state.weightHistory.isEmpty) {
       state = state.copyWith(isLoading: true);
    }

    // Fetch data - Use 'user' if available for instant sync
    final double goal = user?.goalWeightKg ?? await _repository.getGoalWeight();
    
    // START WEIGHT LOGIC:
    // We want the Start Weight to be the user's FIRST EVER weight (onboarding).
    // user.weightKg is often updated to be 'Current Profile Weight' in settings.
    // So we try fetching the earliest history entry.
    double? earliest = await _repository.getEarliestWeight();
    
    // Fallback: If no history, use profile weight (onboarding typically sets this and history together)
    // If profile weight is used as fallback, it's correct for a brand new user.
    final double initial = earliest ?? (user?.weightKg ?? await _repository.getInitialWeight());

    final double height = user?.heightCm ?? await _repository.getUserHeight();
    
    // Type usually doesn't change from settings but nice to have.
    final rawType = await _repository.getGoalType();
    
    // History is in subcollection, so we MUST fetch it or listen to it separately.
    // Repo fetch is fine, but if we wanted instant weight update from 'currentWeight' field in Settings -> 
    // we already handle that by reading 'user?.weightKg' as 'initial'.
    // If 'currentWeight' is derived from History, we need History.
    final history = await _repository.getWeightHistory(state.selectedRange);
    final photos = await _repository.getProgressPhotos();
    final created = user?.createdAt ?? await _repository.getAccountCreationDate();

    final normalizedType = _normalizeGoalType(rawType);

    // FIX: Determine current weight logic
    // initialWeight = onboarding/first-baseline. currentWeight = latest weight_history OR initialWeight.
    double current = 0;

    if (history.isNotEmpty) {
      current = history.last.weightKg;
    } else {
      current = initial;
    }

    // Safety check
    if (current == 0 && initial > 0) current = initial;

    // FIRST-TIME SYNC FIX:
    // When user logs first weight (history.length == 1), we need to ensure:
    // - Cards display immediately with the single data point
    // - No comparison needed (initial == current for first entry)
    // For length == 1: treat first log as both start and current
    // For length >= 2: normal comparison (initial = earliest, current = latest)
    final double effectiveInitial = history.length == 1 ? current : initial;

    // Construct display history for graph
    List<WeightEntry> displayHistory = [...history];

    // For empty state (no logs yet), keep synthetic baseline
    // This helps show UI structure even before first log
    if (displayHistory.isEmpty && initial > 0) {
      final date = created ?? DateTime.now();
      displayHistory.add(WeightEntry(id: 'init', weightKg: initial, date: date, loggedAt: date));
      displayHistory.add(WeightEntry(id: 'curr', weightKg: current, date: DateTime.now(), loggedAt: DateTime.now()));
    }
    // When length >= 1: use real data only (no synthetic entries)

    displayHistory.sort((a, b) => a.date.compareTo(b.date));

    // Update State
    if (mounted) {
      state = state.copyWith(
        isLoading: false,
        goalWeight: goal,
        initialWeight: effectiveInitial,
        currentWeight: current,
        height: height,
        goalType: normalizedType,
        weightHistory: displayHistory,
        photos: photos,
      );
    }
  }

  Future<void> setRange(String range) async {
    state = state.copyWith(selectedRange: range, isLoading: true);
    await loadData();
  }

  Future<void> addWeight(double weight, DateTime date) async {
    await _repository.addWeightEntry(weight, date);
    await loadData(); 
  }
  
  Future<void> updateGoal(double weight) async {
    await _repository.updateGoalWeight(weight);
    await loadData();
  }

  Future<void> addPhoto(File file, double weight) async {
    await _repository.uploadProgressPhoto(file, weight);
    // Reload photos only
    final photos = await _repository.getProgressPhotos();
    state = state.copyWith(photos: photos);
  }

  Future<void> deletePhoto(ProgressPhoto photo) async {
    await _repository.deleteProgressPhoto(photo.id, photo.imageUrl);
    await loadData();
  }
}

