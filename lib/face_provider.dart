import 'dart:typed_data';
import 'package:flutter/material.dart';

class FaceProvider extends ChangeNotifier {
  Uint8List? _faceImageBytes;

  Uint8List? get faceImageBytes => _faceImageBytes;

  void setFaceImage(Uint8List imageBytes) {
    _faceImageBytes = imageBytes;
    notifyListeners();
  }

  void clearFace() {
    _faceImageBytes = null;
    notifyListeners();
  }
}
