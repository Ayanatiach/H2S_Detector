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
  /// Linear interpolation mapping for display purposes.
  /// This is a simplified model; production calibration should use a
  /// polynomial fit derived from empirical dosimeter data.
  static double estimatePpm(double deltaE) {
    if (deltaE < safeMaxDeltaE) {
      // Linear 0→0.9 ppm over ΔE 0→5
      return (deltaE / safeMaxDeltaE) * 0.9;
    } else if (deltaE < warningMaxDeltaE) {
      // Linear 1→19 ppm over ΔE 5→18
      final t = (deltaE - safeMaxDeltaE) / (warningMaxDeltaE - safeMaxDeltaE);
      return 1.0 + t * 18.0;
    } else {
      // Linear 20→50 ppm over ΔE 18→30
      final t = ((deltaE - warningMaxDeltaE) / 12.0).clamp(0.0, 1.0);
      return 20.0 + t * 30.0;
    }
  }

  /// Determine [ExposureStatus] from a raw ΔE value.
  static ExposureStatus statusFromDeltaE(double deltaE) {
    if (deltaE < safeMaxDeltaE) return ExposureStatus.safe;
    if (deltaE < warningMaxDeltaE) return ExposureStatus.warning;
    return ExposureStatus.critical;
  }
}
