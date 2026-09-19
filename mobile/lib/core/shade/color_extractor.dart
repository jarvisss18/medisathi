import 'dart:math';
import 'package:image/image.dart' as img;

class HsvColorSignature {
  final double hue; // 0.0 - 360.0
  final double saturation; // 0.0 - 1.0
  final double value; // 0.0 - 1.0
  final bool isCalibrated;

  const HsvColorSignature({
    required this.hue,
    required this.saturation,
    required this.value,
    this.isCalibrated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'hue': hue,
      'sat': saturation,
      'val': value,
      'calibrated': isCalibrated,
    };
  }
}

class ColorExtractor {
  /// Extracts average HSV color signature from an image ROI or full image.
  static HsvColorSignature extractDominantHsv(img.Image image) {
    if (image.width == 0 || image.height == 0) {
      return const HsvColorSignature(hue: 0, saturation: 0, value: 0, isCalibrated: false);
    }

    double sumH = 0.0;
    double sumS = 0.0;
    double sumV = 0.0;
    int count = 0;

    // Sample pixels across image
    for (int y = 0; y < image.height; y += 2) {
      for (int x = 0; x < image.width; x += 2) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        final maxVal = max(r, max(g, b));
        final minVal = min(r, min(g, b));
        final delta = maxVal - minVal;

        double h = 0.0;
        if (delta > 0.001) {
          if (maxVal == r) {
            h = (g - b) / delta + (g < b ? 6 : 0);
          } else if (maxVal == g) {
            h = (b - r) / delta + 2;
          } else {
            h = (r - g) / delta + 4;
          }
          h *= 60.0;
        }

        final s = maxVal == 0 ? 0.0 : delta / maxVal;
        final v = maxVal;

        sumH += h;
        sumS += s;
        sumV += v;
        count++;
      }
    }

    if (count == 0) {
      return const HsvColorSignature(hue: 0, saturation: 0, value: 0, isCalibrated: false);
    }

    return HsvColorSignature(
      hue: sumH / count,
      saturation: sumS / count,
      value: sumV / count,
      isCalibrated: true,
    );
  }

  /// Calculates Hue distance (0..180 degrees max) taking circular wrap into account.
  static double calculateHueDistance(double h1, double h2) {
    final diff = (h1 - h2).abs() % 360.0;
    return diff > 180.0 ? 360.0 - diff : diff;
  }

  /// Computes color match score (0.0 to 1.0) between extracted signature and reference signature.
  /// If [gateEnabled] is false or reference is not calibrated, returns neutral fallback 1.0 (never penalizes).
  static double computeColorMatchScore({
    required HsvColorSignature extracted,
    required Map<String, dynamic>? referenceConfig,
    bool gateEnabled = false,
  }) {
    if (!gateEnabled || referenceConfig == null) {
      return 1.0; // Uncalibrated / disabled neutral fallback
    }

    final bool isCalibrated = referenceConfig['calibrated'] ?? false;
    if (!isCalibrated) {
      return 1.0; // Safe neutral fallback when medicine strip is not yet calibrated
    }

    final double refHue = (referenceConfig['hue'] as num).toDouble();
    final double tolerance = (referenceConfig['tol'] as num? ?? 30.0).toDouble();

    final hueDist = calculateHueDistance(extracted.hue, refHue);
    if (hueDist <= tolerance) {
      return 1.0 - (hueDist / (tolerance * 2.0));
    } else {
      return max(0.0, 0.50 - ((hueDist - tolerance) / 180.0));
    }
  }
}
