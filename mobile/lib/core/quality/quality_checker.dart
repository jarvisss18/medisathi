import 'dart:math';
import 'package:image/image.dart' as img;

class QualityCheckResult {
  final double laplacianVariance;
  final double glareRatio;
  final double meanBrightness;
  final bool isBlurPassed;
  final bool isGlarePassed;
  final bool isBrightnessPassed;
  final bool isPassed;
  final String? failureReason;

  QualityCheckResult({
    required this.laplacianVariance,
    required this.glareRatio,
    required this.meanBrightness,
    required this.isBlurPassed,
    required this.isGlarePassed,
    required this.isBrightnessPassed,
    required this.isPassed,
    this.failureReason,
  });
}

class QualityChecker {
  // Default thresholds matching gate_config.json
  final double minLaplacianVariance;
  final double maxGlareRatio;
  final double minBrightness;
  final double maxBrightness;

  QualityChecker({
    this.minLaplacianVariance = 100.0,
    this.maxGlareRatio = 0.15,
    this.minBrightness = 40.0,
    this.maxBrightness = 230.0,
  });

  /// Evaluates an image for blur, glare, and brightness quality.
  QualityCheckResult analyzeImage(img.Image image) {
    // Convert to grayscale for performance
    final img.Image grayscale = img.grayscale(image);

    final double variance = _calculateLaplacianVariance(grayscale);
    final double glare = _calculateGlareRatio(grayscale);
    final double brightness = _calculateMeanBrightness(grayscale);

    final bool blurOk = variance >= minLaplacianVariance;
    final bool glareOk = glare <= maxGlareRatio;
    final bool brightnessOk = brightness >= minBrightness && brightness <= maxBrightness;

    final bool overallPassed = blurOk && glareOk && brightnessOk;

    String? reason;
    if (!blurOk) {
      reason = "QUALITY_BLUR_FAILED (Variance: ${variance.toStringAsFixed(1)} < $minLaplacianVariance)";
    } else if (!glareOk) {
      reason = "QUALITY_GLARE_FAILED (Glare ratio: ${(glare * 100).toStringAsFixed(1)}% > ${(maxGlareRatio * 100).toStringAsFixed(1)}%)";
    } else if (!brightnessOk) {
      reason = "QUALITY_BRIGHTNESS_FAILED (Brightness: ${brightness.toStringAsFixed(1)})";
    }

    return QualityCheckResult(
      laplacianVariance: variance,
      glareRatio: glare,
      meanBrightness: brightness,
      isBlurPassed: blurOk,
      isGlarePassed: glareOk,
      isBrightnessPassed: brightnessOk,
      isPassed: overallPassed,
      failureReason: reason,
    );
  }

  /// Calculates Laplacian variance using a standard 3x3 kernel:
  ///  [ 0,  1, 0]
  ///  [ 1, -4, 1]
  ///  [ 0,  1, 0]
  double _calculateLaplacianVariance(img.Image gray) {
    final width = gray.width;
    final height = gray.height;
    if (width < 3 || height < 3) return 0.0;

    double sum = 0.0;
    double sumSq = 0.0;
    int count = 0;

    // Sample every 2nd pixel for performance on mobile
    for (int y = 1; y < height - 1; y += 2) {
      for (int x = 1; x < width - 1; x += 2) {
        final pCenter = gray.getPixel(x, y).r.toDouble();
        final pUp = gray.getPixel(x, y - 1).r.toDouble();
        final pDown = gray.getPixel(x, y + 1).r.toDouble();
        final pLeft = gray.getPixel(x - 1, y).r.toDouble();
        final pRight = gray.getPixel(x + 1, y).r.toDouble();

        final lap = pUp + pDown + pLeft + pRight - (4 * pCenter);
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    return max(0.0, variance);
  }

  /// Calculates ratio of pixels with luminance > 240 (glare highlights).
  double _calculateGlareRatio(img.Image gray) {
    int glarePixelCount = 0;
    int totalCount = 0;

    for (final pixel in gray) {
      final lum = pixel.r;
      if (lum > 240) {
        glarePixelCount++;
      }
      totalCount++;
    }

    if (totalCount == 0) return 0.0;
    return glarePixelCount / totalCount;
  }

  /// Calculates mean luminance across the grayscale image.
  double _calculateMeanBrightness(img.Image gray) {
    double sum = 0.0;
    int totalCount = 0;

    for (final pixel in gray) {
      sum += pixel.r;
      totalCount++;
    }

    if (totalCount == 0) return 0.0;
    return sum / totalCount;
  }
}
