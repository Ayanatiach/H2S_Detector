import 'package:latlong2/latlong.dart';

/// Active telemetry state for the facility map viewport and dose advisory overlay.
class TelemetryState {
  const TelemetryState({
    required this.gpsStatus,
    required this.activeDoseRatePpmHour,
    required this.oshaCompliance,
    this.isComplianceWarning = false,
    required this.movementHistory,
    required this.facilityCenter,
    required this.lastUpdate,
  });

  final String gpsStatus;
  final double activeDoseRatePpmHour;
  final String oshaCompliance;
  final bool isComplianceWarning;
  final List<LatLng> movementHistory;
  final LatLng facilityCenter;
  final DateTime lastUpdate;

  TelemetryState copyWith({
    String? gpsStatus,
    double? activeDoseRatePpmHour,
    String? oshaCompliance,
    bool? isComplianceWarning,
    List<LatLng>? movementHistory,
    LatLng? facilityCenter,
    DateTime? lastUpdate,
  }) {
    return TelemetryState(
      gpsStatus: gpsStatus ?? this.gpsStatus,
      activeDoseRatePpmHour:
          activeDoseRatePpmHour ?? this.activeDoseRatePpmHour,
      oshaCompliance: oshaCompliance ?? this.oshaCompliance,
      isComplianceWarning: isComplianceWarning ?? this.isComplianceWarning,
      movementHistory: movementHistory ?? this.movementHistory,
      facilityCenter: facilityCenter ?? this.facilityCenter,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
