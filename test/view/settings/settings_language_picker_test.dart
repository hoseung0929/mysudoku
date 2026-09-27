import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_locale_scope.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  Future<void> pumpSettings(
    WidgetTester tester, {
    required ValueChanged<Locale?> onSetLocale,
  }) async {
    SharedPreferences.setMockInitialValues({});
    const appLocale = Locale('ko');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: appLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppLocaleScope(
          appLocale: appLocale,
          setAppLocale: (locale) async {
            onSetLocale(locale);
          },
          child: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // 언어 옵션마다 각자 pop 후 setAppLocale을 부르던 예전 코드는 5곳에
  // 똑같은 비동기 로직이 중복돼 있었다. 고른 Locale을 시트의 팝 결과로만
  // 반환하고, setAppLocale은 한 곳에서 정확히 한 번만 호출하도록 정리했다
  // — 그 결과 시트가 완전히 닫힌 뒤에도 화면이 계속 반응하는지(오버레이가
  // 남아 있지 않은지) 함께 검증한다.
  testWidgets('selecting a language applies it exactly once, then closes',
      (tester) async {
    Locale? applied;
    var applyCount = 0;
    await pumpSettings(tester, onSetLocale: (locale) {
      applied = locale;
      applyCount++;
    });

    await tester.tap(find.text('언어 설정'));
    await tester.pumpAndSettle();

    expect(find.text('日本語'), findsOneWidget);
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();

    expect(applyCount, 1);
    expect(applied, const Locale('ja'));

    // 시트가 완전히 사라져 오버레이 배리어가 남아있지 않고, 화면이 계속
    // 반응하는지(테마 카드·언어 설정 다시 열기가 여전히 되는지) 확인한다.
    expect(find.text('日本語'), findsNothing);
    expect(find.text('테마'), findsOneWidget);
    await tester.tap(find.text('언어 설정'));
    await tester.pumpAndSettle();
    expect(find.text('언어 선택'), findsOneWidget);
  });
}
