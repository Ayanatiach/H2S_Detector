import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/kinetic_colors.dart';
import 'features/shell/main_shell.dart';
import 'providers/theme_provider.dart';

/// Root application widget.
///
/// Configures:
///   • Full dark + light theme pair from [AppColors] / [KineticColors] palettes
///   • [themeModeProvider] drives [MaterialApp.themeMode] so the toggle button
///     in the shell actually switches themes
///   • JetBrains Mono / Inter typography via [google_fonts]
///   • Launches into [MainShellScreen] (index 3 = LOGS / H₂S Gas Detector Graph)
class H2sDetectorApp extends ConsumerWidget {
  const H2sDetectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Force system UI to match theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? KineticColors.darkBg : KineticColors.lightBg,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      // Home is the 4-tab shell; index 3 = LOGS (H₂S Gas Detector Graph)
      home: const MainShellScreen(initialIndex: 3),
    );
  }

  // ── Dark Theme (OLED Kinetic Hazard Protocol) ─────────────────────────────
  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: KineticColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: KineticColors.blazeOrange,
        secondary: KineticColors.electricCyan,
        surface: KineticColors.darkCard,
        error: KineticColors.dangerRed,
        onPrimary: Colors.white,
        onSurface: KineticColors.darkTextPrimary,
        outline: KineticColors.darkBorder,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.barlowCondensed(
            color: KineticColors.darkTextPrimary,
            fontWeight: FontWeight.w900),
        headlineLarge: GoogleFonts.barlowCondensed(
            color: KineticColors.darkTextPrimary,
            fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.barlowCondensed(
            color: KineticColors.darkTextPrimary,
            fontWeight: FontWeight.w700),
        labelLarge: GoogleFonts.jetBrainsMono(
            color: KineticColors.darkTextPrimary, letterSpacing: 1.5),
        bodyLarge: GoogleFonts.inter(color: KineticColors.darkTextPrimary),
        bodyMedium: GoogleFonts.inter(color: KineticColors.darkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KineticColors.darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.barlowCondensed(
          color: KineticColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        iconTheme:
            const IconThemeData(color: KineticColors.darkTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: KineticColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
              color: KineticColors.darkBorderSubtle, width: 0.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KineticColors.darkCard,
        contentTextStyle: GoogleFonts.inter(
            color: KineticColors.darkTextPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KineticColors.darkCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: KineticColors.darkBorderSubtle,
        thickness: 0.5,
      ),
    );
  }

  // ── Light Theme (Industrial High-Contrast) ────────────────────────────────
  ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: KineticColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: KineticColors.blazeOrange,
        secondary: KineticColors.electricCyan,
        surface: KineticColors.lightCard,
        error: KineticColors.dangerRed,
        onPrimary: Colors.white,
        onSurface: KineticColors.lightTextPrimary,
        outline: KineticColors.lightBorder,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.barlowCondensed(
            color: KineticColors.lightTextPrimary,
            fontWeight: FontWeight.w900),
        headlineLarge: GoogleFonts.barlowCondensed(
            color: KineticColors.lightTextPrimary,
            fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.barlowCondensed(
            color: KineticColors.lightTextPrimary,
            fontWeight: FontWeight.w700),
        labelLarge: GoogleFonts.jetBrainsMono(
            color: KineticColors.lightTextPrimary, letterSpacing: 1.5),
        bodyLarge: GoogleFonts.inter(color: KineticColors.lightTextPrimary),
        bodyMedium:
            GoogleFonts.inter(color: KineticColors.lightTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KineticColors.lightCanvas,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.barlowCondensed(
          color: KineticColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        iconTheme:
            const IconThemeData(color: KineticColors.lightTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: KineticColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
              color: KineticColors.lightBorderSubtle, width: 0.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KineticColors.lightCard,
        contentTextStyle: GoogleFonts.inter(
            color: KineticColors.lightTextPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KineticColors.lightCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: KineticColors.lightBorderSubtle,
        thickness: 0.5,
      ),
    );
  }
}

