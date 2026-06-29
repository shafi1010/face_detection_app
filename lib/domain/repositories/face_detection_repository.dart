import 'dart:typed_data';

import '../entities/face_data.dart';

abstract class FaceDetectionRepository {
  Future<List<FaceData>> detectFaces({
    required Uint8List imageBytes,
    required int width,
    required int height,
    required int bytesPerRow,
    required int imageFormat,
    required int rotation,
    required bool isFrontCamera,
  });

  Future<Uint8List?> captureStillImage();
}
