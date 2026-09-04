import 'package:flutter/material.dart';

/// Industrial OLED-optimized color palette for H₂S Detector.
/// Designed for maximum legibility in harsh industrial environments.
abstract final class AppColors {
  // ── Background & Surface ──────────────────────────────────────────────────
  /// True OLED black — primary background
  static const Color background = Color(0xFF0B0E14);

  /// Elevated surface / card background
  static const Color surface = Color(0xFF1E2638);

  /// Slightly lighter surface for nested cards
  static const Color surfaceVariant = Color(0xFF252D40);

  /// Divider / border color
  static const Color border = Color(0xFF2E3A54);

  // ── Status Colors ─────────────────────────────────────────────────────────
  /// Safe — ΔE < 5.0  (<1 ppm)
  static const Color safe = Color(0xFF00E676);
  static const Color safeBackground = Color(0xFF002E1A);

  /// Warning — 5.0 ≤ ΔE < 18.0  (1–19 ppm)
  static const Color warning = Color(0xFFFFD600);
  static const Color warningBackground = Color(0xFF2E2700);

  /// Critical — ΔE ≥ 18.0  (≥20 ppm, OSHA ceiling breached)
  static const Color critical = Color(0xFFFF1744);
  static const Color criticalBackground = Color(0xFF2E0008);

  // ── Text ──────────────────────────────────────────────────────────────────
  /// Primary text — near white for OLED readability
  static const Color textPrimary = Color(0xFFECF0F1);

  /// Secondary text — muted slate
  static const Color textSecondary = Color(0xFF8A9BBE);

  /// Disabled / hint text
  static const Color textDisabled = Color(0xFF3D4F6E);

  // ── Accent & Interactive ──────────────────────────────────────────────────
  /// Primary accent — electric blue for CTAs
  static const Color accent = Color(0xFF2979FF);
  static const Color accentDark = Color(0xFF1A4FCC);

  /// Reticle / targeting overlay
  static const Color reticle = Color(0xFF00E5FF);
  static const Color reticleDim = Color(0x4000E5FF);

  // ── Chart ─────────────────────────────────────────────────────────────────
  static const Color chartLine = Color(0xFF2979FF);
  static const Color chartFill = Color(0x222979FF);
  static const Color chartGridLine = Color(0xFF1E2638);
  static const Color chartThresholdSafe = Color(0xFF00E676);
  static const Color chartThresholdWarning = Color(0xFFFFD600);
  static const Color chartThresholdCritical = Color(0xFFFF1744);

  // ── Gradient presets ──────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B0E14), Color(0xFF111827)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
  );

  static LinearGradient safeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [safe.withValues(alpha: 0.15), safeBackground],
  );

  static LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning.withValues(alpha: 0.15), warningBackground],
  );

  static LinearGradient criticalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [critical.withValues(alpha: 0.15), criticalBackground],
  );
}
