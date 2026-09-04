import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/camera_provider.dart';
import '../../providers/scan_provider.dart';
import '../../providers/baseline_provider.dart';
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
    final size = MediaQuery.of(context).size;
    final cameraRatio = controller.value.aspectRatio;
    final screenRatio = size.height / size.width;

    return ClipRect(
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
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            widget.isCalibrationMode
                ? 'CALIBRATE'
                : AppStrings.scannerTitle.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: widget.isCalibrationMode
                  ? AppColors.warning
                  : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
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
        ? AppColors.warning
        : AppColors.reticle;

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
