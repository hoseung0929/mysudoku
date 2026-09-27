import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  for (final entry in {
    'small phone 2x': (const Size(320, 568), 2.0, false, 'ko'),
    'phone 1.3x dark es': (const Size(390, 844), 1.3, true, 'es'),
    'tablet portrait': (const Size(768, 1024), 1.0, false, 'en'),
    'tablet landscape dark': (const Size(1024, 768), 1.0, true, 'ja'),
  }.entries) {
    testWidgets('settings renders without overflow: ${entry.key}',
        (tester) async {
      final (size, scale, dark, lang) = entry.value;
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const SettingsScreen(),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> pumpSettings(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool pushed = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: pushed
            ? Navigator(
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: Builder(
                      builder: (context) => TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ),
                        child: const Text('open'),
                      ),
                    ),
                  ),
                ),
              )
            : const SettingsScreen(),
      ),
    );
    await tester.pump();
    if (pushed) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets(
      'mobile horizontal padding is 16px, tablet is 24px, capped at 960 wide',
      (tester) async {
    await pumpSettings(tester);
    final mobilePadding = tester
        .widget<Padding>(find.byKey(const Key('settings_content_padding')))
        .padding as EdgeInsets;
    expect(mobilePadding.left, 16);
    expect(mobilePadding.right, 16);

    await pumpSettings(tester, size: const Size(768, 1024));
    final tabletPadding = tester
        .widget<Padding>(find.byKey(const Key('settings_content_padding')))
        .padding as EdgeInsets;
    expect(tabletPadding.left, 24);
    expect(tabletPadding.right, 24);
    expect(
      tester.getSize(find.byKey(const Key('settings_content_padding'))).width,
      lessThanOrEqualTo(960),
    );
  });

  testWidgets('shown as a bottom tab: no back button', (tester) async {
    await pumpSettings(tester);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('opened via Navigator.push: back button is shown',
      (tester) async {
    await pumpSettings(tester, pushed: true);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });
}
