import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('BottomNavBar renders three tabs', (WidgetTester tester) async {
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

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
