import 'package:equatable/equatable.dart';
import 'exposure_status.dart';

/// Represents a single dosimeter scan reading persisted to Supabase.
///
/// Fields align 1-to-1 with the `dosimeter_logs` Supabase table schema:
///   id (uuid), worker_id (text), delta_e (numeric), estimated_ppm (numeric),
///   status (text), lab_l (numeric), lab_a (numeric), lab_b (numeric),
///   created_at (timestamptz), synced (local-only boolean)
class DosimeterReading extends Equatable {
  const DosimeterReading({
    required this.id,
    required this.workerId,
    required this.deltaE,
    required this.estimatedPpm,
    required this.status,
    required this.labL,
    required this.labA,
    required this.labB,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String workerId;

  /// CIE76 ΔE* colour distance from the unexposed baseline.
  final double deltaE;

  /// Estimated cumulative H₂S exposure in ppm.
  final double estimatedPpm;

  /// OSHA-mapped hazard classification.
  final ExposureStatus status;

  /// CIELAB L* channel of the scanned patch.
  final double labL;

  /// CIELAB a* channel of the scanned patch.
  final double labA;

  /// CIELAB b* channel of the scanned patch.
  final double labB;

  /// Timestamp of the scan.
  final DateTime createdAt;

  /// Whether this reading has been successfully uploaded to Supabase.
  final bool synced;

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'delta_e': deltaE,
        'estimated_ppm': estimatedPpm,
        'status': status.dbValue,
        'lab_l': labL,
        'lab_a': labA,
        'lab_b': labB,
        'created_at': createdAt.toIso8601String(),
      };

  factory DosimeterReading.fromJson(Map<String, dynamic> json) {
    return DosimeterReading(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      deltaE: (json['delta_e'] as num).toDouble(),
      estimatedPpm: (json['estimated_ppm'] as num).toDouble(),
      status: ExposureStatusX.fromDbValue(json['status'] as String),
      labL: (json['lab_l'] as num?)?.toDouble() ?? 0.0,
      labA: (json['lab_a'] as num?)?.toDouble() ?? 0.0,
      labB: (json['lab_b'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      synced: true,
    );
  }

  DosimeterReading copyWith({
    String? id,
    String? workerId,
    double? deltaE,
    double? estimatedPpm,
    ExposureStatus? status,
    double? labL,
    double? labA,
    double? labB,
    DateTime? createdAt,
    bool? synced,
  }) {
    return DosimeterReading(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      deltaE: deltaE ?? this.deltaE,
      estimatedPpm: estimatedPpm ?? this.estimatedPpm,
      status: status ?? this.status,
      labL: labL ?? this.labL,
      labA: labA ?? this.labA,
      labB: labB ?? this.labB,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [id, workerId, deltaE, estimatedPpm, status,
      labL, labA, labB, createdAt, synced];
}
