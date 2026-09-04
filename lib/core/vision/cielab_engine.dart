// ignore_for_file: constant_identifier_names

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:image/image.dart' as img;

// =============================================================================
//  CIE-LAB Color Science Engine
//  ─────────────────────────────────────────────────────────────────────────────
//  Self-contained pure-Dart math engine for the H₂S Sentinel dosimeter reader.
//
//  Pipeline:
//    JPEG bytes  ──►  50 × 50 px crop  ──►  avg sRGB
//                ──►  Linear RGB  ──►  CIE XYZ (D65)  ──►  CIELAB
//                ──►  ΔE*₇₆  ──►  ExposureAlert
//
//  All mathematics follow:
//    • IEC 61966-2-1:1999   — sRGB specification (gamma curve)
//    • CIE Publication 15:2004 — Colorimetry (XYZ matrix, D65 white point)
//    • ISO 11664-4 / CIE 76  — ΔE*₇₆ Euclidean colour difference
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
//  1 ▸ Public data classes
// ─────────────────────────────────────────────────────────────────────────────

/// Mean sRGB values (each 0–255) sampled from the dosimeter region of interest.
class SrgbSample {
  const SrgbSample({
    required this.r,
    required this.g,
    required this.b,
    required this.pixelCount,
  });

  /// Mean red channel (0–255).
  final double r;

  /// Mean green channel (0–255).
  final double g;

  /// Mean blue channel (0–255).
  final double b;

  /// Number of pixels included in the average.
  final int pixelCount;

  @override
  String toString() =>
      'SrgbSample(r=${r.toStringAsFixed(1)}, '
      'g=${g.toStringAsFixed(1)}, b=${b.toStringAsFixed(1)}, n=$pixelCount)';
}

/// A colour expressed in the CIELAB (L*a*b*) colour space.
class LabColor {
  const LabColor({required this.l, required this.a, required this.b});

  /// L* — Lightness axis:  0 (pure black) ── 100 (perfect diffuse white).
  final double l;

  /// a* — Chroma axis:  negative (green) ── positive (red/magenta).
  final double a;

  /// b* — Chroma axis:  negative (blue/violet) ── positive (yellow).
  final double b;

  @override
  String toString() =>
      'LAB(L*=${l.toStringAsFixed(3)}, a*=${a.toStringAsFixed(3)}, '
      'b*=${b.toStringAsFixed(3)})';
}

/// The complete output of one dosimeter exposure evaluation.
class ExposureResult {
  const ExposureResult({
    required this.srgbSample,
    required this.lab,
    required this.deltaE,
    required this.alert,
  });

  /// The averaged sRGB patch from the 50 × 50 px crop.
  final SrgbSample srgbSample;

  /// CIELAB values of the scanned sample.
  final LabColor lab;

  /// CIE76 ΔE* distance from the pure-white baseline (L*=100, a*=0, b*=0).
  final double deltaE;

  /// Hazard classification string derived from [deltaE].
  final String alert;

  @override
  String toString() =>
      'ExposureResult(deltaE=${deltaE.toStringAsFixed(3)}, '
      'alert=$alert, $lab)';
}

// ─────────────────────────────────────────────────────────────────────────────
//  2 ▸ Alert constants  (task requirement #8)
// ─────────────────────────────────────────────────────────────────────────────

/// ΔE threshold below which exposure is classified as safe.
const double kSafeMaxDeltaE = 5.0;

/// ΔE threshold below which exposure is classified as a warning.
const double kWarningMaxDeltaE = 18.0;

/// Alert string returned when ΔE < [kSafeMaxDeltaE].
const String kAlertSafe = 'SAFE';

/// Alert string returned when [kSafeMaxDeltaE] <= ΔE < [kWarningMaxDeltaE].
const String kAlertWarning = 'WARNING';

/// Alert string returned when ΔE >= [kWarningMaxDeltaE].
const String kAlertDanger = 'DANGER';

// ─────────────────────────────────────────────────────────────────────────────
//  3 ▸ CIELabEngine  — the main engine class
// ─────────────────────────────────────────────────────────────────────────────

/// Pure-Dart color-science math engine for H₂S dosimeter strip analysis.
///
/// All public methods are static.
///
/// ### Typical usage
/// ```dart
/// // From a captured camera file:
/// final bytes = await xfile.readAsBytes();
/// final result = CIELabEngine.analyzeImage(bytes);
///
/// // From a known Flutter Color:
/// final deltaE = CIELabEngine.calculateExposure(const Color(0xFFD4A57C));
/// ```
abstract final class CIELabEngine {
  // D65 Reference White  (CIE Publication 15:2004, Table 1, Y_n = 100)
  static const double _Xn = 95.047;
  static const double _Yn = 100.000;
  static const double _Zn = 108.883;

