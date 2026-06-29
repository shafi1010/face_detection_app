import 'dart:typed_data';

import 'package:camera/camera.dart';

Uint8List convertYUV420ToNV21(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final yRowStride = image.planes[0].bytesPerRow;
  final uvRowStride = image.planes[1].bytesPerRow;
  final uvPixelStride = image.planes[1].bytesPerPixel!;

  final size = width * height + width * height ~/ 2;
  final nv21 = Uint8List(size);

  final yBuffer = image.planes[0].bytes;
  if (yRowStride == width) {
    nv21.setRange(0, width * height, yBuffer);
  } else {
    for (int row = 0; row < height; row++) {
      nv21.setRange(
        row * width,
        row * width + width,
        yBuffer.sublist(row * yRowStride, row * yRowStride + width),
      );
    }
  }

  final uBuffer = image.planes[1].bytes;
  final vBuffer = image.planes[2].bytes;

  for (int row = 0; row < height ~/ 2; row++) {
    for (int col = 0; col < width ~/ 2; col++) {
      final uvIndex = col * uvPixelStride + row * uvRowStride;
      final nv21Index = width * height + row * width + col * 2;

      nv21[nv21Index + 1] = uBuffer[uvIndex];
      nv21[nv21Index] = vBuffer[uvIndex];
    }
  }

  return nv21;
}
