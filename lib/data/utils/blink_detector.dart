import '../../domain/entities/face_data.dart';

enum LivenessState { waitingForFace, needBlink, verified }

class BlinkDetector {
  final double _openThreshold;
  final int _minClosedFrames;
  final int _maxFramesWithoutBlink;

  int _framesSinceGoodFace = 0;
  int _closedFrameCount = 0;
  bool _wasEyesOpen = true;
  bool _blinkDetected = false;

  BlinkDetector({
    double openThreshold = 0.5,
    int minClosedFrames = 2,
    int maxFramesWithoutBlink = 300,
  })  : _openThreshold = openThreshold,
        _minClosedFrames = minClosedFrames,
        _maxFramesWithoutBlink = maxFramesWithoutBlink;

  LivenessState get state {
    if (_blinkDetected) return LivenessState.verified;
    if (_framesSinceGoodFace > 0) return LivenessState.needBlink;
    return LivenessState.waitingForFace;
  }

  void processFrame(FaceData face) {
    if (_blinkDetected) return;

    final eyeOpenProb = face.averageEyeOpenProb;
    final isClosed = eyeOpenProb < _openThreshold;

    if (_wasEyesOpen && isClosed) {
      _closedFrameCount = 1;
      _wasEyesOpen = false;
    } else if (!_wasEyesOpen && isClosed) {
      _closedFrameCount++;
    } else if (!_wasEyesOpen && !isClosed) {
      if (_closedFrameCount >= _minClosedFrames) {
        _blinkDetected = true;
      }
      _closedFrameCount = 0;
      _wasEyesOpen = true;
    }

    _framesSinceGoodFace++;

    if (_framesSinceGoodFace > _maxFramesWithoutBlink) {
      reset();
    }
  }

  bool get hasBlinked => _blinkDetected;

  void reset() {
    _framesSinceGoodFace = 0;
    _closedFrameCount = 0;
    _wasEyesOpen = true;
    _blinkDetected = false;
  }
}
