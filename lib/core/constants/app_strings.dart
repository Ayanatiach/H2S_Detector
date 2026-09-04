/// Application-wide string constants for H₂S Detector.
abstract final class AppStrings {
  // ── App Identity ──────────────────────────────────────────────────────────
  static const String appName = 'H₂S Detector';
  static const String appTagline = 'Industrial Dosimeter Reader';

  // ── Supabase ─────────────────────────────────────────────────────────────
  /// TODO: Replace with your Supabase project URL
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';

  /// TODO: Replace with your Supabase anon key
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  static const String supabaseTable = 'dosimeter_logs';

  // ── Scanner ───────────────────────────────────────────────────────────────
  static const String scannerTitle = 'Dosimeter Scanner';
  static const String alignPrompt = 'ALIGN DOSIMETER STRIP WITHIN FRAME';
  static const String captureButton = 'CAPTURE & ANALYZE';
  static const String lowLightWarning = '⚠ LOW LIGHT — Improve lighting for accurate reading';
  static const String processingLabel = 'PROCESSING SAMPLE…';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static const String dashboardTitle = 'Safety Dashboard';
  static const String latestReading = 'Latest Reading';
  static const String exposureTimeline = 'Exposure Timeline (Shift)';
  static const String scanNewReading = 'SCAN NEW READING';
  static const String manualCalibration = 'Manual Calibration';
  static const String noReadingsYet = 'No readings recorded this shift.\nTap SCAN NEW READING to start monitoring.';
  static const String deltaELabel = 'ΔE Color Shift';
  static const String estimatedPpm = 'Est. Exposure';

  // ── Sync ──────────────────────────────────────────────────────────────────
  static const String syncStatusOnline = 'Synced';
  static const String syncStatusSyncing = 'Syncing…';
  static const String syncStatusOffline = 'Offline';
  static const String syncQueuedFormat = 'Offline (%d queued)';

  // ── Scan Result ───────────────────────────────────────────────────────────
  static const String scanResultTitle = 'Scan Result';
  static const String labValuesLabel = 'CIELAB Values';
  static const String saveReading = 'SAVE READING';
  static const String discardReading = 'DISCARD';
  static const String savedSuccess = 'Reading saved & queued for sync';

  // ── Errors ────────────────────────────────────────────────────────────────
  static const String errorCameraPermission =
      'Camera permission denied.\nGrant access in Settings to scan dosimeters.';
  static const String errorNoCameraHardware =
      'No rear camera detected on this device.';
  static const String errorCameraInit = 'Camera failed to initialize.';
  static const String errorAnalysis =
      'Color analysis failed. Ensure the dosimeter strip is well-lit.';
  static const String errorSyncFailed = 'Sync failed. Reading stored locally.';

  // ── Calibration ───────────────────────────────────────────────────────────
  static const String calibrationTitle = 'Baseline Calibration';
  static const String calibrationInfo =
      'Scan an unexposed (clean white) dosimeter strip to set your baseline.';
  static const String calibrationSet = 'BASELINE SET';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String prefWorkerId = 'worker_id';
  static const String prefOfflineQueue = 'offline_queue';
  static const String prefBaselineL = 'baseline_l';
  static const String prefBaselineA = 'baseline_a';
  static const String prefBaselineB = 'baseline_b';
}
