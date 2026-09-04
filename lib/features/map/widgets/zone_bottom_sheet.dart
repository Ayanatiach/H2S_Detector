import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/exposure_status.dart';
import '../models/facility_zone.dart';

/// Interactive sliding bottom sheet detailing a tapped facility zone / sector.
///
/// Supports interactive drag up/down gestures, expanding & collapsing,
/// grab-handle tapping, and explicit dismissal to keep the map full size.
class ZoneBottomSheet extends StatefulWidget {
  const ZoneBottomSheet({
    super.key,
    required this.zone,
    required this.onClose,
    required this.onRequestEvacuation,
    this.onExpandedChanged,
    this.initiallyExpanded = true,
  });

  final FacilityZone zone;
  final VoidCallback onClose;
  final VoidCallback onRequestEvacuation;
  final ValueChanged<bool>? onExpandedChanged;
  final bool initiallyExpanded;

  @override
  State<ZoneBottomSheet> createState() => _ZoneBottomSheetState();
}

class _ZoneBottomSheetState extends State<ZoneBottomSheet> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ZoneBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zone.id != widget.zone.id) {
      setState(() => _isExpanded = true);
      widget.onExpandedChanged?.call(true);
    }
  }

  void _toggleExpanded([bool? forceState]) {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = forceState ?? !_isExpanded;
    });
    widget.onExpandedChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final statusColor = zone.statusColor;
    final percentAbove = zone.percentAboveThreshold;
    final isExceeded = percentAbove > 0;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 250) {
          // Dragged downwards
          if (_isExpanded) {
            _toggleExpanded(false);
          } else {
            widget.onClose();
          }
        } else if (velocity < -250) {
          // Dragged upwards
          if (!_isExpanded) {
            _toggleExpanded(true);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: zone.status == ExposureStatus.critical
                ? AppColors.critical.withValues(alpha: 0.7)
                : AppColors.border,
            width: zone.status == ExposureStatus.critical ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
            if (zone.status == ExposureStatus.critical)
              BoxShadow(
                color: AppColors.critical.withValues(alpha: 0.25),
                blurRadius: 22,
                offset: const Offset(0, -2),
              ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Interactive Grab Handle ────────────────────────────────
                GestureDetector(
                  onTap: () => _toggleExpanded(),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Header: Zone Name, Status Badge, & Controls ───────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status glowing indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Title & optional description
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleExpanded(),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zone.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (_isExpanded && zone.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                zone.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        _isExpanded
                            ? zone.status.label.toUpperCase()
                            : '${zone.peakTwaPpm.toStringAsFixed(1)} PPM',
                        style: GoogleFonts.jetBrainsMono(
                          color: statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Expand / Collapse Toggle Button
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: Icon(
                        _isExpanded
                            ? Icons.expand_more_rounded
                            : Icons.expand_less_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: _isExpanded ? 'Collapse Sheet' : 'Expand Details',
                      onPressed: () => _toggleExpanded(),
                    ),

                    // Close Button (dismiss card completely to restore full map)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      tooltip: 'Close Card (Full Map)',
                      onPressed: widget.onClose,
                    ),
                  ],
                ),

                // ── Expandable Body (Metric Cards, Flow, CTA) ─────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: _isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),

                            // Metric Cards Row
                            Row(
                              children: [
                                // Card 1: PEAK SENSOR TWA
                                Expanded(
                                  child: _buildMetricCard(
                                    title: 'PEAK SENSOR TWA',
                                    value:
                                        '${zone.peakTwaPpm.toStringAsFixed(1)} PPM',
                                    accentColor: statusColor,
                                    subtext: isExceeded
                                        ? '+${percentAbove.toStringAsFixed(0)}% ABOVE ${zone.thresholdPpm.toStringAsFixed(0)} PPM PEL'
                                        : 'WITHIN ${zone.thresholdPpm.toStringAsFixed(0)} PPM PEL',
                                    subtextColor: isExceeded
                                        ? AppColors.warning
                                        : AppColors.safe,
                                    icon: Icons.speed_rounded,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Card 2: ACTIVE BADGES
                                Expanded(
                                  child: _buildMetricCard(
                                    title: 'ACTIVE BADGES',
                                    value: '${zone.activeBadgesCount} ON-SITE',
                                    accentColor: AppColors.reticle,
                                    subtext: 'RADIO LINK: ENCRYPTED',
                                    subtextColor: AppColors.textSecondary,
                                    icon: Icons.sensors_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Hardware Status: Ventilation Scrubber Flow Rate
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.border, width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.air_rounded,
                                      color: AppColors.reticle,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'VENTILATION & SCRUBBER FLOW',
                                          style: GoogleFonts.jetBrainsMono(
                                            color: AppColors.textSecondary,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          zone.scrubberFlowRate,
                                          style: GoogleFonts.jetBrainsMono(
                                            color: AppColors.textPrimary,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: zone.scrubberStatus == 'NORMAL'
                                          ? AppColors.safe
                                              .withValues(alpha: 0.15)
                                          : AppColors.warning
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      zone.scrubberStatus,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: zone.scrubberStatus == 'NORMAL'
                                            ? AppColors.safe
                                            : AppColors.warning,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Action CTA: Evacuation button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.critical,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: AppColors.critical
                                      .withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: Colors.white24, width: 1),
                                  ),
                                ),
                                onPressed: () => _confirmEvacuation(context),
                                icon: const Icon(Icons.warning_rounded,
                                    color: Colors.white, size: 18),
                                label: Text(
                                  'REQUEST SECTOR EVACUATION',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color accentColor,
    required String subtext,
    required Color subtextColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 13),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              color: subtextColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEvacuation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.critical, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.notification_important_rounded,
                color: AppColors.critical, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'CONFIRM EVACUATION',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Broadcast mandatory evacuation alarm for ${widget.zone.name}? All ${widget.zone.activeBadgesCount} on-site personnel will be commanded to evacuate to ZONE 05 MUSTER AREA immediately.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onRequestEvacuation();
            },
            child: Text(
              'BROADCAST ORDER',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
