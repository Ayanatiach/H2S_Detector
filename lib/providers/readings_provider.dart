import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dosimeter_reading.dart';
import '../models/exposure_status.dart';

/// In-memory list of readings recorded in the current shift session.
///
/// This provider is the primary data source for the dashboard chart.
/// Readings are prepended (most recent first) as they are saved.
class ReadingsHistoryNotifier
    extends StateNotifier<List<DosimeterReading>> {
  ReadingsHistoryNotifier() : super([]);

  /// Prepend a new reading to the session history.
  void add(DosimeterReading reading) {
    state = [reading, ...state];
  }

  /// Replace an existing reading (e.g. after sync confirms upload).
  void updateSyncStatus(DosimeterReading updated) {
    state = state.map((r) => r.id == updated.id ? updated : r).toList();
  }

  /// Clear all readings (e.g. on shift reset).
  void clear() {
    state = [];
  }
}

/// Provides the current shift's scan history list.
final readingsHistoryProvider =
    StateNotifierProvider<ReadingsHistoryNotifier, List<DosimeterReading>>(
  (ref) => ReadingsHistoryNotifier(),
);

/// Derived: the single latest reading across the session.
final latestReadingProvider = Provider<DosimeterReading?>((ref) {
  final history = ref.watch(readingsHistoryProvider);
  return history.isEmpty ? null : history.first;
});

// ── Success / Compliance Statistics ───────────────────────────────────────────

/// Aggregated statistics for the current shift's dosimeter readings.
class ReadingStats {
  const ReadingStats({
    required this.total,
    required this.safe,
    required this.warning,
    required this.critical,
    required this.avgPpm,
    required this.peakPpm,
  });

  final int total;
  final int safe;
  final int warning;
  final int critical;

  /// Mean estimated ppm across all readings in this session.
  final double avgPpm;

  /// Peak ppm reading observed this session.
  final double peakPpm;

  /// Percentage of readings that fell within the OSHA SAFE zone (< 1 ppm).
  ///
  /// Returns 100.0 when no readings have been taken (optimistic baseline).
  double get successPercent =>
      total == 0 ? 100.0 : (safe / total) * 100.0;

  /// OSHA PEL proximity score for the peak reading, expressed as a percentage.
  ///
  /// Score = clamp((1 − peakPpm / 10.0) × 100, 0, 100)
  /// — 100 % means peak is at 0 ppm (perfect), 0 % means peak ≥ 10 ppm (at
  ///   or above the OSHA 8-hr PEL of 10 ppm).
  double get oshaPelScore =>
      ((1.0 - (peakPpm / 10.0)) * 100.0).clamp(0.0, 100.0);

  /// Human label for the overall session health.
  String get sessionHealthLabel {
    if (successPercent >= 90) return 'EXCELLENT';
    if (successPercent >= 70) return 'GOOD';
    if (successPercent >= 50) return 'MARGINAL';
    return 'POOR';
  }

  static const ReadingStats empty = ReadingStats(
    total: 0,
    safe: 0,
    warning: 0,
    critical: 0,
    avgPpm: 0.0,
    peakPpm: 0.0,
  );
}

/// Derived provider that computes [ReadingStats] from the current session history.
final readingSuccessStatsProvider = Provider<ReadingStats>((ref) {
  final history = ref.watch(readingsHistoryProvider);

  if (history.isEmpty) return ReadingStats.empty;

  int safe = 0, warning = 0, critical = 0;
  double sumPpm = 0.0;
  double peakPpm = 0.0;

  for (final r in history) {
    sumPpm += r.estimatedPpm;
    if (r.estimatedPpm > peakPpm) peakPpm = r.estimatedPpm;

    switch (r.status) {
      case ExposureStatus.safe:
        safe++;
      case ExposureStatus.warning:
        warning++;
      case ExposureStatus.critical:
        critical++;
    }
  }

  return ReadingStats(
    total: history.length,
    safe: safe,
    warning: warning,
    critical: critical,
    avgPpm: sumPpm / history.length,
    peakPpm: peakPpm,
  );
});
