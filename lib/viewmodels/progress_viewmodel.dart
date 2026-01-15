import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/weight_model.dart';
import 'package:physiq/models/progress_photo_model.dart';
import 'package:physiq/services/progress_repository.dart';

final progressViewModelProvider = StateNotifierProvider<ProgressViewModel, ProgressState>((ref) {
  return ProgressViewModel(ref.read(progressRepositoryProvider));
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

  ProgressViewModel(this._repository) : super(ProgressState()) {
    loadData();
  }

  // Normalize raw strings from Firebase
  String _normalizeGoalType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('gain')) return 'gain';
    if (lower.contains('maintain')) return 'maintain';
    return 'loss'; // Default to loss
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    
    final goal = await _repository.getGoalWeight();
    final initial = await _repository.getInitialWeight(); // Onboarding weight (immutable source)
    final height = await _repository.getUserHeight();
    final rawType = await _repository.getGoalType();
    final history = await _repository.getWeightHistory(state.selectedRange);
    final photos = await _repository.getProgressPhotos();
    final created = await _repository.getAccountCreationDate();

    final normalizedType = _normalizeGoalType(rawType);

    // FIX: Determine current weight logic
    // initialWeight must ALWAYS be onboarding weight (users.weightKg) - never overwritten.
    // currentWeight = latest weight_history OR initialWeight.
    
    double current = 0;
    
    if (history.isNotEmpty) {
      current = history.last.weightKg;
    } else {
      current = initial;
    }
    
    // Safety check just in case both represent 0 or failure
    if (current == 0 && initial > 0) current = initial;
    
    // Construct display history for graph
    List<WeightEntry> displayHistory = [...history];
    
    // Only inject fake data if history is COMPLETELY empty and we have an initial weight
    // This is the "New User" state.
    if (history.isEmpty && initial > 0) {
       final date = created ?? DateTime.now();
       // Initial point
       displayHistory.add(WeightEntry(id: 'init', weightKg: initial, date: date, loggedAt: date));
       // Current point (now) to create a flat line
       displayHistory.add(WeightEntry(id: 'curr', weightKg: current, date: DateTime.now(), loggedAt: DateTime.now()));
    } 
    
    // Sort logic
    displayHistory.sort((a,b) => a.date.compareTo(b.date));

    state = state.copyWith(
      isLoading: false,
      goalWeight: goal,
      initialWeight: initial,
      currentWeight: current,
      height: height,
      goalType: normalizedType,
      weightHistory: displayHistory,
      photos: photos,
    );
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

  Future<void> addPhoto(ProgressPhoto photo) async {
    await _repository.uploadProgressPhoto(photo);
    final photos = await _repository.getProgressPhotos();
    state = state.copyWith(photos: photos);
  }
}
