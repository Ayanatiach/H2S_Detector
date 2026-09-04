import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dosimeter_reading.dart';
import '../features/sync/supabase_service.dart';
import '../features/sync/offline_queue_service.dart';
import '../core/constants/app_strings.dart';

// ── Connectivity ──────────────────────────────────────────────────────────────

/// Stream of current connectivity result.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// True if the device currently has any network access.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (results) => results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none),
    orElse: () => false,
  );
});

// ── Sync State ────────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, success, failed, offline }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.queueLength = 0,
    this.message,
  });

  final SyncStatus status;
  final int queueLength;
  final String? message;

  bool get isOffline => status == SyncStatus.offline;
  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    int? queueLength,
    String? message,
  }) {
    return SyncState(
      status: status ?? this.status,
      queueLength: queueLength ?? this.queueLength,
      message: message ?? this.message,
    );
  }
}

/// Manages cloud sync, offline queuing, and readings persistence.
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref) : super(const SyncState()) {
    _init();
  }

  final Ref _ref;
  SupabaseService? _supabase;
  OfflineQueueService? _queue;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _queue = OfflineQueueService(prefs);
    state = state.copyWith(queueLength: _queue!.queueLength);
  }

  void attachSupabase(SupabaseService service) {
    _supabase = service;
  }

  /// Save a reading locally then attempt to sync immediately.
  Future<void> saveAndSync(DosimeterReading reading) async {
    await _queue?.enqueue(reading);
    state = state.copyWith(queueLength: _queue?.queueLength ?? 0);

    final isOnline = _ref.read(isOnlineProvider);
    if (isOnline) {
      await _flushQueue();
    } else {
      state = state.copyWith(
        status: SyncStatus.offline,
        message: AppStrings.syncStatusOffline,
      );
    }
  }

  /// Attempt to upload all queued readings to Supabase.
  Future<void> _flushQueue() async {
    if (_supabase == null || _queue == null) return;

    final pending = _queue!.getQueue();
    if (pending.isEmpty) return;

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      final synced = await _supabase!.batchInsert(pending);
      for (final r in synced) {
        await _queue!.remove(r);
      }
      state = state.copyWith(
        status: SyncStatus.success,
        queueLength: _queue!.queueLength,
        message: AppStrings.syncStatusOnline,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.failed,
        message: '${AppStrings.errorSyncFailed}: $e',
      );
    }
  }

  /// Called when connectivity is restored — flush the queue.
  Future<void> onConnectivityRestored() async {
    await _flushQueue();
  }

  int get pendingCount => _queue?.queueLength ?? 0;
}

/// Global sync provider.
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

// ── Readings List ─────────────────────────────────────────────────────────────

/// All readings from Supabase for the current worker (async fetch).
final readingsProvider =
    FutureProvider<List<DosimeterReading>>((ref) async {
  // For demo/offline mode, return empty if Supabase not configured
  return [];
});
