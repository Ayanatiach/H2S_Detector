import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/exposure_status.dart';
import '../../providers/readings_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/delta_e_meter.dart';

/// Animated top-of-dashboard card showing the current alert level, ΔE, and ppm.
class StatusHeaderCard extends ConsumerWidget {
  const StatusHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestReadingProvider);

    if (latest == null) return _EmptyHeader();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: latest.status.gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: latest.status.color.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: latest.status.color.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRENT STATUS',
                  style: GoogleFonts.jetBrainsMono(
                    color: latest.status.color.withValues(alpha: 0.7),
                    fontSize: 10,
                    letterSpacing: 2.5,
                  ),
                ),
                StatusBadge(status: latest.status),
              ],
            ),
            const SizedBox(height: 20),

            // Gauge + metrics row
            Row(
              children: [
                DeltaEMeter(deltaE: latest.deltaE, size: 130),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetricRow(
                        label: AppStrings.deltaELabel,
                        value: latest.deltaE.toStringAsFixed(2),
                        color: latest.status.color,
                        isLarge: true,
                      ),
                      const SizedBox(height: 16),
                      _MetricRow(
                        label: AppStrings.estimatedPpm,
                        value: '${latest.estimatedPpm.toStringAsFixed(1)} ppm',
                        color: latest.status.color,
                        isLarge: false,
                      ),
                      const SizedBox(height: 16),
                      _MetricRow(
                        label: 'SCANNED AT',
                        value: _formatTime(latest.createdAt),
                        color: AppColors.textSecondary,
                        isLarge: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Regulatory note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(latest.status.icon,
                      color: latest.status.color.withValues(alpha: 0.7), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      latest.status.regulatoryNote,
                      style: GoogleFonts.inter(
                        color: latest.status.color.withValues(alpha: 0.85),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: isLarge ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _EmptyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined,
              color: AppColors.textDisabled, size: 48),
          const SizedBox(height: 16),
          Text(
            'No reading recorded yet',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap SCAN NEW READING to begin monitoring',
            style: GoogleFonts.inter(
                color: AppColors.textDisabled, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
