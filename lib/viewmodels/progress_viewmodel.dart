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
  final List<WeightEntry> weightHistory;
  final List<ProgressPhoto> photos;
  final String selectedRange;

  ProgressState({
    this.isLoading = true,
    this.currentWeight = 0,
    this.goalWeight = 0,
    this.initialWeight = 0,
    this.weightHistory = const [],
    this.photos = const [],
    this.selectedRange = '3M',
  });

  ProgressState copyWith({
    bool? isLoading,
    double? currentWeight,
    double? goalWeight,
    double? initialWeight,
    List<WeightEntry>? weightHistory,
    List<ProgressPhoto>? photos,
    String? selectedRange,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      currentWeight: currentWeight ?? this.currentWeight,
      goalWeight: goalWeight ?? this.goalWeight,
      initialWeight: initialWeight ?? this.initialWeight,
      weightHistory: weightHistory ?? this.weightHistory,
      photos: photos ?? this.photos,
      selectedRange: selectedRange ?? this.selectedRange,
    );
  }
  
  double get progressPercent {
    if (initialWeight == goalWeight) return 0;
    final totalDiff = (goalWeight - initialWeight).abs();
    final currentDiff = (currentWeight - initialWeight).abs();
    // If we moved away from goal, 0%
    // If goal is lower (loss): initial 85, goal 70. current 78.5.
    // total 15. current diff 6.5. 6.5/15 = 43%
    
    // Check direction
    bool isWeightLoss = goalWeight < initialWeight;
    if (isWeightLoss && currentWeight > initialWeight) return 0;
    if (!isWeightLoss && currentWeight < initialWeight) return 0;
    
    double percent = (currentDiff / totalDiff);
    if (percent > 1) percent = 1;
    if (percent < 0) percent = 0;
    return percent;
  }
  
  double get bmi {
    // Assuming height 175cm for now as we don't have it in this state yet.
    // In real app, fetch from user profile.
    double heightM = 1.75; 
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

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    
    final goal = await _repository.getGoalWeight();
    final initial = await _repository.getInitialWeight();
    final history = await _repository.getWeightHistory(state.selectedRange);
    final photos = await _repository.getProgressPhotos();
    
    double current = initial;
    if (history.isNotEmpty) {
      current = history.last.weightKg;
    }

    state = state.copyWith(
      isLoading: false,
      goalWeight: goal,
      initialWeight: initial,
      currentWeight: current,
      weightHistory: history,
      photos: photos,
    );
  }

  Future<void> setRange(String range) async {
    state = state.copyWith(selectedRange: range, isLoading: true);
    final history = await _repository.getWeightHistory(range);
    state = state.copyWith(isLoading: false, weightHistory: history);
  }

  Future<void> addWeight(double weight, DateTime date) async {
    await _repository.addWeightEntry(weight, date);
    await loadData(); // Reload to update graph and current weight
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
