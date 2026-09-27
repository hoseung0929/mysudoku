import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/widgets/bottom_nav_bar.dart';

void main() {
  AppLogger.setMuted(true);

  testWidgets('BottomNavBar renders three labeled tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
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

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
