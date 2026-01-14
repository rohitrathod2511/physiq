import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final int? birthYear;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final int? dailyStepGoal;
  final UserPreferences preferences;
  final Map<String, dynamic>? currentPlan;
  final bool isPremium;
  final UserInvites? invites;
  final List<Referral>? referrals;
  final double leaderboardScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? nutritionGoals;

  UserModel({
    required this.uid,
    required this.displayName,
    this.birthYear,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.dailyStepGoal,
    required this.preferences,
    this.currentPlan,
    this.isPremium = false,
    this.invites,
    this.referrals,
    this.leaderboardScore = 0.0,
    this.createdAt,
    this.updatedAt,
    this.nutritionGoals,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    final goals = data['goals'] as Map<String, dynamic>? ?? {};
    final nutrition = data['nutrition'] as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: uid,
      displayName: profile['name'] ?? data['displayName'] ?? '',
      birthYear: profile['birthYear'] ?? profile['birthDate'] ?? data['birthYear'],
      gender: profile['gender'] ?? data['gender'],
      heightCm: (profile['height'] ?? data['heightCm'] as num?)?.toDouble(),
      weightKg: (profile['weight'] ?? data['weightKg'] as num?)?.toDouble(),
      goalWeightKg: (goals['targetWeight'] ?? data['goalWeightKg'] as num?)?.toDouble(),
      dailyStepGoal: data['dailyStepGoal'],
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      currentPlan: data['currentPlan'] ?? nutrition, // Fallback or mapping
      isPremium: data['isPremium'] ?? false,
      invites: data['invites'] != null ? UserInvites.fromMap(data['invites']) : null,
      referrals: (data['referrals'] as List?)
          ?.map((e) => Referral.fromMap(e))
          .toList(),
      leaderboardScore: (data['leaderboardScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['auth']?['createdAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      nutritionGoals: nutrition.isNotEmpty ? nutrition : data['nutritionGoals'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'birthYear': birthYear,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goalWeightKg': goalWeightKg,
      'dailyStepGoal': dailyStepGoal,
      'preferences': preferences.toMap(),
      'currentPlan': currentPlan,
      'isPremium': isPremium,
      'invites': invites?.toMap(),
      'referrals': referrals?.map((e) => e.toMap()).toList(),
      'leaderboardScore': leaderboardScore,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'nutritionGoals': nutritionGoals,
    };
  }
}

class UserPreferences {
  final String language;
  final String theme;
  final String units;

  UserPreferences({
    this.language = 'en',
    this.theme = 'light',
    this.units = 'metric',
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      language: data['language'] ?? 'en',
      theme: data['theme'] ?? 'light',
      units: data['units'] ?? 'metric',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'theme': theme,
      'units': units,
    };
  }
}

class UserInvites {
  final String? code;
  final DateTime? createdAt;
  final int redeemedCount;
  final double creditedAmount;

  UserInvites({
    this.code,
    this.createdAt,
    this.redeemedCount = 0,
    this.creditedAmount = 0.0,
  });

  factory UserInvites.fromMap(Map<String, dynamic> data) {
    return UserInvites(
      code: data['code'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      redeemedCount: data['redeemedCount'] ?? 0,
      creditedAmount: (data['creditedAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'redeemedCount': redeemedCount,
      'creditedAmount': creditedAmount,
    };
  }
}

class Referral {
  final String uid;
  final DateTime claimedAt;
  final double amount;
  final String status;

  Referral({
    required this.uid,
    required this.claimedAt,
    required this.amount,
    required this.status,
  });

  factory Referral.fromMap(Map<String, dynamic> data) {
    return Referral(
      uid: data['uid'] ?? '',
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'claimedAt': Timestamp.fromDate(claimedAt),
      'amount': amount,
      'status': status,
    };
  }
}
