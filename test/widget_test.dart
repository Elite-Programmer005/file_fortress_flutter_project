import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We provide a valid initial route for the test.
    await tester.pumpWidget(const FileFortressApp(initialRoute: Routes.setupPin));

    // Verify that the app starts and a Scaffold is rendered.
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
