import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/widgets/bottom_nav_bar.dart';

void main() {
  AppLogger.setMuted(true);

  testWidgets('BottomNavBar renders three icon tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            selectedIndex: 0,
            onItemTapped: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cottage_rounded), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
  });
}
