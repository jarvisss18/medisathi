import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum MotionStabilityState {
  steady, // Safe to trigger capture
  slightMotion, // Almost steady
  shaking, // Too much motion
}

class MotionGateController extends ChangeNotifier {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  MotionStabilityState _state = MotionStabilityState.steady;
  double _currentMagnitude = 0.0;
  final List<double> _magnitudeWindow = [];
  static const int windowSize = 10;

  // Thresholds (rad/s)
  static const double steadyThreshold = 0.15;
  static const double slightMotionThreshold = 0.45;

  MotionStabilityState get state => _state;
  double get currentMagnitude => _currentMagnitude;
  bool get isSteady => _state == MotionStabilityState.steady;

  void startListening() {
    _magnitudeWindow.clear();
    _gyroSubscription?.cancel();

    try {
      _gyroSubscription = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          _currentMagnitude = mag;

          _magnitudeWindow.add(mag);
          if (_magnitudeWindow.length > windowSize) {
            _magnitudeWindow.removeAt(0);
          }

          final avgMag = _magnitudeWindow.reduce((a, b) => a + b) / _magnitudeWindow.length;

          if (avgMag < steadyThreshold) {
            _setState(MotionStabilityState.steady);
          } else if (avgMag < slightMotionThreshold) {
            _setState(MotionStabilityState.slightMotion);
          } else {
            _setState(MotionStabilityState.shaking);
          }
        },
        onError: (Object error) {
          _setState(MotionStabilityState.steady);
        },
        cancelOnError: false,
      );
    } catch (e) {
      _setState(MotionStabilityState.steady);
    }
  }

  void stopListening() {
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }

  void _setState(MotionStabilityState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
