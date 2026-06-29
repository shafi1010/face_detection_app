import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../utils/image_converter.dart';

class MlKitFaceDatasource {
  final FaceDetector _detector;

  MlKitFaceDatasource({
    FaceDetectorOptions? options,
  }) : _detector = FaceDetector(
          options: options ??
              FaceDetectorOptions(
                enableContours: true,
                enableLandmarks: true,
                performanceMode: FaceDetectorMode.fast,
              ),
        );

  Future<List<Face>> processCameraImage(CameraImage image, CameraDescription camera) async {
    final inputImage = _buildInputImage(image, camera);
    if (inputImage == null) return [];
    return await _detector.processImage(inputImage);
  }

  InputImage? _buildInputImage(CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;

    final rotation = Platform.isIOS
        ? InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg
        : _androidRotation(image, camera, sensorOrientation);

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

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImageRotation _androidRotation(
    CameraImage image,
    CameraDescription camera,
    int sensorOrientation,
  ) {
    var rotationCompensation = _orientations[DeviceOrientation.portraitUp] ?? 0;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(rotationCompensation) ?? InputImageRotation.rotation0deg;
  }

  void close() {
    _detector.close();
  }
}
