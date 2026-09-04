import 'dart:math' as math;

/// CIELAB colour values for a single sample point.
class LabColor {
  const LabColor({
    required this.l,
    required this.a,
    required this.b,
  });

  /// L* — Lightness (0 = black, 100 = white)
  final double l;

  /// a* — green (−) to red (+) axis
  final double a;

  /// b* — blue (−) to yellow (+) axis
  final double b;

  @override
  String toString() =>
      'LAB(L*=${l.toStringAsFixed(2)}, a*=${a.toStringAsFixed(2)}, b*=${b.toStringAsFixed(2)})';
}

/// Complete colour-space conversion pipeline:
///   sRGB (0–255) → Linear RGB → CIE XYZ (D65) → CIELAB (L*, a*, b*)
///
/// References:
///   • IEC 61966-2-1: sRGB specification
///   • CIE Publication 15:2004: Colorimetry
///   • ICC: D65 adapted reference white (Xn=95.047, Yn=100.0, Zn=108.883)
abstract final class ColorSpaceConverter {
  // ── Reference white (D65 illuminant) ──────────────────────────────────────
  static const double _xn = 95.047; // X reference white
  static const double _yn = 100.000; // Y reference white
  static const double _zn = 108.883; // Z reference white

  // ── CIE76 ε and κ (used in XYZ→Lab) ─────────────────────────────────────
  /// ε = (6/29)³ ≈ 0.008856
  static const double _epsilon = 0.008856;

  /// κ = (29/3)³ ≈ 903.3
  static const double _kappa = 903.3;

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1: sRGB (0–255) → Linear RGB (0.0–1.0)
  // ─────────────────────────────────────────────────────────────────────────
  /// Applies inverse sRGB gamma (gamma expansion).
  ///
  ///   If C_srgb ≤ 0.04045:  C_lin = C_srgb / 12.92
  ///   Otherwise:             C_lin = ((C_srgb + 0.055) / 1.055) ^ 2.4
  static double _srgbToLinear(double channelByte) {
    // Normalise 0–255 → 0.0–1.0
    final c = channelByte / 255.0;

    if (c <= 0.04045) {
      return c / 12.92;
    } else {
      return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2: Linear RGB → CIE XYZ (D65 reference illuminant)
  // ─────────────────────────────────────────────────────────────────────────
  /// Applies the IEC 61966-2-1 sRGB → XYZ transformation matrix
  /// (D65 white point, normalised so Y=100 for white):
  ///
  ///   ┌ X ┐   ┌ 0.4124564  0.3575761  0.1804375 ┐   ┌ R_lin ┐
  ///   │ Y │ = │ 0.2126729  0.7151522  0.0721750 │ × │ G_lin │  × 100
  ///   └ Z ┘   └ 0.0193339  0.1191920  0.9503041 ┘   └ B_lin ┘
  static ({double x, double y, double z}) _linearRgbToXyz(
    double rLin,
    double gLin,
    double bLin,
  ) {
    return (
      x: (0.4124564 * rLin + 0.3575761 * gLin + 0.1804375 * bLin) * 100.0,
      y: (0.2126729 * rLin + 0.7151522 * gLin + 0.0721750 * bLin) * 100.0,
      z: (0.0193339 * rLin + 0.1191920 * gLin + 0.9503041 * bLin) * 100.0,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3: CIE XYZ → CIELAB (L*, a*, b*)
  // ─────────────────────────────────────────────────────────────────────────
  /// Applies the CIE f() function (cube-root approximation):
  ///
  ///   f(t) = t^(1/3)          if t > ε
  ///   f(t) = (κ·t + 16) / 116  otherwise
  static double _f(double t) {
    if (t > _epsilon) {
      return math.pow(t, 1.0 / 3.0).toDouble();
    } else {
      return (_kappa * t + 16.0) / 116.0;
    }
  }

  /// Full XYZ → CIELAB conversion:
  ///
  ///   L* = 116 · f(Y/Yn) − 16
  ///   a* = 500 · [f(X/Xn) − f(Y/Yn)]
  ///   b* = 200 · [f(Y/Yn) − f(Z/Zn)]
  static LabColor _xyzToLab(double x, double y, double z) {
    final fx = _f(x / _xn);
    final fy = _f(y / _yn);
    final fz = _f(z / _zn);

    return LabColor(
      l: 116.0 * fy - 16.0,
      a: 500.0 * (fx - fy),
      b: 200.0 * (fy - fz),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert an sRGB triplet (each 0–255) to CIELAB (L*, a*, b*).
  ///
  /// This is the full pipeline:
  ///   sRGB → Linear RGB → XYZ (D65) → CIELAB
  static LabColor rgbToLab(double r, double g, double b) {
    // 1. Gamma expansion (sRGB → linear)
    final rLin = _srgbToLinear(r);
    final gLin = _srgbToLinear(g);
    final bLin = _srgbToLinear(b);

    // 2. Linear RGB → XYZ (D65 illuminant, scaled ×100)
    final xyz = _linearRgbToXyz(rLin, gLin, bLin);

    // 3. XYZ → CIELAB
    return _xyzToLab(xyz.x, xyz.y, xyz.z);
  }
}