  // CIE f() function constants  (CIE Publication 15:2004 §8.2.1)
  // epsilon = (6/29)^3 ≈ 0.008856
  static const double _epsilon = 0.008856;
  // kappa   = (29/3)^3 ≈ 903.3
  static const double _kappa = 903.3;

  // Baseline: pure white unexposed dosimeter  (task requirement #7)
  static const double _baselineL = 100.0;
  static const double _baselineA = 0.0;
  static const double _baselineB = 0.0;

  /// Fixed crop side-length in pixels applied to the centre of each image.
  static const int roiSidePx = 50;

  // ===========================================================================
  //  PUBLIC API
  // ===========================================================================

  // ---------------------------------------------------------------------------
  //  A: Full pipeline from raw JPEG/PNG bytes  (requirements #1 through #8)
  // ---------------------------------------------------------------------------

  /// Decode [imageBytes], crop the central 50 x 50 px bounding box, compute
  /// the average sRGB, run the full color-science pipeline, and return an
  /// [ExposureResult] containing CIELAB values, ΔE, and the alert string.
  ///
  /// Throws [ArgumentError] if [imageBytes] cannot be decoded.
  static ExposureResult analyzeImage(Uint8List imageBytes) {
    // 1. Decode
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ArgumentError(
        'CIELabEngine.analyzeImage: could not decode image bytes. '
        'Ensure the buffer contains a valid JPEG, PNG, or supported format.',
      );
    }

    // 2. Crop the centre 50 x 50 region of interest and average sRGB
    final sample = _extractRoi(image);

    // 3-5. sRGB -> Linear RGB -> XYZ -> CIELAB
    final lab = _rgbToLab(sample.r, sample.g, sample.b);

    // 6. ΔE*₇₆ against the pure-white baseline
    final de = _deltaE76(
      lab,
      const LabColor(l: _baselineL, a: _baselineA, b: _baselineB),
    );

    // 7-8. Map to alert string
    final alert = _alertFromDeltaE(de);

