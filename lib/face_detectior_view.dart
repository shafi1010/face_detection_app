

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_detection_app/face_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'camera_view.dart';
import 'detector_view.dart';
import 'face_detector_painter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({super.key});

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final GlobalKey<CameraViewState> _cameraViewKey = GlobalKey<CameraViewState>();
  Future<Uint8List?> _captureStillImage() async {
    final CameraViewState? cameraViewState =
    _cameraViewKey.currentState;

    if (cameraViewState == null) {
      print("ERROR: Could not access camera view state");
      return null;
    }

    return await cameraViewState.captureStillImage();
  }

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast
    ),
  );

  // Add these variables at the top
  bool _faceDetected = false;
  DateTime? _lastCaptureTime;
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Face Detector',
      key: _cameraViewKey,
      customPaint: _customPaint,
      text: _text,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }


  bool _isGoodFace(Face face) {
    // Ensure face is large enough and well-positioned
    final bounds = face.boundingBox;
    final faceSize = bounds.width * bounds.height;
    final screenSize = MediaQuery.of(context).size;
    final minFaceSize = screenSize.width * screenSize.height * 0.1; // 10% of screen

    return faceSize > minFaceSize &&
        (face.headEulerAngleY?.abs() ?? 0) < 30 && // Not too angled
        (face.smilingProbability ?? 0) > 0.4; // Optional: only smiling faces
  }

// In FaceDetectorView, use this _processImage method:
  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;

    setState(() {
      _text = '';
    });

    try {
      print("Processing image for face detection...");
      final faces = await _faceDetector.processImage(inputImage);
      print("Found ${faces.length} faces");

      if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
        final painter = FaceDetectorPainter(
          faces,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          _cameraLensDirection,
        );

        _customPaint = CustomPaint(painter: painter);
      } else {
        _customPaint = null;
      }

      if (faces.isNotEmpty) {
        // Find the primary face (you can add more sophisticated selection logic)
        final Face primaryFace = faces.first;

        // Optional: Check for quality criteria
        bool isGoodFace = primaryFace.headEulerAngleY != null &&
            primaryFace.headEulerAngleY!.abs() < 15 &&
            primaryFace.headEulerAngleZ != null &&
            primaryFace.headEulerAngleZ!.abs() < 10;

        if (isGoodFace) {
          print("Good face detected! Attempting to capture image...");

          setState(() {
            _faceDetected = true;
            _text = 'Face detected! Capturing...';
          });

          // Try to capture the image
          final imageBytes = await _captureStillImage();
          print("Image captured? ${imageBytes != null}");

          if (imageBytes != null && mounted) {
            print("Navigating to preview page...");
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FacePreviewPage(imageBytes: imageBytes),
              ),
            );

            // Reset detection state when returning
            setState(() {
              _faceDetected = false;
              _text = '';
            });
          } else {
            print("Failed to capture image bytes");
            setState(() {
              _faceDetected = false;
              _text = 'Failed to capture image';
            });
          }
        } else {
          setState(() {
            _text = 'Face detected, but adjust position for better quality';
          });
        }
      } else {
        setState(() {
          _text = 'No face detected';
        });
      }
    } catch (e) {
      print("Error during face detection: $e");
      setState(() {
        _text = 'Error: $e';
      });
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }



}
