
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class OnboardingStore extends ChangeNotifier {
  static const String _storageKey = 'onboarding_draft';
  Map<String, dynamic> _data = {};

  Map<String, dynamic> get data => _data;
  
  // Helper getters
  bool get isGuest => _data['isGuest'] ?? false;

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        _data = json.decode(jsonString);
        notifyListeners();
      } catch (e) {
        print('Error loading draft: $e');
      }
    }
  }

  Future<void> saveStepData(String stepKey, dynamic value) async {
    _data[stepKey] = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(_data));
  }

  Future<void> clearDraft() async {
    _data = {};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
  
  // Helper getters for common fields
  String? get name => _data['name'];
  String? get gender => _data['gender'];
  int? get birthYear => _data['birthYear'];
  double? get heightCm => _data['heightCm'];
  double? get weightKg => _data['weightKg'];
  String? get activityLevel => _data['activityLevel'];
  String? get goal => _data['goal'];
  double? get targetWeightKg => _data['targetWeightKg'];
  String? get dietPreference => _data['dietPreference'];
  
  // Helper to check if essential data is present for plan generation
  bool get canGeneratePlan {
    return gender != null &&
           birthYear != null &&
           heightCm != null &&
           weightKg != null &&
           activityLevel != null &&
           goal != null;
  }
}
