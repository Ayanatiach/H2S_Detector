import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/dosimeter_reading.dart';
import '../../models/exposure_status.dart';
import '../../providers/scan_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/readings_provider.dart';
import '../../widgets/industrial_button.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/delta_e_meter.dart';

/// Displays the result of a dosimeter scan with LAB values, ΔE gauge,
/// estimated ppm, and Save/Discard actions.
class ScanResultScreen extends ConsumerWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final reading = scanState.latestResult;

    if (reading == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('No result available.',
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(context),
              const SizedBox(height: 32),
              _StatusSection(reading: reading),
              const SizedBox(height: 28),
              _GaugeSection(reading: reading),
              const SizedBox(height: 28),
              _LabValuesCard(reading: reading),
              const SizedBox(height: 28),
              _RegulatoryNote(reading: reading),
              const SizedBox(height: 40),
              _ActionBar(reading: reading),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.context);
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 16),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          AppStrings.scanResultTitle.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.reading});
  final DosimeterReading reading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HAZARD CLASSIFICATION',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        StatusBadge(status: reading.status, large: true),
        const SizedBox(height: 8),
        Text(
          reading.status.regulatoryNote,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _GaugeSection extends StatelessWidget {
  const _GaugeSection({required this.reading});
  final DosimeterReading reading;

  /// OSHA PEL proximity score: 100% = 0 ppm, 0% = ≥ 10 ppm (ceiling).
  double get _oshaPelScore =>
      ((1.0 - (reading.estimatedPpm / 10.0)) * 100.0).clamp(0.0, 100.0);

  Color get _oshaPelColor {
    final s = _oshaPelScore;
    if (s >= 75) return AppColors.safe;
    if (s >= 50) return AppColors.warning;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DeltaEMeter(deltaE: reading.deltaE, size: 160),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricTile(
                label: 'ΔE COLOR SHIFT',
                value: reading.deltaE.toStringAsFixed(2),
                color: reading.status.color,
              ),
              const SizedBox(height: 16),
              _MetricTile(
                label: 'EST. EXPOSURE',
                value: '${reading.estimatedPpm.toStringAsFixed(1)} ppm',
                color: reading.status.color,
              ),
              const SizedBox(height: 16),
              _MetricTile(
                label: 'TIME',
                value: _formatTime(reading.createdAt),
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),

              // ── OSHA Compliance Score chip ─────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OSHA PEL SCORE',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${_oshaPelScore.toStringAsFixed(0)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: _oshaPelColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _oshaPelScore / 100.0,
                            minHeight: 5,
                            backgroundColor:
                                AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _oshaPelColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reading.estimatedPpm < 10.0
                        ? 'Within OSHA 8-hr PEL limit'
                        : 'PEL EXCEEDED — action required',
                    style: GoogleFonts.inter(
                      color: _oshaPelColor.withValues(alpha: 0.8),
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

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
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LabValuesCard extends StatelessWidget {
  const _LabValuesCard({required this.reading});
  final DosimeterReading reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CIELAB SPECTRAL VALUES',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LabChannel(
                  label: 'L*', value: reading.labL, color: const Color(0xFFE0E0E0)),
              _LabChannel(
                  label: 'a*', value: reading.labA, color: const Color(0xFFEF5350)),
              _LabChannel(
                  label: 'b*', value: reading.labB, color: const Color(0xFFFFD600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabChannel extends StatelessWidget {
  const _LabChannel({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(
          value.toStringAsFixed(1),
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RegulatoryNote extends StatelessWidget {
  const _RegulatoryNote({required this.reading});
  final DosimeterReading reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reading.status.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: reading.status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(reading.status.icon, color: reading.status.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reading.status.regulatoryNote,
              style: GoogleFonts.inter(
                color: reading.status.color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.reading});
  final DosimeterReading reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        IndustrialButton(
          label: AppStrings.saveReading,
          icon: Icons.save_rounded,
          onPressed: () async {
            // Save to history + sync
            ref.read(readingsHistoryProvider.notifier).add(reading);
            await ref.read(syncProvider.notifier).saveAndSync(reading);
            ref.read(scanProvider.notifier).clearResult();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.savedSuccess,
                      style: GoogleFonts.inter(color: Colors.black)),
                  backgroundColor: AppColors.safe,
                  duration: const Duration(seconds: 2),
                ),
              );
              // Pop back to dashboard
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ref.read(scanProvider.notifier).clearResult();
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              AppStrings.discardReading,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
