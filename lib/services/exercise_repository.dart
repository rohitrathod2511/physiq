import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/exercise_model.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/utils/metrics_calculator.dart';

final exerciseRepositoryProvider = Provider((ref) => ExerciseRepository());

class ExerciseRepository {
  // Mock data for now
  final List<Exercise> _mockLibrary = [
    Exercise(
      id: 'push_ups',
      title: 'Push Ups',
      category: 'Upper Body',
      equipment: 'Bodyweight',
      defaultMET: 8.0,
      instructions: 'Keep your body straight and lower your chest to the floor.',
    ),
    Exercise(
      id: 'squats',
      title: 'Squats',
      category: 'Legs & Glutes',
      equipment: 'Bodyweight',
      defaultMET: 5.5,
      instructions: 'Lower your hips back and down as if sitting in a chair.',
    ),
    Exercise(
      id: 'plank',
      title: 'Plank',
      category: 'Core & Stability',
      equipment: 'Bodyweight',
      defaultMET: 3.0,
      instructions: 'Hold your body in a straight line supported by forearms and toes.',
    ),
    Exercise(
      id: 'burpees',
      title: 'Burpees',
      category: 'Cardio & Strength',
      equipment: 'Bodyweight',
      defaultMET: 10.0,
      instructions: 'Drop to a squat, kick back, push up, jump forward, and jump up.',
    ),
    Exercise(
      id: 'running',
      title: 'Running',
      category: 'Cardio & Strength',
      equipment: 'None',
      defaultMET: 9.8,
      instructions: 'Run at a steady pace.',
    ),
  ];

  Future<List<Exercise>> getExercisesByCategory(String category) async {
    if (AppConfig.useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (category == 'All') return _mockLibrary;
      return _mockLibrary.where((e) => e.category == category || (category == 'Cardio & Strength' && e.category == 'Cardio & Strength')).toList();
    }
    // TODO: Implement Firestore fetch
    return [];
  }

  // Mock logs
  final List<ExerciseLog> _mockLogs = [];

  Future<List<ExerciseLog>> getWorkoutHistory() async {
    if (AppConfig.useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Return sorted by date desc
      _mockLogs.sort((a, b) => b.endedAt.compareTo(a.endedAt));
      return _mockLogs;
    }
    // TODO: Implement Firestore fetch
    return [];
  }

  Future<void> saveExerciseLog(ExerciseLog log) async {
    if (AppConfig.useMockBackend) {
      print('Saving log locally: ${log.title}, ${log.exerciseCalories} kcal');
      _mockLogs.add(log);
      return;
    }
    // TODO: Implement Firestore save
  }

  Future<void> saveCustomExercise(Exercise exercise) async {
    if (AppConfig.useMockBackend) {
      print('Saving custom exercise: ${exercise.title}');
      _mockLibrary.add(exercise);
      return;
    }
    // TODO: Implement Firestore save
  }
  
  List<String> getCategories() {
    return [
      'Upper Body',
      'Back & Biceps',
      'Legs & Glutes',
      'Core & Stability',
      'Cardio & Strength',
      'Fat Loss',
    ];
  }
}
