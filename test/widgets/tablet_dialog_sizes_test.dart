import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/widgets/game_over_dialog.dart';
import 'package:sudoku159/widgets/replay_confirm_dialog.dart';

void main() {
  Future<void> pump(WidgetTester tester, Size size, Widget Function() open,
      {double textScale = 1.0, Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showReplayConfirmDialog(context, gameNumber: 7),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  double dialogWidth(WidgetTester tester) => tester
      .getSize(find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first)
      .width;

  for (final entry in {
    'phone': (const Size(390, 844), 340.0),
    'tablet portrait': (const Size(834, 1194), 440.0),
    'tablet landscape': (const Size(1194, 834), 440.0),
  }.entries) {
    testWidgets('replay dialog max width: ${entry.key}', (tester) async {
      await pump(tester, entry.value.$1, () => const SizedBox());
      expect(dialogWidth(tester), entry.value.$2);
      expect(tester.takeException(), isNull);
    });
  }

  for (final lang in ['en', 'ko', 'ja', 'es', 'zh']) {
    testWidgets('replay dialog fits on a low tablet at 1.3x: $lang',
        (tester) async {
      await pump(tester, const Size(1024, 600), () => const SizedBox(),
          textScale: 1.3, locale: Locale(lang));
      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  }

  for (final e in {
    'phone': (const Size(390, 844), 350.0),
    'tablet': (const Size(834, 1194), 480.0),
  }.entries) {
    testWidgets('game over dialog width: ${e.key}', (tester) async {
      tester.view.physicalSize = e.value.$1;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => GameOverDialog(
                  wrongCount: 3,
                  maxWrongCount: 3,
                  onRestart: () {},
                  onGoToLevelSelection: () {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(dialogWidth(tester), e.value.$2);
      expect(tester.takeException(), isNull);
    });
  }
}
