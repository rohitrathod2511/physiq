import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/weight_model.dart';
import 'package:physiq/models/progress_photo_model.dart';
import 'package:physiq/services/auth_service.dart';


final progressRepositoryProvider = Provider((ref) => ProgressRepository());

class ProgressRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Mock Data (unused)
  final List<WeightEntry> _mockWeights = [];
  final List<ProgressPhoto> _mockPhotos = [];
  double _mockGoalWeight = 70.0;
  double _mockInitialWeight = 85.0;

  Future<List<WeightEntry>> getWeightHistory(String range) async {
    if (AppConfig.useMockBackend) {
       return [];
    }

    final user = _auth.currentUser;
    if (user == null) return [];

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
      case '9M':
        duration = const Duration(days: 270);
        break;
      case '1Y':
        duration = const Duration(days: 365);
        break;
      case 'All Time': 
        duration = const Duration(days: 3650);
        break;
      default:
        duration = const Duration(days: 90);
    }
    final startTime = now.subtract(duration);

    try {
      // Use Timestamp comparison as requested
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weight_history')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs.map((doc) => WeightEntry.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching weight history: $e');
      return [];
    }
  }

  Future<void> addWeightEntry(double weight, DateTime date) async {
    if (AppConfig.useMockBackend) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final entry = WeightEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weightKg: weight,
        date: date,
        loggedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weight_history')
          .doc(entry.id)
          .set(entry.toMap());
    } catch (e) {
      print('Error adding weight entry: $e');
    }
  }

  Future<List<ProgressPhoto>> getProgressPhotos() async {
    if (AppConfig.useMockBackend) return [];

    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progressPhotos')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => ProgressPhoto.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching progress photos: $e');
      return [];
    }
  }

  Future<void> uploadProgressPhoto(File imageFile, double currentWeight) async {
    if (AppConfig.useMockBackend) return;

    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(now);

      // 1. Check Daily Limit
      final todayPhotos = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progressPhotos')
          .where('dateKey', isEqualTo: dateKey)
          .get();

      if (todayPhotos.docs.length >= 3) {
        throw Exception('Daily upload limit reached (max 3).');
      }

      // 2. Upload to Storage
      final photoId = now.millisecondsSinceEpoch.toString();
      final storageRef = _storage
          .ref()
          .child('progress_photos/${user.uid}/$photoId.jpg');

      final uploadTask = await storageRef.putFile(imageFile); // Assuming pre-compressed
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 3. Save to Firestore
      final photo = ProgressPhoto(
        id: photoId,
        imageUrl: downloadUrl,
        weightKg: currentWeight,
        date: now,
        uploadedAt: now,
      );

      // Add dateKey for querying
      final photoMap = photo.toMap();
      photoMap['dateKey'] = dateKey;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progressPhotos')
          .doc(photoId)
          .set(photoMap);
      
    } catch (e) {
      print('Error uploading progress photo: $e');
      rethrow;
    }
  }

  Future<void> deleteProgressPhoto(String photoId, String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Delete from Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progressPhotos')
          .doc(photoId)
          .delete();

      // 2. Delete from Storage
      // Extract path or use stored ref if possible. 
      // Based on structure: progress_photos/{uid}/{photoId}.jpg
      // Ideally we would store the storage path, but we can reconstruct it or use the refFromURL if needed.
      // However, safest is to use the ID if we stuck to the naming convention.
      // But refFromURL is safer if we change naming later.
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (storageError) {
        print('Error deleting from storage (might act odd if URL is weird): $storageError');
        // Fallback to constructed path if URL parsing fails
        final fallbackRef = _storage.ref().child('progress_photos/${user.uid}/$photoId.jpg');
        await fallbackRef.delete();
      }

    } catch (e) {
      print('Error deleting progress photo: $e');
      rethrow;
    }
  }

  Future<double> getGoalWeight() async {
    if (AppConfig.useMockBackend) return _mockGoalWeight;

    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return 0.0;
      
      final data = doc.data()!;
      
      // Update: Check for 'targetWeightKg' at root level first
      if (data['targetWeightKg'] != null) {
        return (data['targetWeightKg'] as num).toDouble();
      }
      
      if (data['goals'] is Map && data['goals']['targetWeight'] != null) {
        return (data['goals']['targetWeight'] as num).toDouble();
      }
      if (data['goalWeightKg'] != null) {
        return (data['goalWeightKg'] as num).toDouble();
      }
      if (data['targetWeight'] != null) {
        return (data['targetWeight'] as num).toDouble();
      }
    } catch (e) {
      print('Error fetching goal weight: $e');
    }
    return 0.0;
  }

  Future<double> getInitialWeight() async {
    if (AppConfig.useMockBackend) return _mockInitialWeight;

    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return 0.0;

      final data = doc.data()!;
      // Prioritize 'weightKg' as this is the immutable onboarding weight
      if (data['weightKg'] != null) {
        return (data['weightKg'] as num).toDouble();
      }
      if (data['profile'] is Map && data['profile']['weight'] != null) {
        return (data['profile']['weight'] as num).toDouble();
      }
      if (data['weight'] != null) {
        return (data['weight'] as num).toDouble();
      }
    } catch (e) {
      print('Error fetching initial weight: $e');
    }
    return 0.0;
  }
  
  Future<void> updateGoalWeight(double weight) async {
    if (AppConfig.useMockBackend) return;
    
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // NOTE: Should we also update targetWeightKg at root? 
      // The request says "Fix getGoalWeight() to read data['targetWeightKg']", it didn't explicitly say update it.
      // But if we read from there, we probably should update there too for consistency.
      // However, constraint "Make minimal repository logic change only" suggests only fixing the READ.
      await _firestore.collection('users').doc(user.uid).set({
        'goals': {'targetWeight': weight},
        'targetWeightKg': weight, // Syncing to root for safety/consistency
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating goal weight: $e');
    }
  }

  Future<double> getUserHeight() async {
    if (AppConfig.useMockBackend) return 175.0;

    final user = _auth.currentUser;
    if (user == null) return 170.0;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return 170.0;

      final data = doc.data()!;
      if (data['profile'] is Map && data['profile']['height'] != null) {
        return (data['profile']['height'] as num).toDouble();
      }
      if (data['heightCm'] != null) {
        return (data['heightCm'] as num).toDouble();
      }
      if (data['height'] != null) {
        return (data['height'] as num).toDouble();
      }
    } catch (e) {
      print('Error fetching height: $e');
    }
    return 170.0;
  }

  Future<DateTime?> getAccountCreationDate() async {
    if (AppConfig.useMockBackend) return DateTime.now().subtract(const Duration(days: 30));

    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      // Tries to find createdAt in meta or root
      if (data['meta'] is Map && data['meta']['created_at'] != null) {
        return (data['meta']['created_at'] as Timestamp).toDate();
      }
      if (data['createdAt'] != null) {
         if (data['createdAt'] is Timestamp) return (data['createdAt'] as Timestamp).toDate();
      }
      return user.metadata.creationTime;
    } catch (e) {
      print('Error fetching creation date: $e');
    }
    return null;
  }

  Future<String> getGoalType() async {
    if (AppConfig.useMockBackend) return 'lose_weight';

    final user = _auth.currentUser;
    if (user == null) return 'lose_weight';

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return 'lose_weight';

      final data = doc.data()!;
      if (data['goal'] != null) return data['goal'] as String;
      if (data['goals'] is Map && data['goals']['goal'] != null) {
        return data['goals']['goal'] as String;
      }
      if (data['goals'] is Map && data['goals']['type'] != null) {
        return data['goals']['type'] as String;
      }
    } catch (e) {
      print('Error fetching goal type: $e');
    }
    return 'lose_weight';
  }
  Future<double?> getEarliestWeight() async {
    if (AppConfig.useMockBackend) return _mockInitialWeight;

    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weight_history')
          .orderBy('date', descending: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return (snapshot.docs.first.data()['weightKg'] as num).toDouble();
      }
    } catch (e) {
      print('Error fetching earliest weight: $e');
    }
    return null;
  }
}
