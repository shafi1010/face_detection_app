import 'dart:ui';

class FaceData {
  final Rect boundingBox;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final double? smilingProbability;
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;

  const FaceData({
    required this.boundingBox,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.smilingProbability,
    this.leftEyeOpenProb,
    this.rightEyeOpenProb,
  });

  bool get isGoodQuality {
    final yaw = headEulerAngleY?.abs() ?? 0;
    final roll = headEulerAngleZ?.abs() ?? 0;
    return yaw < 15 && roll < 10;
  }

  double get averageEyeOpenProb {
    final left = leftEyeOpenProb;
    final right = rightEyeOpenProb;
    if (left != null && right != null) return (left + right) / 2;
    if (left != null) return left;
    if (right != null) return right;
    return 1.0;
  }

  double get area => boundingBox.width * boundingBox.height;
}
