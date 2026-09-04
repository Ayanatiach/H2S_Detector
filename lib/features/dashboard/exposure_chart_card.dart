import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/exposure_thresholds.dart';
import '../../models/dosimeter_reading.dart';
import '../../models/exposure_status.dart';
import '../../providers/readings_provider.dart';

/// `fl_chart` LineChart tracking ΔE shift across the current shift.
///
/// Features:
///   • Animated line from first scan to latest
///   • Dashed reference lines at ΔE=5 (safe) and ΔE=18 (warning) thresholds
///   • Custom tooltip showing ΔE and ppm
///   • Gradient fill under the data line
class ExposureChartCard extends ConsumerWidget {
  const ExposureChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(readingsHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.exposureTimeline.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${readings.length} reading${readings.length == 1 ? "" : "s"}',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Legend
          const Row(
            children: [
              _LegendDot(color: AppColors.safe, label: 'Safe <5'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.warning, label: 'Warning <18'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.critical, label: 'Critical ≥18'),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 200,
            child: readings.isEmpty
                ? _EmptyChart()
                : _Chart(readings: readings),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.readings});
  final List<DosimeterReading> readings;

  @override
  Widget build(BuildContext context) {
    // Reverse so oldest is on the left
    final ordered = readings.reversed.toList();

    final spots = List.generate(
      ordered.length,
      (i) => FlSpot(i.toDouble(), ordered[i].deltaE.clamp(0, 30).toDouble()),
    );

    return LineChart(
      duration: const Duration(milliseconds: 600),
      LineChartData(
        minY: 0,
        maxY: ExposureThresholds.chartMaxDeltaE,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (v) => const FlLine(
            color: AppColors.chartGridLine,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textDisabled, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: ordered.length > 1,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= ordered.length) {
                  return const SizedBox.shrink();
                }
                final dt = ordered[idx].createdAt;
                return Text(
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textDisabled, fontSize: 9),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        // Threshold reference lines
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: ExposureThresholds.safeMaxDeltaE,
              color: AppColors.safe.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'SAFE',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.safe, fontSize: 8, letterSpacing: 1),
              ),
            ),
            HorizontalLine(
              y: ExposureThresholds.warningMaxDeltaE,
              color: AppColors.warning.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'WARN',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.warning, fontSize: 8, letterSpacing: 1),
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.chartLine,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) {
                final reading = ordered[idx];
                return FlDotCirclePainter(
                  radius: 4,
                  color: reading.status.color,
                  strokeWidth: 2,
                  strokeColor: AppColors.background,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.chartLine.withValues(alpha: 0.25),
                  AppColors.chartLine.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceVariant,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final idx = spot.x.toInt().clamp(0, ordered.length - 1);
                final r = ordered[idx];
                return LineTooltipItem(
                  'ΔE ${r.deltaE.toStringAsFixed(1)}\n${r.estimatedPpm.toStringAsFixed(1)} ppm',
                  GoogleFonts.jetBrainsMono(
                    color: r.status.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart_rounded,
              color: AppColors.textDisabled, size: 40),
          const SizedBox(height: 12),
          Text(
            'No data yet — scan to begin',
            style: GoogleFonts.inter(
                color: AppColors.textDisabled, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.textDisabled, fontSize: 9, letterSpacing: 1)),
      ],
    );
  }
}
