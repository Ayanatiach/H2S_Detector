import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/dosimeter_reading.dart';
import '../../core/constants/app_strings.dart';

/// Manages the local offline queue for dosimeter readings that could not be
/// synced to Supabase due to network unavailability.
///
/// Readings are serialized to JSON and stored in [SharedPreferences].
/// The queue is a simple append-only list; successful syncs remove entries.
class OfflineQueueService {
  OfflineQueueService(this._prefs);

  final SharedPreferences _prefs;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all readings currently held in the local offline queue.
  List<DosimeterReading> getQueue() {
    final raw = _prefs.getStringList(AppStrings.prefOfflineQueue) ?? [];
    return raw.map((s) {
      try {
        return DosimeterReading.fromJson(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<DosimeterReading>().toList();
  }

  /// Number of readings currently queued offline.
  int get queueLength => getQueue().length;

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Enqueue a single [reading] for later sync.
  Future<void> enqueue(DosimeterReading reading) async {
    final current = _prefs.getStringList(AppStrings.prefOfflineQueue) ?? [];
    current.add(jsonEncode(reading.toJson()));
    await _prefs.setStringList(AppStrings.prefOfflineQueue, current);
  }

  /// Remove a specific [reading] from the queue after successful upload.
  Future<void> remove(DosimeterReading reading) async {
    final current = getQueue();
    current.removeWhere((r) => r.id == reading.id);
    await _save(current);
  }

  /// Clear the entire queue (e.g. after bulk sync).
  Future<void> clearAll() async {
    await _prefs.remove(AppStrings.prefOfflineQueue);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _save(List<DosimeterReading> readings) async {
    final serialized = readings.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(AppStrings.prefOfflineQueue, serialized);
  }
}
