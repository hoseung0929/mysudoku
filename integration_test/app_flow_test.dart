import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mysudoku/main.dart' as app;
import 'package:mysudoku/utils/app_logger.dart';

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

    await _waitUntilFound(tester, find.text('홈'));
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);

    await _waitUntilFound(tester, find.text('게스트'));
    expect(find.text('스도쿠에 오신 것을 환영합니다 👋'), findsOneWidget);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await _waitUntilFound(tester, find.text('알림'));
    expect(find.text('알림 설정'), findsOneWidget);
  });
}
