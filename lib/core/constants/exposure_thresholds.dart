import '../../models/exposure_status.dart';

/// Thresholds and calibration constants for the H₂S dosimeter CIELAB engine.
///
/// Reference: OSHA 29 CFR 1910.1000 Table Z-2 — H₂S ceiling limits.
/// Colorimetric calibration based on standard Dräger/MSA passive dosimeter
/// colour development curves.
abstract final class ExposureThresholds {
  // ── ΔE Thresholds (CIE76 Euclidean distance) ─────────────────────────────

  /// ΔE below this value → SAFE zone (< 1 ppm cumulative)
  static const double safeMaxDeltaE = 5.0;

  /// ΔE below this value → WARNING zone (1–19 ppm)
  /// ΔE at or above this value → CRITICAL (≥ 20 ppm)
  static const double warningMaxDeltaE = 18.0;

  // ── Baseline CIELAB (unexposed dosimeter substrate) ───────────────────────
  /// Default baseline L* — near-white / pale cream substrate
  static const double baselineL = 95.0;

  /// Default baseline a* — very slight red-green balance
  static const double baselineA = 0.0;

  /// Default baseline b* — slight warm yellow tint of unloaded paper
  static const double baselineB = 5.0;

  // ── Lighting ──────────────────────────────────────────────────────────────
  /// Luminance threshold below which we show a low-light warning.
  /// Expressed as a 0–255 mean channel value of the full frame.
  static const double minAcceptableLuminance = 60.0;

  // ── Chart ─────────────────────────────────────────────────────────────────
  /// Maximum Y-axis value for the exposure chart.
  static const double chartMaxDeltaE = 30.0;

  // ── Calibration Curve: ΔE → estimated ppm ────────────────────────────────
  /// Linear calibration mapping from CIE76 ΔE to cumulative estimated H₂S exposure (ppm).
  ///
  /// Response zones:
  ///   • 0 ≤ ΔE < 5.0  → 0.0 to 0.9 ppm (Safe baseline)
  ///   • 5.0 ≤ ΔE < 18.0 → 1.0 to 19.0 ppm (Elevated / warning zone)
  ///   • ΔE ≥ 18.0     → 20.0+ ppm (Critical / OSHA Ceiling & Peak).
  ///     Continues linearly with a constant slope of 2.5 ppm per ΔE unit:
  ///     ΔE = 18.0 → 20 ppm
  ///     ΔE = 30.0 → 50 ppm
  ///     ΔE = 46.0 → 90 ppm
  ///     ΔE = 50.0 → 100 ppm
  static double estimatePpm(double deltaE) {
    if (deltaE <= 0.0) return 0.0;
    if (deltaE < safeMaxDeltaE) {
      // Linear 0→0.9 ppm over ΔE 0→5
      return (deltaE / safeMaxDeltaE) * 0.9;
    } else if (deltaE < warningMaxDeltaE) {
      // Linear 1→19 ppm over ΔE 5→18
      final t = (deltaE - safeMaxDeltaE) / (warningMaxDeltaE - safeMaxDeltaE);
      return 1.0 + t * 18.0;
    } else {
      // Continuous linear response without ceiling clamping:
      // Slope: (50 - 20) / (30 - 18) = 2.5 ppm / ΔE
      return 20.0 + (deltaE - warningMaxDeltaE) * 2.5;
    }
  }

  /// Inverse calibration mapping: estimated ppm → ΔE.
  static double deltaEFromPpm(double ppm) {
    if (ppm <= 0.0) return 0.0;
    if (ppm < 0.9) {
      return (ppm / 0.9) * safeMaxDeltaE;
    } else if (ppm < 20.0) {
      final t = (ppm - 1.0) / 18.0;
      return safeMaxDeltaE + t * (warningMaxDeltaE - safeMaxDeltaE);
    } else {
      return warningMaxDeltaE + (ppm - 20.0) / 2.5;
    }
  }

  /// Calculates dynamic maximum Y-axis value for charts ensuring headroom and clean tick steps.
  static double computeChartMax(double maxObserved, {double baselineMax = 30.0}) {
    if (maxObserved <= baselineMax * 0.85) {
      return baselineMax;
    }
    // Add ~15% headroom and round up to a clean step
    final rawTarget = maxObserved * 1.15;
    final step = rawTarget > 120.0 ? 25.0 : (rawTarget > 60.0 ? 20.0 : 10.0);
    return (rawTarget / step).ceil() * step;
  }

  /// Determine [ExposureStatus] from a raw ΔE value.
  static ExposureStatus statusFromDeltaE(double deltaE) {
    if (deltaE < safeMaxDeltaE) return ExposureStatus.safe;
    if (deltaE < warningMaxDeltaE) return ExposureStatus.warning;
    return ExposureStatus.critical;
  }
}
