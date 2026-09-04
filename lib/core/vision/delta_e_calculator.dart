import 'dart:math' as math;
import 'color_space_converter.dart';
import 'color_extractor.dart';
import '../constants/exposure_thresholds.dart';
import '../../models/exposure_status.dart';

/// Result of a ΔE analysis pass.
class DeltaEResult {
  const DeltaEResult({
    required this.lab,
    required this.deltaE,
    required this.estimatedPpm,
    required this.status,
  });

  /// CIELAB values of the scanned sample.
  final LabColor lab;

  /// CIE76 Euclidean colour difference from the unexposed baseline.
  final double deltaE;

  /// Estimated cumulative H₂S exposure in ppm (via calibration curve).
  final double estimatedPpm;

  /// OSHA-mapped hazard classification.
  final ExposureStatus status;
}

/// Calculates the CIE76 ΔE* colour difference between a scanned dosimeter
/// sample and the unexposed (clean) baseline.
///
/// Formula (CIE76 / ISO 11664-4):
///
///   ΔE*₇₆ = √[ (L₂* − L₁*)² + (a₂* − a₁*)² + (b₂* − b₁*)² ]
///
/// Where:
///   (L₁*, a₁*, b₁*) = baseline (unexposed strip) — default: L*=95, a*=0, b*=5
///   (L₂*, a₂*, b₂*) = current scan sample
abstract final class DeltaECalculator {
  /// Compute ΔE from an already-extracted [RgbSample] and given baseline.
  ///
  /// [baselineL], [baselineA], [baselineB]: unexposed dosimeter CIELAB values.
  static DeltaEResult compute(
    RgbSample sample, {
    double baselineL = ExposureThresholds.baselineL,
    double baselineA = ExposureThresholds.baselineA,
    double baselineB = ExposureThresholds.baselineB,
  }) {
    // Convert sampled sRGB → CIELAB
    final lab = ColorSpaceConverter.rgbToLab(sample.r, sample.g, sample.b);

    // CIE76 ΔE Euclidean distance:
    //   ΔE = √[(L₂−L₁)² + (a₂−a₁)² + (b₂−b₁)²]
    final dL = lab.l - baselineL;
    final da = lab.a - baselineA;
    final db = lab.b - baselineB;
    final deltaE = math.sqrt(dL * dL + da * da + db * db);

    final estimatedPpm = ExposureThresholds.estimatePpm(deltaE);
    final status = ExposureThresholds.statusFromDeltaE(deltaE);

    return DeltaEResult(
      lab: lab,
      deltaE: deltaE,
      estimatedPpm: estimatedPpm,
      status: status,
    );
  }

  /// Convenience: compute baseline CIELAB for a freshly-captured calibration
  /// scan (an unexposed dosimeter strip).
  static LabColor computeBaseline(RgbSample sample) {
    return ColorSpaceConverter.rgbToLab(sample.r, sample.g, sample.b);
  }
}
