import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/kinetic_colors.dart';
import '../../providers/camera_provider.dart';
import '../../providers/scan_provider.dart';
import '../../providers/baseline_provider.dart';
import '../../widgets/calibration_required_dialog.dart';
import 'scanner_overlay.dart';
import 'scan_result_screen.dart';

/// Full-screen camera scanner screen for dosimeter strip reading.
///
/// State machine:
///   1. [_PermissionState] — before / after permission decision
///   2. [_LoadingState]    — CameraController initializing
///   3. [_LiveState]       — live preview + targeting reticle
///   4. [_CapturingState]  — shutter pressed, analysis running
///   5. [_ErrorState]      — generic camera error
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, this.isCalibrationMode = false});

  /// When true, the captured scan sets the baseline instead of logging a reading.
  final bool isCalibrationMode;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isCapturing = false;

  // ── Zoom state ───────────────────────────────────────────────────────────
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  bool _zoomInitialized = false;

  Future<void> _checkAndInitZoom(CameraController controller) async {
    if (_zoomInitialized) return;
    try {
      final minZ = await controller.getMinZoomLevel();
      final maxZ = await controller.getMaxZoomLevel();
      if (mounted) {
        setState(() {
          _minZoom = minZ;
          _maxZoom = math.max(minZ, math.min(maxZ, 8.0));
          _currentZoom = minZ;
          _zoomInitialized = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _setZoomLevel(double zoom) async {
    final camState = ref.read(cameraProvider);
    if (!camState.isReady) return;
    final target = zoom.clamp(_minZoom, _maxZoom);
    setState(() => _currentZoom = target);
    try {
      await camState.controller?.setZoomLevel(target);
    } catch (_) {}
  }

  // ── FAB pulse animation ──────────────────────────────────────────────────
  late final AnimationController _fabPulse;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();

    // Lock to portrait for accurate dosimeter framing
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // FAB subtle pulse when idle
    _fabPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _fabScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _fabPulse, curve: Curves.easeInOut),
    );

    // Kick off permission check + camera init on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _fabPulse.dispose();
    super.dispose();
  }

  // ── Capture & Analyze ────────────────────────────────────────────────────

  Future<void> _captureAndAnalyze() async {
    final camState = ref.read(cameraProvider);
    if (!camState.isReady || _isCapturing) return;

    // Check if calibration has occurred before capturing an exposure reading
    if (!widget.isCalibrationMode) {
      final baseline = ref.read(baselineProvider);
      if (!baseline.isCalibrated) {
        final shouldCalibrate = await showCalibrationRequiredDialog(context);
        if (shouldCalibrate == true && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const ScannerScreen(isCalibrationMode: true),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      final controller = camState.controller!;
      final file = await controller.takePicture();

      if (widget.isCalibrationMode) {
        // ── Calibration path: store the LAB of the clean strip as the new baseline
        await ref.read(scanProvider.notifier).analyzeCapture(
              file,
              // Compare against pure-white so we get absolute LAB values back
              baselineL: 100.0,
              baselineA: 0.0,
              baselineB: 0.0,
            );

        if (mounted) {
          setState(() => _isCapturing = false);
          final scanState = ref.read(scanProvider);
          final reading = scanState.latestResult;
          if (reading != null) {
            // Persist the scanned strip's own LAB as the new baseline
            await ref.read(baselineProvider.notifier).setBaseline(
                  reading.labL,
                  reading.labA,
                  reading.labB,
                );
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Baseline set  •  L*=${reading.labL.toStringAsFixed(1)}  '
                    'a*=${reading.labA.toStringAsFixed(1)}  '
                    'b*=${reading.labB.toStringAsFixed(1)}',
                    style: GoogleFonts.jetBrainsMono(
                        color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppColors.safe,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      } else {
        // ── Normal scan path: compare against stored baseline
        final baseline = ref.read(baselineProvider);
        await ref.read(scanProvider.notifier).analyzeCapture(
              file,
              baselineL: baseline.l,
              baselineA: baseline.a,
              baselineB: baseline.b,
            );

        if (mounted) {
          setState(() => _isCapturing = false);
          final scanState = ref.read(scanProvider);
          if (scanState.latestResult != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScanResultScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorAnalysis,
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraProvider);
    final scanState = ref.watch(scanProvider);
    final isAnalyzing = scanState.isAnalyzing;
    final isBusy = _isCapturing || isAnalyzing;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Camera preview / state screens ──────────────────────────
          if (camState.isPermissionDenied)
            _PermissionDeniedView(
              isPermanent: camState.error?.contains('permanently') ?? false,
              onRetry: () => ref.read(cameraProvider.notifier).initialize(),
              onOpenSettings:
                  () => ref.read(cameraProvider.notifier).openSettings(),
            )
          else if (camState.isReady)
            _buildCameraPreview(camState.controller!)
          else if (camState.isInitializing)
            _buildInitializingView()
          else if (camState.error != null)
            _buildErrorView(camState.error!),

          // ── 2. Targeting overlay (only when camera is live) ─────────────
          if (camState.isReady) ScannerOverlay(isCapturing: isBusy),

          // ── 3. UI chrome ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                if (widget.isCalibrationMode) _buildCalibrationBanner(),
                const Spacer(),
                if (isAnalyzing) _buildAnalyzingBanner(),
                if (camState.isReady || camState.isInitializing)
                  _buildBottomArea(camState, isBusy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Camera preview ───────────────────────────────────────────────────────

  Widget _buildCameraPreview(CameraController controller) {
    _checkAndInitZoom(controller);

    final size = MediaQuery.of(context).size;
    final cameraRatio = controller.value.aspectRatio;
    final screenRatio = size.height / size.width;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (details) {
        _baseZoom = _currentZoom;
      },
      onScaleUpdate: (details) {
        if (details.pointerCount >= 2) {
          final target = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
          _setZoomLevel(target);
        }
      },
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.width *
                  (screenRatio > cameraRatio ? screenRatio : cameraRatio),
              child: CameraPreview(controller),
            ),
          ),
        ),
      ),
    );
  }

  // ── Initializing spinner ─────────────────────────────────────────────────

  Widget _buildInitializingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.reticle,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'INITIALIZING CAMERA…',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.reticle.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error view ───────────────────────────────────────────────────────────

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded,
                color: AppColors.critical, size: 64),
            const SizedBox(height: 20),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.read(cameraProvider.notifier).initialize(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('RETRY',
                  style: GoogleFonts.jetBrainsMono(letterSpacing: 1.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.reticle,
                side: const BorderSide(color: AppColors.reticle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calibration mode banner ───────────────────────────────────────────────

  Widget _buildCalibrationBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'CALIBRATION MODE — Hold an UNEXPOSED dosimeter strip in the frame',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.warning,
                fontSize: 10,
                letterSpacing: 1,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white24),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          // Optical Link Active HUD Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: KineticColors.emeraldSafe,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isCalibrationMode
                      ? 'CALIBRATION MODE'
                      : 'OPTICAL LINK ACTIVE',
                  style: GoogleFonts.barlowCondensed(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Night vision / lighting indicator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.flash_auto_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── Analyzing banner ─────────────────────────────────────────────────────

  Widget _buildAnalyzingBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.reticle.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.reticle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppStrings.processingLabel,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.reticle,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom area: circular shutter button ─────────────────────────────────

  Widget _buildBottomArea(CameraState camState, bool isBusy) {
    final bool canCapture = camState.isReady && !isBusy;
    final Color ringColor = widget.isCalibrationMode
        ? KineticColors.amber
        : KineticColors.blazeOrange;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Zoom controls ──────────────────────────────────────────────
          if (camState.isReady && _maxZoom > 1.0) _buildZoomBar(),

          // ── Circular shutter button ────────────────────────────────────
          ScaleTransition(
            scale: isBusy
                ? const AlwaysStoppedAnimation<double>(1.0)
                : _fabScale,
            child: GestureDetector(
              onTap: canCapture ? _captureAndAnalyze : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBusy
                      ? AppColors.border
                      : ringColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: isBusy ? AppColors.border : ringColor,
                    width: 3,
                  ),
                  boxShadow: isBusy
                      ? null
                      : [
                          BoxShadow(
                            color: ringColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isBusy ? AppColors.border : ringColor,
                    ),
                    child: isBusy
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Label ──────────────────────────────────────────────────────
          Text(
            isBusy
                ? AppStrings.processingLabel
                : AppStrings.captureButton,
            style: GoogleFonts.jetBrainsMono(
              color: isBusy
                  ? AppColors.textSecondary
                  : ringColor,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Zoom controls UI ─────────────────────────────────────────────────────

  Widget _buildZoomBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildZoomChip(1.0, '1x'),
          if (_maxZoom >= 2.0) ...[
            const SizedBox(width: 4),
            _buildZoomChip(2.0, '2x'),
          ],
          if (_maxZoom >= 3.0) ...[
            const SizedBox(width: 4),
            _buildZoomChip(3.0, '3x'),
          ],
          if ((_currentZoom - 1.0).abs() > 0.15 &&
              (_currentZoom - 2.0).abs() > 0.15 &&
              (_currentZoom - 3.0).abs() > 0.15) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.reticle.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.reticle.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Text(
                '${_currentZoom.toStringAsFixed(1)}x',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.reticle,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoomChip(double level, String label) {
    final isSelected = (_currentZoom - level).abs() < 0.15;
    final activeColor = widget.isCalibrationMode
        ? AppColors.warning
        : AppColors.reticle;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _setZoomLevel(level);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission denied screen
// ─────────────────────────────────────────────────────────────────────────────

/// Shown when the user has denied (or permanently denied) camera permission.
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({
    required this.isPermanent,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final bool isPermanent;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.criticalBackground,
                border: Border.all(
                    color: AppColors.critical.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                color: AppColors.critical,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'CAMERA ACCESS REQUIRED',
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Body
            Text(
              isPermanent
                  ? AppStrings.errorCameraPermission
                  : 'Camera permission is needed to photograph\nthe dosimeter strip for H₂S analysis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // CTA — open Settings (permanent) or retry prompt (soft deny)
            if (isPermanent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: Text(
                    'OPEN SETTINGS',
                    style: GoogleFonts.jetBrainsMono(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(
                    'GRANT PERMISSION',
                    style: GoogleFonts.jetBrainsMono(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.reticle,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
