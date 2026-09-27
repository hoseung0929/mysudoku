import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  final solution = [
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

  late List<List<int>> board;
  late SudokuGamePresenter presenter;

  SudokuGamePresenter buildPresenter(List<List<int>> puzzle) {
    final level = SudokuLevel.levels.first;
    final policy = SudokuGameFeaturePolicy.forLevel(level);
    return SudokuGamePresenter(
      level: level,
      puzzleBoard: puzzle,
      initialBoard: puzzle,
      solution: solution,
      maxHints: policy.maxHints,
      maxWrongCount: policy.maxWrongCount,
      onBoardChanged: (_) {},
      onFixedNumbersChanged: (_) {},
      onWrongNumbersChanged: (_) {},
      onTimeChanged: (_) {},
      onPauseStateChanged: (_) {},
      onGameCompleteChanged: (_) {},
      onWrongCountChanged: (_) {},
      onGameOver: () {},
    );
  }

  setUp(() {
    // 빈칸 3개: (0,1)/(0,2)는 서로 다른 후보 조합, (8,8)은 정답과 다른
    // 사용자 숫자를 미리 넣어 자동 메모가 "이미 채워진 칸"은 건드리지
    // 않는지 확인할 때 쓴다.
    board = solution.map((r) => List<int>.from(r)).toList();
    board[0][1] = 0;
    board[0][2] = 0;
  });

  tearDown(() => presenter.dispose());

  test('computes candidates from row/col/box exclusion only, not the solution',
      () {
    presenter = buildPresenter(board);
    final result = presenter.applyAutoNotes();
    expect(result, AutoNotesResult.applied);
    // 실제 정답은 (0,1)=3, (0,2)=4지만, 이 보드에서는 각 칸이 유일한 후보라
    // 메모도 정답과 같은 값 하나씩만 남는다(우연이 아니라 두 칸 다
    // naked single이 되도록 고른 보드).
    expect(presenter.getCellNotes(0, 1), {3});
    expect(presenter.getCellNotes(0, 2), {4});
  });

  test(
      'excludes row, column, and box numbers correctly for a multi-candidate cell',
      () {
    // 나머지 칸은 모두 비워 두고 0행에만 값을 채워, (0,0)·(0,1)의 같은 열·
    // 박스에는 아무 숫자도 없게 만든다 — 행에서 빠진 두 숫자(3, 5)가 그대로
    // 둘 다 후보로 남아야 한다(정답 solution과는 무관하게 계산되는지 확인).
    final sparse = List.generate(9, (_) => List.filled(9, 0));
    sparse[0] = [0, 0, 4, 6, 7, 8, 9, 1, 2];
    presenter = buildPresenter(sparse);
    final result = presenter.applyAutoNotes();
    expect(result, AutoNotesResult.applied);
    expect(presenter.getCellNotes(0, 0), {3, 5});
    expect(presenter.getCellNotes(0, 1), {3, 5});
  });

  test('excludes fixed, filled, and hint cells from candidate computation', () {
    final withHint = solution.map((r) => List<int>.from(r)).toList();
    withHint[0][1] = 0;
    withHint[0][2] = 0;
    presenter = buildPresenter(withHint);
    presenter.selectCell(0, 2);
    presenter.useHint(); // (0,2)를 힌트로 채움
    final notesBeforeForHintCell = presenter.getCellNotes(0, 2);

    final result = presenter.applyAutoNotes();
    expect(result, AutoNotesResult.applied);
    // 고정 칸·이미 채워진 칸(힌트 포함)은 메모 대상이 아니다.
    expect(presenter.getCellNotes(0, 2), notesBeforeForHintCell);
    expect(presenter.getCellNotes(0, 2), isEmpty);
    // 진짜 빈칸(0,1)만 메모가 채워진다.
    expect(presenter.getCellNotes(0, 1), isNotEmpty);
  });

  test(
      'a contradiction (a blank cell with zero candidates) rolls back everything',
      () {
    // (0,0)~(0,8) 전부 채우되 하나만 비워, 그 칸의 행에는 후보가 남지만
    // 열·박스에서 억지로 같은 숫자들을 겹치게 만들어 후보를 0개로 만든다.
    final contradiction = solution.map((r) => List<int>.from(r)).toList();
    contradiction[0][0] = 0;
    // (0,0)의 후보를 0개로 만들기 위해 열0과 박스0에 1~9 중 (0,0) 행에 남은
    // 후보(5)까지 포함해 모든 숫자가 이미 등장하도록 조작한다.
    // 행0(다른 칸 채움 상태): 3,4,6,7,8,9,1,2 → (0,0) 후보는 {5}만 가능.
    // 열0에 5를 강제로 넣어 후보를 0개로 만든다(다른 규칙 위반은 이 테스트의
    // 목적이 아니므로 무시한다 — computeBasicCandidates는 보드만 본다).
    contradiction[3][0] = 5;
    presenter = buildPresenter(contradiction);
    final beforeNotes = presenter.getCellNotes(0, 0);

    final result = presenter.applyAutoNotes();
    expect(result, AutoNotesResult.contradiction);
    expect(presenter.getCellNotes(0, 0), beforeNotes);
    expect(presenter.autoNotesUsed, isFalse);
  });

  test('all changes are a single undo step; undo restores prior notes', () {
    final withExisting = solution.map((r) => List<int>.from(r)).toList();
    withExisting[0][1] = 0;
    withExisting[0][2] = 0;
    presenter = buildPresenter(withExisting);
    presenter.selectCell(0, 1);
    presenter.toggleMemoMode();
    presenter.setSelectedCellValue(9); // 기존 메모 하나를 미리 남겨 둔다.
    final priorNotes = presenter.getCellNotes(0, 1);
    expect(priorNotes, {9});

    presenter.applyAutoNotes();
    expect(presenter.getCellNotes(0, 1), isNot(priorNotes));
    expect(presenter.canUndo, isTrue);

    presenter.undo();
    expect(presenter.getCellNotes(0, 1), priorNotes);
    expect(presenter.getCellNotes(0, 2), isEmpty);
  });

  test('autoNotesUsed stays true after undoing the auto-notes action', () {
    presenter = buildPresenter(board);
    presenter.applyAutoNotes();
    expect(presenter.autoNotesUsed, isTrue);
    presenter.undo();
    expect(presenter.autoNotesUsed, isTrue);
  });

  test('restarting the game resets autoNotesUsed', () {
    presenter = buildPresenter(board);
    presenter.applyAutoNotes();
    expect(presenter.autoNotesUsed, isTrue);
    presenter.restartGame();
    expect(presenter.autoNotesUsed, isFalse);
  });

  test('does not change remaining hints or wrong count', () {
    presenter = buildPresenter(board);
    final hintsBefore = presenter.hintsRemaining;
    final wrongBefore = presenter.wrongCount;
    presenter.applyAutoNotes();
    expect(presenter.hintsRemaining, hintsBefore);
    expect(presenter.wrongCount, wrongBefore);
  });

  test('blocked while paused', () {
    presenter = buildPresenter(board);
    presenter.togglePause();
    expect(presenter.applyAutoNotes(), AutoNotesResult.blocked);
  });

  test('resuming with a saved autoNotesUsed flag restores it', () {
    final level = SudokuLevel.levels.first;
    final policy = SudokuGameFeaturePolicy.forLevel(level);
    presenter = SudokuGamePresenter(
      level: level,
      puzzleBoard: board,
      initialBoard: board,
      solution: solution,
      maxHints: policy.maxHints,
      maxWrongCount: policy.maxWrongCount,
      onBoardChanged: (_) {},
      onFixedNumbersChanged: (_) {},
      onWrongNumbersChanged: (_) {},
      onTimeChanged: (_) {},
      onPauseStateChanged: (_) {},
      onGameCompleteChanged: (_) {},
      onWrongCountChanged: (_) {},
      onGameOver: () {},
      initialAutoNotesUsed: true,
    );
    expect(presenter.autoNotesUsed, isTrue);
  });
}
