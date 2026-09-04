import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../models/exposure_status.dart';
import '../../../../core/constants/app_colors.dart';

/// Represents an industrial facility sector or monitoring zone.
class FacilityZone {
  const FacilityZone({
    required this.id,
    required this.name,
    required this.status,
    required this.polygonPoints,
    required this.peakTwaPpm,
    this.thresholdPpm = 10.0,
    required this.activeBadgesCount,
    required this.scrubberFlowRate,
    this.scrubberStatus = 'NORMAL',
    this.description = '',
  });

  final String id;
  final String name;
  final ExposureStatus status;
  final List<LatLng> polygonPoints;
  final double peakTwaPpm;
  final double thresholdPpm;
  final int activeBadgesCount;
  final String scrubberFlowRate;
  final String scrubberStatus;
  final String description;

  /// Percentage above OSHA TWA/PEL threshold (0% if below).
  double get percentAboveThreshold {
    if (peakTwaPpm <= thresholdPpm) return 0.0;
    return ((peakTwaPpm - thresholdPpm) / thresholdPpm) * 100.0;
  }

  /// Color associated with this zone's current status.
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

  /// Semi-transparent polygon fill color.
  Color get fillColor => statusColor.withValues(alpha: 0.18);

  /// Polygon border color.
  Color get borderColor => statusColor.withValues(alpha: 0.85);

  /// Geometric center point of the zone polygon.
  LatLng get centerPoint {
    if (polygonPoints.isEmpty) return const LatLng(0, 0);
    double latSum = 0;
    double lngSum = 0;
    for (final p in polygonPoints) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / polygonPoints.length, lngSum / polygonPoints.length);
  }

  /// Ray-casting algorithm to test whether a LatLng point falls within this sector.
  bool containsPoint(LatLng point) {
    if (polygonPoints.length < 3) return false;
    bool inside = false;
    int j = polygonPoints.length - 1;
    for (int i = 0; i < polygonPoints.length; i++) {
      if ((polygonPoints[i].longitude > point.longitude) !=
              (polygonPoints[j].longitude > point.longitude) &&
          (point.latitude <
              (polygonPoints[j].latitude - polygonPoints[i].latitude) *
                      (point.longitude - polygonPoints[i].longitude) /
                      (polygonPoints[j].longitude - polygonPoints[i].longitude) +
                  polygonPoints[i].latitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  FacilityZone copyWith({
    String? id,
    String? name,
    ExposureStatus? status,
    List<LatLng>? polygonPoints,
    double? peakTwaPpm,
    double? thresholdPpm,
    int? activeBadgesCount,
    String? scrubberFlowRate,
    String? scrubberStatus,
    String? description,
  }) {
    return FacilityZone(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      polygonPoints: polygonPoints ?? this.polygonPoints,
      peakTwaPpm: peakTwaPpm ?? this.peakTwaPpm,
      thresholdPpm: thresholdPpm ?? this.thresholdPpm,
      activeBadgesCount: activeBadgesCount ?? this.activeBadgesCount,
      scrubberFlowRate: scrubberFlowRate ?? this.scrubberFlowRate,
      scrubberStatus: scrubberStatus ?? this.scrubberStatus,
      description: description ?? this.description,
    );
  }
}
