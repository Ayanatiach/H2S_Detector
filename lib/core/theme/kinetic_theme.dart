import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'kinetic_colors.dart';

/// Complete ThemeData builder for the Kinetic Hazard Protocol.
///
/// Implements typography (Barlow Condensed, Inter, JetBrains Mono),
/// high-contrast color schemes, and custom card/app bar styling
/// for both Light and Dark themes.
class KineticTheme {
  KineticTheme._();

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KineticColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: KineticColors.blazeOrange,
        onPrimary: Colors.white,
        primaryContainer: KineticColors.blazeOrangeDark,
        onPrimaryContainer: Colors.white,
        secondary: KineticColors.electricCyan,
        onSecondary: Color(0xFF00363A),
        secondaryContainer: KineticColors.cyanContainer,
        tertiary: KineticColors.cautionYellow,
        onTertiary: Color(0xFF373100),
        error: KineticColors.dangerRed,
        onError: Colors.white,
        surface: KineticColors.darkCard,
        onSurface: KineticColors.darkTextPrimary,
        outline: KineticColors.darkBorder,
      ),
      textTheme: _buildTextTheme(
        isDark: true,
        primaryColor: KineticColors.darkTextPrimary,
        secondaryColor: KineticColors.darkTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KineticColors.darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: KineticColors.darkTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: KineticColors.darkBg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: KineticColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KineticColors.darkBorderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KineticColors.darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KineticColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: KineticColors.darkBorder, width: 1),
        ),
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: KineticColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: KineticColors.blazeOrange,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFDBCE),
        onPrimaryContainer: KineticColors.blazeOrangeDark,
        secondary: KineticColors.cyanAlt,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFD3FBFF),
        tertiary: KineticColors.cautionYellowAlt,
        onTertiary: Color(0xFF373100),
        error: KineticColors.dangerRed,
        onError: Colors.white,
        surface: KineticColors.lightCard,
        onSurface: KineticColors.lightTextPrimary,
        outline: KineticColors.lightBorder,
      ),
      textTheme: _buildTextTheme(
        isDark: false,
        primaryColor: KineticColors.lightTextPrimary,
        secondaryColor: KineticColors.lightTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KineticColors.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: KineticColors.lightTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: KineticColors.lightBg,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: KineticColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KineticColors.lightBorderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KineticColors.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KineticColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: KineticColors.lightBorder, width: 1),
        ),
      ),
    );
  }

  // ── Typography System ─────────────────────────────────────────────────────
  static TextTheme _buildTextTheme({
    required bool isDark,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return TextTheme(
      // Athletic Headlines & Display (Barlow Condensed, heavy weights)
      displayLarge: GoogleFonts.barlowCondensed(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.barlowCondensed(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      headlineLarge: GoogleFonts.barlowCondensed(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.barlowCondensed(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: primaryColor,
      ),
      headlineSmall: GoogleFonts.barlowCondensed(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: primaryColor,
      ),

      // Monospace Technical Telemetry (JetBrains Mono)
      titleLarge: GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: primaryColor,
      ),
      titleSmall: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: secondaryColor,
      ),

      // Body Text & Descriptions (Inter)
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),

      // Label & Action Buttons (Barlow Condensed / JetBrains Mono)
      labelLarge: GoogleFonts.barlowCondensed(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: primaryColor,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: primaryColor,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: secondaryColor,
      ),
    );
  }
}
