import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../domain/entities/face_data.dart';
import '../../domain/repositories/face_detection_repository.dart';
import '../datasources/camera_datasource.dart';
import '../datasources/mlkit_face_datasource.dart';

class FaceDetectionRepositoryImpl implements FaceDetectionRepository {
  final CameraDatasource _cameraDatasource;
  final MlKitFaceDatasource _mlKitDatasource;

  FaceDetectionRepositoryImpl({
    required CameraDatasource cameraDatasource,
    required MlKitFaceDatasource mlKitDatasource,
  })  : _cameraDatasource = cameraDatasource,
        _mlKitDatasource = mlKitDatasource;

  @override
  Future<List<FaceData>> detectFaces({
    required Uint8List imageBytes,
    required int width,
    required int height,
    required int bytesPerRow,
    required int imageFormat,
    required int rotation,
    required bool isFrontCamera,
  }) async {
    throw UnimplementedError('Use processCameraImage for live stream');
  }

  Future<List<FaceData>> processCameraImage(CameraImage image) async {
    final camera = _cameraDatasource.currentCamera;
    if (camera == null) return [];

    final mlFaces = await _mlKitDatasource.processCameraImage(image, camera);
    return mlFaces.map(_mapToFaceData).toList();
  }

  @override
  Future<Uint8List?> captureStillImage() async {
    final xFile = await _cameraDatasource.takePicture();
    if (xFile == null) return null;
    return await xFile.readAsBytes();
  }

  FaceData _mapToFaceData(Face face) {
    return FaceData(
      boundingBox: face.boundingBox,
      headEulerAngleY: face.headEulerAngleY,
      headEulerAngleZ: face.headEulerAngleZ,
      smilingProbability: face.smilingProbability,
      leftEyeOpenProb: face.leftEyeOpenProbability,
      rightEyeOpenProb: face.rightEyeOpenProbability,
    );
  }
}
