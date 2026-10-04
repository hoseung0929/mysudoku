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

  AnimatedOpacity lineLayer(WidgetTester tester) =>
      tester.widget(find.byKey(const ValueKey('cell-line-0-0')));

  testWidgets(
      'line completion fades by opacity: quick in, slow out, no color lerp',
      (tester) async {
    final presenters = <SudokuGamePresenter>[];
    await tester.pumpWidget(
        _app(grid(presenters, lineCompleteActive: const {'0,0': true})));
    expect(lineLayer(tester).opacity, 1);
    expect(
        lineLayer(tester).duration, GameEffectsController.lineFadeInDuration);
    // 칸 사이 파동 간격(25ms)보다 길어야 계단이 아니라 한 줄기로 이어진다.
    expect(GameEffectsController.lineFadeInDuration.inMilliseconds,
        greaterThan(25 * 2));
    // 투명도 전환이라 효과 색 층은 줄 완성 색으로 보간되지 않는다.
    final overlayBox = tester.widget<DecoratedBox>(find.descendant(
      of: find.byKey(const ValueKey('cell-effect-0-0')),
      matching: find.byType(DecoratedBox),
    ));
    expect((overlayBox.decoration as BoxDecoration).color,
        anyOf(isNull, Colors.transparent));

    await tester.pumpWidget(
        _app(grid(presenters, lineCompleteActive: const {'0,0': false})));
    expect(lineLayer(tester).opacity, 0);
    expect(
        lineLayer(tester).duration, GameEffectsController.lineFadeOutDuration);
    expect(GameEffectsController.lineFadeOutDuration,
        greaterThan(GameEffectsController.lineFadeInDuration));

    // 다른 효과(오답)가 이 칸을 차지하면 줄 완성 층은 끈다.
    await tester.pumpWidget(_app(grid(
      presenters,
      lineCompleteActive: const {'0,0': true},
      errorActive: const {'0,0': true},
    )));
    expect(lineLayer(tester).opacity, 0);
    for (final p in presenters) {
      p.dispose();
    }
  });

  testWidgets('the line completion color is clearly visible, not near-white',
      (tester) async {
    final presenters = <SudokuGamePresenter>[];
    await tester.pumpWidget(
        _app(grid(presenters, lineCompleteActive: const {'0,0': true})));
    final fill = tester.widget<ColoredBox>(find.descendant(
        of: find.byKey(const ValueKey('cell-line-0-0')),
        matching: find.byType(ColoredBox)));
    // 흰 배경 위에서 눈으로 구분될 만큼(초록 채널이 충분히 낮은) 보라 계열.
    final blended = Color.alphaBlend(fill.color, Colors.white);
    expect(blended.g * 255, lessThan(225));
    expect(blended.b, greaterThanOrEqualTo(blended.r));
    for (final p in presenters) {
      p.dispose();
    }
  });

  testWidgets('reduce motion makes the line fade instant too', (tester) async {
    final presenters = <SudokuGamePresenter>[];
    await tester.pumpWidget(_app(
      grid(presenters, lineCompleteActive: const {'0,0': true}),
      reduceMotion: true,
    ));
    expect(lineLayer(tester).duration, Duration.zero);
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

    // 줄·박스 완성 강조 층의 목표 투명도(켜짐 1, 꺼짐 0). 이 층은 색을
    // 보간하지 않고 투명도만 바꾼다.
    double lineTarget(WidgetTester tester, {int row = 0, int col = 0}) => tester
        .widget<AnimatedOpacity>(find.byKey(ValueKey('cell-line-$row-$col')))
        .opacity;

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
        '~260ms', (tester) async {
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

      // 대기 시간(200ms)이 끝나기 전에는 계속 강조색이어야 한다.
      await tester.pump(const Duration(milliseconds: 40)); // 누적 100ms
      expect(effectColor(tester), isNot(Colors.transparent));

      // 대기 시간이 끝나는 경계(200ms)를 넘겨 컨트롤러의 예약 콜백이
      // 실행되게 한 뒤, AnimatedContainer가 새 목표(투명)를 등록하도록
      // 한 프레임을 더 그리고 위젯 전환 시간만큼 흘려보낸다. 전체 지속
      // 시간이 문서화된 260ms 근방에서 끝난다.
      await tester.pump(const Duration(milliseconds: 102)); // 누적 202ms
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60)); // 누적 262ms
      expect(effectColor(tester), Colors.transparent);

      // 컨트롤러가 예약해 둔 타이머(취소돼 아무 것도 안 하는 것 포함)를 모두 흘려보내 테스트 종료 시 남은 타이머가 없게 한다.
      await tester.pump(const Duration(seconds: 1));
      presenter.dispose();
    });

    testWidgets(
        'a line completion ripples out from the entered cell and comes back '
        'in', (tester) async {
      final presenter = _presenter();
      final controller = GameEffectsController();
      final board = copy();
      board[0][8] = 0; // 행0·박스2의 유일한 빈 칸(열8은 아래 (8,8) 때문에 미완성)
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

      // 출발점 (0,8)은 바로 켜지고, 가장 먼 (0,0)은 아직 꺼져 있다.
      expect(lineTarget(tester, row: 0, col: 8), 1);
      expect(lineTarget(tester, row: 0, col: 0), 0);

      // 퍼짐: (0,0)은 8칸 * 28ms = 224ms 뒤에 켜진다.
      await tester.pump(const Duration(milliseconds: 230));
      await tester.pump();
      expect(lineTarget(tester, row: 0, col: 0), 1);
      expect(lineTarget(tester, row: 0, col: 8), 1);

      // 되돌아옴: 가장 먼 (0,0)이 먼저(켜진 지 160ms 뒤) 꺼지고 출발점은 남는다.
      await tester.pump(const Duration(milliseconds: 170)); // 누적 400ms
      await tester.pump();
      expect(lineTarget(tester, row: 0, col: 0), 0);
      expect(lineTarget(tester, row: 0, col: 8), 1);

      // 출발점이 마지막(608ms)에 꺼지고, 서서히 사라지는 시간이 지나면 끝난다.
      await tester.pump(const Duration(milliseconds: 215)); // 누적 615ms
      await tester.pump();
      expect(lineTarget(tester, row: 0, col: 8), 0);
      await tester.pump(GameEffectsController.lineFadeOutDuration);

      // 컨트롤러가 예약해 둔 타이머를 모두 흘려보내 남은 타이머가 없게 한다.
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
      // (0,1)은 행0 파동의 두 번째 칸(지연 25ms)이라, 파동의 최대 지연
      // (9칸 기준 최대 200ms)을 넉넉히 덮는 시간까지 흘려보낸 뒤 확인한다.
      await tester.pump(const Duration(milliseconds: 220));
      await tester.pump(const Duration(milliseconds: 60));

      // 줄 완성 층이 켜지고, 이전 일반 정답 색은 효과 층에서 치워진다.
      expect(lineTarget(tester, row: 0, col: 1), 1);
      expect(effectColor(tester, row: 0, col: 1), isNot(waveColor));

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

      // (0,0)은 행0 파동에서 맨 앞(지연 0)이라 이벤트2가 T=100에 곧장
      // 켠다. 이벤트1의 전용 칸(1,0)은 T=50에 켜져 T=430에 꺼지고,
      // 이벤트2가 새로 켠 (0,0)은 T=480에 꺼진다.
      //
      // AnimatedContainer는 목표가 바뀐 프레임에서야 그 시점의 색부터
      // 새로 전환을 시작하므로(중간에 프레임을 그리지 않고 한 번에 크게
      // 건너뛰면 그 큰 점프 시작 시점을 기준으로 다시 전환이 시작된다),
      // 각 꺼짐 경계마다 딱 맞춰 한 프레임을 그려 목표를 등록한 뒤 위젯
      // 전환 시간(60ms)만큼 흘려보내야 실제로 다 사라진 상태를 본다.
      await tester.pump(const Duration(milliseconds: 330)); // 누적 430ms
      await tester.pump(); // (1,0) 꺼짐 목표 등록
      expect(lineTarget(tester, row: 1, col: 0), 0);
      // (0,0)은 이벤트2가 새로 켜서 T=480에 꺼진다 — 이벤트1의 오래된 종료가
      // 새 완성이 차지한 공유 칸을 먼저 끄지 않았다.
      expect(lineTarget(tester, row: 0, col: 0), 1);

      await tester.pump(const Duration(milliseconds: 60)); // 누적 490ms
      await tester.pump();
      expect(lineTarget(tester, row: 0, col: 0), 0);
      await tester.pump(GameEffectsController.lineFadeOutDuration);

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
