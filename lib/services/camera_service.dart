import '../core/network/api_client.dart';
import '../models/camera.dart';

class CameraService {
  final ApiClient _apiClient;

  CameraService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Camera>> getCameras() async {
    return await _apiClient.get<List<Camera>>(
      '/cameras',
      fromJson: (json) {
        final list = json as List;
        return list.map((e) => Camera.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<Camera> getCamera(String id) async {
    return await _apiClient.get<Camera>(
      '/cameras/$id',
      fromJson: (json) => Camera.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> toggleDetection(String cameraId, bool enabled) async {
    await _apiClient.patch<void>(
      '/cameras/$cameraId',
      body: {'is_detecting': enabled},
    );
  }

  Future<void> toggleRecording(String cameraId, bool enabled) async {
    await _apiClient.patch<void>(
      '/cameras/$cameraId',
      body: {'is_recording': enabled},
    );
  }

  Future<String> getStreamUrl(String cameraId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/cameras/$cameraId/stream',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return result['url'] as String;
  }
}
