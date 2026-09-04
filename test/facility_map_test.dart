import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:h2s_sentinel/providers/worker_provider.dart';
import 'package:h2s_sentinel/models/exposure_status.dart';
import 'package:h2s_sentinel/features/map/models/facility_zone.dart';
import 'package:h2s_sentinel/features/map/models/telemetry_state.dart';
import 'package:h2s_sentinel/features/map/providers/facility_map_provider.dart';
import 'package:h2s_sentinel/features/map/widgets/dose_advisory_card.dart';
import 'package:h2s_sentinel/features/map/widgets/zone_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FacilityZone Model & Geometry Tests', () {
    test('Calculates percentAboveThreshold accurately against OSHA 10 ppm PEL', () {
      const elevatedZone = FacilityZone(
        id: 'zone_03',
        name: 'ZONE 03: AUX TURBINE',
        status: ExposureStatus.warning,
        polygonPoints: [
          LatLng(29.750, -95.360),
          LatLng(29.750, -95.358),
          LatLng(29.748, -95.358),
          LatLng(29.748, -95.360),
        ],
        peakTwaPpm: 14.2,
        thresholdPpm: 10.0,
        activeBadgesCount: 3,
        scrubberFlowRate: '12,400 CFM',
      );

      // (14.2 - 10) / 10 * 100 = 42%
      expect(elevatedZone.percentAboveThreshold, closeTo(42.0, 0.1));

      final safeZone = elevatedZone.copyWith(peakTwaPpm: 4.5);
      expect(safeZone.percentAboveThreshold, 0.0);
    });

    test('Ray-casting containsPoint correctly identifies points inside and outside polygon', () {
      const zone = FacilityZone(
        id: 'zone_01',
        name: 'ZONE 01: TEST',
        status: ExposureStatus.safe,
        polygonPoints: [
          LatLng(10.0, 10.0),
          LatLng(10.0, 20.0),
          LatLng(20.0, 20.0),
          LatLng(20.0, 10.0),
        ],
        peakTwaPpm: 1.0,
        activeBadgesCount: 1,
        scrubberFlowRate: '10,000 CFM',
      );

      // Point inside
      expect(zone.containsPoint(const LatLng(15.0, 15.0)), isTrue);
      // Points outside
      expect(zone.containsPoint(const LatLng(5.0, 5.0)), isFalse);
      expect(zone.containsPoint(const LatLng(25.0, 15.0)), isFalse);
    });
  });

  group('FacilityMapNotifier State Tests', () {
    test('Initializes with 5 industrial sectors and active worker badges', () {
      final container = ProviderContainer(
        overrides: [workerIdProvider.overrideWithValue('TEST-WRK-01')],
      );
      addTearDown(container.dispose);

      final state = container.read(facilityMapProvider);
      expect(state.zones.length, 5);
      expect(state.zones.any((z) => z.id == 'zone_03'), isTrue);
      expect(state.zones.any((z) => z.id == 'zone_04'), isTrue);
      expect(state.workerBadges.isNotEmpty, isTrue);
      expect(state.workerBadges.any((b) => b.badgeId == '#DOS-9418-H2S'), isTrue);
      expect(state.telemetry.movementHistory.isNotEmpty, isTrue);
    });

    test('selectZone updates selectedZone', () {
      final container = ProviderContainer(
        overrides: [workerIdProvider.overrideWithValue('TEST-WRK-01')],
      );
      addTearDown(container.dispose);

      final notifier = container.read(facilityMapProvider.notifier);
      final zone04 = container.read(facilityMapProvider).zones.firstWhere((z) => z.id == 'zone_04');

      notifier.selectZone(zone04);
      expect(container.read(facilityMapProvider).selectedZone?.id, 'zone_04');

      notifier.selectZone(null);
      expect(container.read(facilityMapProvider).selectedZone, isNull);
    });

    test('requestSectorEvacuation triggers critical alert and evacuation state', () {
      final container = ProviderContainer(
        overrides: [workerIdProvider.overrideWithValue('TEST-WRK-01')],
      );
      addTearDown(container.dispose);

      final notifier = container.read(facilityMapProvider.notifier);
      notifier.requestSectorEvacuation('zone_03');

      final state = container.read(facilityMapProvider);
      expect(state.isEvacuationRequested, isTrue);
      expect(state.evacuatedZoneId, 'zone_03');
      expect(state.zones.firstWhere((z) => z.id == 'zone_03').status, ExposureStatus.critical);
      expect(state.telemetry.isComplianceWarning, isTrue);
    });
  });

  group('Facility Map UI Widget Tests', () {
    testWidgets('DoseAdvisoryCard renders GPS status, dose rate, and OSHA compliance', (tester) async {
      final telemetry = TelemetryState(
        gpsStatus: 'RTK INDUSTRIAL LOCK (±0.4m)',
        activeDoseRatePpmHour: 1.85,
        oshaCompliance: 'OSHA 29 CFR 1910.1000 COMPLIANT',
        isComplianceWarning: false,
        movementHistory: const [LatLng(29.7485, -95.3598)],
        facilityCenter: const LatLng(29.7499, -95.3584),
        lastUpdate: DateTime.now(),
      );

      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseAdvisoryCard(
              telemetry: telemetry,
              onBack: () => backPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('DOSE ADVISORY'), findsOneWidget);
      expect(find.text('RTK INDUSTRIAL LOCK (±0.4m)'), findsOneWidget);
      expect(find.text('1.85'), findsOneWidget);
      expect(find.text('PPM·H'), findsOneWidget);
      expect(find.text('OSHA 29 CFR 1910.1000 COMPLIANT'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(backPressed, isTrue);
    });

    testWidgets('ZoneBottomSheet displays header, metric cards, scrubber flow, and evacuation CTA', (tester) async {
      const zone = FacilityZone(
        id: 'zone_03',
        name: 'ZONE 03: AUX TURBINE',
        status: ExposureStatus.warning,
        polygonPoints: [
          LatLng(29.750, -95.360),
          LatLng(29.750, -95.358),
        ],
        peakTwaPpm: 14.2,
        thresholdPpm: 10.0,
        activeBadgesCount: 3,
        scrubberFlowRate: '12,400 CFM (94% NOMINAL)',
        scrubberStatus: 'NORMAL',
        description: 'Gas turbine generator deck.',
      );

      bool evacuationTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoneBottomSheet(
              zone: zone,
              onClose: () {},
              onRequestEvacuation: () => evacuationTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('ZONE 03: AUX TURBINE'), findsOneWidget);
      expect(find.text('PEAK SENSOR TWA'), findsOneWidget);
      expect(find.text('14.2 PPM'), findsOneWidget);
      expect(find.text('+42% ABOVE 10 PPM PEL'), findsOneWidget);
      expect(find.text('ACTIVE BADGES'), findsOneWidget);
      expect(find.text('3 ON-SITE'), findsOneWidget);
      expect(find.text('12,400 CFM (94% NOMINAL)'), findsOneWidget);
      expect(find.text('REQUEST SECTOR EVACUATION'), findsOneWidget);

      // Tap evacuation CTA button
      await tester.tap(find.text('REQUEST SECTOR EVACUATION'));
      await tester.pumpAndSettle();

      // Confirmation dialog shows
      expect(find.text('CONFIRM EVACUATION'), findsOneWidget);
      expect(find.text('BROADCAST ORDER'), findsOneWidget);

      await tester.tap(find.text('BROADCAST ORDER'));
      await tester.pumpAndSettle();

      expect(evacuationTriggered, isTrue);
    });
  });
}
