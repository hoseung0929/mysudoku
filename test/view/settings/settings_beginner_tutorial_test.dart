import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/onboarding/beginner_tutorial_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/onboarding/beginner_tutorial_screen.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  Future<void> pumpSettings(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('How to play opens the tutorial in replay mode', (tester) async {
    await pumpSettings(tester);
    await tester.scrollUntilVisible(
      find.text('How to play'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('How to play'), findsOneWidget);

    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();

    expect(find.byType(BeginnerTutorialScreen), findsOneWidget);
    final widget = tester
        .widget<BeginnerTutorialScreen>(find.byType(BeginnerTutorialScreen));
    expect(widget.isReplay, isTrue);
  });

  testWidgets(
      'replaying does not require the tutorial to have been seen before',
      (tester) async {
    await pumpSettings(tester);
    expect(
      await BeginnerTutorialService().getState(),
      BeginnerTutorialState.unseen,
    );

    await tester.scrollUntilVisible(
      find.text('How to play'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.byType(BeginnerTutorialScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
