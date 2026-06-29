import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/camera_datasource.dart';
import '../../data/datasources/mlkit_face_datasource.dart';
import '../../data/repositories/face_detection_repository_impl.dart';
import '../../domain/entities/face_data.dart';
import '../widgets/face_detector_painter.dart';

class FaceDetectionProvider extends ChangeNotifier {
  final CameraDatasource _cameraDatasource;
  final MlKitFaceDatasource _mlKitDatasource;
  late final FaceDetectionRepositoryImpl _repository;

  CustomPaint? _customPaint;
  String _statusText = '';
  bool _isBusy = false;
  bool _canProcess = true;
  DateTime? _lastCaptureTime;
  bool _faceDetected = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  CustomPaint? get customPaint => _customPaint;
  String get statusText => _statusText;
  bool get isBusy => _isBusy;
  bool get canProcess => _canProcess;
  double get currentZoom => _currentZoom;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  CameraController? get cameraController => _cameraDatasource.controller;

  FaceDetectionProvider({
    CameraDatasource? cameraDatasource,
    MlKitFaceDatasource? mlKitDatasource,
  })  : _cameraDatasource = cameraDatasource ?? CameraDatasource(),
        _mlKitDatasource = mlKitDatasource ?? MlKitFaceDatasource() {
    _repository = FaceDetectionRepositoryImpl(
      cameraDatasource: _cameraDatasource,
      mlKitDatasource: _mlKitDatasource,
    );
  }

  Future<void> initialize() async {
    await _cameraDatasource.initialize(lensDirection: CameraLensDirection.front);

    await _cameraDatasource.startLiveFeed(
      onImage: _onCameraImage,
    );

    _minZoom = await _cameraDatasource.getMinZoomLevel();
    _maxZoom = await _cameraDatasource.getMaxZoomLevel();
    _currentZoom = _minZoom;
    notifyListeners();
  }

  void _onCameraImage(CameraImage image) {
    if (!_canProcess || _isBusy) return;
    _processImage(image);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_faceDetected) return;

    final now = DateTime.now();
    if (_lastCaptureTime != null &&
        now.difference(_lastCaptureTime!) < const Duration(seconds: 3)) {
      return;
    }

    _isBusy = true;

    try {
      final faces = await _repository.processCameraImage(image);

      final camera = _cameraDatasource.currentCamera;
      if (camera != null) {
        _updateOverlay(faces, image, camera);
      }

      if (faces.isNotEmpty) {
        final primaryFace = faces.first;
        if (primaryFace.isGoodQuality) {
          await _captureAndNavigate();
        } else {
          _statusText = 'Face detected, adjust position';
        }
      } else {
        _statusText = 'No face detected';
      }
    } catch (e) {
      _statusText = 'Error: $e';
    }

    _isBusy = false;
    notifyListeners();
  }

  void _updateOverlay(List<FaceData> faces, CameraImage image, CameraDescription camera) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final rotation = camera.sensorOrientation;

    _customPaint = CustomPaint(
      painter: FaceDetectorPainter(
        faces,
        imageSize,
        rotation,
        camera.lensDirection,
      ),
    );
  }

  Future<void> _captureAndNavigate() async {
    _statusText = 'Face detected! Capturing...';
    _faceDetected = true;
    notifyListeners();

    final imageBytes = await _repository.captureStillImage();

    if (imageBytes != null) {
      _lastCaptureTime = DateTime.now();
      await _navigateToPreview(imageBytes);
      _faceDetected = false;
      _statusText = '';
    } else {
      _faceDetected = false;
      _statusText = 'Failed to capture image';
    }

    notifyListeners();
  }

  Future<void> _navigateToPreview(Uint8List imageBytes) async {
    // Navigation should be handled by the screen, not the provider.
    // This will be passed as a callback.
    if (_onNavigateToPreview != null) {
      await _onNavigateToPreview!(imageBytes);
    }
  }

  Future<void> Function(Uint8List imageBytes)? _onNavigateToPreview;

  void setNavigationCallback(Future<void> Function(Uint8List imageBytes) callback) {
    _onNavigateToPreview = callback;
  }

  Future<void> setZoomLevel(double zoom) async {
    _currentZoom = zoom;
    await _cameraDatasource.setZoomLevel(zoom);
    notifyListeners();
  }

  @override
  void dispose() {
    _canProcess = false;
    _mlKitDatasource.close();
    _cameraDatasource.dispose();
    super.dispose();
  }
}
