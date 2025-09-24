import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tmelnik_app/main.dart';

void main() {
  testWidgets('App loads project list screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TmelnikApp());

    // Verify that our app loads with the project list screen.
    expect(find.text('Project Management'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
