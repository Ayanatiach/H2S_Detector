import 'package:flutter/material.dart';

/// Kinetic Hazard Protocol Color Palette.
///
/// Implements high-contrast athletic industrial design tokens defined in DESIGN.md.
class KineticColors {
  KineticColors._();

  // ── High-Impact Brand Accents ──────────────────────────────────────────
  /// Blaze Velocity Orange: Primary threshold, active tracking, primary CTAs, critical peaks
  static const Color blazeOrange = Color(0xFFFF5500);
  static const Color blazeOrangeLight = Color(0xFFFF5708);
  static const Color blazeOrangeDark = Color(0xFFE04800);
  static const Color blazeOrangeGlow = Color(0x73FF5500);

  /// Ion Electric Cyan: Tactical overlays, baseline ambient sweeps, sensor links
  static const Color electricCyan = Color(0xFF00F0FF);
  static const Color cyanAlt = Color(0xFF00B4D8);
  static const Color cyanContainer = Color(0xFF00EEFC);

  /// Radiation Caution Yellow: Advisory states, time-to-limit warnings
  static const Color cautionYellow = Color(0xFFFFE600);
  static const Color cautionYellowAlt = Color(0xFFDEC800);
  static const Color amber = Color(0xFFF59E0B);

  /// Emerald Safe Green: Safe readings, active telemetry status
  static const Color emeraldSafe = Color(0xFF10B981);
  static const Color emeraldSafeLight = Color(0xFF34D399);

  /// Critical Danger Red: Extreme ceiling breaches, emergency evacuation
  static const Color dangerRed = Color(0xFFF43F5E);
  static const Color redCritical = Color(0xFFEF4444);

  // ── Dark Mode Neutral Surfaces (Void Base) ──────────────────────────────
  static const Color darkBg = Color(0xFF131315);
  static const Color darkCanvas = Color(0xFF0E0E10);
  static const Color darkCard = Color(0xFF1C1B1D);
  static const Color darkCardAlt = Color(0xFF252427);
  static const Color darkSurfaceContainer = Color(0xFF201F21);
  static const Color darkSurfaceHigh = Color(0xFF2A2A2C);
  static const Color darkBorder = Color(0x1FFFFFFF); // rgba(255, 255, 255, 0.12)
  static const Color darkBorderSubtle = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color darkTextPrimary = Color(0xFFE5E1E4);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // ── Light Mode Neutral Surfaces (High-Contrast Industrial) ──────────────
  static const Color lightBg = Color(0xFFDDD5CD); // Sandstone industrial ground
  static const Color lightCanvas = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFF8F9FA);
  static const Color lightSurfaceContainer = Color(0xFFF1F5F9);
  static const Color lightSurfaceHigh = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0x33000000); // rgba(0, 0, 0, 0.12)
  static const Color lightBorderSubtle = Color(0x14000000); // rgba(0, 0, 0, 0.08)
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF6B7280);
}
