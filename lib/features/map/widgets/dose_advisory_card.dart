import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../models/telemetry_state.dart';

/// Top-anchored floating telemetry advisory card.
///
/// Displays:
///   • Current GPS / RTK lock status
///   • Active worker dose rate (ppm·h)
///   • OSHA compliance string
///   • Quick return / back CTA
class DoseAdvisoryCard extends StatelessWidget {
  const DoseAdvisoryCard({
    super.key,
    required this.telemetry,
    required this.onBack,
  });

  final TelemetryState telemetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isWarning = telemetry.isComplianceWarning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? AppColors.critical.withValues(alpha: 0.6)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          if (isWarning)
            BoxShadow(
              color: AppColors.critical.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Back button + Title + GPS Status Pill
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Text(
                'DOSE ADVISORY',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // GPS Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.reticle.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.reticle.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.reticle,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.reticle,
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      telemetry.gpsStatus,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.reticle,
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
          const SizedBox(height: 10),

          // Dose Rate Metric Readout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                telemetry.activeDoseRatePpmHour.toStringAsFixed(2),
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'PPM·H',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                'ACTIVE WORKER DOSE',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // OSHA Compliance Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isWarning
                  ? AppColors.critical.withValues(alpha: 0.15)
                  : AppColors.safe.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWarning
                    ? AppColors.critical.withValues(alpha: 0.4)
                    : AppColors.safe.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.verified_user_outlined,
                  color: isWarning ? AppColors.critical : AppColors.safe,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    telemetry.oshaCompliance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      color: isWarning ? AppColors.critical : AppColors.safe,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
