import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_strings.dart';
import 'providers/worker_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load or generate a persistent worker UUID
  final workerId = await loadWorkerId();

  // Initialize Supabase
  // NOTE: Replace the URL and anon key in AppStrings with your project values.
  try {
    await Supabase.initialize(
      url: AppStrings.supabaseUrl,
      publishableKey: AppStrings.supabaseAnonKey,
      debug: false,
    );
  } catch (e) {
    // Supabase init failed (e.g. placeholder credentials) — app runs in
    // offline-only mode. Readings are queued locally until credentials are set.
    debugPrint('⚠️  Supabase init failed (offline mode): $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        // Inject the resolved worker ID into the provider tree
        workerIdProvider.overrideWithValue(workerId),
      ],
      child: const H2sDetectorApp(),
    ),
  );
}
