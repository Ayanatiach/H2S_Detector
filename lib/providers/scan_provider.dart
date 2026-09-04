import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../core/vision/color_extractor.dart';
import '../core/vision/delta_e_calculator.dart';
import '../core/constants/exposure_thresholds.dart';
import '../models/dosimeter_reading.dart';
import 'worker_provider.dart';

/// State for the scan analysis lifecycle.
class ScanState {
  const ScanState({
    this.isAnalyzing = false,
    this.latestResult,
    this.error,
  });

  final bool isAnalyzing;
  final DosimeterReading? latestResult;
  final String? error;

  ScanState copyWith({
    bool? isAnalyzing,
    DosimeterReading? latestResult,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ScanState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      latestResult: clearResult ? null : (latestResult ?? this.latestResult),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier that drives the dosimeter image analysis pipeline.
class ScanNotifier extends StateNotifier<ScanState> {
  ScanNotifier(this._ref) : super(const ScanState());

  final Ref _ref;
  final _uuid = const Uuid();

  /// Analyse a [XFile] captured from the camera.
  ///
  /// Pipeline:
  ///   1. Decode JPEG bytes into an [img.Image]
  ///   2. Extract average ROI RGB via [ColorExtractor.extractRoi]
  ///   3. Run [DeltaECalculator.compute] against the stored baseline
  ///   4. Wrap result into [DosimeterReading] and update state
  Future<void> analyzeCapture(
    XFile file, {
    double baselineL = ExposureThresholds.baselineL,
    double baselineA = ExposureThresholds.baselineA,
    double baselineB = ExposureThresholds.baselineB,
  }) async {
    state = state.copyWith(isAnalyzing: true, clearError: true);

    try {
      // 1. Read JPEG bytes
      final Uint8List bytes = await file.readAsBytes();

      // 2. Decode image with the `image` package (pure Dart)
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Failed to decode image data.');
      }

      // 3. Extract average RGB from the central ROI bounding box
      final sample = ColorExtractor.extractRoi(decoded);

      // 4. Compute ΔE against the baseline and map to ppm
      final result = DeltaECalculator.compute(
        sample,
        baselineL: baselineL,
        baselineA: baselineA,
        baselineB: baselineB,
      );

      // 5. Retrieve worker ID
      final workerId = _ref.read(workerIdProvider);

      // 6. Build the reading model
      final reading = DosimeterReading(
        id: _uuid.v4(),
        workerId: workerId,
        deltaE: result.deltaE,
        estimatedPpm: result.estimatedPpm,
        status: result.status,
        labL: result.lab.l,
        labA: result.lab.a,
        labB: result.lab.b,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        isAnalyzing: false,
        latestResult: reading,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: 'Analysis failed: ${e.toString()}',
        clearResult: false,
      );
    }
  }

  void clearResult() {
    state = state.copyWith(clearResult: true, clearError: true);
  }
}

/// Provides the scan notifier scoped to the current session.
final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(ref);
});
