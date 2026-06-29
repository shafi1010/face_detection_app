import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../../data/utils/coordinate_translator.dart';
import '../../domain/entities/face_data.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
    this.faces,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final List<FaceData> faces;
  final Size imageSize;
  final int rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.red;
    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.green;

    for (final face in faces) {
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg,
        cameraLensDirection,
      );

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint1,
      );

      canvas.drawCircle(
        Offset(
          (left + right) / 2,
          (top + bottom) / 2,
        ),
        4,
        paint2,
      );
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
  }
}
