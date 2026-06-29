import 'dart:ui';

class FaceData {
  final Rect boundingBox;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final double? smilingProbability;

  const FaceData({
    required this.boundingBox,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.smilingProbability,
  });

  bool get isGoodQuality {
    final yaw = headEulerAngleY?.abs() ?? 0;
    final roll = headEulerAngleZ?.abs() ?? 0;
    return yaw < 15 && roll < 10;
  }

  double get area => boundingBox.width * boundingBox.height;
}
