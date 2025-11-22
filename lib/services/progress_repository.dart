import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/weight_model.dart';
import 'package:physiq/models/progress_photo_model.dart';
import 'package:physiq/services/auth_service.dart';

final progressRepositoryProvider = Provider((ref) => ProgressRepository());

class ProgressRepository {
  // Mock Data
  final List<WeightEntry> _mockWeights = [
    WeightEntry(id: '1', weightKg: 85.0, date: DateTime.now().subtract(const Duration(days: 90)), loggedAt: DateTime.now()),
    WeightEntry(id: '2', weightKg: 84.0, date: DateTime.now().subtract(const Duration(days: 75)), loggedAt: DateTime.now()),
    WeightEntry(id: '3', weightKg: 82.5, date: DateTime.now().subtract(const Duration(days: 60)), loggedAt: DateTime.now()),
    WeightEntry(id: '4', weightKg: 81.0, date: DateTime.now().subtract(const Duration(days: 45)), loggedAt: DateTime.now()),
    WeightEntry(id: '5', weightKg: 80.0, date: DateTime.now().subtract(const Duration(days: 30)), loggedAt: DateTime.now()),
    WeightEntry(id: '6', weightKg: 79.0, date: DateTime.now().subtract(const Duration(days: 15)), loggedAt: DateTime.now()),
    WeightEntry(id: '7', weightKg: 78.5, date: DateTime.now(), loggedAt: DateTime.now()),
  ];

  final List<ProgressPhoto> _mockPhotos = [];

  double _mockGoalWeight = 70.0;
  double _mockInitialWeight = 85.0;

  Future<List<WeightEntry>> getWeightHistory(String range) async {
    if (AppConfig.useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 500));
      final now = DateTime.now();
      Duration duration;
      switch (range) {
        case '1M':
          duration = const Duration(days: 30);
          break;
        case '3M':
          duration = const Duration(days: 90);
          break;
        case '6M':
          duration = const Duration(days: 180);
          break;
        case '1Y':
          duration = const Duration(days: 365);
          break;
        default:
          duration = const Duration(days: 30);
      }
      
      return _mockWeights.where((w) => w.date.isAfter(now.subtract(duration))).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    }
    // TODO: Implement Firestore fetch
    return [];
  }

  Future<void> addWeightEntry(double weight, DateTime date) async {
    if (AppConfig.useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockWeights.add(WeightEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weightKg: weight,
        date: date,
        loggedAt: DateTime.now(),
      ));
      return;
    }
    // TODO: Implement Firestore save
  }

  Future<List<ProgressPhoto>> getProgressPhotos() async {
    if (AppConfig.useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockPhotos..sort((a, b) => b.date.compareTo(a.date));
    }
    // TODO: Implement Firestore fetch
    return [];
  }

  Future<void> uploadProgressPhoto(ProgressPhoto photo) async {
    if (AppConfig.useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _mockPhotos.add(photo);
      return;
    }
    // TODO: Implement Firestore upload
  }

  Future<double> getGoalWeight() async {
    if (AppConfig.useMockBackend) {
      return _mockGoalWeight;
    }
    // TODO: Fetch from user profile
    return 70.0;
  }

  Future<double> getInitialWeight() async {
    if (AppConfig.useMockBackend) {
      return _mockInitialWeight;
    }
    // TODO: Fetch from user profile
    return 85.0;
  }
  
  Future<void> updateGoalWeight(double weight) async {
     if (AppConfig.useMockBackend) {
      _mockGoalWeight = weight;
      return;
    }
    // TODO: Update Firestore
  }
}
