import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:medisathi/core/shade/color_extractor.dart';

void main() {
  group('ColorExtractor Hue Distance Tests', () {
    test('Calculates simple hue distance', () {
      expect(ColorExtractor.calculateHueDistance(10, 30), 20.0);
    });

    test('Handles circular 360-degree wrap around correctly', () {
      // 350 deg and 10 deg are 20 degrees apart
      expect(ColorExtractor.calculateHueDistance(350, 10), 20.0);
      expect(ColorExtractor.calculateHueDistance(5, 355), 10.0);
    });
  });

  group('ColorExtractor Match Score & Fallback Tests', () {
    test('Returns 1.0 neutral score when gate is disabled', () {
      const extracted = HsvColorSignature(hue: 120, saturation: 0.5, value: 0.8);
      final ref = {'hue': 0, 'sat': 0, 'val': 0, 'tol': 30, 'calibrated': true};

      final score = ColorExtractor.computeColorMatchScore(
        extracted: extracted,
        referenceConfig: ref,
        gateEnabled: false,
      );

      expect(score, equals(1.0));
    });

    test('Returns 1.0 neutral score when reference is uncalibrated', () {
      const extracted = HsvColorSignature(hue: 120, saturation: 0.5, value: 0.8);
      final uncalibratedRef = {'hue': 0, 'sat': 0, 'val': 0, 'tol': 30, 'calibrated': false};

      final score = ColorExtractor.computeColorMatchScore(
        extracted: extracted,
        referenceConfig: uncalibratedRef,
        gateEnabled: true,
      );

      expect(score, equals(1.0));
    });

    test('Computes high score for matching calibrated hue', () {
      const extracted = HsvColorSignature(hue: 200, saturation: 0.8, value: 0.8);
      final calibratedRef = {'hue': 205, 'sat': 0.8, 'val': 0.8, 'tol': 30, 'calibrated': true};

      final score = ColorExtractor.computeColorMatchScore(
        extracted: extracted,
        referenceConfig: calibratedRef,
        gateEnabled: true,
      );

      expect(score, greaterThan(0.90));
    });
  });

  group('ColorExtractor Image Extraction Tests', () {
    test('Extracts dominant blue HSV from solid blue image', () {
      final image = img.Image(width: 50, height: 50);
      img.fill(image, color: img.ColorRgb8(0, 0, 255)); // Pure RGB Blue

      final sig = ColorExtractor.extractDominantHsv(image);

      expect(sig.hue, closeTo(240.0, 5.0)); // Blue hue = 240 deg
      expect(sig.saturation, closeTo(1.0, 0.05));
      expect(sig.isCalibrated, isTrue);
    });
  });
}
