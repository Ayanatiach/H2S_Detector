import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../models/worker_marker_data.dart';

/// Custom industrial marker representing an active dosimeter badge on the facility map.
class WorkerBadgeMarker extends StatefulWidget {
  const WorkerBadgeMarker({
    super.key,
    required this.data,
    this.onTap,
  });

  final WorkerMarkerData data;
  final VoidCallback? onTap;

  @override
  State<WorkerBadgeMarker> createState() => _WorkerBadgeMarkerState();
}

class _WorkerBadgeMarkerState extends State<WorkerBadgeMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.data.statusColor;
    final isCurrent = widget.data.isCurrentUser;

    return GestureDetector(
      onTap: widget.onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge ID pill tag (e.g., #DOS-9418-H2S)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.accent.withValues(alpha: 0.9)
                  : AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCurrent ? Colors.white : statusColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              widget.data.badgeId,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 3),

          // Pulsing Core Beacon + Pin Icon
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isCurrent ? _pulseAnim.value : 1.0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.25),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.8),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    isCurrent ? Icons.person : Icons.sensors_rounded,
                    color: Colors.black,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Exposure Reading Readout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(
              '${widget.data.estimatedPpm.toStringAsFixed(1)} ppm',
              style: GoogleFonts.jetBrainsMono(
                color: statusColor,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
