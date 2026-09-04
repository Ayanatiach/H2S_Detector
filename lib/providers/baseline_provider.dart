import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/exposure_thresholds.dart';

/// Holds the active dosimeter baseline CIELAB values.
class BaselineState {
  const BaselineState({
    this.l = ExposureThresholds.baselineL,
    this.a = ExposureThresholds.baselineA,
    this.b = ExposureThresholds.baselineB,
    this.isDefault = true,
  });

  final double l;
  final double a;
  final double b;

  /// True if the user has not yet performed a custom calibration scan.
  final bool isDefault;

  BaselineState copyWith({double? l, double? a, double? b, bool? isDefault}) {
    return BaselineState(
      l: l ?? this.l,
      a: a ?? this.a,
      b: b ?? this.b,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Manages the dosimeter calibration baseline stored in SharedPreferences.
class BaselineNotifier extends StateNotifier<BaselineState> {
  BaselineNotifier() : super(const BaselineState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final l = prefs.getDouble(AppStrings.prefBaselineL);
    final a = prefs.getDouble(AppStrings.prefBaselineA);
    final b = prefs.getDouble(AppStrings.prefBaselineB);

    if (l != null && a != null && b != null) {
      state = BaselineState(l: l, a: a, b: b, isDefault: false);
    }
  }

  /// Persist a new calibration baseline from a clean dosimeter scan.
  Future<void> setBaseline(double l, double a, double b) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppStrings.prefBaselineL, l);
    await prefs.setDouble(AppStrings.prefBaselineA, a);
    await prefs.setDouble(AppStrings.prefBaselineB, b);
    state = BaselineState(l: l, a: a, b: b, isDefault: false);
  }

  /// Reset to the factory default baseline.
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStrings.prefBaselineL);
    await prefs.remove(AppStrings.prefBaselineA);
    await prefs.remove(AppStrings.prefBaselineB);
    state = const BaselineState();
  }
}

/// Global baseline calibration provider.
final baselineProvider =
    StateNotifierProvider<BaselineNotifier, BaselineState>((ref) {
  return BaselineNotifier();
});
