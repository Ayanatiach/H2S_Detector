import 'package:flutter_test/flutter_test.dart';
import 'package:h2s_sentinel/core/constants/exposure_thresholds.dart';
import 'package:h2s_sentinel/core/vision/color_extractor.dart';
import 'package:h2s_sentinel/core/vision/color_space_converter.dart';
import 'package:h2s_sentinel/core/vision/delta_e_calculator.dart';
import 'package:h2s_sentinel/models/dosimeter_reading.dart';
import 'package:h2s_sentinel/models/exposure_status.dart';

void main() {
  group('ColorSpaceConverter (sRGB -> XYZ -> CIELAB)', () {
    test('Pure black (0,0,0) converts to L* = 0', () {
      final lab = ColorSpaceConverter.rgbToLab(0, 0, 0);
      expect(lab.l, closeTo(0.0, 0.01));
      expect(lab.a, closeTo(0.0, 0.01));
      expect(lab.b, closeTo(0.0, 0.01));
    });

    test('Pure white (255,255,255) converts to L* = 100', () {
      final lab = ColorSpaceConverter.rgbToLab(255, 255, 255);
      expect(lab.l, closeTo(100.0, 0.5));
      expect(lab.a, closeTo(0.0, 0.5));
      expect(lab.b, closeTo(0.0, 0.5));
    });

    test('Mid-grey (128,128,128) has L* around 53.5 and neutral chroma', () {
      final lab = ColorSpaceConverter.rgbToLab(128, 128, 128);
      expect(lab.l, inInclusiveRange(50.0, 56.0));
      expect(lab.a, closeTo(0.0, 1.0));
      expect(lab.b, closeTo(0.0, 1.0));
    });
  });

  group('DeltaECalculator & Exposure Thresholds', () {
    test('Identical color to baseline results in deltaE ~ 0 and SAFE status', () {
      // Baseline defaults: L=95, A=0, B=5
      // Compute sRGB that corresponds roughly to baseline or use default
      final lab = ColorSpaceConverter.rgbToLab(245, 245, 240);
      const sample = RgbSample(r: 245, g: 245, b: 240, pixelCount: 1000);
      final result = DeltaECalculator.compute(
        sample,
        baselineL: lab.l,
        baselineA: lab.a,
        baselineB: lab.b,
      );

      expect(result.deltaE, closeTo(0.0, 0.01));
      expect(result.status, ExposureStatus.safe);
      expect(result.estimatedPpm, closeTo(0.0, 0.1));
    });

    test('DeltaE below 5.0 is mapped to Safe status', () {
      expect(ExposureThresholds.statusFromDeltaE(0.0), ExposureStatus.safe);
      expect(ExposureThresholds.statusFromDeltaE(4.9), ExposureStatus.safe);
    });

    test('DeltaE between 5.0 and 17.9 is mapped to Warning status', () {
      expect(ExposureThresholds.statusFromDeltaE(5.0), ExposureStatus.warning);
      expect(ExposureThresholds.statusFromDeltaE(12.0), ExposureStatus.warning);
      expect(ExposureThresholds.statusFromDeltaE(17.9), ExposureStatus.warning);
    });

    test('DeltaE >= 18.0 is mapped to Critical status', () {
      expect(ExposureThresholds.statusFromDeltaE(18.0), ExposureStatus.critical);
      expect(ExposureThresholds.statusFromDeltaE(25.0), ExposureStatus.critical);
    });

    test('Estimated PPM increases monotonically with deltaE', () {
      final ppm0 = ExposureThresholds.estimatePpm(0.0);
      final ppm4 = ExposureThresholds.estimatePpm(4.0);
      final ppm10 = ExposureThresholds.estimatePpm(10.0);
      final ppm20 = ExposureThresholds.estimatePpm(20.0);

      expect(ppm0, 0.0);
      expect(ppm4, greaterThan(ppm0));
      expect(ppm10, greaterThan(ppm4));
      expect(ppm20, greaterThan(ppm10));
    });
  });

  group('DosimeterReading model serialization', () {
    test('Serialization to/from JSON maintains data integrity', () {
      final original = DosimeterReading(
        id: 'test-uuid-1234',
        workerId: 'worker-alpha',
        deltaE: 14.5,
        estimatedPpm: 12.8,
        status: ExposureStatus.warning,
        labL: 75.2,
        labA: 12.1,
        labB: -4.3,
        createdAt: DateTime.utc(2026, 9, 3, 12, 0, 0),
        synced: true,
      );

      final json = original.toJson();
      final reconstructed = DosimeterReading.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.workerId, original.workerId);
      expect(reconstructed.deltaE, original.deltaE);
      expect(reconstructed.estimatedPpm, original.estimatedPpm);
      expect(reconstructed.status, original.status);
      expect(reconstructed.labL, original.labL);
      expect(reconstructed.labA, original.labA);
      expect(reconstructed.labB, original.labB);
      expect(reconstructed.createdAt, original.createdAt);
      expect(reconstructed.synced, isTrue);
    });
  });
}
