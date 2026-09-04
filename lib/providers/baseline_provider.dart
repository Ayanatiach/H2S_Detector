import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/exposure_thresholds.dart';

/// Holds the active dosimeter baseline CIELAB values and calibration status.
class BaselineState {
  const BaselineState({
    this.l = ExposureThresholds.baselineL,
    this.a = ExposureThresholds.baselineA,
    this.b = ExposureThresholds.baselineB,
    this.isCalibrated = false,
    this.calibratedAt,
  });

  final double l;
  final double a;
  final double b;

  /// True if the user has performed a valid calibration scan.
  final bool isCalibrated;

  /// Timestamp when calibration was performed.
  final DateTime? calibratedAt;

  /// Backwards compatibility: true when not calibrated
  bool get isDefault => !isCalibrated;

  BaselineState copyWith({
    double? l,
    double? a,
    double? b,
    bool? isCalibrated,
    DateTime? calibratedAt,
  }) {
    return BaselineState(
      l: l ?? this.l,
      a: a ?? this.a,
      b: b ?? this.b,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      calibratedAt: calibratedAt ?? this.calibratedAt,
    );
  }
}

/// Manages the dosimeter calibration baseline stored in SharedPreferences.
class BaselineNotifier extends StateNotifier<BaselineState> {
  BaselineNotifier() : super(const BaselineState()) {
    _load();
  }

  static const String prefCalibratedKey = 'dosimeter_calibrated_v2';
  static const String prefCalibratedAtKey = 'dosimeter_calibrated_at_v2';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isCalibrated = prefs.getBool(prefCalibratedKey) ?? false;
    final l = prefs.getDouble(AppStrings.prefBaselineL);
    final a = prefs.getDouble(AppStrings.prefBaselineA);
    final b = prefs.getDouble(AppStrings.prefBaselineB);
    final atStr = prefs.getString(prefCalibratedAtKey);
    final calibratedAt = atStr != null ? DateTime.tryParse(atStr) : null;

    // A valid calibration must have the explicit v2 flag and valid LAB coordinates.
    // In addition, if older than 12 hours, the shift session has expired.
    if (isCalibrated && l != null && a != null && b != null) {
      if (calibratedAt != null &&
          DateTime.now().difference(calibratedAt).inHours >= 12) {
        // Shift expired; require fresh calibration for the new badge
        await resetCalibration();
        return;
      }
      state = BaselineState(
        l: l,
        a: a,
        b: b,
        isCalibrated: true,
        calibratedAt: calibratedAt,
      );
    } else {
      state = const BaselineState(isCalibrated: false);
    }
  }

  /// Persist a new calibration baseline from a clean dosimeter scan.
  Future<void> setBaseline(double l, double a, double b) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setDouble(AppStrings.prefBaselineL, l);
    await prefs.setDouble(AppStrings.prefBaselineA, a);
    await prefs.setDouble(AppStrings.prefBaselineB, b);
    await prefs.setBool(prefCalibratedKey, true);
    await prefs.setString(prefCalibratedAtKey, now.toIso8601String());
    state = BaselineState(
      l: l,
      a: a,
      b: b,
      isCalibrated: true,
      calibratedAt: now,
    );
  }

  /// Reset to uncalibrated status so worker must calibrate before taking readings.
  Future<void> resetCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStrings.prefBaselineL);
    await prefs.remove(AppStrings.prefBaselineA);
    await prefs.remove(AppStrings.prefBaselineB);
    await prefs.remove(prefCalibratedKey);
    await prefs.remove(prefCalibratedAtKey);
    state = const BaselineState(isCalibrated: false);
  }

  /// Legacy alias
  Future<void> resetToDefault() => resetCalibration();
}

/// Global baseline calibration provider.
final baselineProvider =
    StateNotifierProvider<BaselineNotifier, BaselineState>((ref) {
  return BaselineNotifier();
});
