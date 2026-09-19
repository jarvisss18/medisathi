import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class BurstCaptureResult {
  final List<XFile> frames;
  final bool isComplete;
  final String? error;

  BurstCaptureResult({
    required this.frames,
    required this.isComplete,
    this.error,
  });
}

class BurstCaptureController extends ChangeNotifier {
  bool _isCapturing = false;
  int _capturedCount = 0;
  final int totalFrames = 3;

  bool get isCapturing => _isCapturing;
  int get capturedCount => _capturedCount;
  double get progress => _capturedCount / totalFrames;

  Future<BurstCaptureResult> captureBurst(CameraController cameraController) async {
    if (_isCapturing) {
      return BurstCaptureResult(frames: [], isComplete: false, error: "Capture already in progress");
    }

    _isCapturing = true;
    _capturedCount = 0;
    notifyListeners();

    final List<XFile> capturedFrames = [];

    try {
      for (int i = 0; i < totalFrames; i++) {
        final XFile file = await cameraController.takePicture();
        capturedFrames.add(file);
        _capturedCount = i + 1;
        notifyListeners();
        // Delay 150ms between burst frames
        await Future.delayed(const Duration(milliseconds: 150));
      }

      _isCapturing = false;
      notifyListeners();

      return BurstCaptureResult(
        frames: capturedFrames,
        isComplete: true,
      );
    } catch (e) {
      _isCapturing = false;
      notifyListeners();
      return BurstCaptureResult(
        frames: capturedFrames,
        isComplete: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    _isCapturing = false;
    _capturedCount = 0;
    notifyListeners();
  }
}
