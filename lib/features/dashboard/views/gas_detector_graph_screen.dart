import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/kinetic_colors.dart';
import '../../../models/exposure_status.dart';
import '../../../providers/baseline_provider.dart';
import '../../../providers/readings_provider.dart';
import '../../../providers/theme_provider.dart';

enum TimeframeFilter {
  m15('15M'),
  h1('1H'),
  h8('8H'),
  h24('24H');

  const TimeframeFilter(this.label);
  final String label;
}

/// Full screen implementation of stitch_ai_h2s_gas_detector_graph (Dark & Light).
class GasDetectorGraphScreen extends ConsumerStatefulWidget {
  const GasDetectorGraphScreen({super.key});

  @override
  ConsumerState<GasDetectorGraphScreen> createState() =>
      _GasDetectorGraphScreenState();
}

class _GasDetectorGraphScreenState
    extends ConsumerState<GasDetectorGraphScreen> {
  TimeframeFilter _selectedTimeframe = TimeframeFilter.h1;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final latestReading = ref.watch(latestReadingProvider);
    final isCalibrated = ref.watch(baselineProvider).isCalibrated;

    final currentPpm = latestReading?.estimatedPpm ?? 0.08;
    final currentStatus = latestReading?.status ?? ExposureStatus.safe;
    final oshaPelPercent = ((currentPpm / 10.0) * 100).clamp(0, 100);

    final cardBg = isDark ? KineticColors.darkCard : KineticColors.lightCard;
    final borderCol =
        isDark ? KineticColors.darkBorderSubtle : KineticColors.lightBorderSubtle;
    final textCol =
        isDark ? KineticColors.darkTextPrimary : KineticColors.lightTextPrimary;
    final secondaryText = isDark
        ? KineticColors.darkTextSecondary
        : KineticColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Bar Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: RAD-NET LIVE, Sensor Paired, Theme Switch, Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? KineticColors.darkSurfaceContainer
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderCol),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: KineticColors.cyanAlt,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RAD-NET LIVE',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: textCol,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? KineticColors.darkSurfaceContainer
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderCol),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: KineticColors.blazeOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'SENSOR PAIRED',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Action buttons
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  ref.read(themeModeProvider.notifier).toggleTheme(),
                              icon: Icon(
                                isDark
                                    ? Icons.wb_sunny_rounded
                                    : Icons.nightlight_round,
                                color: isDark
                                    ? KineticColors.cautionYellow
                                    : KineticColors.darkCard,
                                size: 20,
                              ),
                              tooltip: isDark
                                  ? 'Switch to Light Theme'
                                  : 'Switch to Dark Theme',
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? KineticColors.darkSurfaceContainer
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: isDark
                                  ? KineticColors.darkSurfaceHigh
                                  : KineticColors.lightSurfaceHigh,
                              child: Icon(
                                Icons.person_rounded,
                                color: textCol,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'H2S GAS DETECTOR',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: textCol,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: KineticColors.emeraldSafe.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: KineticColors.emeraldSafe.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: KineticColors.emeraldSafe,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'H2S SENSOR OK',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: KineticColors.emeraldSafe,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Identity Strip ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderCol),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: KineticColors.cyanAlt,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'STITCH AI // H2S DETECTOR',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderCol),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sensors_rounded, size: 12, color: secondaryText),
                          const SizedBox(width: 5),
                          Text(
                            '#H2S-9418 · NDIR',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Primary Metric Hero Card ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card subhead
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.science_rounded,
                                  size: 16, color: KineticColors.cyanAlt),
                              const SizedBox(width: 6),
                              Text(
                                'HYDROGEN SULFIDE [H₂S]',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(currentStatus).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _getStatusColor(currentStatus).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _getStatusLabel(currentStatus),
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: _getStatusColor(currentStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Giant readout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currentPpm.toStringAsFixed(2),
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: textCol,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PPM',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: KineticColors.emeraldSafe.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: KineticColors.emeraldSafe.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '${oshaPelPercent.toStringAsFixed(0)}% OSHA PEL',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: KineticColors.emeraldSafe,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Standard: 10.0 ppm',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // OSHA PEL Progress Strip
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? KineticColors.darkCardAlt
                              : KineticColors.lightCardAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'OSHA PEL: 10.0 PPM',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: secondaryText,
                                  ),
                                ),
                                Text(
                                  'CEILING: 20.0 PPM',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: KineticColors.blazeOrange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (currentPpm / 20.0).clamp(0.02, 1.0),
                                minHeight: 7,
                                backgroundColor: isDark
                                    ? KineticColors.darkSurfaceContainer
                                    : Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation(
                                  currentPpm > 10.0
                                      ? KineticColors.dangerRed
                                      : currentPpm > 5.0
                                          ? KineticColors.amber
                                          : KineticColors.cyanAlt,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Live H2S Concentration Trend Card ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Timeframe filters
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.show_chart_rounded,
                                    size: 18, color: textCol),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'CONCENTRATION TREND',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.barlowCondensed(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: textCol,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? KineticColors.darkCardAlt
                                  : KineticColors.lightCardAlt,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: TimeframeFilter.values.map((tf) {
                                final isSelected = tf == _selectedTimeframe;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedTimeframe = tf),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? KineticColors.blazeOrange
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      tf.label,
                                      style: GoogleFonts.barlowCondensed(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : secondaryText,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Threshold Alert Subhead
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PAST ${_selectedTimeframe.label} TELEMETRY',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: secondaryText,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 2,
                                color: KineticColors.blazeOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '1.00 PPM ALARM LVL 1',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: KineticColors.blazeOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Visual Graph Box
                      Container(
                        height: 170,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? KineticColors.darkBg
                              : const Color(0xFFE8DFD7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderCol),
                        ),
                        child: Stack(
                          children: [
                            // Custom Painter Graph
                            CustomPaint(
                              size: const Size(double.infinity, 170),
                              painter: _TrendGraphPainter(
                                currentPpm: currentPpm,
                                isDark: isDark,
                              ),
                            ),

                            // Live Pill overlay on graph
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cardBg.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderCol),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: KineticColors.cyanAlt,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${currentPpm.toStringAsFixed(2)} PPM (LIVE)',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: textCol,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom time axis labels
                            Positioned(
                              bottom: 6,
                              left: 12,
                              right: 12,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '14:00',
                                    style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9, color: secondaryText),
                                  ),
                                  Text(
                                    '14:20',
                                    style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9, color: secondaryText),
                                  ),
                                  Text(
                                    '14:40',
                                    style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9, color: secondaryText),
                                  ),
                                  Text(
                                    '15:00',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: KineticColors.cyanAlt,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 2x2 Environmental & Sensor Diagnostics Grid ─────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _buildDiagnosticTile(
                    title: 'SENSOR TEMP',
                    value: '24.2',
                    unit: '°C',
                    subtext: 'NOMINAL',
                    subtextColor: KineticColors.emeraldSafe,
                    icon: Icons.thermostat_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    secondaryText: secondaryText,
                  ),
                  _buildDiagnosticTile(
                    title: 'HUMIDITY',
                    value: '48.0',
                    unit: '%',
                    subtext: 'OPTIMAL',
                    subtextColor: KineticColors.emeraldSafe,
                    icon: Icons.water_drop_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    secondaryText: secondaryText,
                  ),
                  _buildDiagnosticTile(
                    title: 'BATTERY',
                    value: '87',
                    unit: '%',
                    subtext: '9.4 HRS LEFT',
                    subtextColor: KineticColors.cyanAlt,
                    icon: Icons.battery_charging_full_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    secondaryText: secondaryText,
                  ),
                  _buildDiagnosticTile(
                    title: 'CALIBRATION',
                    value: isCalibrated ? '99.2' : 'NOT CAL',
                    unit: isCalibrated ? '%' : '',
                    subtext: isCalibrated ? 'CALIBRATED TODAY' : 'PENDING CHECK',
                    subtextColor: isCalibrated
                        ? KineticColors.emeraldSafe
                        : KineticColors.amber,
                    icon: Icons.verified_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    secondaryText: secondaryText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticTile({
    required String title,
    required String value,
    required String unit,
    required String subtext,
    required Color subtextColor,
    required IconData icon,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: secondaryText,
                ),
              ),
              Icon(icon, size: 15, color: subtextColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textCol,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: secondaryText,
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: subtextColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                subtext,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ExposureStatus status) {
    switch (status) {
      case ExposureStatus.safe:
        return KineticColors.emeraldSafe;
      case ExposureStatus.warning:
        return KineticColors.amber;
      case ExposureStatus.critical:
        return KineticColors.dangerRed;
    }
  }

  String _getStatusLabel(ExposureStatus status) {
    switch (status) {
      case ExposureStatus.safe:
        return 'NORMAL / SAFE';
      case ExposureStatus.warning:
        return 'ELEVATED / WARN';
      case ExposureStatus.critical:
        return 'CRITICAL / EVAC';
    }
  }
}

class _TrendGraphPainter extends CustomPainter {
  const _TrendGraphPainter({
    required this.currentPpm,
    required this.isDark,
  });

  final double currentPpm;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..strokeWidth = 1.0;

    final dashPaint = Paint()
      ..color = KineticColors.blazeOrange.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // 1.00 PPM Alarm threshold dashed line
    final alarmY = h * 0.25;
    for (double x = 0; x < w; x += 8) {
      canvas.drawLine(Offset(x, alarmY), Offset(x + 4, alarmY), dashPaint);
    }

    // Horizontal baseline
    canvas.drawLine(Offset(0, h * 0.55), Offset(w, h * 0.55), gridPaint);
    canvas.drawLine(Offset(0, h * 0.85), Offset(w, h * 0.85), gridPaint);

    // Build curve points
    final points = [
      Offset(10, h * 0.82),
      Offset(w * 0.22, h * 0.78),
      Offset(w * 0.45, h * 0.65),
      Offset(w * 0.68, h * 0.72),
      Offset(w * 0.85, h * 0.76),
      Offset(w * 0.96, (h * 0.85) - ((currentPpm / 2.0) * h * 0.6).clamp(0, h * 0.65)),
    ];

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Fill gradient
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, h * 0.9)
      ..lineTo(points.first.dx, h * 0.9)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          KineticColors.cyanAlt.withValues(alpha: 0.35),
          KineticColors.blazeOrange.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = KineticColors.cyanAlt
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Endpoint pulsating dot
    final endPoint = points.last;
    canvas.drawCircle(
        endPoint, 6.0, Paint()..color = KineticColors.cyanAlt.withValues(alpha: 0.3));
    canvas.drawCircle(endPoint, 3.5, Paint()..color = KineticColors.cyanAlt);
    canvas.drawCircle(
      endPoint,
      3.5,
      Paint()
        ..color = isDark ? KineticColors.darkBg : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendGraphPainter oldDelegate) {
    return oldDelegate.currentPpm != currentPpm ||
        oldDelegate.isDark != isDark;
  }
}
