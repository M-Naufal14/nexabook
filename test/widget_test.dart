// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:nexabook/main.dart';

void main() {
  testWidgets('Splash page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that Splash Page displays the main slogan.
    expect(find.text('Booking Visual Jadi Mudah'), findsOneWidget);

    // Verify that Splash Page has Login.
    expect(find.text('Login'), findsOneWidget);

    // Verify that Splash Page does NOT have the old Vendor Portal button.
    expect(find.text('Vendor Portal'), findsNothing);

    // Tap on Login to navigate to LoginPage.
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Verify we are on the LoginPage and it has the Buka Vendor Portal button.
    expect(find.text('Buka Vendor Portal'), findsOneWidget);
  });
}
