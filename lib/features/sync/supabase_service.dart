import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/dosimeter_reading.dart';
import '../../core/constants/app_strings.dart';

/// Service encapsulating all Supabase interactions for dosimeter readings.
///
/// Table: `dosimeter_logs`
///   id (uuid, pk, default gen_random_uuid())
///   worker_id (text, not null)
///   delta_e (numeric, not null)
///   estimated_ppm (numeric, not null)
///   status (text, not null)
///   lab_l (numeric)
///   lab_a (numeric)
///   lab_b (numeric)
///   created_at (timestamptz, default now())
class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table =>
      _client.from(AppStrings.supabaseTable);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Upserts a [reading] to the `dosimeter_logs` table.
  /// Returns the reading marked as [DosimeterReading.synced] = true on success.
  Future<DosimeterReading> insertReading(DosimeterReading reading) async {
    await _table.upsert(reading.toJson());
    return reading.copyWith(synced: true);
  }

  /// Batch-upsert a list of [readings] in a single call.
  Future<List<DosimeterReading>> batchInsert(
      List<DosimeterReading> readings) async {
    if (readings.isEmpty) return [];
    final rows = readings.map((r) => r.toJson()).toList();
    await _table.upsert(rows);
    return readings.map((r) => r.copyWith(synced: true)).toList();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches all readings for [workerId] ordered by creation time descending.
  Future<List<DosimeterReading>> fetchReadings(String workerId) async {
    final response = await _table
        .select()
        .eq('worker_id', workerId)
        .order('created_at', ascending: false)
        .limit(100);

    return (response as List)
        .map((json) => DosimeterReading.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Real-time stream of new readings for [workerId].
  Stream<List<DosimeterReading>> readingsStream(String workerId) {
    return _client
        .from(AppStrings.supabaseTable)
        .stream(primaryKey: ['id'])
        .eq('worker_id', workerId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((json) => DosimeterReading.fromJson(json))
            .toList());
  }
}
