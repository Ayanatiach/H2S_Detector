import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kinetic_colors.dart';

/// Fullscreen camera overlay for the dosimeter scanner.
///
/// Implements Kinetic Hazard Protocol & Stitch AI Viewfinder:
///   1. Dark semi-transparent vignette outside the ROI rectangle.
///   2. Bright corner bracket guides on the targeting rectangle.
///   3. Dashed border around the ROI.
///   4. Animated laser sweep beam line with Blaze Orange glow.
///   5. Optical target reference chip and "ALIGN DOSIMETER STRIP WITHIN FRAME" label.
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({
    super.key,
    this.isCapturing = false,
    this.isCalibrationMode = false,
  });

  /// When true, plays a quick flash animation to signal capture.
  final bool isCapturing;

  /// When true, highlights calibration reticle and target point.
  final bool isCalibrationMode;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  late final AnimationController _sweepController;
  late final Animation<double> _sweepAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _sweepAnim = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // ROI rectangle — centred, 72 % width, 22 % height
        final roiWidth = w * 0.72;
        final roiHeight = h * 0.22;
        final roiLeft = (w - roiWidth) / 2;
        final roiTop = (h - roiHeight) / 2 - h * 0.04;
        final roiRect = Rect.fromLTWH(roiLeft, roiTop, roiWidth, roiHeight);

        return AnimatedBuilder(
          animation: Listenable.merge([_pulseAnim, _sweepAnim]),
          builder: (context, _) {
            return CustomPaint(
              size: Size(w, h),
              painter: _OverlayPainter(
                roiRect: roiRect,
                pulseOpacity: _pulseAnim.value,
                sweepProgress: _sweepAnim.value,
                isCapturing: widget.isCapturing,
                isCalibrationMode: widget.isCalibrationMode,
              ),
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    // ── Reticle: ROI corner tag ──────────────────────────
                    Positioned(
                      left: roiLeft + 8,
                      top: roiTop - 24,
                      child: Row(
                        children: [
                          Text(
                            'ROI',
                            style: GoogleFonts.jetBrainsMono(
                              color: KineticColors.blazeOrange,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '// OPTICAL CIELAB TARGET',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white54,
                              fontSize: 9,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Target Detection Chip (Right-aligned above ROI) ──
                    Positioned(
                      right: roiLeft + 8,
                      top: roiTop - 26,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.isCalibrationMode
                                ? KineticColors.amber
                                : KineticColors.blazeOrange.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: widget.isCalibrationMode
                                    ? KineticColors.amber
                                    : KineticColors.blazeOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.isCalibrationMode
                                  ? 'CALIBRATION MODE'
                                  : 'ΔE SENSOR READY',
                              style: GoogleFonts.jetBrainsMono(
                                color: widget.isCalibrationMode
                                    ? KineticColors.amber
                                    : KineticColors.blazeOrange,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Reticle: Center Calibrate Point Tag ───────────────
                    Positioned(
                      left: roiLeft,
                      top: roiTop + (roiHeight / 2) + 16,
                      width: roiWidth,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (widget.isCalibrationMode
                                      ? KineticColors.amber
                                      : Colors.white24)
                                  .withValues(alpha: _pulseAnim.value * 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.isCalibrationMode
                                ? 'CALIBRATION TARGET POINT'
                                : 'CALIBRATE POINT',
                            style: GoogleFonts.jetBrainsMono(
                              color: widget.isCalibrationMode
                                  ? KineticColors.amber
                                  : Colors.white70,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Reticle: label below ─────────────────────────────
                    Positioned(
                      left: roiLeft,
                      top: roiTop + roiHeight + 16,
                      width: roiWidth,
                      child: Column(
                        children: [
                          Text(
                            'ALIGN DOSIMETER STRIP WITHIN FRAME',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.barlowCondensed(
                              color: Colors.white,
                              fontSize: 13,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep strip illuminated & level',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painter — vignette + dashed border + corner brackets + laser sweep
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter({
    required this.roiRect,
    required this.pulseOpacity,
    required this.sweepProgress,
    required this.isCapturing,
    required this.isCalibrationMode,
  });

  final Rect roiRect;
  final double pulseOpacity;
  final double sweepProgress;
  final bool isCapturing;
  final bool isCalibrationMode;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark vignette outside ROI
    final vignetteColor = isCapturing
        ? Colors.white.withValues(alpha: 0.2)
        : const Color(0xCC08080A);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(roiRect, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = vignetteColor);

    // 2. Dashed ROI border
    _drawDashedRect(canvas, roiRect, pulseOpacity);

    // 3. Corner brackets with Blaze Orange/Amber athletic accent
    _drawCornerBrackets(canvas, roiRect, pulseOpacity);

    // 4. Center Calibrate Point & Crosshairs
    _drawCalibratePoint(canvas, roiRect, pulseOpacity, isCalibrationMode);

    // 5. Glowing laser sweep line
    _drawLaserSweep(canvas, roiRect, sweepProgress);
  }

  void _drawCalibratePoint(
      Canvas canvas, Rect rect, double opacity, bool isCalMode) {
    final center = rect.center;
    final primaryColor =
        isCalMode ? KineticColors.amber : KineticColors.blazeOrange;

    // Outer concentric target ring
    final outerRingPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 13, outerRingPaint);

    // Inner target ring
    final innerRingPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 6.5, innerRingPaint);

    // Precision crosshair ticks leaving center open
    final tickPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.9)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const tickDist = 20.0;
    const tickGap = 8.5;

    // Horizontal ticks
    canvas.drawLine(
        Offset(center.dx - tickDist, center.dy),
        Offset(center.dx - tickGap, center.dy),
        tickPaint);
    canvas.drawLine(
        Offset(center.dx + tickGap, center.dy),
        Offset(center.dx + tickDist, center.dy),
        tickPaint);

    // Vertical ticks
    canvas.drawLine(
        Offset(center.dx, center.dy - tickDist),
        Offset(center.dx, center.dy - tickGap),
        tickPaint);
    canvas.drawLine(
        Offset(center.dx, center.dy + tickGap),
        Offset(center.dx, center.dy + tickDist),
        tickPaint);

    // Center calibrate point dot with subtle glow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, 3.5, glowPaint);

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.2, dotPaint);
  }

  void _drawLaserSweep(Canvas canvas, Rect rect, double progress) {
    final y = rect.top + (rect.height * progress);

    // Glowing laser beam background wash
    final glowPaint = Paint()
      ..color = KineticColors.blazeOrange.withValues(alpha: 0.18)
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawLine(
      Offset(rect.left + 4, y),
      Offset(rect.right - 4, y),
      glowPaint,
    );

    // Crisp sharp laser core line
    final linePaint = Paint()
      ..color = KineticColors.blazeOrange
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(rect.left + 4, y),
      Offset(rect.right - 4, y),
      linePaint,
    );
  }

  void _drawDashedRect(Canvas canvas, Rect rect, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashLen = 6.0;
    const gapLen = 4.0;

    void drawDashed(Offset p1, Offset p2) {
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final dist = (Offset(dx, dy)).distance;
      final steps = (dist / (dashLen + gapLen)).floor();
      final unitX = dx / dist;
      final unitY = dy / dist;
      for (int i = 0; i < steps; i++) {
        final start = i * (dashLen + gapLen);
        final end = start + dashLen;
        canvas.drawLine(
          Offset(p1.dx + unitX * start, p1.dy + unitY * start),
          Offset(p1.dx + unitX * end, p1.dy + unitY * end),
          paint,
        );
      }
    }

    drawDashed(rect.topLeft, rect.topRight);
    drawDashed(rect.topRight, rect.bottomRight);
    drawDashed(rect.bottomRight, rect.bottomLeft);
    drawDashed(rect.bottomLeft, rect.topLeft);
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, double opacity) {
    final paint = Paint()
      ..color = KineticColors.blazeOrange.withValues(alpha: opacity)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const bracketLen = 22.0;
    final corners = [
      // top-left
      [
        [rect.left, rect.top + bracketLen, rect.left, rect.top, rect.left + bracketLen, rect.top]
      ],
      // top-right
      [
        [rect.right - bracketLen, rect.top, rect.right, rect.top, rect.right, rect.top + bracketLen]
      ],
      // bottom-left
      [
        [rect.left, rect.bottom - bracketLen, rect.left, rect.bottom, rect.left + bracketLen, rect.bottom]
      ],
      // bottom-right
      [
        [rect.right - bracketLen, rect.bottom, rect.right, rect.bottom, rect.right, rect.bottom - bracketLen]
      ],
    ];

    for (final corner in corners) {
      final pts = corner[0];
      canvas.drawLine(Offset(pts[0], pts[1]), Offset(pts[2], pts[3]), paint);
      canvas.drawLine(Offset(pts[2], pts[3]), Offset(pts[4], pts[5]), paint);
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.pulseOpacity != pulseOpacity ||
      old.sweepProgress != sweepProgress ||
      old.isCapturing != isCapturing;
}
