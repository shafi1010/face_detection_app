import 'face_match.dart';

enum AlertSeverity { critical, warning, info }
enum AlertStatus { unacknowledged, acknowledged, dismissed, escalated }
enum AlertType {
  blacklistMatch,
  watchlistMatch,
  unknownFace,
  crowdDensity,
  dwellTime,
  loitering,
  zoneViolation,
}

class Alert {
  final String id;
  final String tenantId;
  final String cameraId;
  final String cameraName;
  final AlertType type;
  final AlertSeverity severity;
  final AlertStatus status;
  final FaceMatch? faceMatch;
  final String? snapshotUrl;
  final String? snapshotLocalPath;
  final String message;
  final double? confidence;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;

  const Alert({
    required this.id,
    required this.tenantId,
    required this.cameraId,
    required this.cameraName,
    required this.type,
    this.severity = AlertSeverity.warning,
    this.status = AlertStatus.unacknowledged,
    this.faceMatch,
    this.snapshotUrl,
    this.snapshotLocalPath,
    required this.message,
    this.confidence,
    this.metadata = const {},
    required this.timestamp,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      cameraId: json['camera_id'] as String,
      cameraName: json['camera_name'] as String? ?? 'Unknown',
      type: AlertType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'unknownFace'),
        orElse: () => AlertType.unknownFace,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == (json['severity'] as String? ?? 'warning'),
        orElse: () => AlertSeverity.warning,
      ),
      status: AlertStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'unacknowledged'),
        orElse: () => AlertStatus.unacknowledged,
      ),
      faceMatch: json['face_match'] != null
          ? FaceMatch.fromJson(json['face_match'] as Map<String, dynamic>)
          : null,
      snapshotUrl: json['snapshot_url'] as String?,
      message: json['message'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      acknowledgedBy: json['acknowledged_by'] as String?,
    );
  }

  Alert copyWith({AlertStatus? status, String? acknowledgedBy}) {
    return Alert(
      id: id,
      tenantId: tenantId,
      cameraId: cameraId,
      cameraName: cameraName,
      type: type,
      severity: severity,
      status: status ?? this.status,
      faceMatch: faceMatch,
      snapshotUrl: snapshotUrl,
      snapshotLocalPath: snapshotLocalPath,
      message: message,
      confidence: confidence,
      metadata: metadata,
      timestamp: timestamp,
      acknowledgedAt: status == AlertStatus.acknowledged ? DateTime.now() : acknowledgedAt,
      acknowledgedBy: acknowledgedBy,
    );
  }

  Duration get age => DateTime.now().difference(timestamp);
}
