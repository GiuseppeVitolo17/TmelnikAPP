import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmelnik_app/widgets/project_card.dart';

void main() {
  testWidgets('ProjectCard displays title and dates', (WidgetTester tester) async {
    // Build ProjectCard widget wrapped in MaterialApp
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectCard(
            title: 'Project Berlin',
            dates: '14 July / 19 July',
            imagePathOrUrl: 'assets/images/placeholder.jpg',
            onApply: () {},
            onInfo: () {},
          ),
        ),
      ),
    );

    // Verify title text exists
    expect(find.text('Project Berlin'), findsOneWidget);

    // Verify dates text exists
    expect(find.text('14 July / 19 July'), findsOneWidget);

    // Verify buttons exist
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Infopack'), findsOneWidget);
  });
}

