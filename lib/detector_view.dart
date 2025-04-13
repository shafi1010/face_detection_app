import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'camera_view.dart';

enum DetectorViewMode { liveFeed, gallery }

class DetectorView extends StatefulWidget {
  const DetectorView({
    super.key,
    required this.title,
    required this.onImage,
    this.customPaint,
    this.text,
    this.initialDetectionMode = DetectorViewMode.liveFeed,
    this.initialCameraLensDirection = CameraLensDirection.front,
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
    this.cameraViewKey,
    this.faceDetected = false,
  });

  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final DetectorViewMode initialDetectionMode;
  final Function(InputImage inputImage) onImage;
  final Function()? onCameraFeedReady;
  final Function(DetectorViewMode mode)? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final GlobalKey<CameraViewState>? cameraViewKey;
  final bool faceDetected;

  @override
  State<DetectorView> createState() => _DetectorViewState();
}

class _DetectorViewState extends State<DetectorView> {
  late DetectorViewMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialDetectionMode;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children:[
        CameraView(
          key: widget.cameraViewKey,
          text: widget.text,
          customPaint: widget.customPaint,
          onImage: widget.onImage,
          onCameraFeedReady: widget.onCameraFeedReady,
          onDetectorViewModeChanged: _onDetectorViewModeChanged,
          initialCameraLensDirection: widget.initialCameraLensDirection,
          onCameraLensDirectionChanged: widget.onCameraLensDirectionChanged,
        ),

        Positioned(
          bottom: 100,
          child: Container(
            padding: EdgeInsets.all(12),
            color: Colors.black54,
            child: Text(
              widget.faceDetected ? "✓ Face Captured!" : "🔍 Searching for face...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        )
      ],
    );
  }

  void _onDetectorViewModeChanged() {
    setState(() {
      DetectorViewMode.liveFeed;
      widget.onDetectorViewModeChanged?.call(_mode);
    });
  }
}