    return ExposureResult(srgbSample: sample, lab: lab, deltaE: de, alert: alert);
  }

  // ---------------------------------------------------------------------------
  //  B: calculateExposure — from a Flutter Color  (requirement #7)
  // ---------------------------------------------------------------------------

  /// Compare [capturedColor] against the pure-white baseline
  /// (L*=100, a*=0, b*=0) and return the ΔE*₇₆ float.
  ///
  /// The alpha channel is ignored; only the RGB components are used.
  ///
  /// ```dart
  /// final deltaE = CIELabEngine.calculateExposure(const Color(0xFFD4A57C));
  /// ```
  static double calculateExposure(Color capturedColor) {
    // Color.r/g/b are normalized floats [0,1] in modern Flutter; scale to 0–255.
    final r = (capturedColor.r * 255.0).roundToDouble().clamp(0.0, 255.0);
    final g = (capturedColor.g * 255.0).roundToDouble().clamp(0.0, 255.0);
    final b = (capturedColor.b * 255.0).roundToDouble().clamp(0.0, 255.0);
    final lab = _rgbToLab(r, g, b);
    return _deltaE76(
      lab,
      const LabColor(l: _baselineL, a: _baselineA, b: _baselineB),
    );
  }

  /// Convenience: run [calculateExposure] and also return the alert string.
  ///
  /// Returns a named record `(deltaE: double, alert: String)`.
  static ({double deltaE, String alert}) calculateExposureWithAlert(
    Color capturedColor,
  ) {
    final de = calculateExposure(capturedColor);
    return (deltaE: de, alert: _alertFromDeltaE(de));
  }

  // ---------------------------------------------------------------------------
  //  C: alertFromDeltaE — stand-alone status classifier  (requirement #8)
  // ---------------------------------------------------------------------------

  /// Map a raw ΔE value to one of the three alert strings:
  ///
  ///   ΔE < 5.0          ->  "SAFE"
  ///   5.0 <= ΔE < 18.0  ->  "WARNING"
  ///   ΔE >= 18.0        ->  "DANGER"
  static String alertFromDeltaE(double deltaE) => _alertFromDeltaE(deltaE);

  // ---------------------------------------------------------------------------
  //  D: Individual step helpers exposed for unit testing
  // ---------------------------------------------------------------------------

  /// Step 2: Extract the mean sRGB of the central 50 x 50 px box.
  static SrgbSample extractRoiFromImage(img.Image image) => _extractRoi(image);

  /// Step 3: sRGB channel byte (0–255) -> linear light value (0.0–1.0).
  ///
  /// IEC 61966-2-1 inverse gamma (piecewise):
  ///   u = c / 255
  ///   u <= 0.04045  ->  u / 12.92
  ///   u  > 0.04045  ->  ((u + 0.055) / 1.055)^2.4
  static double srgbToLinear(double channelByte) =>
      _srgbChannelToLinear(channelByte);

  /// Step 4: Linear-light RGB triplet -> CIE XYZ (D65, Y scaled to 100).
  ///
  /// IEC 61966-2-1 Annex A matrix:
  ///   X = 100 * (0.4124564*R + 0.3575761*G + 0.1804375*B)
  ///   Y = 100 * (0.2126729*R + 0.7151522*G + 0.0721750*B)
  ///   Z = 100 * (0.0193339*R + 0.1191920*G + 0.9503041*B)
  static ({double x, double y, double z}) linearRgbToXyz(
    double rLin,
    double gLin,
    double bLin,
  ) =>
      _linearRgbToXyz(rLin, gLin, bLin);

  /// Step 5: CIE XYZ (D65, Y=100 scale) -> CIELAB (L*, a*, b*).
  static LabColor xyzToLab(double x, double y, double z) => _xyzToLab(x, y, z);

  /// Step 6: CIE76 ΔE*₇₆ Euclidean distance between two CIELAB colours.
  ///   ΔE*₇₆ = sqrt[(L2-L1)^2 + (a2-a1)^2 + (b2-b1)^2]
  static double deltaE76(LabColor sample, LabColor reference) =>
      _deltaE76(sample, reference);

  // ===========================================================================
  //  PRIVATE IMPLEMENTATION
  // ===========================================================================

  // ─── Steps 1–2: Crop + average sRGB ─────────────────────────────────────

  static SrgbSample _extractRoi(img.Image image) {
    final w = image.width;
    final h = image.height;

    // Clamp so we never exceed image boundaries
    final roiW = math.min(roiSidePx, w);
    final roiH = math.min(roiSidePx, h);
    final x0 = ((w - roiW) / 2).floor();
    final y0 = ((h - roiH) / 2).floor();
    final x1 = x0 + roiW;
    final y1 = y0 + roiH;

    double sumR = 0.0, sumG = 0.0, sumB = 0.0;
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
      return const SrgbSample(r: 128.0, g: 128.0, b: 128.0, pixelCount: 0);
    }

    return SrgbSample(
      r: sumR / count,
      g: sumG / count,
      b: sumB / count,
      pixelCount: count,
    );
  }

  // ─── Step 3: sRGB -> Linear RGB (gamma expansion) ────────────────────────

  static double _srgbChannelToLinear(double c) {
    final u = c / 255.0;
    if (u <= 0.04045) return u / 12.92;
    return math.pow((u + 0.055) / 1.055, 2.4).toDouble();
  }

  // ─── Step 4: Linear RGB -> CIE XYZ (D65 illuminant) ─────────────────────

  static ({double x, double y, double z}) _linearRgbToXyz(
    double rLin,
    double gLin,
    double bLin,
  ) {
    return (
      x: 100.0 * (0.4124564 * rLin + 0.3575761 * gLin + 0.1804375 * bLin),
      y: 100.0 * (0.2126729 * rLin + 0.7151522 * gLin + 0.0721750 * bLin),
      z: 100.0 * (0.0193339 * rLin + 0.1191920 * gLin + 0.9503041 * bLin),
    );
  }

  // ─── Step 5: CIE XYZ -> CIELAB ───────────────────────────────────────────

  // CIE f() compressive function:
  //   f(t) = t^(1/3)              if t > epsilon
  //   f(t) = (kappa*t + 16) / 116  otherwise
  static double _f(double t) {
    if (t > _epsilon) return math.pow(t, 1.0 / 3.0).toDouble();
    return (_kappa * t + 16.0) / 116.0;
  }

  static LabColor _xyzToLab(double x, double y, double z) {
    final fx = _f(x / _Xn);
    final fy = _f(y / _Yn);
    final fz = _f(z / _Zn);
    return LabColor(
      l: 116.0 * fy - 16.0,
      a: 500.0 * (fx - fy),
      b: 200.0 * (fy - fz),
    );
  }

  // ─── Full convenience: sRGB (0-255) -> CIELAB ────────────────────────────

  static LabColor _rgbToLab(double r, double g, double b) {
    final rLin = _srgbChannelToLinear(r);
    final gLin = _srgbChannelToLinear(g);
    final bLin = _srgbChannelToLinear(b);
    final xyz = _linearRgbToXyz(rLin, gLin, bLin);
    return _xyzToLab(xyz.x, xyz.y, xyz.z);
  }

  // ─── Step 6: CIE76 ΔE*₇₆ ────────────────────────────────────────────────

  static double _deltaE76(LabColor sample, LabColor reference) {
    final dL = sample.l - reference.l;
    final da = sample.a - reference.a;
    final db = sample.b - reference.b;
    return math.sqrt(dL * dL + da * da + db * db);
  }

  // ─── Steps 7–8: ΔE -> alert string ──────────────────────────────────────

  static String _alertFromDeltaE(double deltaE) {
    if (deltaE < kSafeMaxDeltaE) return kAlertSafe;
    if (deltaE < kWarningMaxDeltaE) return kAlertWarning;
    return kAlertDanger;
  }
}
