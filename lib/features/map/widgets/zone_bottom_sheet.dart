import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/exposure_status.dart';
import '../models/facility_zone.dart';

/// Interactive bottom sheet detailing a tapped facility zone / sector.
class ZoneBottomSheet extends StatelessWidget {
  const ZoneBottomSheet({
    super.key,
    required this.zone,
    required this.onClose,
    required this.onRequestEvacuation,
  });

  final FacilityZone zone;
  final VoidCallback onClose;
  final VoidCallback onRequestEvacuation;

  @override
  Widget build(BuildContext context) {
    final statusColor = zone.statusColor;
    final percentAbove = zone.percentAboveThreshold;
    final isExceeded = percentAbove > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: zone.status == ExposureStatus.critical
              ? AppColors.critical.withValues(alpha: 0.6)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
          if (zone.status == ExposureStatus.critical)
            BoxShadow(
              color: AppColors.critical.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Zone Name & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (zone.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            zone.description,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          zone.status.label.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metric Cards Row
              Row(
                children: [
                  // Card 1: PEAK SENSOR TWA
                  Expanded(
                    child: _buildMetricCard(
                      title: 'PEAK SENSOR TWA',
                      value: '${zone.peakTwaPpm.toStringAsFixed(1)} PPM',
                      accentColor: statusColor,
                      subtext: isExceeded
                          ? '+${percentAbove.toStringAsFixed(0)}% ABOVE ${zone.thresholdPpm.toStringAsFixed(0)} PPM PEL'
                          : 'WITHIN ${zone.thresholdPpm.toStringAsFixed(0)} PPM PEL',
                      subtextColor:
                          isExceeded ? AppColors.warning : AppColors.safe,
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),

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
              const SizedBox(height: 14),

              // Hardware Status: Ventilation Scrubber Flow Rate
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.air_rounded,
                        color: AppColors.reticle,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VENTILATION & SCRUBBER FLOW',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            zone.scrubberFlowRate,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: zone.scrubberStatus == 'NORMAL'
                            ? AppColors.safe.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        zone.scrubberStatus,
                        style: GoogleFonts.jetBrainsMono(
                          color: zone.scrubberStatus == 'NORMAL'
                              ? AppColors.safe
                              : AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action CTA: Full-width high-visibility orange/red evacuation button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.critical,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: AppColors.critical.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  onPressed: () => _confirmEvacuation(context),
                  icon: const Icon(Icons.warning_rounded,
                      color: Colors.white, size: 20),
                  label: Text(
                    'REQUEST SECTOR EVACUATION',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(12),
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
              Icon(icon, color: accentColor, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              color: subtextColor,
              fontSize: 9,
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
          'Broadcast mandatory evacuation alarm for ${zone.name}? All ${zone.activeBadgesCount} on-site personnel will be commanded to evacuate to ZONE 05 MUSTER AREA immediately.',
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
              onRequestEvacuation();
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
