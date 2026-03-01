import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardUser {
  final String uid;
  final String displayName;
  final int totalScore;
  final int streakCount;
  final bool isSubscribed;
  final int rank;
  final String? photoUrl;
  final Timestamp? lastActiveDate;

  const LeaderboardUser({
    required this.uid,
    required this.displayName,
    required this.totalScore,
    required this.streakCount,
    required this.isSubscribed,
    required this.rank,
    this.photoUrl,
    this.lastActiveDate,
  });

  factory LeaderboardUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required int provisionalRank,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    final score = _asInt(data['totalScore']);
    return LeaderboardUser(
      uid: doc.id,
      displayName: _asDisplayName(data),
      totalScore: score,
      streakCount: _asInt(data['streakCount']),
      isSubscribed: data['isSubscribed'] == true,
      rank: score == 0 ? 0 : provisionalRank,
      photoUrl: data['photoUrl']?.toString() ?? data['avatarUrl']?.toString(),
      lastActiveDate: _asTimestamp(data['lastActiveDate']),
    );
  }

  LeaderboardUser copyWith({
    String? uid,
    String? displayName,
    int? totalScore,
    int? streakCount,
    bool? isSubscribed,
    int? rank,
    String? photoUrl,
    Timestamp? lastActiveDate,
  }) {
    return LeaderboardUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      totalScore: totalScore ?? this.totalScore,
      streakCount: streakCount ?? this.streakCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      rank: rank ?? this.rank,
      photoUrl: photoUrl ?? this.photoUrl,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static Timestamp? _asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }

  static String _asDisplayName(Map<String, dynamic> data) {
    final raw =
        data['displayName'] ??
        data['name'] ??
        data['username'] ??
        data['fullName'] ??
        'User';
    final trimmed = raw.toString().trim();
    return trimmed.isEmpty ? 'User' : trimmed;
  }
}
