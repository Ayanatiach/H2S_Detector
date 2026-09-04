import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/dosimeter_reading.dart';
import '../../models/exposure_status.dart';
import '../../providers/readings_provider.dart';
import '../../providers/baseline_provider.dart';
import '../../widgets/industrial_button.dart';
import '../scanner/scanner_screen.dart';
import 'status_header_card.dart';
import 'exposure_chart_card.dart';
import 'sync_status_indicator.dart';

/// Main safety dashboard — the app's home screen.
///
/// Layout:
///   • Industrial top app bar with sync indicator
///   • [StatusHeaderCard] — current alert level + ΔE gauge
///   • [ExposureChartCard] — shift timeline graph
///   • Recent readings list
///   • Action bar: Scan CTA + Calibrate button
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: _Body(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // App logo / icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: const Icon(Icons.sensors, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  AppStrings.appTagline,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SyncStatusIndicator(),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(readingsHistoryProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Current Status Card
              const StatusHeaderCard(),
              const SizedBox(height: 20),

              // Exposure Timeline Chart
              const ExposureChartCard(),
              const SizedBox(height: 20),

              // Action bar
              _ActionBar(),
              const SizedBox(height: 28),

              // Recent Readings
              if (readings.isNotEmpty) ...[
                const _SectionHeader(title: 'RECENT READINGS'),
                const SizedBox(height: 12),
                ...readings.take(10).map((r) => _ReadingListTile(reading: r)),
              ],
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseline = ref.watch(baselineProvider);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: IndustrialButton(
            label: AppStrings.scanNewReading,
            icon: Icons.document_scanner_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => _showCalibrationDialog(context, ref),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: baseline.isDefault
                      ? AppColors.warning.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: baseline.isDefault
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CALIBRATE',
                    style: GoogleFonts.jetBrainsMono(
                      color: baseline.isDefault
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCalibrationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppStrings.calibrationTitle,
          style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppStrings.calibrationInfo,
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ScannerScreen(isCalibrationMode: true),
                ),
              );
            },
            child: Text('SCAN BASELINE',
                style: GoogleFonts.jetBrainsMono(
                    color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ],
    );
  }
}

class _ReadingListTile extends StatelessWidget {
  const _ReadingListTile({required this.reading});
  final DosimeterReading reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: reading.status.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: reading.status.color.withValues(alpha: 0.4), blurRadius: 6)
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Time
          Text(
            '${reading.createdAt.hour.toString().padLeft(2, '0')}:'
            '${reading.createdAt.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 16),

          // ΔE
          Expanded(
            child: Text(
              'ΔE ${reading.deltaE.toStringAsFixed(2)}',
              style: GoogleFonts.jetBrainsMono(
                color: reading.status.color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ppm
          Text(
            '${reading.estimatedPpm.toStringAsFixed(1)} ppm',
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 10),

          // Sync indicator
          Icon(
            reading.synced
                ? Icons.cloud_done_outlined
                : Icons.cloud_upload_outlined,
            size: 14,
            color: reading.synced
                ? AppColors.safe.withValues(alpha: 0.5)
                : AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}
