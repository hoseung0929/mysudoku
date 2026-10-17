import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sudoku159/main.dart' as app;
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';
import 'package:sudoku159/widgets/bottom_nav_bar.dart';

Future<void> _waitUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Widget not found within timeout: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  testWidgets('home to settings flow', (WidgetTester tester) async {
    app.main();

    await _waitUntilFound(tester, find.byType(BottomNavBar));
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await _waitUntilFound(tester, find.byType(SettingsScreen));
    expect(find.byKey(const Key('settings_content_padding')), findsOneWidget);
  });
}
