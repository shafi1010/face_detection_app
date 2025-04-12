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

Uint8List convertYUV420ToNV21(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel!;

  final Uint8List yBuffer = image.planes[0].bytes;
  final Uint8List uBuffer = image.planes[1].bytes;
  final Uint8List vBuffer = image.planes[2].bytes;

  final Uint8List nv21 = Uint8List(width * height + (width * height) ~/ 2);

  int uvIndex = width * height;

  for (int i = 0; i < height; i++) {
    int yRowStart = i * image.planes[0].bytesPerRow;
    for (int j = 0; j < width; j++) {
      nv21[i * width + j] = yBuffer[yRowStart + j];
    }
  }

  for (int i = 0; i < height ~/ 2; i++) {
    for (int j = 0; j < width ~/ 2; j++) {
      final int uvPos = i * uvRowStride + j * uvPixelStride;
      nv21[uvIndex++] = vBuffer[uvPos];
      nv21[uvIndex++] = uBuffer[uvPos];
    }
  }

  return nv21;
}
