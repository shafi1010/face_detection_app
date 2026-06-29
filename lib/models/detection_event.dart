class DetectionEvent {
  final String id;
  final String cameraId;
  final String tenantId;
  final double confidence;
  final String? faceUrl;
  final double? dwellSeconds;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const DetectionEvent({
    required this.id,
    required this.cameraId,
    required this.tenantId,
    required this.confidence,
    this.faceUrl,
    this.dwellSeconds,
    this.metadata = const {},
    required this.timestamp,
  });

  factory DetectionEvent.fromJson(Map<String, dynamic> json) {
    return DetectionEvent(
      id: json['id'] as String,
      cameraId: json['camera_id'] as String,
      tenantId: json['tenant_id'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      faceUrl: json['face_url'] as String?,
      dwellSeconds: (json['dwell_seconds'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
