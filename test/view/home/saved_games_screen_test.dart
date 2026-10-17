import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/saved_games_screen.dart';

final _levelA = SudokuLevel.levels[0];
final _levelB = SudokuLevel.levels[1];

List<List<int>> _solution() => List.generate(
      9,
      (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
    );

List<List<int>> _puzzle(SudokuLevel level) {
  final b = _solution();
  for (var i = 0; i < level.emptyCells; i++) {
    b[i ~/ 9][i % 9] = 0;
  }
  return b;
}

SudokuGame _game(SudokuLevel level, int number) => SudokuGame(
      board: _puzzle(level),
      solution: _solution(),
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: number,
    );

ContinueGameSummary _summary(
  SudokuLevel level,
  int number, {
  int lastPlayedAtMillis = 0,
}) =>
    ContinueGameSummary(
      level: level,
      game: _game(level, number),
      progress: 0.4,
      elapsedFilledCells: 10,
      lastPlayedAtMillis: lastPlayedAtMillis,
      elapsedSeconds: 60,
      wrongCount: 0,
      isMemoMode: false,
      noteCount: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<ContinueGameSummary> games,
    required Future<List<ContinueGameSummary>> Function(
      ContinueGameSummary summary,
    ) onDelete,
    bool reduceMotion = false,
    Size size = const Size(390, 844),
    ThemeData? theme,
    String deleteTooltip = 'Delete',
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: theme ?? AppTheme.lightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<ContinueGameSummary>(
                      builder: (context) => SavedGamesScreen(
                        initialGames: games,
                        title: 'Saved',
                        description: 'desc',
                        itemTitleBuilder: (s) =>
                            '${s.level.name} #${s.game.gameNumber}',
                        itemSubtitleBuilder: (s) => 'subtitle',
                        deleteTooltip: deleteTooltip,
                        onDelete: onDelete,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDelete(WidgetTester tester, {required int cardIndex}) async {
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).at(cardIndex));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
  }

  testWidgets(
      'loading indicator shows only on the tapped row; other rows stay usable',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gameB = _summary(_levelA, 2, lastPlayedAtMillis: 200);
    final gate = Completer<List<ContinueGameSummary>>();
    await pumpScreen(
      tester,
      games: [gameA, gameB],
      onDelete: (_) => gate.future,
    );

    // 최신순 정렬이라 gameB(200)가 위, gameA(100)가 아래.
    expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(2));
    await tapDelete(tester, cardIndex: 0);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    final remainingMenu = tester.widget<PopupMenuButton>(
      find.byKey(const ValueKey('saved-game-actions-menu')),
    );
    expect(remainingMenu.enabled, isFalse);

    // 삭제 중이 아닌 카드의 이어하기 버튼은 여전히 사용할 수 있다.
    final continueButtons = tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    );
    expect(continueButtons.where((button) => button.onPressed != null),
        hasLength(1));

    gate.complete([gameA, gameB]);
    await tester.pumpAndSettle();
  });

  testWidgets('redesigned list fits iPhone and iPad layouts in both themes',
      (tester) async {
    final games = [
      _summary(_levelA, 1, lastPlayedAtMillis: 100),
      _summary(_levelB, 2, lastPlayedAtMillis: 200),
    ];

    await pumpScreen(
      tester,
      games: games,
      onDelete: (_) async => games,
    );
    expect(
      find.byKey(const ValueKey('saved-game-level-image')),
      findsNWidgets(2),
    );
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('saved-games-sort-menu')),
      findsOneWidget,
    );
    final phoneFirst =
        tester.getTopLeft(find.byKey(ValueKey('${_levelB.name}#2')));
    final phoneSecond =
        tester.getTopLeft(find.byKey(ValueKey('${_levelA.name}#1')));
    expect(phoneFirst.dx, phoneSecond.dx);
    expect(phoneFirst.dy, isNot(phoneSecond.dy));
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      games: games,
      onDelete: (_) async => games,
      size: const Size(1024, 1366),
      theme: AppTheme.darkTheme(),
    );
    expect(
      find.byKey(const ValueKey('saved-game-level-image')),
      findsNWidgets(2),
    );
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    final tabletFirst =
        tester.getTopLeft(find.byKey(ValueKey('${_levelB.name}#2')));
    final tabletSecond =
        tester.getTopLeft(find.byKey(ValueKey('${_levelA.name}#1')));
    expect(tabletFirst.dx, isNot(tabletSecond.dx));
    expect(tabletFirst.dy, tabletSecond.dy);
    expect(tester.takeException(), isNull);
  });

  testWidgets('difficulty filters use the active locale and canonical order',
      (tester) async {
    final games = [
      _summary(_levelB, 2),
      _summary(_levelA, 1),
    ];
    await pumpScreen(
      tester,
      games: games,
      locale: const Locale('en'),
      onDelete: (_) async => games,
    );

    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('초급'), findsNothing);
    expect(find.text('중급'), findsNothing);

    final allCenter = tester.getCenter(find.text('All'));
    final beginnerCenter = tester.getCenter(find.text('Beginner'));
    expect(allCenter.dy, beginnerCenter.dy);

    final filterRect = tester.getRect(
      find.byKey(const ValueKey('saved-games-level-filter')),
    );
    final sortRect = tester.getRect(
      find.byKey(const ValueKey('saved-games-sort-menu')),
    );
    expect(filterRect.top, sortRect.top);
    expect(filterRect.bottom, sortRect.bottom);

    await tester.drag(
      find.byKey(const ValueKey('saved-games-level-filter-list')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('중급'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('level filter highlight slides to the tapped chip',
      (tester) async {
    final games = [_summary(_levelA, 1), _summary(_levelA, 2)];
    await pumpScreen(
      tester,
      games: games,
      size: const Size(834, 1194),
      onDelete: (_) async => games,
    );

    final slide = find.byKey(const ValueKey('saved-games-level-filter-slide'));
    expect(slide, findsOneWidget);
    Finder highlight() => find
        .descendant(of: slide, matching: find.byType(AnimatedPositioned))
        .first;
    final before = tester.getTopLeft(highlight()).dx;

    await tester.tap(find.text('Beginner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getTopLeft(highlight()).dx;
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(highlight()).dx;

    expect(after, greaterThan(before));
    expect(mid, greaterThan(before));
    expect(mid, lessThan(after));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long localized delete label fits inside the popup menu',
      (tester) async {
    final game = _summary(_levelA, 1);
    await pumpScreen(
      tester,
      games: [game],
      deleteTooltip: 'Borrar progreso guardado',
      size: const Size(320, 640),
      onDelete: (_) async => [game],
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Borrar progreso guardado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('level filter shows directional hints only when more is hidden',
      (tester) async {
    final games = [
      for (var index = 0; index < SudokuLevel.levels.length; index++)
        _summary(SudokuLevel.levels[index], index + 1),
    ];
    await pumpScreen(
      tester,
      games: games,
      size: const Size(390, 844),
      onDelete: (_) async => games,
    );

    expect(
      find.byKey(const ValueKey('saved-games-filter-more-right')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('saved-games-filter-more-left')),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const ValueKey('saved-games-level-filter-list')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('saved-games-filter-more-left')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('row is removed from the list once deletion succeeds',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gameB = _summary(_levelA, 2, lastPlayedAtMillis: 200);
    await pumpScreen(
      tester,
      games: [gameA, gameB],
      onDelete: (s) async => [gameB],
    );

    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.textContaining('#2'), findsOneWidget);

    await tapDelete(tester, cardIndex: 1);
    // 제거 애니메이션(170ms) 진행 중에는 아직 남아 있다.
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('#1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.textContaining('#1'), findsNothing);
    expect(find.textContaining('#2'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog keeps the row and restores icon',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gate = Completer<List<ContinueGameSummary>>();
    await pumpScreen(
      tester,
      games: [gameA],
      onDelete: (s) => gate.future,
    );

    await tapDelete(tester, cardIndex: 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete([gameA]);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    expect(find.textContaining('#1'), findsOneWidget);
  });

  testWidgets('deleting the last item closes the screen after the animation',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    await pumpScreen(
      tester,
      games: [gameA],
      onDelete: (s) async => [],
    );

    expect(find.text('Saved'), findsOneWidget);
    await tapDelete(tester, cardIndex: 0);
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('reduce motion removes the row instantly, no lingering state',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gameB = _summary(_levelA, 2, lastPlayedAtMillis: 200);
    await pumpScreen(
      tester,
      games: [gameA, gameB],
      onDelete: (s) async => [gameB],
      reduceMotion: true,
    );

    await tapDelete(tester, cardIndex: 1);
    // 애니메이션 프레임을 더 기다리지 않아도 즉시 반영된다.
    expect(find.textContaining('#1'), findsNothing);
    expect(find.textContaining('#2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting under an active filter removes the correct puzzle',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 300);
    final gameB = _summary(_levelB, 5, lastPlayedAtMillis: 200);
    final gameC = _summary(_levelA, 3, lastPlayedAtMillis: 100);
    await pumpScreen(
      tester,
      games: [gameA, gameB, gameC],
      onDelete: (s) async => [gameA, gameB, gameC]..removeWhere((g) =>
          g.level.name == s.level.name &&
          g.game.gameNumber == s.game.gameNumber),
    );

    // levelA만 필터링: gameA(#1), gameC(#3)
    await tester.tap(find.text('Beginner'));
    await tester.pump();
    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.textContaining('#3'), findsOneWidget);
    expect(find.textContaining('#5'), findsNothing);

    // 필터 안에서 두 번째(#3, 더 오래된 것)를 삭제해도 정확히 그 항목만 사라진다.
    await tapDelete(tester, cardIndex: 1);
    await tester.pumpAndSettle();
    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.textContaining('#3'), findsNothing);
  });

  testWidgets(
      'a failed delete keeps the row, clears loading, re-enables buttons, and shows a SnackBar',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gameB = _summary(_levelA, 2, lastPlayedAtMillis: 200);
    var gate = Completer<List<ContinueGameSummary>>();
    await pumpScreen(
      tester,
      games: [gameA, gameB],
      onDelete: (s) => gate.future,
    );

    await tapDelete(tester, cardIndex: 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.completeError(Exception('boom'));
    await tester.pumpAndSettle();

    // 대상 카드가 그대로 남아 있고, 로딩이 사라지고, 메뉴가 다시 활성화된다.
    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(2));
    for (final menu in tester.widgetList<PopupMenuButton>(
      find.byKey(const ValueKey('saved-game-actions-menu')),
    )) {
      expect(menu.enabled, isTrue);
    }
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 실패 후 같은 항목을 다시 삭제할 수 있다.
    gate = Completer<List<ContinueGameSummary>>();
    await tapDelete(tester, cardIndex: 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete([gameB]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('#1'), findsNothing);
  });
}
