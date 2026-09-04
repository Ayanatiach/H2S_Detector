import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Represents the OSHA-mapped exposure severity derived from ΔE computation.
enum ExposureStatus {
  /// ΔE < 5.0 → estimated <1 ppm cumulative exposure.
  safe,

  /// 5.0 ≤ ΔE < 18.0 → estimated 1–19 ppm cumulative exposure.
  warning,

  /// ΔE ≥ 18.0 → ≥20 ppm — OSHA 8-hr ceiling breached.
  critical,
}

extension ExposureStatusX on ExposureStatus {
  /// Human-readable display label shown in the status banner.
  String get label {
    return switch (this) {
      ExposureStatus.safe => 'SAFE',
      ExposureStatus.warning => 'ELEVATED',
      ExposureStatus.critical => 'DANGER',
    };
  }

  /// OSHA ppm description string.
  String get ppmRange {
    return switch (this) {
      ExposureStatus.safe => '< 1 ppm',
      ExposureStatus.warning => '1 – 19 ppm',
      ExposureStatus.critical => '≥ 20 ppm',
    };
  }

  /// Detailed regulatory note.
  String get regulatoryNote {
    return switch (this) {
      ExposureStatus.safe => 'Within OSHA permissible limits',
      ExposureStatus.warning => 'Approaching OSHA ceiling — monitor closely',
      ExposureStatus.critical => 'OSHA ceiling BREACHED — evacuate & report',
    };
  }

  /// Primary indicator color.
  Color get color {
    return switch (this) {
      ExposureStatus.safe => AppColors.safe,
      ExposureStatus.warning => AppColors.warning,
      ExposureStatus.critical => AppColors.critical,
    };
  }

  /// Background tint for status cards.
  Color get backgroundColor {
    return switch (this) {
      ExposureStatus.safe => AppColors.safeBackground,
      ExposureStatus.warning => AppColors.warningBackground,
      ExposureStatus.critical => AppColors.criticalBackground,
    };
  }

  /// Gradient for the status header card.
  LinearGradient get gradient {
    return switch (this) {
      ExposureStatus.safe => AppColors.safeGradient,
      ExposureStatus.warning => AppColors.warningGradient,
      ExposureStatus.critical => AppColors.criticalGradient,
    };
  }

  /// Icon for the status badge.
  IconData get icon {
    return switch (this) {
      ExposureStatus.safe => Icons.check_circle_rounded,
      ExposureStatus.warning => Icons.warning_amber_rounded,
      ExposureStatus.critical => Icons.dangerous_rounded,
    };
  }

  /// Serialize to/from Supabase text field.
  String get dbValue {
    return switch (this) {
      ExposureStatus.safe => 'safe',
      ExposureStatus.warning => 'warning',
      ExposureStatus.critical => 'critical',
    };
  }

  static ExposureStatus fromDbValue(String value) {
    return switch (value) {
      'warning' => ExposureStatus.warning,
      'critical' => ExposureStatus.critical,
      _ => ExposureStatus.safe,
    };
  }
}
