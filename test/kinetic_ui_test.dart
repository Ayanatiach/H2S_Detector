import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:h2s_sentinel/core/theme/kinetic_colors.dart';
import 'package:h2s_sentinel/core/theme/kinetic_theme.dart';
import 'package:h2s_sentinel/providers/theme_provider.dart';
import 'package:h2s_sentinel/providers/worker_provider.dart';
import 'package:h2s_sentinel/features/team/providers/team_provider.dart';
import 'package:h2s_sentinel/features/team/views/team_safety_screen.dart';
import 'package:h2s_sentinel/features/dashboard/views/gas_detector_graph_screen.dart';
import 'package:h2s_sentinel/features/shell/main_shell.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Kinetic Theme & Design Tokens Tests', () {
    testWidgets('Dark theme configured with OLED void surfaces & high-impact accents', (tester) async {
      final dark = KineticTheme.darkTheme;
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, KineticColors.darkBg);
      expect(dark.colorScheme.primary, KineticColors.blazeOrange);
      expect(dark.colorScheme.secondary, KineticColors.electricCyan);
      expect(dark.colorScheme.error, KineticColors.dangerRed);
    });

    testWidgets('Light theme configured with high-contrast surfaces', (tester) async {
      final light = KineticTheme.lightTheme;
      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, KineticColors.lightBg);
      expect(light.colorScheme.primary, KineticColors.blazeOrange);
    });

    test('themeModeProvider toggles between dark and light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);
      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('Team Safety & Roster Provider Tests', () {
    test('Initializes with on-site workers and calculates accurate metrics', () {
      final container = ProviderContainer(
        overrides: [workerIdProvider.overrideWithValue('TEST-OP-01')],
      );
      addTearDown(container.dispose);

      final state = container.read(teamProvider);
      expect(state.members.length, 8);
      expect(state.safeCount, 5);
      expect(state.warningCount, 3);
      expect(state.averageShiftDose, greaterThan(0.0));

      // Filter by warning
      container.read(teamProvider.notifier).setFilter(TeamFilter.warning);
      expect(container.read(teamProvider).filteredMembers.length, 3);

      // Filter by safe
      container.read(teamProvider.notifier).setFilter(TeamFilter.safe);
      expect(container.read(teamProvider).filteredMembers.length, 5);
    });
  });

  group('Kinetic UI Widget Tests', () {
    testWidgets('TeamSafetyScreen renders header, metrics, and workers in Dark theme', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workerIdProvider.overrideWithValue('TEST-OP-01')],
          child: MaterialApp(
            theme: KineticTheme.darkTheme,
            home: const TeamSafetyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TEAM SAFETY'), findsOneWidget);
      expect(find.text('FACILITY 09'), findsOneWidget);
      expect(find.text('RAD-NET LIVE'), findsOneWidget);
      expect(find.text('ON-SITE PERSONNEL'), findsOneWidget);
      expect(find.text('8 Workers Active'), findsOneWidget);
      expect(find.text('D. Vance'), findsOneWidget);
      expect(find.text('S. Chen'), findsOneWidget);
    });

    testWidgets('GasDetectorGraphScreen renders concentration hero card and diagnostics', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workerIdProvider.overrideWithValue('TEST-OP-01')],
          child: MaterialApp(
            theme: KineticTheme.darkTheme,
            home: const GasDetectorGraphScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('H2S GAS DETECTOR'), findsOneWidget);
      expect(find.text('H2S SENSOR OK'), findsOneWidget);
      expect(find.text('HYDROGEN SULFIDE [H₂S]'), findsOneWidget);
      expect(find.text('CONCENTRATION TREND'), findsOneWidget);
      expect(find.text('SENSOR TEMP'), findsOneWidget);
      expect(find.text('HUMIDITY'), findsOneWidget);
      expect(find.text('BATTERY'), findsOneWidget);
    });

    testWidgets('MainShellScreen renders 4 docked athletic navigation tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workerIdProvider.overrideWithValue('TEST-OP-01')],
          child: MaterialApp(
            theme: KineticTheme.darkTheme,
            home: const MainShellScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ZONES'), findsOneWidget);
      expect(find.text('SCAN'), findsOneWidget);
      expect(find.text('TEAM'), findsOneWidget);
      expect(find.text('LOGS'), findsOneWidget);

      // Tap TEAM tab
      await tester.tap(find.text('TEAM'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TEAM SAFETY'), findsOneWidget);

      // Tap LOGS tab
      await tester.tap(find.text('LOGS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CONCENTRATION TREND'), findsOneWidget);
    });
  });
}
