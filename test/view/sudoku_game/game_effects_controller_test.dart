// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/view/sudoku_game/game_effects_controller.dart';

void main() {
  group('GameEffectsController', () {
    test('detects newly completed row, column, and box', () {
      final board = [
        [5, 3, 0, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 0],
      ];
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
      final controller = GameEffectsController();

      controller.initializeCompletedLineState(board: board, solution: solution);
      board[0][2] = 4;

      final delta = controller.handleBoardChanged(
        board: board,
        solution: solution,
        setState: (fn) => fn(),
        isMounted: () => true,
      );

      expect(delta.completedRows, 1);
      expect(delta.completedCols, 1);
      expect(delta.completedBoxes, 1);
      expect(delta.hasNewCompletion, isTrue);
      expect(controller.lineCompleteActive['0,0'], isTrue);
      expect(controller.lineCompleteActive['0,2'], isTrue);
      expect(controller.lineCompleteActive['8,2'], isTrue);
      expect(controller.lineCompleteActive['1,1'], isTrue);
    });

    test('triggers temporary error effect for a wrong cell', () async {
      final controller = GameEffectsController();

      controller.triggerErrorEffect(
        row: 2,
        col: 4,
        setState: (fn) => fn(),
        isMounted: () => true,
      );

      await Future<void>.delayed(Duration.zero);
      expect(controller.errorActive['2,4'], isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 320));
      expect(controller.errorActive['2,4'], isFalse);
    });

    test('ignores stale delayed effects after board reset', () async {
      final controller = GameEffectsController();
      final board = List.generate(9, (_) => List.filled(9, 0));

      controller.resetForBoard(board: board, solution: board);
      controller.triggerErrorEffect(
        row: 2,
        col: 4,
        setState: (fn) => fn(),
        isMounted: () => true,
      );
      controller.triggerCorrectEffect(
        row: 2,
        col: 4,
        setState: (fn) => fn(),
        isMounted: () => true,
      );

      controller.resetForBoard(board: board, solution: board);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 320));

      expect(controller.errorActive, isEmpty);
      expect(controller.waveActive, isEmpty);
      expect(controller.lineCompleteActive, isEmpty);
    });

    group('effect priority and timing', () {
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

      List<List<int>> copy() => [for (final r in solved) [...r]];
      void run(void Function() fn) => fn();

      GameEffectsController fresh(List<List<int>> board) {
        final c = GameEffectsController();
        c.resetForBoard(board: board, solution: solved);
        return c;
      }

      test('plain correct input highlights only its own cell, then restores',
          () {
        fakeAsync((async) {
          final c = fresh(copy());
          c.triggerCorrectEffect(
            row: 4,
            col: 4,
            setState: run,
            isMounted: () => true,
          );
          expect(c.waveActive.entries.where((e) => e.value).map((e) => e.key),
              ['4,4']);
          async.elapse(const Duration(milliseconds: 200));
          expect(c.waveActive['4,4'], isFalse);
        });
      });

      test('row and box completing together merge into one line effect and '
          'skip the plain pulse', () {
        fakeAsync((async) {
          final board = copy()..[0][2] = 0;
          board[1][0] = 0;
          board[8][8] = 0;
          final c = fresh(board);
          board[0][2] = 4;
          board[1][0] = 6;
          // box 0 and row 0 both need both cells; fill the last one.
          final delta = c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          expect(delta.completedRows, greaterThanOrEqualTo(1));
          expect(delta.completedBoxes, 1);
          c.triggerCorrectEffect(
            row: 0,
            col: 2,
            setState: run,
            isMounted: () => true,
          );
          expect(c.waveActive['0,2'], isNull);
          expect(c.lineCompleteActive['0,2'], isTrue);
          async.elapse(const Duration(milliseconds: 700));
          expect(c.lineCompleteActive.values.any((v) => v), isFalse);
        });
      });

      test('final input reports puzzle complete and starts no line effect', () {
        fakeAsync((async) {
          final board = copy()..[8][8] = 0;
          final c = fresh(board);
          board[8][8] = 9;
          final delta = c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          expect(delta.isPuzzleComplete, isTrue);
          expect(c.lineCompleteActive, isEmpty);
          c.triggerCorrectEffect(
            row: 8,
            col: 8,
            setState: run,
            isMounted: () => true,
          );
          expect(c.waveActive, isEmpty);
        });
      });

      test('resuming an already complete area does not celebrate', () {
        final c = fresh(copy());
        final delta = c.handleBoardChanged(
          board: copy(),
          solution: solved,
          setState: run,
          isMounted: () => true,
        );
        expect(delta.hasNewCompletion, isFalse);
        expect(c.lineCompleteActive, isEmpty);
      });

      test('a stale timer from an earlier input does not clear a newer one',
          () {
        fakeAsync((async) {
          final c = fresh(copy());
          c.triggerErrorEffect(
            row: 1,
            col: 1,
            setState: run,
            isMounted: () => true,
          );
          async.elapse(const Duration(milliseconds: 120));
          c.triggerErrorEffect(
            row: 1,
            col: 1,
            setState: run,
            isMounted: () => true,
          );
          // first effect's end (~204ms) passes; second must still be active.
          async.elapse(const Duration(milliseconds: 120));
          expect(c.errorActive['1,1'], isTrue);
          async.elapse(const Duration(milliseconds: 200));
          expect(c.errorActive['1,1'], isFalse);
        });
      });

      test('shake stays within 3px and total time under 220ms', () {
        fakeAsync((async) {
          final c = fresh(copy());
          final seen = <double>[];
          c.triggerErrorEffect(
            row: 0,
            col: 0,
            setState: (fn) {
              fn();
              seen.add(c.errorOffset['0,0'] ?? 0);
            },
            isMounted: () => true,
          );
          async.elapse(const Duration(milliseconds: 220));
          expect(seen.map((v) => v.abs()).reduce((a, b) => a > b ? a : b),
              lessThanOrEqualTo(3));
          expect(c.errorActive['0,0'], isFalse);
        });
      });

      test('reduce motion skips the horizontal shake', () {
        fakeAsync((async) {
          final c = fresh(copy())..reduceMotion = true;
          final seen = <double>[];
          c.triggerErrorEffect(
            row: 0,
            col: 0,
            setState: (fn) {
              fn();
              seen.add(c.errorOffset['0,0'] ?? 0);
            },
            isMounted: () => true,
          );
          async.elapse(const Duration(milliseconds: 300));
          expect(seen.every((v) => v == 0), isTrue);
        });
      });

      test('callbacks after unmount never call setState', () {
        fakeAsync((async) {
          final c = fresh(copy());
          var mounted = true;
          var calls = 0;
          void tracked(void Function() fn) {
            calls++;
            fn();
          }

          c.triggerErrorEffect(
            row: 0,
            col: 0,
            setState: tracked,
            isMounted: () => mounted,
          );
          c.triggerCorrectEffect(
            row: 1,
            col: 1,
            setState: tracked,
            isMounted: () => mounted,
          );
          final before = calls;
          mounted = false;
          async.elapse(const Duration(seconds: 1));
          expect(calls, before);
        });
      });

      test('clearTransientEffects (background) cancels pending endings', () {
        fakeAsync((async) {
          final c = fresh(copy());
          c.triggerErrorEffect(
            row: 0,
            col: 0,
            setState: run,
            isMounted: () => true,
          );
          c.clearTransientEffects();
          expect(c.errorActive, isEmpty);
          async.elapse(const Duration(seconds: 1));
          expect(c.errorActive, isEmpty);
        });
      });
    });
  });
}
