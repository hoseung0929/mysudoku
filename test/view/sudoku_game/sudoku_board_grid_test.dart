import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/view/sudoku_game/game_effects_controller.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';

/// 실제 게임 로직은 필요 없고 보드 렌더링만 확인하므로, 콜백은 전부 비워 둔
/// 최소 프리젠터를 매번 새로 만든다(선택 상태를 공유하지 않기 위해).
SudokuGamePresenter _presenter() {
  final solution = List.generate(
    9,
    (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
  );
  final board = solution.map((r) => List<int>.from(r)).toList();
  return SudokuGamePresenter(
    level: SudokuLevel.levels.first,
    onBoardChanged: (_) {},
    onFixedNumbersChanged: (_) {},
    onWrongNumbersChanged: (_) {},
    onTimeChanged: (_) {},
    onPauseStateChanged: (_) {},
    onGameCompleteChanged: (_) {},
    onWrongCountChanged: (_) {},
    onGameOver: () {},
    puzzleBoard: board,
    initialBoard: board,
    solution: solution,
    maxHints: 3,
    maxWrongCount: 3,
  );
}

Widget _app(
  Widget child, {
  double width = 360,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: c!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: width, child: child),
      ),
    ),
  );
}

void main() {
  // SudokuGamePresenter는 생성 시 주기 타이머를 시작한다. flutter_test의
  // 대기 타이머 검사는 addTearDown보다 먼저 실행되므로, 각 테스트 본문
  // 안에서 직접 dispose까지 마친 뒤 끝낸다.
  Widget grid(
    List<SudokuGamePresenter> created, {
    Map<String, bool> waveActive = const {},
    Map<String, bool> lineCompleteActive = const {},
    Map<String, bool> errorActive = const {},
    Map<String, double> errorOffset = const {},
  }) {
    final presenter = _presenter();
    created.add(presenter);
    return SudokuBoardGrid(
      presenter: presenter,
      waveActive: waveActive,
      lineCompleteActive: lineCompleteActive,
      errorActive: errorActive,
      errorOffset: errorOffset,
      onCellTapped: (_, __) {},
    );
  }

  // (0,0) 칸의 기본 배경/효과 오버레이 AnimatedContainer를 각각 키로 찾는다.
  AnimatedContainer effectOverlay(WidgetTester tester) =>
      tester.widget(find.byKey(const ValueKey('cell-effect-0-0')));

  AnimatedContainer baseContainer(WidgetTester tester) =>
      tester.widget(find.byKey(const ValueKey('cell-base-0-0')));

  testWidgets(
      'selection and effect layers use short, independent transition times',
      (tester) async {
    final presenters = <SudokuGamePresenter>[];
    await tester
        .pumpWidget(_app(grid(presenters, errorActive: const {'0,0': true})));

    // 선택 등 기본 배경은 100ms 이내에 반영돼야 한다.
    expect(
        baseContainer(tester).duration.inMilliseconds, lessThanOrEqualTo(100));
    // 효과 색은 컨트롤러의 GameEffectsController.effectFadeDuration과
    // 반드시 같아야, 대기 시간과 합친 전체 지속 시간이 문서화된 값과
    // 어긋나지 않는다.
    expect(effectOverlay(tester).duration,
        GameEffectsController.effectFadeDuration);
    for (final p in presenters) {
      p.dispose();
    }
  });

  testWidgets('reduce motion collapses both transition layers to zero',
      (tester) async {
    final presenters = <SudokuGamePresenter>[];
    await tester.pumpWidget(_app(
      grid(presenters, errorActive: const {'0,0': true}),
      reduceMotion: true,
    ));

    expect(baseContainer(tester).duration, Duration.zero);
    expect(effectOverlay(tester).duration, Duration.zero);
    for (final p in presenters) {
      p.dispose();
    }
  });

  testWidgets(
      'the error shake moves the same pixel amount on a phone-size and a '
      'tablet-size board', (tester) async {
    final presenters = <SudokuGamePresenter>[];
    for (final width in [342.0, 900.0]) {
      await tester.pumpWidget(_app(
        grid(
          presenters,
          errorActive: const {'0,0': true},
          errorOffset: const {'0,0': 3.0},
        ),
        width: width,
      ));

      final shifted = tester
          .widgetList<Transform>(find.byType(Transform))
          .where((t) => t.transform.getTranslation().x != 0)
          .toList();
      expect(shifted, hasLength(1), reason: 'width=$width');
      // AnimatedSlide처럼 칸 크기에 비례하지 않고, 항상 같은 실제 픽셀 값.
      expect(shifted.single.transform.getTranslation().x, 3.0,
          reason: 'width=$width');
    }
    for (final p in presenters) {
      p.dispose();
    }
  });

  testWidgets('a cell with no offset entry sits exactly at rest',
      (tester) async {
    final presenters = <SudokuGamePresenter>[];
    await tester.pumpWidget(_app(grid(presenters)));
    final translations = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((t) => t.transform.getTranslation().x);
    expect(translations.every((x) => x == 0), isTrue);
    for (final p in presenters) {
      p.dispose();
    }
  });

  group('effect rendering over time (real GameEffectsController)', () {
    const solved = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];
    List<List<int>> copy() => [
          for (final r in solved) [...r]
        ];
    void setStateVia(StateSetter setter, void Function() fn) => setter(fn);

    // 효과 오버레이 칸의 실제로 렌더링된 색상. AnimatedContainer(color: ...)는
    // 내부적으로 DecoratedBox 하나로 그려진다.
    Color effectColor(WidgetTester tester, {int row = 0, int col = 0}) {
      final box = tester.widget<DecoratedBox>(find.descendant(
        of: find.byKey(ValueKey('cell-effect-$row-$col')),
        matching: find.byType(DecoratedBox),
      ));
      return (box.decoration as BoxDecoration).color ?? Colors.transparent;
    }

    // 흔들림은 기본 배경 칸을 감싸는 Transform.translate가 담당한다.
    double offsetXOf(WidgetTester tester, {int row = 0, int col = 0}) {
      final transform = tester.widget<Transform>(find.ancestor(
        of: find.byKey(ValueKey('cell-base-$row-$col')),
        matching: find.byType(Transform),
      ));
      return transform.transform.getTranslation().x;
    }

    Future<StateSetter> pumpBoard(
      WidgetTester tester,
      SudokuGamePresenter presenter,
      GameEffectsController controller,
    ) async {
      late StateSetter setState;
      await tester.pumpWidget(_app(StatefulBuilder(
        builder: (context, setter) {
          setState = setter;
          return SudokuBoardGrid(
            presenter: presenter,
            waveActive: controller.waveActive,
            lineCompleteActive: controller.lineCompleteActive,
            errorActive: controller.errorActive,
            errorOffset: controller.errorOffset,
            onCellTapped: (_, __) {},
          );
        },
      )));
      return setState;
    }

    testWidgets(
        'a plain correct pulse colors in, then fully restores within '
        '~180ms', (tester) async {
      final presenter = _presenter();
      final controller = GameEffectsController();
      final board = List.generate(9, (_) => List.filled(9, 0));
      controller.resetForBoard(board: board, solution: board);
      final setState = await pumpBoard(tester, presenter, controller);

      expect(effectColor(tester), Colors.transparent);
      controller.triggerCorrectEffect(
        row: 0,
        col: 0,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // AnimatedContainer가 새 목표를 등록하도록 우선 한 프레임 그린 뒤
      // 전환 시간만큼 흘려보낸다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(effectColor(tester), isNot(Colors.transparent));

      // 대기 시간(120ms)이 끝나기 전에는 계속 강조색이어야 한다.
      await tester.pump(const Duration(milliseconds: 40)); // 누적 100ms
      expect(effectColor(tester), isNot(Colors.transparent));

      // 대기 시간이 끝나는 경계(120ms)를 넘겨 컨트롤러의 예약 콜백이
      // 실행되게 한 뒤, AnimatedContainer가 새 목표(투명)를 등록하도록
      // 한 프레임을 더 그리고 위젯 전환 시간만큼 흘려보낸다. 전체 지속
      // 시간이 문서화된 180ms 근방에서 끝난다.
      await tester.pump(const Duration(milliseconds: 22)); // 누적 122ms
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60)); // 누적 182ms
      expect(effectColor(tester), Colors.transparent);

      // 컨트롤러가 예약해 둔 타이머(취소돼 아무 것도 안 하는 것 포함)를 모두 흘려보내 테스트 종료 시 남은 타이머가 없게 한다.
      await tester.pump(const Duration(seconds: 1));
      presenter.dispose();
    });

    testWidgets(
        'a line/box completion colors in, then fully restores within '
        '~550ms', (tester) async {
      final presenter = _presenter();
      final controller = GameEffectsController();
      final board = copy();
      board[0][8] = 0; // 행0·열8·박스2의 유일한 빈 칸
      board[8][8] = 0; // 계속 비워 둬 퍼즐 전체 완료로 번지지 않게 한다
      controller.resetForBoard(board: board, solution: solved);
      final setState = await pumpBoard(tester, presenter, controller);

      board[0][8] = solved[0][8];
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(effectColor(tester, row: 0, col: 8), isNot(Colors.transparent));

      // 대기 시간(490ms)이 끝나기 전에는 계속 강조색이어야 한다.
      await tester.pump(const Duration(milliseconds: 400)); // 누적 460ms
      expect(effectColor(tester, row: 0, col: 8), isNot(Colors.transparent));

      // 대기 시간이 끝나는 경계(490ms)를 넘긴 뒤 새 목표(투명)를 등록할
      // 프레임을 한 번 더 그리고 위젯 전환 시간만큼 흘려보낸다. 전체
      // 지속 시간이 문서화된 550ms 근방에서 끝난다.
      await tester.pump(const Duration(milliseconds: 32)); // 누적 492ms
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60)); // 누적 552ms
      expect(effectColor(tester, row: 0, col: 8), Colors.transparent);

      // 컨트롤러가 예약해 둔 타이머(취소돼 아무 것도 안 하는 것 포함)를 모두 흘려보내 테스트 종료 시 남은 타이머가 없게 한다.
      await tester.pump(const Duration(seconds: 1));
      presenter.dispose();
    });

    testWidgets(
        'a completing input replaces a still-visible plain pulse color with '
        'the completion color', (tester) async {
      final presenter = _presenter();
      final controller = GameEffectsController();
      final board = copy();
      board[0][1] = 0; // A: 나중에 행0을 완성시키는 칸
      board[0][5] = 0; // B: 행0의 마지막 빈 칸
      board[1][1] = 0; // A만 채워도 열1·박스0은 아직 완성되지 않게 한다
      controller.resetForBoard(board: board, solution: solved);
      final setState = await pumpBoard(tester, presenter, controller);

      board[0][1] = solved[0][1];
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      controller.triggerCorrectEffect(
        row: 0,
        col: 1,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final waveColor = effectColor(tester, row: 0, col: 1);
      expect(waveColor, isNot(Colors.transparent));

      // 펄스가 자연히 꺼지기 전(120ms 미만)에 B를 채워 행을 완성한다.
      await tester.pump(const Duration(milliseconds: 40));
      board[0][5] = solved[0][5];
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final lineColor = effectColor(tester, row: 0, col: 1);
      expect(lineColor, isNot(Colors.transparent));
      // 이전 일반 정답 색과 달라야 줄 완성 색이 실제로 우선한 것이 보인다.
      expect(lineColor, isNot(waveColor));

      // 컨트롤러가 예약해 둔 타이머(취소돼 아무 것도 안 하는 것 포함)를 모두 흘려보내 테스트 종료 시 남은 타이머가 없게 한다.
      await tester.pump(const Duration(seconds: 1));
      presenter.dispose();
    });

    testWidgets(
        'an earlier stale line-complete end does not fade a cell now owned '
        'by a newer completion, but still clears its own cells',
        (tester) async {
      final presenter = _presenter();
      final controller = GameEffectsController();
      final board = copy();
      board[2][2] = 0; // 박스0(과 열2)의 유일한 빈 칸
      board[0][7] = 0; // 행0(과 열7, 박스2)의 유일한 빈 칸
      board[8][8] = 0; // 퍼즐 전체 완료로 번지지 않게 한다
      controller.resetForBoard(board: board, solution: solved);
      final setState = await pumpBoard(tester, presenter, controller);

      // 이벤트 1: 박스0을 완성한다. (1,0)은 박스0 전용, (0,0)은 박스0·행0
      // 공유 칸이다.
      board[2][2] = solved[2][2];
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      await tester.pump();

      // 100ms 뒤, 이벤트 2: 행0을 완성한다(공유 칸 (0,0) 포함).
      await tester.pump(const Duration(milliseconds: 100));
      board[0][7] = solved[0][7];
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      await tester.pump();

      // 이벤트1이 원래 끝났어야 할 시점(t=490)을 넘긴 뒤, 새 목표를 등록할
      // 프레임을 한 번 더 그리고 위젯 전환 시간만큼 흘려보낸다: 전용 칸은
      // 꺼지지만, 공유 칸은 이벤트2가 새로 가져가(t=590에 끝남) 켜진 채로
      // 남아야 한다.
      await tester.pump(const Duration(milliseconds: 392)); // 누적 492ms
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60)); // 누적 552ms
      expect(effectColor(tester, row: 1, col: 0), Colors.transparent);
      expect(effectColor(tester, row: 0, col: 0), isNot(Colors.transparent));

      // 컨트롤러가 예약해 둔 타이머(취소돼 아무 것도 안 하는 것 포함)를 모두 흘려보내 테스트 종료 시 남은 타이머가 없게 한다.
      await tester.pump(const Duration(seconds: 1));
      presenter.dispose();
    });

    testWidgets(
        'wrong -> correct on the same cell clears the shake immediately and '
        'the color fades out cleanly', (tester) async {
      final presenter = _presenter();
      final controller = GameEffectsController();
      final board = copy();
      board[0][0] = 0;
      board[0][1] = 0;
      board[0][2] = 0;
      board[1][1] = 0; // (0,1)을 정답으로 고쳐도 열1이 완성되지 않게 한다
      controller.resetForBoard(board: board, solution: solved);
      final setState = await pumpBoard(tester, presenter, controller);

      board[0][1] = 9; // solved[0][1] == 3, 오답
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      controller.triggerErrorEffect(
        row: 0,
        col: 1,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(effectColor(tester, row: 0, col: 1), isNot(Colors.transparent));
      expect(offsetXOf(tester, row: 0, col: 1).abs(), greaterThan(0));

      board[0][1] = 3; // 곧바로 정답으로 고친다
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      await tester.pump();

      // 흔들림 오프셋은 애니메이션 없이 그대로 반영되므로 즉시 0이어야 한다.
      expect(offsetXOf(tester, row: 0, col: 1), 0);

      // 오답 색은 위젯 전환 시간(60ms) 안에 깨끗이 사라진다.
      await tester.pump(GameEffectsController.effectFadeDuration);
      expect(effectColor(tester, row: 0, col: 1), Colors.transparent);

      // 컨트롤러가 예약해 둔 타이머(취소돼 아무 것도 안 하는 것 포함)를 모두 흘려보내 테스트 종료 시 남은 타이머가 없게 한다.
      await tester.pump(const Duration(seconds: 1));
      presenter.dispose();
    });

    testWidgets('wrong -> erase leaves no color or shake on the blank cell',
        (tester) async {
      final presenter = _presenter();
      final controller = GameEffectsController();
      final board = copy();
      board[0][0] = 0;
      board[0][1] = 0;
      board[0][2] = 0;
      controller.resetForBoard(board: board, solution: solved);
      final setState = await pumpBoard(tester, presenter, controller);

      board[0][2] = 9; // 오답
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      controller.triggerErrorEffect(
        row: 0,
        col: 2,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(effectColor(tester, row: 0, col: 2), isNot(Colors.transparent));

      board[0][2] = 0; // 지우기
      controller.handleBoardChanged(
        board: board,
        solution: solved,
        setState: (fn) => setStateVia(setState, fn),
        isMounted: () => true,
      );
      // 실제 앱(game_screen.dart)도 handleBoardChanged 직후 이렇게 별도로
      // setState를 부른다 — 보드 diff 취소는 그 콜백 밖에서 일어나기 때문이다.
      setState(() {});
      await tester.pump();
      expect(offsetXOf(tester, row: 0, col: 2), 0);

      await tester.pump(GameEffectsController.effectFadeDuration);
      expect(effectColor(tester, row: 0, col: 2), Colors.transparent);

      // 컨트롤러가 예약해 둔 타이머(취소돼 아무 것도 안 하는 것 포함)를 모두 흘려보내 테스트 종료 시 남은 타이머가 없게 한다.
      await tester.pump(const Duration(seconds: 1));
      presenter.dispose();
    });

    testWidgets(
        'reduce motion shows the completed error state from the first '
        'frame with no shake', (tester) async {
      final presenters = <SudokuGamePresenter>[];
      await tester.pumpWidget(_app(
        grid(
          presenters,
          errorActive: const {'0,0': true},
        ),
        reduceMotion: true,
      ));

      // duration=0이므로 별도로 시간을 흘려보내지 않아도 첫 프레임부터
      // 최종 상태(강조색)가 바로 보인다.
      expect(effectColor(tester), isNot(Colors.transparent));

      for (final p in presenters) {
        p.dispose();
      }
    });
  });
}
