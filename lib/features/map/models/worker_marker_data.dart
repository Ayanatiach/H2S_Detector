import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../models/exposure_status.dart';
import '../../../../core/constants/app_colors.dart';

/// Telemetry marker data for a worker badge on the facility map.
class WorkerMarkerData {
  const WorkerMarkerData({
    required this.badgeId,
    required this.workerName,
    required this.position,
    required this.deltaE,
    required this.estimatedPpm,
    required this.status,
    this.isCurrentUser = false,
    required this.lastSeen,
    this.currentZoneId,
  });

  final String badgeId;
  final String workerName;
  final LatLng position;
  final double deltaE;
  final double estimatedPpm;
  final ExposureStatus status;
  final bool isCurrentUser;
  final DateTime lastSeen;
  final String? currentZoneId;

  Color get statusColor {
    switch (status) {
      case ExposureStatus.safe:
        return AppColors.safe;
      case ExposureStatus.warning:
        return AppColors.warning;
      case ExposureStatus.critical:
        return AppColors.critical;
    }
  }

  WorkerMarkerData copyWith({
    String? badgeId,
    String? workerName,
    LatLng? position,
    double? deltaE,
    double? estimatedPpm,
    ExposureStatus? status,
    bool? isCurrentUser,
    DateTime? lastSeen,
    String? currentZoneId,
  }) {
    return WorkerMarkerData(
      badgeId: badgeId ?? this.badgeId,
      workerName: workerName ?? this.workerName,
      position: position ?? this.position,
      deltaE: deltaE ?? this.deltaE,
      estimatedPpm: estimatedPpm ?? this.estimatedPpm,
      status: status ?? this.status,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      lastSeen: lastSeen ?? this.lastSeen,
      currentZoneId: currentZoneId ?? this.currentZoneId,
    );
  }
}
