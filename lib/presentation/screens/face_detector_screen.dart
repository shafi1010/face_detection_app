import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/face_detection_provider.dart';
import '../widgets/camera_view.dart';
import 'face_preview_screen.dart';

class FaceDetectorScreen extends StatefulWidget {
  const FaceDetectorScreen({super.key});

  @override
  State<FaceDetectorScreen> createState() => _FaceDetectorScreenState();
}

class _FaceDetectorScreenState extends State<FaceDetectorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FaceDetectionProvider>();
      provider.setNavigationCallback(_navigateToPreview);
      provider.initialize();
    });
  }

  Future<void> _navigateToPreview(Uint8List imageBytes) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacePreviewScreen(imageBytes: imageBytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FaceDetectionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: CameraView(
            controller: provider.cameraController,
            customPaint: provider.customPaint,
            currentZoom: provider.currentZoom,
            minZoom: provider.minZoom,
            maxZoom: provider.maxZoom,
            onZoomChanged: provider.setZoomLevel,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
