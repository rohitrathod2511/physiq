import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:physiq/services/exercise_service.dart';
import 'package:physiq/services/calorie_calculator_service.dart';
import 'package:physiq/services/user_repository.dart';
import 'package:uuid/uuid.dart';

final exerciseViewModelProvider = StateNotifierProvider<ExerciseViewModel, AsyncValue<void>>((ref) {
  return ExerciseViewModel(
    ref.read(userRepositoryProvider),
    ExerciseService(),
  );
});

class ExerciseViewModel extends StateNotifier<AsyncValue<void>> {
  final UserRepository _userRepo;
  final ExerciseService _exerciseService;
  final _uuid = const Uuid();

  ExerciseViewModel(this._userRepo, this._exerciseService) : super(const AsyncValue.data(null));

  Future<List<Map<String, dynamic>>> loadCategories() {
    return _exerciseService.loadExerciseCategories();
  }

  Future<void> logExercise({
    required String userId,
    required String exerciseId,
    required String name,
    required ExerciseType type,
    required int durationMinutes,
    required double calories,
    required String intensity,
    Map<String, dynamic> details = const {},
    bool isManualOverride = false,
    String source = 'manual',
  }) async {
    state = const AsyncValue.loading();
    try {
      final log = ExerciseLog(
        id: _uuid.v4(),
        userId: userId,
        exerciseId: exerciseId,
        name: name,
        type: type,
        timestamp: DateTime.now(),
        durationMinutes: durationMinutes,
        calories: calories,
        intensity: intensity,
        details: details,
        isManualOverride: isManualOverride,
        source: source,
      );

      await _exerciseService.logExercise(log);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<double> estimateCalories({
    required String exerciseType,
    required String intensity,
    required int durationMinutes,
    required double weightKg,
  }) async {
    final metadata = await _exerciseService.getExerciseMetadata(exerciseType);
    double met = 5.0; // Default fallback

    if (metadata != null) {
      final metData = metadata['met'];
      if (metadata['supportsIntensity'] == true && metData is Map) {
         met = (metData[intensity] ?? metData['medium'] ?? 5.0).toDouble();
      } else if (metData is num) {
         met = metData.toDouble();
      }
    }
    
    return CalorieCalculator.calculateCalories(
      met: met,
      weightKg: weightKg,
      durationMinutes: durationMinutes,
      intensity: intensity,
      exerciseType: exerciseType,
    );
  }
  
  // Timer logic would go here if we were managing global timer state, 
  // but for this scope, local state in the widget is often sufficient 
  // unless the timer needs to persist across screens.
  // We will implement timer logic in the UI widget for simplicity as per requirements.
}
