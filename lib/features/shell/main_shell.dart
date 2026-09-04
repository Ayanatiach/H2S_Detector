import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kinetic_colors.dart';
import '../../providers/baseline_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/calibration_required_dialog.dart';
import '../dashboard/views/gas_detector_graph_screen.dart';
import '../map/views/facility_map.dart';
import '../scanner/scanner_screen.dart';
import '../team/views/team_safety_screen.dart';

/// Main Shell hosting the docked athletic 4-tab navigation:
///   1. ZONES (Facility Radar Map)
///   2. SCAN (Center elevated Blaze Orange action)
///   3. TEAM (Team Safety & Active Personnel Roster)
///   4. LOGS (H2S Concentration Trend & Telemetry Diagnostics)
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      _openScanner();
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _openScanner() async {
    final isCalibrated = ref.read(baselineProvider).isCalibrated;
    if (!isCalibrated) {
      final shouldCalibrate = await showCalibrationRequiredDialog(context);
      if (shouldCalibrate == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ScannerScreen(isCalibrationMode: true),
          ),
        );
      }
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ScannerScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final navBg = isDark ? KineticColors.darkBg : KineticColors.lightCard;
    final navBorder =
        isDark ? KineticColors.darkBorderSubtle : KineticColors.lightBorderSubtle;

    return Scaffold(
      body: Stack(
        children: [
          // ── Active Tab View ───────────────────────────────────────────────
          IndexedStack(
            index: _currentIndex,
            children: const [
              FacilityMapScreen(), // 0: ZONES
              SizedBox.shrink(), // 1: Center Scan CTA placeholder
              TeamSafetyScreen(), // 2: TEAM
              GasDetectorGraphScreen(), // 3: LOGS
            ],
          ),

          // ── Docked Athletic Bottom Navigation Bar ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              decoration: BoxDecoration(
                color: navBg.withValues(alpha: 0.96),
                border: Border(top: BorderSide(color: navBorder, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Tab 0: ZONES
                  _buildNavItem(
                    index: 0,
                    label: 'ZONES',
                    icon: Icons.radar_rounded,
                    isActive: _currentIndex == 0,
                    isDark: isDark,
                  ),

                  // Tab 1: SCAN (Elevated Center Button)
                  _buildCenterScanButton(),

                  // Tab 2: TEAM
                  _buildNavItem(
                    index: 2,
                    label: 'TEAM',
                    icon: Icons.group_rounded,
                    isActive: _currentIndex == 2,
                    isDark: isDark,
                  ),

                  // Tab 3: LOGS
                  _buildNavItem(
                    index: 3,
                    label: 'LOGS',
                    icon: Icons.show_chart_rounded,
                    isActive: _currentIndex == 3,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isDark,
  }) {
    const activeColor = KineticColors.blazeOrange;
    final inactiveColor =
        isDark ? KineticColors.darkTextMuted : KineticColors.lightTextMuted;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.barlowCondensed(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0.8,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterScanButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(1),
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: KineticColors.blazeOrange,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: KineticColors.blazeOrange.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.filter_center_focus_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SCAN',
              style: GoogleFonts.barlowCondensed(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: KineticColors.blazeOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
