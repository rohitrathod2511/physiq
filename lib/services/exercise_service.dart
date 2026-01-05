import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:physiq/services/user_repository.dart'; // Assuming this exists for user data

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _kPendingLogsKey = 'pending_exercise_logs';

  Future<void> logExercise(ExerciseLog log) async {
    try {
      // 1. Write to exerciseLogs collection
      await _firestore
          .collection('users')
          .doc(log.userId)
          .collection('exerciseLogs')
          .doc(log.id)
          .set(log.toMap());

      // 2. Update daily aggregate atomically
      final dateKey = log.timestamp.toIso8601String().split('T')[0];
      final dailyRef = _firestore
          .collection('users')
          .doc(log.userId)
          .collection('daily')
          .doc(dateKey);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(dailyRef);
        
        if (!snapshot.exists) {
          transaction.set(dailyRef, {
            'exerciseCalories': log.calories,
            'totalCaloriesBurned': log.calories, // + BMR + steps (handled elsewhere)
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(dailyRef, {
            'exerciseCalories': FieldValue.increment(log.calories),
            'totalCaloriesBurned': FieldValue.increment(log.calories),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Offline handling
      await _queueLogLocally(log);
    }
  }

  Future<void> _queueLogLocally(ExerciseLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_kPendingLogsKey) ?? [];
    pending.add(jsonEncode(log.toMap())); // Simple serialization
    await prefs.setStringList(_kPendingLogsKey, pending);
  }

  Future<void> syncPendingLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_kPendingLogsKey) ?? [];
    
    if (pending.isEmpty) return;

    final List<String> remaining = [];
    
    for (final logStr in pending) {
      try {
        // Re-deserialize but we need to handle Timestamp conversion manually if using fromMap directly on JSON
        // For simplicity, we'll reconstruct the map
        final Map<String, dynamic> map = jsonDecode(logStr);
        // Fix timestamp for fromMap
        map['timestamp'] = Timestamp.fromDate(DateTime.parse(map['timestamp'] is String ? map['timestamp'] : DateTime.now().toIso8601String())); 
        
        final log = ExerciseLog.fromMap(map);
        await logExercise(log);
      } catch (e) {
        remaining.add(logStr); // Keep if failed
      }
    }

    await prefs.setStringList(_kPendingLogsKey, remaining);
  }

  Future<List<Map<String, dynamic>>> loadExerciseCategories() async {
    // In a real app, fetch from Firestore or RemoteConfig
    // Returning hardcoded list for now as per requirements
    return [
      {'id': 'home', 'title': 'Home Exercises', 'subtitle': 'Bodyweight & at-home routines', 'icon': 'home'},
      {'id': 'gym', 'title': 'Gym', 'subtitle': 'Gym & equipment-based', 'icon': 'fitness_center'},
      {'id': 'run', 'title': 'Run', 'subtitle': 'Running, jogging, sprinting', 'icon': 'directions_run'},
      {'id': 'cycling', 'title': 'Cycling', 'subtitle': 'Cycle, spin, outdoor', 'icon': 'directions_bike'},
      {'id': 'describe', 'title': 'Describe', 'subtitle': 'Write your workout in text', 'icon': 'edit'},
      {'id': 'manual', 'title': 'Manual', 'subtitle': 'Enter exact calories burned', 'icon': 'add_circle_outline'},
    ];
  }
}
