import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/kinetic_theme.dart';
import 'features/shell/main_shell.dart';
import 'providers/theme_provider.dart';

/// Root application widget.
///
/// Configures:
///   • Kinetic Hazard Protocol Light & Dark Themes
///   • Global ThemeMode state tracking
///   • Main docked 4-tab shell navigation
class H2sDetectorApp extends ConsumerWidget {
  const H2sDetectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: KineticTheme.lightTheme,
      darkTheme: KineticTheme.darkTheme,
      themeMode: themeMode,
      home: const MainShellScreen(),
    );
  }
}
