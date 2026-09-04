import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Fullscreen camera overlay for the dosimeter scanner.
///
/// Renders:
///   1. A dark semi-transparent vignette outside the ROI rectangle.
///   2. Bright corner bracket guides on the targeting rectangle.
///   3. A dashed border around the ROI to indicate the scan zone.
///   4. A "ALIGN DOSIMETER STRIP" label below the reticle.
///   5. Four color-reference squares (White, Red, Green, Blue) in the screen
///      corners to help the worker verify the ambient lighting quality before
///      capturing a colorimetric reading.
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({super.key, this.isCapturing = false});

  /// When true, plays a quick flash animation to signal capture.
  final bool isCapturing;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // ROI rectangle — centred, 70 % width, 22 % height
        final roiWidth = w * 0.70;
        final roiHeight = h * 0.22;
        final roiLeft = (w - roiWidth) / 2;
        final roiTop = (h - roiHeight) / 2 - h * 0.05;
        final roiRect = Rect.fromLTWH(roiLeft, roiTop, roiWidth, roiHeight);

        return AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) {
            return CustomPaint(
              size: Size(w, h),
              painter: _OverlayPainter(
                roiRect: roiRect,
                pulseOpacity: _pulseAnim.value,
                isCapturing: widget.isCapturing,
              ),
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    // ── Reticle: label below ─────────────────────────────
                    Positioned(
                      left: roiLeft,
                      top: roiTop + roiHeight + 16,
                      width: roiWidth,
                      child: Text(
                        'ALIGN DOSIMETER STRIP WITHIN FRAME',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.reticle.withValues(alpha: 0.85),
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // ── Reticle: ROI corner tag ──────────────────────────
                    Positioned(
                      left: roiLeft + 8,
                      top: roiTop - 22,
                      child: Text(
                        'ROI',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.reticle.withValues(alpha: 0.5),
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    // ── Color reference squares ──────────────────────────
                    // Four small squares in the screen corners guide the
                    // worker on ambient lighting / white balance before capture.
                    const _ColorRefSquare(
                      color: Colors.white,
                      label: 'W',
                      alignment: Alignment.topLeft,
                      margin: EdgeInsets.only(top: 72, left: 16),
                    ),
                    const _ColorRefSquare(
                      color: Color(0xFFFF1744), // vivid red
                      label: 'R',
                      alignment: Alignment.topRight,
                      margin: EdgeInsets.only(top: 72, right: 16),
                    ),
                    const _ColorRefSquare(
                      color: Color(0xFF00E676), // vivid green
                      label: 'G',
                      alignment: Alignment.bottomLeft,
                      margin: EdgeInsets.only(bottom: 120, left: 16),
                    ),
                    const _ColorRefSquare(
                      color: Color(0xFF2979FF), // vivid blue
                      label: 'B',
                      alignment: Alignment.bottomRight,
                      margin: EdgeInsets.only(bottom: 120, right: 16),
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
// Color reference square widget
// ─────────────────────────────────────────────────────────────────────────────

/// A small labeled color swatch in one corner of the screen.
///
/// The worker should see these squares reproduce the named colors under good
/// lighting. Any major color cast indicates poor illumination conditions.
class _ColorRefSquare extends StatelessWidget {
  const _ColorRefSquare({
    required this.color,
    required this.label,
    required this.alignment,
    required this.margin,
  });

  final Color color;
  final String label;
  final Alignment alignment;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Swatch
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painter — vignette + dashed border + corner brackets
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter({
    required this.roiRect,
    required this.pulseOpacity,
    required this.isCapturing,
  });

  final Rect roiRect;
  final double pulseOpacity;
  final bool isCapturing;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark vignette outside ROI
    final vignetteColor = isCapturing
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xCC000000);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(roiRect, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = vignetteColor);

    // 2. Dashed ROI border
    _drawDashedRect(canvas, roiRect, pulseOpacity);

    // 3. Corner brackets
    _drawCornerBrackets(canvas, roiRect, pulseOpacity);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, double opacity) {
    final paint = Paint()
      ..color = AppColors.reticle.withValues(alpha: opacity * 0.4)
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
      ..color = AppColors.reticle.withValues(alpha: opacity)
      ..strokeWidth = 3.0
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
      old.pulseOpacity != pulseOpacity || old.isCapturing != isCapturing;
}
