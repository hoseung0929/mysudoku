import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/services/home/level_progress_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// 퍼즐 목록 → 게임 → 저장 → 목록 복귀 → 이어하기까지를 실제 저장소
/// (SharedPreferences 목)와 실제 화면으로 잇는 흐름 테스트.
/// DB만 가짜다.
class _NoopWakelockPlatform extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

final _level = SudokuLevel.levels.first;

List<List<int>> _solution() => List.generate(
      9,
      (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
    );

/// 앞에서부터 emptyCells개를 비운 퍼즐 (레벨의 빈칸 수와 일치).
List<List<int>> _puzzle() {
  final board = _solution();
  for (var i = 0; i < _level.emptyCells; i++) {
    board[i ~/ 9][i % 9] = 0;
  }
  return board;
}

class _FakeDb implements DatabaseHelper {
  _FakeDb(this.games, this.cleared);
  final List<int> games;
  final Set<int> cleared;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  Future<List<int>> getGameNumbersForLevel(String levelName) async => games;

  @override
  Future<List<int>> getClearedGameNumbersForLevel(String levelName) async =>
      cleared.toList();

  @override
  Future<List<Map<String, dynamic>>> getClearRecordsForLevel(
    String levelName,
  ) async =>
      [
        for (final n in cleared)
          {'game_number': n, 'clear_time': 125, 'level_name': levelName},
      ];

  @override
  Future<Map<String, dynamic>?> getGameEntry(
    String levelName,
    int gameNumber,
  ) async =>
      {
        'game_number': gameNumber,
        'board': _puzzle(),
        'solution': _solution(),
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();
  EditableText.debugDeterministicCursor = true;

  final games = List.generate(6, (i) => i + 1);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    Set<int> cleared = const {},
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LevelPickerScreen(
          level: _level,
          databaseHelper: _FakeDb(games, cleared),
          levelProgressService: LevelProgressService(
            loadClearedGameCount: (_) async => cleared.length,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  SudokuGamePresenter presenterOf(WidgetTester tester) =>
      tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid)).presenter;

  /// 게임 화면에서 뒤로 가기(저장 후 pop)로 목록에 복귀.
  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle(tester);
    await settle(tester);
  }

  setUp(() => SharedPreferences.setMockInitialValues({
        'beginner_tutorial_state_v1': 'completed',
      }));

  testWidgets('A/B: new puzzle → notes only → back → in progress → restored',
      (tester) async {
    await pumpPicker(tester);
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.text('Start puzzle'));
    await settle(tester);
    expect(find.byType(SudokuGameScreen), findsOneWidget);

    final presenter = presenterOf(tester);
    presenter.selectCell(0, 0);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('game-action-memo')));
    await tester.pump();
    presenter.setSelectedCellValue(3);
    presenter.setSelectedCellValue(5);
    await tester.pump();
    await goBack(tester);

    // 확정 숫자 없이 메모만 있어도 진행 중 / 대표 이어하기.
    expect(find.byType(SudokuGameScreen), findsNothing);
    expect(find.text('In progress 1'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('Writing notes'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(presenterOf(tester).getCellNotes(0, 0), {3, 5});
    expect(presenterOf(tester).getCellValue(0, 0), 0);
    await goBack(tester);
  });

  testWidgets('C: merely opening another puzzle does not displace the recent',
      (tester) async {
    // 실제로 풀던 5번 (숫자 입력 저장) — 가장 최근이 아니어도 이어하기 대상.
    final board = _puzzle();
    board[0][0] = _solution()[0][0];
    await GameStateService().saveSession(
      levelName: _level.name,
      gameNumber: 5,
      board: board,
      notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      elapsedSeconds: 30,
      hintsRemaining: 3,
      wrongCount: 0,
      isMemoMode: false,
    );
    await pumpPicker(tester);
    expect(find.text('Puzzle 5'), findsOneWidget);

    // 새 퍼즐(001)을 열기만 하고 나온다.
    await tester.tap(find.text('001'));
    await settle(tester);
    await tester.pump(const Duration(seconds: 2)); // 타이머가 흘러 저장이 일어남
    await goBack(tester);

    expect(find.text('Puzzle 5'), findsOneWidget);
    expect(find.text('In progress 1'), findsOneWidget);
    expect(find.text('New 5'), findsOneWidget); // 1번은 여전히 새 퍼즐
  });

  testWidgets('D: erased digit/notes stay erased after leaving and resuming',
      (tester) async {
    await pumpPicker(tester);
    await tester.tap(find.text('Start puzzle'));
    await settle(tester);
    final presenter = presenterOf(tester);

    presenter.selectCell(0, 0);
    presenter.setSelectedCellValue(_solution()[0][0]);
    presenter.selectCell(0, 1);
    await tester.tap(find.byKey(const ValueKey('game-action-memo')));
    await tester.pump();
    presenter.setSelectedCellValue(7);
    presenter.selectCell(0, 2);
    presenter.setSelectedCellValue(2);
    await tester.pump();

    presenter.selectCell(0, 0);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('game-action-erase')));
    await tester.pump();
    presenter.selectCell(0, 2);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('game-action-erase')));
    await tester.pump();
    await goBack(tester);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    final resumed = presenterOf(tester);
    expect(resumed.getCellValue(0, 0), 0);
    expect(resumed.getCellNotes(0, 2), isEmpty);
    expect(resumed.getCellNotes(0, 1), {7}); // 다른 칸의 메모는 유지
    await goBack(tester);
  });

  testWidgets('tapping the progress card itself (not the button) resumes',
      (tester) async {
    final board = _puzzle();
    board[0][0] = _solution()[0][0];
    await GameStateService().saveSession(
      levelName: _level.name,
      gameNumber: 5,
      board: board,
      notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      elapsedSeconds: 30,
      hintsRemaining: 3,
      wrongCount: 0,
      isMemoMode: false,
    );
    await pumpPicker(tester);
    expect(find.text('Puzzle 5'), findsOneWidget);

    await tester.tap(find.text('Puzzle 5'));
    await settle(tester);
    expect(find.byType(SudokuGameScreen), findsOneWidget);
    await goBack(tester);
  });

  testWidgets('E: replaying a cleared puzzle is resumed, record is kept',
      (tester) async {
    await pumpPicker(tester, cleared: {1});
    expect(find.text('Done 1'), findsOneWidget);

    await tester.tap(find.text('001').first);
    await settle(tester);
    await tester.tap(find.text('Replay')); // 다시 풀기 확인
    await settle(tester);
    expect(find.byType(SudokuGameScreen), findsOneWidget);

    final presenter = presenterOf(tester);
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(_solution()[0][1]);
    await tester.pump();
    await goBack(tester);

    // 재도전 세션이 있으므로 진행 중, 과거 완료 기록(1/6)은 유지.
    expect(find.text('In progress 1'), findsOneWidget);
    expect(find.text('Done 0'), findsOneWidget);
    expect(find.text('1 completed'), findsOneWidget);
    expect(find.text('Puzzle 1'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(presenterOf(tester).getCellValue(0, 1), _solution()[0][1]);
    await goBack(tester);
  });

  testWidgets('replay confirm: numbered title, kept-record body, cancel stays',
      (tester) async {
    await pumpPicker(tester, cleared: {1});
    await tester.tap(find.text('001').first);
    await settle(tester);
    expect(find.text('Replay puzzle 1?'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('only your best record is updated')),
        findsOneWidget);
    // 주 버튼은 전체 폭, 취소는 그 아래 텍스트 버튼.
    final replay = tester.getRect(find.widgetWithText(FilledButton, 'Replay'));
    final cancel = tester.getRect(find.widgetWithText(TextButton, 'Cancel'));
    expect(replay.height, 48);
    expect(cancel.top, greaterThan(replay.bottom));
    expect(cancel.width, replay.width);

    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('Replay puzzle 1?'), findsNothing);
    expect(find.byType(SudokuGameScreen), findsNothing);
  });

  testWidgets('G: rapid double tap opens a single game screen', (tester) async {
    await pumpPicker(tester);
    final start = find.text('Start puzzle');
    await tester.tap(start);
    await tester.tap(start, warnIfMissed: false);
    await settle(tester);
    expect(find.byType(SudokuGameScreen), findsOneWidget);
    await goBack(tester);
    expect(find.byType(SudokuGameScreen), findsNothing);
  });

  testWidgets('I: completed / game-over leftovers are not offered as continue',
      (tester) async {
    final service = GameStateService();
    final noNotes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    final board = _puzzle();
    board[0][0] = _solution()[0][0];
    await service.saveSession(
      levelName: _level.name,
      gameNumber: 2,
      board: board,
      notes: noNotes,
      elapsedSeconds: 50,
      hintsRemaining: 1,
      wrongCount: 5,
      isMemoMode: false,
      isGameOver: true,
    );
    await service.saveSession(
      levelName: _level.name,
      gameNumber: 3,
      board: _solution(),
      notes: noNotes,
      elapsedSeconds: 90,
      hintsRemaining: 1,
      wrongCount: 0,
      isMemoMode: false,
      isGameComplete: true,
    );
    await pumpPicker(tester);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('In progress 0'), findsOneWidget);
    expect(find.text('New 6'), findsOneWidget);
  });
}
