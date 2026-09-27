import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/sudoku_game/game_session_controller.dart';

List<List<Set<int>>> _emptyNotes() =>
    List.generate(9, (_) => List.generate(9, (_) => <int>{}));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  final level = SudokuLevel.levels.first; // 초급: 최대 힌트 5
  final maxHints = SudokuGameFeaturePolicy.forLevel(level).maxHints;
  final puzzle = [
    [5, 0, 0, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];
  late GameStateService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = GameStateService();
  });

  Future<void> save({
    required int hintsRemaining,
    int? initialHints,
    List<List<int>>? board,
    Set<String> hintCells = const {},
  }) {
    return service.saveSession(
      levelName: level.name,
      gameNumber: 1,
      board: board ?? puzzle,
      notes: _emptyNotes(),
      elapsedSeconds: 30,
      hintsRemaining: hintsRemaining,
      wrongCount: 0,
      isMemoMode: false,
      hintCells: hintCells,
      initialHints: initialHints,
    );
  }

  Future<GameSessionState> load() async =>
      (await service.loadSession(levelName: level.name, gameNumber: 1))!;

  test('hint used without any digit or note is resumable', () async {
    await save(hintsRemaining: maxHints - 1, initialHints: maxHints);
    final session = await load();
    expect(session.hasUsedHint, isTrue);
    expect(
      session.isResumable(userFilledCells: 0, emptyCells: 2),
      isTrue,
    );
  });

  test('opened without using a hint is not resumable', () async {
    await save(hintsRemaining: maxHints, initialHints: maxHints);
    final session = await load();
    expect(session.hasUsedHint, isFalse);
    expect(
      session.isResumable(userFilledCells: 0, emptyCells: 2),
      isFalse,
    );
  });

  test('legacy session without initialHints loads and is not misjudged',
      () async {
    // 이전 버전 형식: initialHints 없음, hintsRemaining은 과거 기본값 3.
    SharedPreferences.setMockInitialValues({
      'game_${level.name}_1': jsonEncode({
        'board': puzzle,
        'elapsedSeconds': 10,
        'hintsRemaining': 3,
        'wrongCount': 0,
        'isMemoMode': false,
      }),
    });
    final session = await load();
    expect(session.initialHints, isNull);
    expect(session.hintsRemaining, 3);
    expect(session.hasUsedHint, isFalse);
    expect(
      session.isResumable(userFilledCells: 0, emptyCells: 2),
      isFalse,
    );
  });

  test('hint-filled cell and remaining hints restore together', () async {
    final board = puzzle.map((row) => List<int>.from(row)).toList();
    board[0][1] = 3;
    await save(
      hintsRemaining: maxHints - 1,
      initialHints: maxHints,
      board: board,
      hintCells: {'0,1'},
    );

    final bootstrap =
        await GameSessionController(gameStateService: service).prepareSession(
      game: SudokuGame(
        board: puzzle,
        solution: puzzle,
        emptyCells: level.emptyCells,
        levelName: level.name,
        gameNumber: 1,
      ),
      level: level,
      restoreSavedSession: true,
    );
    final session = bootstrap.activeSession!;
    expect(session.board[0][1], 3);
    expect(session.hintCells, {'0,1'});
    expect(session.hintsRemaining, maxHints - 1);
    expect(session.initialHints, maxHints);
  });
}
