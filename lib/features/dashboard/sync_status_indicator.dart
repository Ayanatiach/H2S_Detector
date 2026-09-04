import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/sync_provider.dart';

/// Compact sync status indicator chip shown in the dashboard action bar.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final isOnline = ref.watch(isOnlineProvider);

    final (color, icon, label) = switch (syncState.status) {
      SyncStatus.syncing => (AppColors.accent, Icons.sync_rounded, AppStrings.syncStatusSyncing),
      SyncStatus.success => (AppColors.safe, Icons.cloud_done_rounded, AppStrings.syncStatusOnline),
      SyncStatus.failed => (AppColors.critical, Icons.cloud_off_rounded, AppStrings.errorSyncFailed),
      SyncStatus.offline => (
          AppColors.warning,
          Icons.wifi_off_rounded,
          syncState.queueLength > 0
              ? 'Offline (${syncState.queueLength} queued)'
              : AppStrings.syncStatusOffline
        ),
      _ => isOnline
          ? (AppColors.safe, Icons.cloud_done_rounded, AppStrings.syncStatusOnline)
          : (AppColors.warning, Icons.wifi_off_rounded, AppStrings.syncStatusOffline),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          syncState.status == SyncStatus.syncing
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 1.5,
                  ),
                )
              : Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
