import 'package:flutter/foundation.dart';

import '../models/camera.dart';
import '../services/camera_service.dart';

class CameraProvider extends ChangeNotifier {
  final CameraService _cameraService;

  List<Camera> _cameras = [];
  bool _isLoading = false;
  String? _error;

  CameraProvider({required CameraService cameraService})
      : _cameraService = cameraService;

  List<Camera> get cameras => _cameras;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Camera> get onlineCameras =>
      _cameras.where((c) => c.status == CameraStatus.online).toList();

  int get onlineCount =>
      _cameras.where((c) => c.status == CameraStatus.online).length;

  int get offlineCount =>
      _cameras.where((c) => c.status == CameraStatus.offline).length;

  int get errorCount =>
      _cameras.where((c) => c.status == CameraStatus.error).length;

  Future<void> fetchCameras({bool refresh = false}) async {
    if (!refresh && _cameras.isNotEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cameras = await _cameraService.getCameras();
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Camera? getCameraById(String id) {
    try {
      return _cameras.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleDetection(String cameraId, bool enabled) async {
    try {
      await _cameraService.toggleDetection(cameraId, enabled);
      final index = _cameras.indexWhere((c) => c.id == cameraId);
      if (index != -1) {
        _cameras[index] = _cameras[index].copyWith(isDetecting: enabled);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }

  Future<void> toggleRecording(String cameraId, bool enabled) async {
    try {
      await _cameraService.toggleRecording(cameraId, enabled);
      final index = _cameras.indexWhere((c) => c.id == cameraId);
      if (index != -1) {
        _cameras[index] = _cameras[index].copyWith(isRecording: enabled);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }

  Future<String> getStreamUrl(String cameraId) async {
    return await _cameraService.getStreamUrl(cameraId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
