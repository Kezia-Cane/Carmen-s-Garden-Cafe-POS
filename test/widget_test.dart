// Basic widget test for Carmen's Garden Cafe POS

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carmen_garden_pos/app.dart';

void main() {
  testWidgets('App smoke test - splash screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CarmenGardenApp(),
      ),
    );

    // Verify splash screen shows app name
    expect(find.text("Carmen's Garden"), findsOneWidget);
  });
}
