import 'package:image/image.dart' as img;

/// Result from color extraction of a dosimeter ROI patch.
class RgbSample {
  const RgbSample({
    required this.r,
    required this.g,
    required this.b,
    required this.pixelCount,
  });

  /// Mean red channel value (0–255).
  final double r;

  /// Mean green channel value (0–255).
  final double g;

  /// Mean blue channel value (0–255).
  final double b;

  /// Number of pixels sampled (for quality estimation).
  final int pixelCount;

  @override
  String toString() =>
      'RgbSample(r=${r.toStringAsFixed(1)}, g=${g.toStringAsFixed(1)}, b=${b.toStringAsFixed(1)}, n=$pixelCount)';
}

/// Extracts the average RGB colour from the central Region of Interest (ROI)
/// of a captured dosimeter image.
///
/// The ROI is a proportional rectangle centred on the image, intended to
/// correspond to the coloured reaction zone of the H₂S dosimeter strip.
abstract final class ColorExtractor {
  /// Fraction of image width / height to use as the ROI crop.
  static const double roiFraction = 0.35;

  /// Sample the average RGB of the central [roiFraction] × [roiFraction]
  /// bounding box of [image].
  ///
  /// Steps:
  ///   1. Compute the pixel coordinates of the centred ROI rectangle.
  ///   2. Iterate over every pixel inside that rectangle.
  ///   3. Accumulate R, G, B channel values and divide by pixel count.
  static RgbSample extractRoi(img.Image image) {
    final w = image.width;
    final h = image.height;

    // ROI bounds — centred crop
    final roiW = (w * roiFraction).round();
    final roiH = (h * roiFraction).round();
    final x0 = ((w - roiW) / 2).round();
    final y0 = ((h - roiH) / 2).round();
    final x1 = x0 + roiW;
    final y1 = y0 + roiH;

    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;

    for (int y = y0; y < y1; y++) {
      for (int x = x0; x < x1; x++) {
        final pixel = image.getPixel(x, y);
        sumR += pixel.r.toDouble();
        sumG += pixel.g.toDouble();
        sumB += pixel.b.toDouble();
        count++;
      }
    }

    if (count == 0) {
      // Fallback — return neutral grey if image has zero dimensions
      return const RgbSample(r: 128, g: 128, b: 128, pixelCount: 0);
    }

    return RgbSample(
      r: sumR / count,
      g: sumG / count,
      b: sumB / count,
      pixelCount: count,
    );
  }

  /// Extract the average RGB of the entire [image] frame.
  /// Used by [LightingAnalyzer] to estimate ambient luminance.
  static RgbSample extractFull(img.Image image) {
    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;

    for (final pixel in image) {
      sumR += pixel.r.toDouble();
      sumG += pixel.g.toDouble();
      sumB += pixel.b.toDouble();
      count++;
    }

    if (count == 0) {
      return const RgbSample(r: 128, g: 128, b: 128, pixelCount: 0);
    }

    return RgbSample(
      r: sumR / count,
      g: sumG / count,
      b: sumB / count,
      pixelCount: count,
    );
  }
}
