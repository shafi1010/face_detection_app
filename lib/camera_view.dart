import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import 'image_utils.dart';

class CameraView extends StatefulWidget {
  const CameraView(
      {super.key,
        required this.customPaint,
        required this.onImage,
        this.text,
        this.onCameraFeedReady,
        this.onDetectorViewModeChanged,
        this.onCameraLensDirectionChanged,
        this.initialCameraLensDirection = CameraLensDirection.back});

  final String? text;
  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> {

  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  bool _changingCameraLens = false;
  // Add these variables
  double _targetCaptureResolution = 1.0; // 0.0-1.0 scale

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  void _initialize() async {
    print('Initializing cameras...');
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
      print('Available cameras: ${_cameras.length}');
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      print('Starting live feed with camera index: $_cameraIndex');
      _startLiveFeed();
    } else {
      print('No matching camera found!');
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _liveFeedBody());
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: _changingCameraLens
                ? Center(
              child: const Text('Changing camera lens'),
            )
                : CameraPreview(
              _controller!,
              child: widget.customPaint,
            ),
          ),
          _zoomControl(),
        ],
      ),
    );
  }

  Widget _zoomControl() => Positioned(
    bottom: 16,
    left: 0,
    right: 0,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 250,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Slider(
                value: _currentZoomLevel,
                min: _minAvailableZoom,
                max: _maxAvailableZoom,
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
                onChanged: (value) async {
                  setState(() {
                    _currentZoomLevel = value;
                  });
                  await _controller?.setZoomLevel(value);
                },
              ),
            ),
            Container(
              width: 50,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    '${_currentZoomLevel.toStringAsFixed(1)}x',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

// Modify captureStillImage
  Future<Uint8List?> captureStillImage() async {
    if (!_controller!.value.isInitialized) return null;

    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      return bytes;
    } catch (e) {
      print("Error taking picture: $e");
      return null;
    }
  }

  /* Future<Uint8List?> captureStillImage() async {
    print("📸 Starting image capture");

    if (_controller == null || !_controller!.value.isInitialized) {
      print("❌ Camera controller not initialized");
      return null;
    }

    try {
      // Temporarily stop the stream
      print("🛑 Stopping image stream");
      await _controller!.stopImageStream();

      // Give the camera a moment to adjust
      await Future.delayed(Duration(milliseconds: 300));

      print("📷 Taking picture");
      final XFile file = await _controller!.takePicture();
      print("✅ Picture taken: ${file.path}");

      // Read the file
      final bytes = await File(file.path).readAsBytes();
      print("📊 Image size: ${bytes.length} bytes");

      // Restart the stream
      print("▶️ Restarting stream");
      await _controller!.startImageStream(_processCameraImage);

      return bytes;
    } catch (e) {
      print("❌ Capture error: $e");

      // Make sure we restart the stream even if there's an error
      try {
        if (_controller != null &&
            _controller!.value.isInitialized &&
            !_controller!.value.isStreamingImages) {
          await _controller!.startImageStream(_processCameraImage);
        }
      } catch (streamError) {
        print("❌ Error restarting stream: $streamError");
      }

      return null;
    }
  }*/

  Future _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    print('Starting live feed from camera: ${camera.name}');
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        print('Widget not mounted after camera initialized.');
        return;
      }
      print('Camera initialized successfully.');
      _controller?.getMinZoomLevel().then((value) {
        _currentZoomLevel = value;
        _minAvailableZoom = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        _maxAvailableZoom = value;
      });

      _controller?.startImageStream((CameraImage image) {
        print('Received image from camera stream.');
        _processCameraImage(image);
      }).then((value) {
        print('Image stream started.');
        widget.onCameraFeedReady?.call();
        widget.onCameraLensDirectionChanged?.call(camera.lensDirection);
      });
      setState(() {});
    }).catchError((e) {
      print('Camera initialization error: $e');
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void _processCameraImage(CameraImage image) {
    print('Processing camera image...');
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      print('InputImage is null, skipping.');
      return;
    }
    print('Calling widget.onImage with valid InputImage...');
    widget.onImage(inputImage);
  }


  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
    } else {
      var rotationCompensation = _orientations[_controller!.value.deviceOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ?? InputImageRotation.rotation0deg;
    }

    // Handle platform-specific image formats
    if (Platform.isAndroid) {
      final bytes = convertYUV420ToNV21(image);
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } else if (Platform.isIOS) {
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: metadata,
      );
    }

    return null;
  }



}