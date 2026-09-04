import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dosimeter_reading.dart';

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
