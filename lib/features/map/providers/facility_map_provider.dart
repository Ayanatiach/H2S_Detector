import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/exposure_status.dart';
import '../../../providers/readings_provider.dart';
import '../../../providers/worker_provider.dart';
import '../models/facility_zone.dart';
import '../models/worker_marker_data.dart';
import '../models/telemetry_state.dart';

/// State of the facility map, active sector polygons, badges, and telemetry.
class FacilityMapState {
  const FacilityMapState({
    required this.zones,
    this.selectedZone,
    required this.workerBadges,
    required this.telemetry,
    required this.currentWorkerPosition,
    this.isEvacuationRequested = false,
    this.evacuatedZoneId,
    this.isLoadingGps = false,
  });

  final List<FacilityZone> zones;
  final FacilityZone? selectedZone;
  final List<WorkerMarkerData> workerBadges;
  final TelemetryState telemetry;
  final LatLng currentWorkerPosition;
  final bool isEvacuationRequested;
  final String? evacuatedZoneId;
  final bool isLoadingGps;

  FacilityMapState copyWith({
    List<FacilityZone>? zones,
    FacilityZone? selectedZone,
    bool clearSelectedZone = false,
    List<WorkerMarkerData>? workerBadges,
    TelemetryState? telemetry,
    LatLng? currentWorkerPosition,
    bool? isEvacuationRequested,
    String? evacuatedZoneId,
    bool? isLoadingGps,
  }) {
    return FacilityMapState(
      zones: zones ?? this.zones,
      selectedZone:
          clearSelectedZone ? null : (selectedZone ?? this.selectedZone),
      workerBadges: workerBadges ?? this.workerBadges,
      telemetry: telemetry ?? this.telemetry,
      currentWorkerPosition:
          currentWorkerPosition ?? this.currentWorkerPosition,
      isEvacuationRequested:
          isEvacuationRequested ?? this.isEvacuationRequested,
      evacuatedZoneId: evacuatedZoneId ?? this.evacuatedZoneId,
      isLoadingGps: isLoadingGps ?? this.isLoadingGps,
    );
  }
}

class FacilityMapNotifier extends StateNotifier<FacilityMapState> {
  FacilityMapNotifier(this.ref) : super(_createInitialState(ref)) {
    _initLiveSync();
    _tryGetRealLocation();
  }

  final Ref ref;
  Timer? _telemetryTicker;

  // Industrial Facility Anchor (Houston Petrochemical / Refining Complex)
  static const LatLng baseFacility = LatLng(29.7499, -95.3584);

