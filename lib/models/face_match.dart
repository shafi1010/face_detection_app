class FaceMatch {
  final String personId;
  final String personName;
  final double confidence;
  final bool isBlacklisted;
  final String? notes;
  final String? photoUrl;

  const FaceMatch({
    required this.personId,
    required this.personName,
    required this.confidence,
    this.isBlacklisted = false,
    this.notes,
    this.photoUrl,
  });

  factory FaceMatch.fromJson(Map<String, dynamic> json) {
    return FaceMatch(
      personId: json['person_id'] as String,
      personName: json['person_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      isBlacklisted: json['is_blacklisted'] as bool? ?? false,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}
