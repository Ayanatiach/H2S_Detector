import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// State for the camera controller lifecycle.
class CameraState {
  const CameraState({
    this.controller,
    this.isInitializing = false,
    this.isPermissionDenied = false,
    this.error,
  });

  final CameraController? controller;
  final bool isInitializing;

  /// True when the user has permanently denied camera access.
  final bool isPermissionDenied;

  final String? error;

  bool get isReady => controller != null && (controller!.value.isInitialized);

  CameraState copyWith({
    CameraController? controller,
    bool? isInitializing,
    bool? isPermissionDenied,
    String? error,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      isInitializing: isInitializing ?? this.isInitializing,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      error: error,
    );
  }
}

/// Notifier managing [CameraController] lifecycle.
class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(const CameraState());

  CameraController? _controller;

  /// Request camera permission then initialize the rear camera at max resolution.
  ///
  /// Call order:
  ///   1. `permission_handler` to check / request [Permission.camera]
  ///   2. On grant → enumerate cameras and open the rear lens
  ///   3. On denial → set [CameraState.isPermissionDenied] = true
  Future<void> initialize() async {
    if (state.isInitializing) return;
    state = state.copyWith(isInitializing: true, error: null);

    // ── 1. Permission gate ────────────────────────────────────────────────
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      state = state.copyWith(
        isInitializing: false,
        isPermissionDenied: true,
        error: status.isPermanentlyDenied
            ? 'Camera access permanently denied. Enable it in Settings > H₂S Detector.'
            : 'Camera permission is required to scan dosimeter strips.',
      );
      return;
    }

    // ── 2. Enumerate cameras ──────────────────────────────────────────────
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          isInitializing: false,
          error: 'No camera hardware found on this device.',
        );
        return;
      }

      // Prefer the rear camera
      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // ── 3. Open at maximum resolution for accurate colorimetry ─────────
      _controller = CameraController(
        rearCamera,
        ResolutionPreset.max, // highest resolution available
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Auto-focus and auto-exposure give the best colorimetric accuracy
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      state = state.copyWith(
        controller: _controller,
        isInitializing: false,
        isPermissionDenied: false,
      );
    } on CameraException catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: _friendlyError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: e.toString(),
      );
    }
  }

  /// Release the camera resources.
  Future<void> releaseCamera() async {
    await _controller?.dispose();
    _controller = null;
    state = const CameraState();
  }

  /// Open the device's app settings so the user can grant camera permission.
  Future<void> openSettings() => openAppSettings();

  String _friendlyError(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return 'Camera permission denied. Grant access in device Settings.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera access permanently denied. Enable it in Settings > H₂S Detector.';
      default:
        return 'Camera error (${e.code}): ${e.description}';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Global camera provider.
final cameraProvider =
    StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});
