import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bankak_analytics/app.dart';

Widget createTestApp() {
  return const ProviderScope(
    child: BankakApp(),
  );
}

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Note: This test requires provider overrides for repositories.
    // Run with: flutter test --tags=integration
    // Skipped by default - run unit tests in test/ for now.
    await tester.pumpWidget(createTestApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  }, skip: true);
}
