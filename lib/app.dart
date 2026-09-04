import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'features/dashboard/dashboard_screen.dart';

/// Root application widget.
///
/// Configures:
///   • Dark OLED theme with [AppColors] palette
///   • JetBrains Mono / Inter typography via [google_fonts]
///   • Status bar and navigation bar overlay styling
class H2sDetectorApp extends StatelessWidget {
  const H2sDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Force OLED-style system UI
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const DashboardScreen(),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.reticle,
        surface: AppColors.surface,
        error: AppColors.critical,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.jetBrainsMono(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.jetBrainsMono(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.inter(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(color: AppColors.textSecondary),
        labelLarge: GoogleFonts.jetBrainsMono(
            color: AppColors.textPrimary, letterSpacing: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.jetBrainsMono(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle:
            GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
      ),
    );
  }
}
