import 'dart:io';

import 'package:camera/camera.dart';

class CameraDatasource {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = -1;

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  int get cameraIndex => _cameraIndex;

  Future<void> initialize({CameraLensDirection lensDirection = CameraLensDirection.front}) async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == lensDirection) {
        _cameraIndex = i;
        break;
      }
    }
  }

  Future<void> startLiveFeed({
    required void Function(CameraImage image) onImage,
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
  }) async {
    if (_cameraIndex == -1) return;

    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      resolutionPreset,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(onImage);
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    return await _controller!.takePicture();
  }

  Future<void> setZoomLevel(double zoom) async {
    await _controller?.setZoomLevel(zoom);
  }

  Future<double> getMinZoomLevel() async {
    return await _controller?.getMinZoomLevel() ?? 1.0;
  }

  Future<double> getMaxZoomLevel() async {
    return await _controller?.getMaxZoomLevel() ?? 1.0;
  }

  CameraDescription? get currentCamera {
    if (_cameraIndex == -1 || _cameras.isEmpty) return null;
    return _cameras[_cameraIndex];
  }

  Future<void> stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
