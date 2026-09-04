import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:h2s_sentinel/core/constants/app_strings.dart';
import 'package:h2s_sentinel/core/constants/exposure_thresholds.dart';
import 'package:h2s_sentinel/core/vision/cielab_engine.dart';
import 'package:h2s_sentinel/core/vision/lighting_analyzer.dart';
import 'package:h2s_sentinel/features/dashboard/dashboard_screen.dart';
import 'package:h2s_sentinel/features/dashboard/exposure_chart_card.dart';
import 'package:h2s_sentinel/features/scanner/scan_result_screen.dart';
import 'package:h2s_sentinel/features/sync/offline_queue_service.dart';
import 'package:h2s_sentinel/features/sync/supabase_service.dart';
import 'package:h2s_sentinel/models/dosimeter_reading.dart';
import 'package:h2s_sentinel/models/exposure_status.dart';
import 'package:h2s_sentinel/providers/readings_provider.dart';
import 'package:h2s_sentinel/providers/scan_provider.dart';
import 'package:h2s_sentinel/providers/worker_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Synthetic Image & CIELabEngine Pipeline', () {
    test('Pure white image produces DeltaE ~ 0 and SAFE alert', () {
      final image = img.Image(width: 80, height: 80);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      final bytes = Uint8List.fromList(img.encodeJpg(image));

      final result = CIELabEngine.analyzeImage(bytes);

      expect(result.deltaE, lessThan(kSafeMaxDeltaE));
      expect(result.alert, kAlertSafe);
      expect(result.lab.l, closeTo(100.0, 1.0));
      expect(result.srgbSample.pixelCount, 50 * 50);
    });

    test('Discolored exposed strip (pale tan) produces WARNING alert', () {
      final image = img.Image(width: 80, height: 80);
      // Pale tan strip: moderate lightness shift, warm chroma
      img.fill(image, color: img.ColorRgb8(240, 235, 218));
      final bytes = Uint8List.fromList(img.encodeJpg(image));

      final result = CIELabEngine.analyzeImage(bytes);

      expect(result.deltaE, greaterThanOrEqualTo(kSafeMaxDeltaE));
      expect(result.deltaE, lessThan(kWarningMaxDeltaE));
      expect(result.alert, kAlertWarning);
    });

    test('Severely exposed strip (dark charcoal/black) produces DANGER alert', () {
      final image = img.Image(width: 80, height: 80);
      img.fill(image, color: img.ColorRgb8(35, 30, 25));
      final bytes = Uint8List.fromList(img.encodeJpg(image));

      final result = CIELabEngine.analyzeImage(bytes);

      expect(result.deltaE, greaterThanOrEqualTo(kWarningMaxDeltaE));
      expect(result.alert, kAlertDanger);
      expect(result.lab.l, lessThan(20.0));
    });

    test('calculateExposure with Flutter Color produces consistent alerts', () {
      // Clean white: safe
      final whiteResult = CIELabEngine.calculateExposureWithAlert(const Color(0xFFFFFFFF));
      expect(whiteResult.deltaE, closeTo(0.0, 0.5));
      expect(whiteResult.alert, kAlertSafe);

      // Warning color (intermediate lead sulfide precipitate)
      final warningResult = CIELabEngine.calculateExposureWithAlert(const Color(0xFFEDE4D2));
      expect(warningResult.alert, kAlertWarning);
      expect(warningResult.deltaE, inInclusiveRange(kSafeMaxDeltaE, kWarningMaxDeltaE));

      // Danger color (dense lead sulfide precipitate)
      final dangerResult = CIELabEngine.calculateExposureWithAlert(const Color(0xFF32281E));
      expect(dangerResult.alert, kAlertDanger);
      expect(dangerResult.deltaE, greaterThanOrEqualTo(kWarningMaxDeltaE));
    });
  });

  group('2. Ambient Lighting Analysis (BT.601)', () {
    test('Under-exposed dark frame triggers low-light warning', () {
      final darkImage = img.Image(width: 100, height: 100);
      img.fill(darkImage, color: img.ColorRgb8(30, 30, 30));

      final result = LightingAnalyzer.analyze(darkImage);

      expect(result.isTooLow, isTrue);
      expect(result.estimatedLuminance, lessThan(ExposureThresholds.minAcceptableLuminance));
      expect(result.brightnessPercent, lessThan(25.0));
    });

    test('Well-lit industrial environment passes lighting gate', () {
      final brightImage = img.Image(width: 100, height: 100);
      img.fill(brightImage, color: img.ColorRgb8(180, 180, 180));

      final result = LightingAnalyzer.analyze(brightImage);

      expect(result.isTooLow, isFalse);
      expect(result.estimatedLuminance, greaterThan(ExposureThresholds.minAcceptableLuminance));
      expect(result.brightnessPercent, greaterThan(65.0));
    });
  });

  group('3. Offline Queue Service & SharedPreferences', () {
    late SharedPreferences prefs;
    late OfflineQueueService queueService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      queueService = OfflineQueueService(prefs);
    });

    test('Enqueuing, fetching, and removing offline readings', () async {
      final reading1 = DosimeterReading(
        id: 'offline-001',
        workerId: 'worker-delta',
        deltaE: 7.2,
        estimatedPpm: 5.1,
        status: ExposureStatus.warning,
        labL: 88.0,
        labA: 2.1,
        labB: 9.3,
        createdAt: DateTime.now().toUtc(),
        synced: false,
      );

      final reading2 = DosimeterReading(
        id: 'offline-002',
        workerId: 'worker-delta',
        deltaE: 21.0,
        estimatedPpm: 24.5,
        status: ExposureStatus.critical,
        labL: 60.0,
        labA: 8.4,
        labB: 15.2,
        createdAt: DateTime.now().toUtc(),
        synced: false,
      );

      expect(queueService.queueLength, 0);

      await queueService.enqueue(reading1);
      await queueService.enqueue(reading2);

      expect(queueService.queueLength, 2);

      final queued = queueService.getQueue();
      expect(queued.first.id, 'offline-001');
      expect(queued.last.id, 'offline-002');
      expect(queued.last.status, ExposureStatus.critical);

      await queueService.remove(reading1);
      expect(queueService.queueLength, 1);
      expect(queueService.getQueue().first.id, 'offline-002');

      await queueService.clearAll();
      expect(queueService.queueLength, 0);
    });
  });

  group('4. Live Supabase Service Integration', () {
    late SupabaseClient client;
    late SupabaseService service;
    final testWorkerId = 'virt-test-${DateTime.now().millisecondsSinceEpoch}';
    const testReadingId = '44444444-4444-4444-4444-444444444444';

    setUpAll(() {
      // TestWidgetsFlutterBinding mocks HTTP by default; enable real HTTP for live DB test
      HttpOverrides.global = null;

      client = SupabaseClient(
        AppStrings.supabaseUrl,
        AppStrings.supabaseAnonKey,
      );
      service = SupabaseService(client);
    });

    test('Live insertReading, fetchReadings, and upsert update to Supabase', () async {
      final reading = DosimeterReading(
        id: testReadingId,
        workerId: testWorkerId,
        deltaE: 6.4,
        estimatedPpm: 3.5,
        status: ExposureStatus.warning,
        labL: 89.2,
        labA: 1.5,
        labB: 7.8,
        createdAt: DateTime.now().toUtc(),
      );

      try {
        // 1. Insert
        final inserted = await service.insertReading(reading);
        expect(inserted.synced, isTrue);

        // 2. Fetch
        final fetched = await service.fetchReadings(testWorkerId);
        expect(fetched, isNotEmpty);
        expect(fetched.first.id, testReadingId);
        expect(fetched.first.status, ExposureStatus.warning);
        expect(fetched.first.estimatedPpm, closeTo(3.5, 0.01));

        // 3. Upsert (update with new values)
        final updatedReading = reading.copyWith(
          deltaE: 19.5,
          estimatedPpm: 21.0,
          status: ExposureStatus.critical,
        );
        final updated = await service.insertReading(updatedReading);
        expect(updated.synced, isTrue);

        final fetchedUpdated = await service.fetchReadings(testWorkerId);
        expect(fetchedUpdated.first.status, ExposureStatus.critical);
        expect(fetchedUpdated.first.deltaE, closeTo(19.5, 0.01));
      } catch (e, st) {
        debugPrint('Supabase test error: $e\n$st');
        rethrow;
      } finally {
        // Clean up test row if admin secret key is provided via environment
        final secretKey = Platform.environment['SUPABASE_SECRET_KEY'];
        if (secretKey != null && secretKey.isNotEmpty) {
          await http.delete(
            Uri.parse('${AppStrings.supabaseUrl}/rest/v1/${AppStrings.supabaseTable}?id=eq.$testReadingId'),
            headers: {
              'apikey': secretKey,
              'Authorization': 'Bearer $secretKey',
            },
          );
        }
      }
    });
  });

  group('5. UI Virtual Widget Tests', () {
    testWidgets('Dashboard renders populated reading and warning status card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final reading = DosimeterReading(
        id: 'dash-test-1',
        workerId: 'test-worker-99',
        deltaE: 12.0,
        estimatedPpm: 10.5,
        status: ExposureStatus.warning,
        labL: 82.0,
        labA: 4.0,
        labB: 11.0,
        createdAt: DateTime.now().toUtc(),
        synced: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerIdProvider.overrideWithValue('test-worker-99'),
            readingsHistoryProvider.overrideWith((ref) {
              final notifier = ReadingsHistoryNotifier();
              notifier.add(reading);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top bar app title
      expect(find.text(AppStrings.appName.toUpperCase()), findsOneWidget);

      // Header card displays current status and estimated ppm
      expect(find.text('CURRENT STATUS'), findsOneWidget);
      expect(find.text('10.5 ppm'), findsWidgets);
      expect(find.text('ELEVATED'), findsWidgets);

      // Scan CTA button
      expect(find.text(AppStrings.scanNewReading), findsOneWidget);
    });

    testWidgets('ScanResultScreen renders complete gauge, LAB values, and OSHA notes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final reading = DosimeterReading(
        id: 'result-test-1',
        workerId: 'worker-alpha',
        deltaE: 22.5,
        estimatedPpm: 27.0,
        status: ExposureStatus.critical,
        labL: 65.4,
        labA: 9.8,
        labB: 18.2,
        createdAt: DateTime.now().toUtc(),
        synced: false,
      );

      final container = ProviderContainer(
        overrides: [
          scanProvider.overrideWith((ref) {
            final notifier = ScanNotifier(ref);
            notifier.state = ScanState(latestResult: reading);
            return notifier;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ScanResultScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title
      expect(find.text(AppStrings.scanResultTitle.toUpperCase()), findsOneWidget);

      // Danger / OSHA Ceiling breach badge
      expect(find.text('DANGER'), findsWidgets);

      // CIELAB section
      expect(find.text('CIELAB SPECTRAL VALUES'), findsOneWidget);
      expect(find.text('65.4'), findsOneWidget);

      // Save & Discard buttons
      expect(find.text(AppStrings.saveReading), findsOneWidget);
      expect(find.text(AppStrings.discardReading), findsOneWidget);
    });

    testWidgets('ExposureChartCard scales up dynamically to 90 ppm with peak callout badge and metric toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final r1 = DosimeterReading(
        id: 'r-1',
        workerId: 'w-high',
        deltaE: 3.0,
        estimatedPpm: 0.5,
        status: ExposureStatus.safe,
        labL: 94.0,
        labA: 0.2,
        labB: 4.8,
        createdAt: DateTime.utc(2026, 9, 4, 8, 0),
      );

      final r2 = DosimeterReading(
        id: 'r-2',
        workerId: 'w-high',
        deltaE: 25.0,
        estimatedPpm: 37.5,
        status: ExposureStatus.critical,
        labL: 70.0,
        labA: 6.0,
        labB: 12.0,
        createdAt: DateTime.utc(2026, 9, 4, 9, 30),
      );

      // High reading at 90.0 ppm (deltaE = 46.0)
      final r3 = DosimeterReading(
        id: 'r-3',
        workerId: 'w-high',
        deltaE: 46.0,
        estimatedPpm: 90.0,
        status: ExposureStatus.critical,
        labL: 45.0,
        labA: 11.0,
        labB: 20.0,
        createdAt: DateTime.utc(2026, 9, 4, 11, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingsHistoryProvider.overrideWith((ref) {
              final notifier = ReadingsHistoryNotifier();
              notifier.add(r1);
              notifier.add(r2);
              notifier.add(r3);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: ExposureChartCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify peak badge in header showing 90.0 PPM
      expect(find.text('PEAK 90.0 PPM'), findsOneWidget);

      // Verify metric toggle buttons exist
      expect(find.text('PPM'), findsOneWidget);
      expect(find.text('ΔE'), findsOneWidget);

      // Tap on ΔE toggle to switch view
      await tester.tap(find.text('ΔE'));
      await tester.pumpAndSettle();

      // In ΔE mode, peak badge displays 46.0 ΔE
      expect(find.text('PEAK 46.0 ΔE'), findsOneWidget);
    });
  });
}
