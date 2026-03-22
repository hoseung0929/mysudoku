import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/widgets/bottom_nav_bar.dart';

void main() {
  AppLogger.setMuted(true);

  testWidgets('BottomNavBar renders four tabs (KO)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            selectedIndex: 0,
            onItemTapped: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('챌린지'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
