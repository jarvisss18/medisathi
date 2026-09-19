import 'package:flutter_test/flutter_test.dart';
import 'package:medisathi/features/scan/controllers/motion_gate_controller.dart';
import 'package:medisathi/features/scan/controllers/burst_capture_controller.dart';

void main() {
  group('MotionGateController Tests', () {
    test('Initial state is steady (safe fallback)', () {
      final controller = MotionGateController();
      expect(controller.state, MotionStabilityState.steady);
      expect(controller.isSteady, true);
    });

    test('stopListening handles uninitialized state gracefully', () {
      final controller = MotionGateController();
      controller.stopListening();
      expect(controller.isSteady, true);
    });
  });

  group('BurstCaptureController Tests', () {
    test('Initial state is not capturing with zero progress', () {
      final controller = BurstCaptureController();
      expect(controller.isCapturing, false);
      expect(controller.capturedCount, 0);
      expect(controller.progress, 0.0);
    });

    test('reset clears progress', () {
      final controller = BurstCaptureController();
      controller.reset();
      expect(controller.isCapturing, false);
      expect(controller.capturedCount, 0);
    });
  });
}
