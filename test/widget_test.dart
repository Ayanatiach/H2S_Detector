import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:h2s_sentinel/app.dart';
import 'package:h2s_sentinel/providers/worker_provider.dart';

void main() {
  testWidgets('App renders dashboard without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workerIdProvider.overrideWithValue('test-worker-001'),
        ],
        child: const H2sDetectorApp(),
      ),
    );
    // Dashboard title should be visible
    expect(find.textContaining('H₂S'), findsWidgets);
  });
}
