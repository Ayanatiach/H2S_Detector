import 'dart:math' as math;
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

enum ChartMetric { ppm, deltaE }

/// `fl_chart` LineChart tracking cumulative H₂S exposure across the shift.
///
/// Features:
///   • Scalable dynamic Y-axis (scales smoothly to 50, 90, 100+ ppm without ceiling truncation)
///   • Clearly marks out peak and high-exposure points with glowing radar rings and callout pills
///   • OSHA regulatory reference lines (1 ppm safe, 20 ppm ceiling, 50 ppm 10-min peak)
///   • Toggle between PPM (toxicological standard) and ΔE (colorimetric distance)
///   • Monospace industrial telemetry styling
class ExposureChartCard extends ConsumerStatefulWidget {
  const ExposureChartCard({super.key});

  @override
  ConsumerState<ExposureChartCard> createState() => _ExposureChartCardState();
}

class _ExposureChartCardState extends ConsumerState<ExposureChartCard> {
  ChartMetric _metric = ChartMetric.ppm;

  @override
  Widget build(BuildContext context) {
    final readings = ref.watch(readingsHistoryProvider);

    // Compute peak value for header callout
    final isPpm = _metric == ChartMetric.ppm;
    final peakVal = readings.isEmpty
        ? 0.0
        : readings
            .map((r) => isPpm ? r.estimatedPpm : r.deltaE)
            .fold(0.0, math.max);

    final peakStatus = isPpm
        ? (peakVal >= 20.0
            ? ExposureStatus.critical
            : (peakVal >= 1.0 ? ExposureStatus.warning : ExposureStatus.safe))
        : ExposureThresholds.statusFromDeltaE(peakVal);

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
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      AppStrings.exposureTimeline.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (readings.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: peakStatus.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: peakStatus.color.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              peakVal >= 20.0 && isPpm
                                  ? Icons.warning_amber_rounded
                                  : Icons.trending_up_rounded,
                              color: peakStatus.color,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'PEAK ${peakVal.toStringAsFixed(1)} ${isPpm ? "PPM" : "ΔE"}',
                              style: GoogleFonts.jetBrainsMono(
                                color: peakStatus.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Metric Toggle (PPM vs ΔE)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.6),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetricPill(
                      label: 'PPM',
                      selected: _metric == ChartMetric.ppm,
                      onTap: () => setState(() => _metric = ChartMetric.ppm),
                    ),
                    _MetricPill(
                      label: 'ΔE',
                      selected: _metric == ChartMetric.deltaE,
                      onTap: () => setState(() => _metric = ChartMetric.deltaE),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendDot(
                color: AppColors.safe,
                label: isPpm ? 'Safe <1' : 'Safe <5',
              ),
              _LegendDot(
                color: AppColors.warning,
                label: isPpm ? 'Warn 1–19' : 'Warn <18',
              ),
              _LegendDot(
                color: AppColors.critical,
                label: isPpm ? 'Ceiling ≥20' : 'Critical ≥18',
              ),
              if (readings.length > 1)
                const _LegendDot(
                  color: Colors.white,
                  label: '★ Peak',
                  hasHalo: true,
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 215,
            child: readings.isEmpty
                ? _EmptyChart()
                : _Chart(readings: readings, metric: _metric),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: selected ? Colors.white : AppColors.textDisabled,
            fontSize: 9,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.readings, required this.metric});
  final List<DosimeterReading> readings;
  final ChartMetric metric;

  @override
  Widget build(BuildContext context) {
    // Reverse so oldest is on the left
    final ordered = readings.reversed.toList();
    final isPpm = metric == ChartMetric.ppm;

    // Determine values and locate peak point
    int peakIndex = 0;
    double maxObserved = 0.0;
    for (int i = 0; i < ordered.length; i++) {
      final v = isPpm ? ordered[i].estimatedPpm : ordered[i].deltaE;
      if (v > maxObserved) {
        maxObserved = v;
        peakIndex = i;
      }
    }

    // Dynamic scalable maximum:
    // If exposure exceeds baseline (30), smoothly scale up to 50, 90, 100+ with headroom
    final double maxY = ExposureThresholds.computeChartMax(
      maxObserved,
      baselineMax: ExposureThresholds.chartMaxDeltaE,
    );

    // Dynamic horizontal grid interval
    final double interval;
    if (maxY <= 35) {
      interval = 5;
    } else if (maxY <= 70) {
      interval = 10;
    } else if (maxY <= 140) {
      interval = 20;
    } else {
      interval = 50;
    }

    final spots = List.generate(
      ordered.length,
      (i) => FlSpot(
        i.toDouble(),
        isPpm ? ordered[i].estimatedPpm : ordered[i].deltaE,
      ),
    );

    // Reference lines
    final List<HorizontalLine> refLines;
    if (isPpm) {
      refLines = [
        HorizontalLine(
          y: 1.0,
          color: AppColors.safe.withValues(alpha: 0.35),
          strokeWidth: 1,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            labelResolver: (_) => 'SAFE 1ppm',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.safe,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ),
        HorizontalLine(
          y: 20.0,
          color: AppColors.critical.withValues(alpha: 0.45),
          strokeWidth: 1.2,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            labelResolver: (_) => 'CEILING 20ppm',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.critical,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (maxY >= 55.0)
          HorizontalLine(
            y: 50.0,
            color: const Color(0xFFFF5252).withValues(alpha: 0.5),
            strokeWidth: 1.2,
            dashArray: [4, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              labelResolver: (_) => 'PEAK 50ppm',
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFFF5252),
                fontSize: 8,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ];
    } else {
      refLines = [
        HorizontalLine(
          y: ExposureThresholds.safeMaxDeltaE,
          color: AppColors.safe.withValues(alpha: 0.35),
          strokeWidth: 1,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            labelResolver: (_) => 'SAFE 5ΔE',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.safe,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ),
        HorizontalLine(
          y: ExposureThresholds.warningMaxDeltaE,
          color: AppColors.warning.withValues(alpha: 0.45),
          strokeWidth: 1.2,
          dashArray: [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            labelResolver: (_) => 'WARN 18ΔE',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.warning,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ];
    }

    return LineChart(
      duration: const Duration(milliseconds: 500),
      LineChartData(
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.none(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
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
              interval: interval,
              reservedSize: 34,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
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
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textDisabled,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: refLines),
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
                final isPeak = idx == peakIndex && ordered.length > 1;
                final val = isPpm ? reading.estimatedPpm : reading.deltaE;

                if (isPeak) {
                  return _PeakMarkerDotPainter(
                    color: reading.status.color,
                    value: val,
                    unit: isPpm ? 'ppm' : 'ΔE',
                  );
                }

                final isHigh = isPpm
                    ? reading.estimatedPpm >= 20.0
                    : reading.deltaE >= ExposureThresholds.warningMaxDeltaE;

                if (isHigh) {
                  return FlDotCirclePainter(
                    radius: 5.5,
                    color: reading.status.color,
                    strokeWidth: 2.0,
                    strokeColor: Colors.white,
                  );
                }

                return FlDotCirclePainter(
                  radius: 3.5,
                  color: reading.status.color,
                  strokeWidth: 1.5,
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
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt().clamp(0, ordered.length - 1);
                final r = ordered[idx];
                final isPeakPoint = idx == peakIndex;
                final peakPrefix = isPeakPoint ? '★ SHIFT PEAK\n' : '';
                return LineTooltipItem(
                  '$peakPrefix${r.estimatedPpm.toStringAsFixed(1)} ppm\nΔE ${r.deltaE.toStringAsFixed(1)} • ${r.status.label}',
                  GoogleFonts.jetBrainsMono(
                    color: r.status.color,
                    fontSize: 10,
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

/// Custom [FlDotPainter] that draws a glowing halo and floating callout pill
/// marking out the peak exposure point directly on the graph.
class _PeakMarkerDotPainter extends FlDotPainter {
  _PeakMarkerDotPainter({
    required this.color,
    required this.value,
    required this.unit,
  });

  final Color color;
  final double value;
  final String unit;

  @override
  Color get mainColor => color;

  @override
  Size getSize(FlSpot spot) => const Size(20, 20);

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => this;

  @override
  List<Object?> get props => [color, value, unit];

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    // 1. Translucent outer radar halo
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, 11.0, haloPaint);

    // 2. Crisp white stroke ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(offsetInCanvas, 6.0, ringPaint);

    // 3. Status core dot
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, 4.5, corePaint);

    // 4. Callout tag pill above point
    final text = '${value.toStringAsFixed(1)} $unit';
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 10;
    const pillHeight = 16.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(offsetInCanvas.dx, offsetInCanvas.dy - 18),
        width: pillWidth,
        height: pillHeight,
      ),
      const Radius.circular(4),
    );

    final bgPaint = Paint()..color = const Color(0xFF141923);
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(pillRect, bgPaint);
    canvas.drawRRect(pillRect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        offsetInCanvas.dx - textPainter.width / 2,
        offsetInCanvas.dy - 18 - textPainter.height / 2,
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
  const _LegendDot({
    required this.color,
    required this.label,
    this.hasHalo = false,
  });

  final Color color;
  final String label;
  final bool hasHalo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: hasHalo ? Border.all(color: Colors.white, width: 1.5) : null,
            boxShadow: hasHalo
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textDisabled,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
