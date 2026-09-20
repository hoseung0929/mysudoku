import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/widgets/profile_glass_header.dart';

Widget _app(Widget child, {double textScale = 1.0}) => MaterialApp(
      theme: AppTheme.lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
      home: Scaffold(body: Align(alignment: Alignment.topCenter, child: child)),
    );

ProfileGlassHeader _header({
  String? name,
  VoidCallback? onEdit,
  VoidCallback? onSettings,
}) =>
    ProfileGlassHeader(
      isTop: true,
      profileName: name,
      guestTitle: 'Traveler',
      profileImagePath: null,
      onTapSettings: onSettings ?? () {},
      onTapEditProfile: onEdit,
    );

void main() {
  testWidgets('default header is one compact row (~64) without a subtitle',
      (tester) async {
    await tester.pumpWidget(_app(_header()));
    expect(find.text('Traveler'), findsOneWidget);
    // 인사말/소개는 홈 헤더에서 보여주지 않는다.
    expect(find.textContaining('puzzle'), findsNothing);
    final h = tester.getSize(find.byType(ProfileGlassHeader)).height;
    expect(h, inInclusiveRange(60, 68));
  });

  testWidgets('touch targets and callbacks', (tester) async {
    var edited = 0;
    var settings = 0;
    await tester.pumpWidget(
      _app(_header(onEdit: () => edited++, onSettings: () => settings++)),
    );
    final settingsBox = tester.getSize(find.byTooltip('Settings'));
    expect(settingsBox.width, greaterThanOrEqualTo(44));
    expect(settingsBox.height, greaterThanOrEqualTo(44));

    await tester.tap(find.text('Traveler'));
    await tester.tap(find.byTooltip('Settings'));
    expect(edited, 1);
    expect(settings, 1);
  });

  for (final scale in [1.0, 2.3]) {
    testWidgets('long name at ${scale}x: two lines max, settings stays',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const name =
          'A very long traveler nickname that will not fit on a single line';
      await tester.pumpWidget(_app(_header(name: name), textScale: scale));
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Settings'), findsOneWidget);
      // 접근성에는 잘리지 않은 전체 이름이 전달된다.
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(name), findsWidgets);
      handle.dispose();
      final text = tester.widget<Text>(find.text(name));
      expect(text.maxLines, 2);
      if (scale > 1.0) {
        // 줄이지 않고 높이가 늘어난다.
        expect(
          tester.getSize(find.byType(ProfileGlassHeader)).height,
          greaterThan(64),
        );
      }
    });
  }
}
