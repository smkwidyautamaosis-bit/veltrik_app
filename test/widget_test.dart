// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:veltrik/main.dart';

void main() {
  testWidgets('Initial screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VeltrikApp());

    // Verify that the title text is found.
    expect(find.text('Veltrik App'), findsOneWidget);
    expect(find.text('Enter access code to proceed'), findsOneWidget);
  });
}
