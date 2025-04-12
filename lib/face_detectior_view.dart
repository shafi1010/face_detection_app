

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

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
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast
    ),
  );
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
      customPaint: _customPaint,
      text: _text,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }


  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;

    _isBusy = true;
    setState(() {
      _text = '';
    });

    try {
      debugPrint("Detecting faces...");
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        debugPrint("Face detected!");

        // Optionally show preview image or navigate to a preview screen
        final imageBytes = await inputImage.bytes; // This is pseudo-code
        // Save or display the imageBytes
        if (imageBytes != null) {
          // Show the preview dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            //_showFacePreviewDialog(context, imageBytes);
          });
        }
        // Call your API to match
       // await _matchWithApi(imageBytes as Uint8List); // Implement this function
      }

      if (inputImage.metadata?.size != null &&
          inputImage.metadata?.rotation != null) {
        _customPaint = CustomPaint(
          painter: FaceDetectorPainter(
            faces,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            _cameraLensDirection,
          ),
        );
      } else {
        _customPaint = null;
      }
    } catch (e) {
      debugPrint("Error during face detection: $e");
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }

  void _showFacePreviewDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Face Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(imageBytes),
            const SizedBox(height: 16),
            const Text('Face detected successfully!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

 /* Future<void> _matchWithApi(Uint8List imageBytes) async {
    print("okay");
    return;
    try {
      debugPrint("Sending image to API for matching...");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://your.api/face-match'),
      )
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes as List<int>,
          filename: 'captured_face.jpg',
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        debugPrint("Match result: $responseBody");

        // Show result in UI or navigate to another screen
      } else {
        debugPrint("API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Failed to send image: $e");
    }
  }*/



}
