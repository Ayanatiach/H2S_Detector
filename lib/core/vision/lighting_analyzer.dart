import 'package:image/image.dart' as img;
import 'color_extractor.dart';
import '../constants/exposure_thresholds.dart';

/// Result of a frame lighting quality check.
class LightingResult {
  const LightingResult({
    required this.estimatedLuminance,
    required this.isTooLow,
  });

  /// Mean luminance of the full frame (0–255 scale).
  final double estimatedLuminance;

  /// True if light level is below the acceptable threshold for accurate
  /// colorimetric reading.
  final bool isTooLow;

  /// Approx percentage of full brightness (0–100).
  double get brightnessPercent => (estimatedLuminance / 255.0 * 100.0).clamp(0, 100);
}

/// Analyses the ambient lighting in a camera frame to determine whether
/// conditions are adequate for an accurate colorimetric dosimeter reading.
abstract final class LightingAnalyzer {
  /// Analyse a full camera [frame] for adequate lighting.
  ///
  /// Uses a luminance approximation:
  ///   Y ≈ 0.299·R + 0.587·G + 0.114·B   (BT.601 luma coefficients)
  static LightingResult analyze(img.Image frame) {
    final sample = ColorExtractor.extractFull(frame);

    // BT.601 luma estimate (perceptual weighting)
    final luminance =
        0.299 * sample.r + 0.587 * sample.g + 0.114 * sample.b;

    return LightingResult(
      estimatedLuminance: luminance,
      isTooLow: luminance < ExposureThresholds.minAcceptableLuminance,
    );
  }

  /// Quick luminance estimate from raw R,G,B channel averages (0–255).
  static double estimateLuminance(double r, double g, double b) {
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }
}
