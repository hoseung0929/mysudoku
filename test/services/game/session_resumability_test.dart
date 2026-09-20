import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/sudoku_game/game_session_controller.dart';

List<List<Set<int>>> _emptyNotes() =>
    List.generate(9, (_) => List.generate(9, (_) => <int>{}));

GameSessionState _session({
  int wrongCount = 0,
  bool complete = false,
  bool over = false,
  List<List<Set<int>>>? notes,
}) =>
    GameSessionState(
      board: const [],
      notes: notes ?? _emptyNotes(),
      elapsedSeconds: 500,
      hintsRemaining: 3,
      wrongCount: wrongCount,
      isMemoMode: false,
      hintCells: const {},
      isGameComplete: complete,
      isGameOver: over,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  group('GameSessionState.isResumable', () {
    test('opened only (timer elapsed, no input) is fresh', () {
      expect(
          _session().isResumable(userFilledCells: 0, emptyCells: 40), isFalse);
    });

    test('digit input is resumable', () {
      expect(
          _session().isResumable(userFilledCells: 1, emptyCells: 40), isTrue);
    });

    test('notes only (0% digits) is resumable', () {
      final notes = _emptyNotes();
      notes[0][2] = {4, 7};
      expect(
          _session(notes: notes)
              .isResumable(userFilledCells: 0, emptyCells: 40),
          isTrue);
    });

    test('input then erased back to initial state is fresh', () {
      // 보드·메모가 초기 상태이고 실수 기록도 없으면 새 퍼즐.
      expect(
          _session().isResumable(userFilledCells: 0, emptyCells: 40), isFalse);
    });

    test('erased back but mistakes were recorded stays resumable', () {
      expect(
          _session(wrongCount: 1)
              .isResumable(userFilledCells: 0, emptyCells: 40),
          isTrue);
    });

    test('complete / game over / wrong limit / fully filled are excluded', () {
      expect(
          _session(complete: true)
              .isResumable(userFilledCells: 40, emptyCells: 40),
          isFalse);
      expect(
          _session(over: true).isResumable(userFilledCells: 5, emptyCells: 40),
          isFalse);
      expect(
          _session(wrongCount: 3)
              .isResumable(userFilledCells: 5, emptyCells: 40),
          isFalse);
      expect(
          _session().isResumable(userFilledCells: 40, emptyCells: 40), isFalse);
    });
  });

  group('memo-only session persistence', () {
    final level = SudokuLevel.levels.first;
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
    late GameSessionController controller;
    late SudokuGame game;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = GameStateService();
      controller = GameSessionController(gameStateService: service);
      game = SudokuGame(
        board: puzzle,
        solution: puzzle,
        emptyCells: level.emptyCells,
        levelName: level.name,
        gameNumber: 3,
      );
    });

    test('notes survive save and restore with 0 filled digits', () async {
      final notes = _emptyNotes();
      notes[0][1] = {3, 4};
      await service.saveSession(
        levelName: level.name,
        gameNumber: 3,
        board: puzzle,
        notes: notes,
        elapsedSeconds: 12,
        hintsRemaining: 3,
        wrongCount: 0,
        isMemoMode: true,
      );

      final saved = (await service.getSavedGames()).single;
      expect(
          saved.session.isResumable(userFilledCells: 0, emptyCells: 2), isTrue);

      final bootstrap = await controller.prepareSession(
        game: game,
        level: level,
        restoreSavedSession: true,
      );
      expect(bootstrap.activeSession!.notes[0][1], {3, 4});
    });

    test('legacy plain-board and notes-less payloads still load', () async {
      SharedPreferences.setMockInitialValues({
        'game_${level.name}_1':
            puzzle.map((r) => r.join()).join(), // 구버전 문자열 포맷 가정
        'game_${level.name}_2':
            '{"board":${puzzle.toString()},"elapsedSeconds":5}',
      });
      final games = await service.getSavedGames();
      expect(games.where((g) => g.gameNumber == 2), hasLength(1));
      final legacyJson = games.firstWhere((g) => g.gameNumber == 2);
      expect(legacyJson.session.hasNotes, isFalse);
      expect(legacyJson.session.isGameComplete, isFalse);
    });

    test('restoring a completed/game-over leftover discards it', () async {
      await service.saveSession(
        levelName: level.name,
        gameNumber: 3,
        board: puzzle,
        notes: _emptyNotes(),
        elapsedSeconds: 9,
        hintsRemaining: 1,
        wrongCount: 5,
        isMemoMode: false,
        isGameOver: true,
      );
      final bootstrap = await controller.prepareSession(
        game: game,
        level: level,
        restoreSavedSession: true,
      );
      expect(bootstrap.activeSession, isNull);
      expect(await service.getSavedGames(), isEmpty);
    });
  });

  group('challengeDate persistence', () {
    final level = SudokuLevel.levels.first;
    final emptyNotes =
        List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    final board = List.generate(9, (_) => List.filled(9, 1));

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a challenge session keeps its date after saving and reloading',
        () async {
      final service = GameStateService();
      await service.saveSession(
        levelName: level.name,
        gameNumber: 4,
        board: board,
        notes: emptyNotes,
        elapsedSeconds: 10,
        hintsRemaining: 3,
        wrongCount: 0,
        isMemoMode: false,
        challengeDate: '2026-09-19',
      );
      final loaded =
          await service.loadSession(levelName: level.name, gameNumber: 4);
      expect(loaded!.challengeDate, '2026-09-19');
      final listed = (await service.getSavedGames()).single;
      expect(listed.session.challengeDate, '2026-09-19');
    });

    test('sessions saved before this field existed read as a normal game',
        () async {
      final service = GameStateService();
      await service.saveSession(
        levelName: level.name,
        gameNumber: 5,
        board: board,
        notes: emptyNotes,
        elapsedSeconds: 10,
        hintsRemaining: 3,
        wrongCount: 0,
        isMemoMode: false,
      );
      final loaded =
          await service.loadSession(levelName: level.name, gameNumber: 5);
      expect(loaded!.challengeDate, isNull);
    });
  });
}
