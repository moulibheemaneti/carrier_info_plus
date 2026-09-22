// Verifies the example app's widget tree builds.
//
// It deliberately does not assert on carrier data. No plugin is registered in
// a widget test, so the platform call never answers and the app stays on its
// loading state -- which is also why this pumps a single frame rather than
// calling pumpAndSettle, whose progress indicator would spin forever.
//
// Anything about actual carrier values belongs in integration_test/, on a
// device where the platform side exists.

import 'package:carrier_info_plus_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds without a platform implementation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CarrierInfoApp());
    await tester.pump();

    expect(find.text('carrier_info_plus'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
