class ProgressPhoto {
  final String id;
  final String imageUrl;
  final double weightKg;
  final DateTime date;
  final DateTime uploadedAt;

  ProgressPhoto({
    required this.id,
    required this.imageUrl,
    required this.weightKg,
    required this.date,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'weightKg': weightKg,
      'date': date.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) {
    return ProgressPhoto(
      id: map['id'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      weightKg: (map['weightKg'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      uploadedAt: DateTime.parse(map['uploadedAt']),
    );
  }
}
