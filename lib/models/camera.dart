enum CameraStatus { online, offline, error, disabled }

enum CameraStreamProtocol { rtsp, onvif, hls, webrtc }

class Camera {
  final String id;
  final String name;
  final String? location;
  final String rtspUrl;
  final CameraStreamProtocol protocol;
  final CameraStatus status;
  final String tenantId;
  final bool isRecording;
  final bool isDetecting;
  final int fps;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Camera({
    required this.id,
    required this.name,
    this.location,
    required this.rtspUrl,
    this.protocol = CameraStreamProtocol.rtsp,
    this.status = CameraStatus.offline,
    required this.tenantId,
    this.isRecording = false,
    this.isDetecting = true,
    this.fps = 15,
    this.thumbnailUrl,
    this.hlsUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      rtspUrl: json['rtsp_url'] as String,
      protocol: CameraStreamProtocol.values.firstWhere(
        (e) => e.name == (json['protocol'] as String? ?? 'rtsp'),
        orElse: () => CameraStreamProtocol.rtsp,
      ),
      status: CameraStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'offline'),
        orElse: () => CameraStatus.offline,
      ),
      tenantId: json['tenant_id'] as String,
      isRecording: json['is_recording'] as bool? ?? false,
      isDetecting: json['is_detecting'] as bool? ?? true,
      fps: json['fps'] as int? ?? 15,
      thumbnailUrl: json['thumbnail_url'] as String?,
      hlsUrl: json['hls_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Camera copyWith({
    CameraStatus? status,
    bool? isRecording,
    bool? isDetecting,
    String? thumbnailUrl,
    String? hlsUrl,
  }) {
    return Camera(
      id: id,
      name: name,
      location: location,
      rtspUrl: rtspUrl,
      protocol: protocol,
      status: status ?? this.status,
      tenantId: tenantId,
      isRecording: isRecording ?? this.isRecording,
      isDetecting: isDetecting ?? this.isDetecting,
      fps: fps,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
