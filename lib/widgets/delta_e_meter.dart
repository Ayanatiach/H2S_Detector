import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/exposure_thresholds.dart';
import '../models/exposure_status.dart';

/// An animated arc gauge that displays a ΔE value on a 0–30 scale.
///
/// The arc fills from the left (0) to the right (max) and colour-transitions
/// from safe green → warning amber → critical red based on thresholds.
class DeltaEMeter extends StatefulWidget {
  const DeltaEMeter({
    super.key,
    required this.deltaE,
    this.size = 180.0,
    this.animate = true,
  });

  final double deltaE;
  final double size;
  final bool animate;

  @override
  State<DeltaEMeter> createState() => _DeltaEMeterState();
}

class _DeltaEMeterState extends State<DeltaEMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _valueAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _updateAnimation(0, widget.deltaE);
    if (widget.animate) _controller.forward();
  }

  @override
  void didUpdateWidget(DeltaEMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deltaE != widget.deltaE) {
      _updateAnimation(oldWidget.deltaE, widget.deltaE);
      _controller
        ..reset()
        ..forward();
    }
  }

  void _updateAnimation(double from, double to) {
    _valueAnim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForDeltaE(double value) {
    if (value < ExposureThresholds.safeMaxDeltaE) return AppColors.safe;
    if (value < ExposureThresholds.warningMaxDeltaE) return AppColors.warning;
    return AppColors.critical;
  }

  ExposureStatus _statusForDeltaE(double value) {
    return ExposureThresholds.statusFromDeltaE(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _valueAnim,
      builder: (context, _) {
        final value = _valueAnim.value;
        final color = _colorForDeltaE(value);
        final status = _statusForDeltaE(widget.deltaE);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arc painter
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ArcPainter(
                  value: value,
                  maxValue: ExposureThresholds.chartMaxDeltaE,
                  color: color,
                ),
              ),
              // Centre text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(1),
                    style: GoogleFonts.jetBrainsMono(
                      color: color,
                      fontSize: widget.size * 0.18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ΔE',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: widget.size * 0.10,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.ppmRange,
                    style: GoogleFonts.inter(
                      color: color.withValues(alpha: 0.8),
                      fontSize: widget.size * 0.075,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final double value;
  final double maxValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;
    const startAngle = math.pi * 0.75; // 135°
    const sweepTotal = math.pi * 1.5;  // 270° total arc

    // Track (background arc)
    final trackPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Value arc
    final fraction = (value / maxValue).clamp(0.0, 1.0);
    if (fraction > 0) {
      final valuePaint = Paint()
        ..color = color
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * fraction,
        false,
        valuePaint,
      );
    }

    // Threshold tick marks
    _drawThresholdTick(canvas, center, radius, startAngle, sweepTotal,
        ExposureThresholds.safeMaxDeltaE / maxValue, AppColors.safe);
    _drawThresholdTick(canvas, center, radius, startAngle, sweepTotal,
        ExposureThresholds.warningMaxDeltaE / maxValue, AppColors.warning);
  }

  void _drawThresholdTick(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepTotal,
    double fraction,
    Color color,
  ) {
    final angle = startAngle + sweepTotal * fraction;
    final innerR = radius - 16;
    final outerR = radius + 4;
    final p1 = Offset(
      center.dx + innerR * math.cos(angle),
      center.dy + innerR * math.sin(angle),
    );
    final p2 = Offset(
      center.dx + outerR * math.cos(angle),
      center.dy + outerR * math.sin(angle),
    );
    canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}