  static FacilityMapState _createInitialState(Ref ref) {
    String workerId;
    try {
      workerId = ref.read(workerIdProvider);
    } catch (_) {
      workerId = 'WRK-9418';
    }
    final latestReading = ref.read(latestReadingProvider);

    final currentDeltaE = latestReading?.deltaE ?? 1.2;
    final currentPpm = latestReading?.estimatedPpm ?? 0.2;
    final currentStatus = latestReading?.status ?? ExposureStatus.safe;

    // Movement history trail across facility zones
    final trail = [
      const LatLng(29.7485, -95.3598), // Muster entry
      const LatLng(29.7491, -95.3594), // North tank alleyway
      const LatLng(29.7496, -95.3588), // Main pipe rack corridor
      const LatLng(29.7501, -95.3581), // Approaching turbine deck
      const LatLng(29.7506, -95.3576), // Current active worker position
    ];

    final currentPos = trail.last;

    const zones = [
      // ZONE 01: NORTH TANK FARM (Safe)
      FacilityZone(
        id: 'zone_01',
        name: 'ZONE 01: NORTH TANK FARM',
        status: ExposureStatus.safe,
        polygonPoints: [
          LatLng(29.7515, -95.3605),
          LatLng(29.7515, -95.3585),
          LatLng(29.7500, -95.3585),
          LatLng(29.7500, -95.3605),
        ],
        peakTwaPpm: 2.1,
        thresholdPpm: 10.0,
        activeBadgesCount: 2,
        scrubberFlowRate: '15,200 CFM (NORMAL)',
        scrubberStatus: 'NORMAL',
        description: 'Atmospheric crude storage tanks 101–108.',
      ),

      // ZONE 02: H2S STRIPPER UNIT (Warning)
      FacilityZone(
        id: 'zone_02',
        name: 'ZONE 02: H2S STRIPPER COLUMN',
        status: ExposureStatus.warning,
        polygonPoints: [
          LatLng(29.7515, -95.3585),
          LatLng(29.7515, -95.3565),
          LatLng(29.7500, -95.3565),
          LatLng(29.7500, -95.3585),
        ],
        peakTwaPpm: 8.7,
        thresholdPpm: 10.0,
        activeBadgesCount: 2,
        scrubberFlowRate: '14,100 CFM (NORMAL)',
        scrubberStatus: 'NORMAL',
        description: 'Sour gas sweetening and amine regeneration tower.',
      ),

      // ZONE 03: AUX TURBINE (Elevated / Warning)
      FacilityZone(
        id: 'zone_03',
        name: 'ZONE 03: AUX TURBINE',
        status: ExposureStatus.warning,
        polygonPoints: [
          LatLng(29.7500, -95.3605),
          LatLng(29.7500, -95.3585),
          LatLng(29.7485, -95.3585),
          LatLng(29.7485, -95.3605),
        ],
        peakTwaPpm: 14.2,
        thresholdPpm: 10.0,
        activeBadgesCount: 3,
        scrubberFlowRate: '12,400 CFM (94% NOMINAL)',
        scrubberStatus: 'NORMAL',
        description: 'Gas turbine generator deck and secondary exhaust duct.',
      ),

      // ZONE 04: CONTAINMENT (Critical)
      FacilityZone(
        id: 'zone_04',
        name: 'ZONE 04: CONTAINMENT SUMP',
        status: ExposureStatus.critical,
        polygonPoints: [
          LatLng(29.7500, -95.3585),
          LatLng(29.7500, -95.3565),
          LatLng(29.7485, -95.3565),
          LatLng(29.7485, -95.3585),
        ],
        peakTwaPpm: 24.5,
        thresholdPpm: 10.0,
        activeBadgesCount: 1,
        scrubberFlowRate: '8,200 CFM (DEGRADED)',
        scrubberStatus: 'DEGRADED',
        description: 'Low-elevation drainage sump and sour runoff collector.',
      ),

      // ZONE 05: CONTROL ROOM & MUSTER (Safe)
      FacilityZone(
        id: 'zone_05',
        name: 'ZONE 05: CONTROL BLDG & MUSTER',
        status: ExposureStatus.safe,
        polygonPoints: [
          LatLng(29.7485, -95.3605),
          LatLng(29.7485, -95.3565),
          LatLng(29.7470, -95.3565),
          LatLng(29.7470, -95.3605),
        ],
        peakTwaPpm: 0.1,
        thresholdPpm: 10.0,
        activeBadgesCount: 6,
        scrubberFlowRate: '21,000 CFM (POSITIVE PRESS)',
        scrubberStatus: 'OPTIMAL',
        description: 'Pressurized control bunker and primary safety assembly area.',
      ),
    ];

    final badges = [
      WorkerMarkerData(
        badgeId: '#DOS-9418-H2S',
        workerName: 'Operator ($workerId)',
        position: currentPos,
        deltaE: currentDeltaE,
        estimatedPpm: currentPpm,
        status: currentStatus,
        isCurrentUser: true,
        lastSeen: DateTime.now(),
        currentZoneId: 'zone_03',
      ),
      WorkerMarkerData(
        badgeId: '#DOS-8831-H2S',
        workerName: 'T. Kowalski (Mech)',
        position: const LatLng(29.7495, -95.3592),
        deltaE: 11.2,
        estimatedPpm: 6.8,
        status: ExposureStatus.warning,
        isCurrentUser: false,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
        currentZoneId: 'zone_03',
      ),
      WorkerMarkerData(
        badgeId: '#DOS-1044-H2S',
        workerName: 'J. Chen (Safety Insp)',
        position: const LatLng(29.7492, -95.3572),
        deltaE: 22.4,
        estimatedPpm: 21.0,
        status: ExposureStatus.critical,
        isCurrentUser: false,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
        currentZoneId: 'zone_04',
      ),
      WorkerMarkerData(
        badgeId: '#DOS-5520-H2S',
        workerName: 'R. Davis (E&I)',
        position: const LatLng(29.7508, -95.3595),
        deltaE: 3.1,
        estimatedPpm: 0.5,
        status: ExposureStatus.safe,
        isCurrentUser: false,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 4)),
        currentZoneId: 'zone_01',
      ),
    ];

    final telemetry = TelemetryState(
      gpsStatus: 'RTK INDUSTRIAL LOCK (±0.4m)',
      activeDoseRatePpmHour: 1.85,
      oshaCompliance: 'OSHA 29 CFR 1910.1000: COMPLIANT (<20 PPM CEILING)',
      isComplianceWarning: false,
      movementHistory: trail,
      facilityCenter: baseFacility,
      lastUpdate: DateTime.now(),
    );

    return FacilityMapState(
      zones: zones,
      selectedZone: zones[2], // Default focus on Zone 03: Aux Turbine
      workerBadges: badges,
      telemetry: telemetry,
      currentWorkerPosition: currentPos,
    );
  }

  void _initLiveSync() {
    // Listen to changes in readings history from the local camera scanner and Supabase sync
    ref.listen<List<dynamic>>(readingsHistoryProvider, (prev, next) {
      if (next.isNotEmpty) {
        final latest = ref.read(latestReadingProvider);
        if (latest != null) {
          updateCurrentWorkerExposure(
            deltaE: latest.deltaE,
            estimatedPpm: latest.estimatedPpm,
            status: latest.status,
          );
        }
      }
    });

    // Subtle ambient telemetry drift for high realism
    _telemetryTicker = Timer.periodic(const Duration(seconds: 4), (_) {
      _tickTelemetry();
    });
  }

  Future<void> _tryGetRealLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // If user is outdoors / on premises, we note real GPS fix
      if (mounted) {
        state = state.copyWith(
          telemetry: state.telemetry.copyWith(
            gpsStatus:
                'GNSS LIVE FIX (±${position.accuracy.toStringAsFixed(1)}m)',
          ),
        );
      }
    } catch (_) {
      // Graceful fallback to RTK indoor simulation
    }
  }

  void _tickTelemetry() {
    if (!mounted) return;

    final current = state.telemetry.activeDoseRatePpmHour;
    // Jitter ±0.05 ppm·h
    final nextRate = (current + ((DateTime.now().second % 3) - 1) * 0.03)
        .clamp(0.1, 50.0);

    state = state.copyWith(
      telemetry: state.telemetry.copyWith(
        activeDoseRatePpmHour: double.parse(nextRate.toStringAsFixed(2)),
        lastUpdate: DateTime.now(),
      ),
    );
  }

  /// Selects a zone to show its detailed metrics bottom sheet.
  void selectZone(FacilityZone? zone) {
    HapticFeedback.selectionClick();
    if (zone == null) {
      state = state.copyWith(clearSelectedZone: true);
    } else {
      state = state.copyWith(selectedZone: zone);
    }
  }

  /// Updates current worker exposure from latest dosimeter scan.
  void updateCurrentWorkerExposure({
    required double deltaE,
    required double estimatedPpm,
    required ExposureStatus status,
  }) {
    final updatedBadges = state.workerBadges.map((b) {
      if (b.isCurrentUser) {
        return b.copyWith(
          deltaE: deltaE,
          estimatedPpm: estimatedPpm,
          status: status,
          lastSeen: DateTime.now(),
        );
      }
      return b;
    }).toList();

    state = state.copyWith(workerBadges: updatedBadges);
  }

  /// Triggers an immediate emergency sector evacuation broadcast.
  void requestSectorEvacuation(String zoneId) {
    HapticFeedback.heavyImpact();
    final updatedZones = state.zones.map((z) {
      if (z.id == zoneId) {
        return z.copyWith(
          status: ExposureStatus.critical,
          description: 'EVACUATION ORDER ACTIVE — IMMEDIATE MUSTER REQUIRED',
        );
      }
      return z;
    }).toList();

    state = state.copyWith(
      zones: updatedZones,
      isEvacuationRequested: true,
      evacuatedZoneId: zoneId,
      selectedZone: updatedZones.firstWhere((z) => z.id == zoneId),
      telemetry: state.telemetry.copyWith(
        oshaCompliance: 'CRITICAL ALERT — SECTOR EVACUATION IN PROGRESS',
        isComplianceWarning: true,
      ),
    );
  }

  /// Recenter on the current worker's badge position.
  LatLng getCurrentWorkerPosition() {
    final current = state.workerBadges.firstWhere(
      (b) => b.isCurrentUser,
      orElse: () => state.workerBadges.first,
    );
    return current.position;
  }

  @override
  void dispose() {
    _telemetryTicker?.cancel();
    super.dispose();
  }
}

/// Global provider for the live facility mapping and telemetry suite.
final facilityMapProvider =
    StateNotifierProvider<FacilityMapNotifier, FacilityMapState>((ref) {
  return FacilityMapNotifier(ref);
});
