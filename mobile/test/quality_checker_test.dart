import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:medisathi/core/quality/quality_checker.dart';

void main() {
  late QualityChecker checker;

  setUp(() {
    checker = QualityChecker(
      minLaplacianVariance: 100.0,
      maxGlareRatio: 0.15,
      minBrightness: 40.0,
      maxBrightness: 230.0,
    );
  });

  group('QualityChecker Tests', () {
    test('High-contrast sharp checkerboard image passes quality checks', () {
      final image = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final isWhite = ((x ~/ 10) + (y ~/ 10)) % 2 == 0;
          image.setPixelRgb(x, y, isWhite ? 200 : 50, isWhite ? 200 : 50, isWhite ? 200 : 50);
        }
      }

      final result = checker.analyzeImage(image);

      expect(result.isBlurPassed, isTrue);
      expect(result.isGlarePassed, isTrue);
      expect(result.isBrightnessPassed, isTrue);
      expect(result.isPassed, isTrue);
      expect(result.failureReason, null);
    });

    test('Solid uniform gray image fails blur check (low Laplacian variance)', () {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(128, 128, 128));

      final result = checker.analyzeImage(image);

      expect(result.laplacianVariance, closeTo(0.0, 1.0));
      expect(result.isBlurPassed, isFalse);
      expect(result.isPassed, isFalse);
      expect(result.failureReason, contains('QUALITY_BLUR_FAILED'));
    });

    test('Overexposed all-white image fails glare and brightness check', () {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      final result = checker.analyzeImage(image);

      expect(result.glareRatio, equals(1.0));
      expect(result.isGlarePassed, isFalse);
      expect(result.isPassed, isFalse);
    });

    test('Underexposed dark image fails brightness check', () {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(10, 10, 10));

      final result = checker.analyzeImage(image);

      expect(result.meanBrightness, closeTo(10.0, 1.0));
      expect(result.isBrightnessPassed, isFalse);
      expect(result.isPassed, isFalse);
    });
  });
}
