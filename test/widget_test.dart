import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tmelnik_app/main.dart';

void main() {
  testWidgets('App loads main navigation screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TmelnikApp());

    // Verify that our app loads with the main navigation screen.
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
  });
}
