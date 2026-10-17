import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/settings/keypad_placement_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  Future<void> pumpSettings(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    ));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('keypad position setting is shown on iPad and hidden on iPhone',
      (tester) async {
    await pumpSettings(tester, const Size(834, 1194));
    expect(find.text('키패드 위치'), findsOneWidget);
    expect(find.text('세로 모드'), findsOneWidget);
    expect(find.text('가로 모드'), findsOneWidget);

    await pumpSettings(tester, const Size(390, 844));
    expect(find.text('키패드 위치'), findsNothing);
  });

  testWidgets('choosing a position is saved per orientation', (tester) async {
    await pumpSettings(tester, const Size(834, 1194));
    for (final key in [
      'keypad-placement-portrait',
      'keypad-placement-landscape'
    ]) {
      final button = find.byKey(ValueKey(key));
      await tester.ensureVisible(button);
      await tester.tap(find.descendant(of: button, matching: find.text('왼쪽')));
      await tester.pump();
    }

    final service = KeypadPlacementService();
    expect(await service.portrait(), KeypadPlacement.left);
    expect(await service.landscape(), KeypadPlacement.left);
  });
}
