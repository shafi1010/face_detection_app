import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../data/datasources/camera_datasource.dart';
import '../data/datasources/mlkit_face_datasource.dart';
import '../data/repositories/face_detection_repository_impl.dart';
import '../presentation/widgets/face_detector_painter.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _cameraDatasource = CameraDatasource();
  final _mlKitDatasource = MlKitFaceDatasource();
  late final FaceDetectionRepositoryImpl _repository;

  CustomPaint? _customPaint;
  bool _isBusy = false;
  bool _captured = false;
  String _statusText = 'Position your face in the frame';

  @override
  void initState() {
    super.initState();
    _repository = FaceDetectionRepositoryImpl(
      cameraDatasource: _cameraDatasource,
      mlKitDatasource: _mlKitDatasource,
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraDatasource.initialize(lensDirection: CameraLensDirection.front);
    await _cameraDatasource.startLiveFeed(
      onImage: _onCameraImage,
      resolutionPreset: ResolutionPreset.medium,
    );
    if (mounted) setState(() {});
  }

  void _onCameraImage(CameraImage image) {
    if (_isBusy || _captured) return;
    _processImage(image);
  }

  Future<void> _processImage(CameraImage image) async {
    _isBusy = true;
    try {
      final faces = await _repository.processCameraImage(image);
      final camera = _cameraDatasource.currentCamera;

      if (camera != null && mounted) {
        final imageSize = Size(image.width.toDouble(), image.height.toDouble());
        setState(() {
          _customPaint = CustomPaint(
            painter: FaceDetectorPainter(
              faces,
              imageSize,
              camera.sensorOrientation,
              camera.lensDirection,
            ),
          );
        });
      }

      if (faces.isNotEmpty && faces.first.isGoodQuality && !_captured) {
        _captured = true;
        _statusText = 'Face captured!';
        if (mounted) setState(() {});
        await _uploadForEnrollment();
      } else {
        _statusText = faces.isNotEmpty ? 'Adjust position — keep face centered' : 'No face detected';
        if (mounted) setState(() {});
      }
    } catch (e) {
      _statusText = 'Error: $e';
      if (mounted) setState(() {});
    }
    _isBusy = false;
  }

  Future<void> _uploadForEnrollment() async {
    final imageBytes = await _repository.captureStillImage();
    if (imageBytes == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face enrolled successfully')),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _cameraDatasource.dispose();
    _mlKitDatasource.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Face'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _cameraDatasource.controller?.value.isInitialized == true
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_cameraDatasource.controller!),
                      if (_customPaint != null) _customPaint!,
                      if (_captured)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppTheme.primary, size: 64),
                                SizedBox(height: 16),
                                Text(
                                  'Face Captured',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Icon(
                  _captured ? Icons.check_circle : Icons.info_outline,
                  color: _captured ? AppTheme.primary : AppTheme.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _statusText,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
