import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<Uint8List?> cropFaceFromImage(
    Uint8List imageBytes,
    Size imageSize,
    Rect boundingBox,
    ) async {
  final originalImage = img.decodeImage(imageBytes);
  if (originalImage == null) return null;

  final scaleX = originalImage.width / imageSize.width;
  final scaleY = originalImage.height / imageSize.height;

  final left = (boundingBox.left * scaleX).toInt().clamp(0, originalImage.width);
  final top = (boundingBox.top * scaleY).toInt().clamp(0, originalImage.height);
  final width = (boundingBox.width * scaleX).toInt().clamp(0, originalImage.width - left);
  final height = (boundingBox.height * scaleY).toInt().clamp(0, originalImage.height - top);

  final cropped = img.copyCrop(originalImage, x: left, y: top, width: width, height: height);
  return Uint8List.fromList(img.encodeJpg(cropped));
}

Future<String> getAssetPath(String asset) async {
  final path = await getLocalPath(asset);
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(asset);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future<String> getLocalPath(String path) async {
  return '${(await getApplicationSupportDirectory()).path}/$path';
}

// Make sure this exists in your image_utils.dart
Uint8List convertYUV420ToNV21(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final yRowStride = image.planes[0].bytesPerRow;
  final uvRowStride = image.planes[1].bytesPerRow;
  final uvPixelStride = image.planes[1].bytesPerPixel!;

  final size = width * height + width * height ~/ 2;
  final nv21 = Uint8List(size);

  // Copy Y plane
  final yBuffer = image.planes[0].bytes;
  if (yRowStride == width) {
    // Fast path when there's no row padding
    nv21.setRange(0, width * height, yBuffer);
  } else {
    // Need to handle row padding
    for (int row = 0; row < height; row++) {
      nv21.setRange(
          row * width,
          row * width + width,
          yBuffer.sublist(row * yRowStride, row * yRowStride + width)
      );
    }
  }

  // Copy UV data
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


