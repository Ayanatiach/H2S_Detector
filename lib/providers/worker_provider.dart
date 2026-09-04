import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_strings.dart';

/// Provider that returns (or generates) a persistent worker UUID.
///
/// On first launch, a UUID v4 is generated and stored in SharedPreferences.
/// Subsequent launches re-use the stored ID.
final workerIdProvider = Provider<String>((ref) {
  // This is a synchronous provider that requires SharedPreferences
  // to be pre-loaded. In main.dart we call _loadWorkerId() before
  // runApp() and pass the ID via ProviderScope overrides.
  throw UnimplementedError(
    'workerIdProvider must be overridden in ProviderScope with the actual ID.',
  );
});

/// Helper to load or generate the worker ID before the app starts.
Future<String> loadWorkerId() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString(AppStrings.prefWorkerId);
  if (id == null || id.isEmpty) {
    id = const Uuid().v4();
    await prefs.setString(AppStrings.prefWorkerId, id);
  }
  return id;
}
