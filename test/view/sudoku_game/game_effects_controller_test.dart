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

      List<List<int>> copy() => [
            for (final r in solved) [...r]
          ];
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

      test(
          'row and box completing together merge into one line effect and '
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

    group('same-cell cancellation (wrong<->correct<->erase)', () {
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
      void run(void Function() fn) => fn();

      // (0,0)~(1,2) 여섯 칸을 항상 비워 둔다. 각 행·열·박스0에 빈 칸이
      // 최소 둘 이상 남으므로, 이 그룹에서 이 칸들 중 하나만 채워도 뜻하지
      // 않게 행·열·박스가 완성돼 버리는 일이 없다.
      List<List<int>> partial() {
        final b = copy();
        for (final cell in const [
          [0, 0],
          [0, 1],
          [0, 2],
          [1, 0],
          [1, 1],
          [1, 2],
        ]) {
          b[cell[0]][cell[1]] = 0;
        }
        return b;
      }

      GameEffectsController fresh(List<List<int>> board) {
        final c = GameEffectsController();
        c.resetForBoard(board: board, solution: solved);
        return c;
      }

      test(
          'a quick wrong -> correct fix on the same cell cancels the old '
          'shake instantly, before the new pulse is even triggered', () {
        fakeAsync((async) {
          final board = partial();
          final c = fresh(board);

          board[0][1] = 7; // solved[0][1] == 3, so 7 is wrong
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          c.triggerErrorEffect(
            row: 0,
            col: 1,
            setState: run,
            isMounted: () => true,
          );
          async.elapse(const Duration(milliseconds: 30));
          expect(c.errorActive['0,1'], isTrue);
          expect(c.errorOffset['0,1'], isNot(0));

          board[0][1] = 3; // 곧바로 정답으로 고친다
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          // triggerCorrectEffect를 부르기 전, 값이 바뀐 시점에 이미 이전
          // 흔들림·배경이 사라져 있어야 한다.
          expect(c.errorActive['0,1'], isNull);
          expect(c.errorOffset.containsKey('0,1'), isFalse);

          c.triggerCorrectEffect(
            row: 0,
            col: 1,
            setState: run,
            isMounted: () => true,
          );
          expect(c.waveActive['0,1'], isTrue);

          // 취소된 이전 오답의 예약 콜백이 나중에 실행돼도 지금의 정답
          // 강조에 영향이 없어야 한다.
          async.elapse(const Duration(milliseconds: 60));
          expect(c.waveActive['0,1'], isTrue);
          async.elapse(const Duration(milliseconds: 200));
          expect(c.waveActive['0,1'], isFalse);
          expect(c.errorActive['0,1'], isNull);
        });
      });

      test('erasing a wrong cell back to blank leaves no lingering effect', () {
        fakeAsync((async) {
          final board = partial();
          final c = fresh(board);

          board[0][2] = 9; // wrong
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          c.triggerErrorEffect(
            row: 0,
            col: 2,
            setState: run,
            isMounted: () => true,
          );
          async.elapse(const Duration(milliseconds: 30));
          expect(c.errorActive['0,2'], isTrue);

          board[0][2] = 0; // 지우기
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          expect(c.errorActive['0,2'], isNull);
          expect(c.errorOffset.containsKey('0,2'), isFalse);

          // 지워진 뒤 이전 오답의 예약 콜백이 실행돼도 아무 것도 다시
          // 켜지지 않는다.
          async.elapse(const Duration(seconds: 1));
          expect(c.errorActive['0,2'], isNull);
          expect(c.errorOffset.containsKey('0,2'), isFalse);
        });
      });

      test(
          'a correct pulse is cancelled when the same cell is changed to '
          'a wrong value', () {
        fakeAsync((async) {
          final board = partial();
          final c = fresh(board);

          board[0][1] = 3; // 정답
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          c.triggerCorrectEffect(
            row: 0,
            col: 1,
            setState: run,
            isMounted: () => true,
          );
          expect(c.waveActive['0,1'], isTrue);

          board[0][1] = 9; // 다시 오답으로 바꿔 씀
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          expect(c.waveActive['0,1'], isNull);

          c.triggerErrorEffect(
            row: 0,
            col: 1,
            setState: run,
            isMounted: () => true,
          );
          expect(c.errorActive['0,1'], isTrue);
          expect(c.waveActive['0,1'], isNull);

          // 취소된 이전 정답 강조의 예약 콜백이 실행돼도 지금의 오답
          // 강조를 끄지 않는다.
          async.elapse(const Duration(milliseconds: 90));
          expect(c.errorActive['0,1'], isTrue);
        });
      });

      test('cancelling one cell does not touch a different cell mid-flight',
          () {
        fakeAsync((async) {
          final board = partial();
          final c = fresh(board);

          board[0][1] = 9; // wrong
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          c.triggerErrorEffect(
            row: 0,
            col: 1,
            setState: run,
            isMounted: () => true,
          );
          async.elapse(const Duration(milliseconds: 20));
          expect(c.errorActive['0,1'], isTrue);

          board[0][2] = 4; // 다른 칸에 정답 입력, solved[0][2] == 4
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          c.triggerCorrectEffect(
            row: 0,
            col: 2,
            setState: run,
            isMounted: () => true,
          );

          // (0,1)의 오답 강조는 그대로 남아 있어야 한다.
          expect(c.errorActive['0,1'], isTrue);
          expect(c.waveActive['0,2'], isTrue);
        });
      });

      test(
          'a lingering plain pulse is replaced when a later input completes '
          'its line', () {
        fakeAsync((async) {
          final board = copy();
          board[0][1] = 0; // A: 나중에 행0을 완성시키는 칸
          board[0][5] = 0; // B: 행0의 마지막 빈 칸
          board[1][1] = 0; // A를 채워도 열1·박스0은 아직 완성되지 않게 한다
          final c = fresh(board);

          // 입력 1: A만 채운다. 아직 어떤 줄도 완성되지 않아 일반 정답
          // 펄스만 뜬다.
          board[0][1] = solved[0][1];
          var delta = c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          expect(delta.hasNewCompletion, isFalse);
          c.triggerCorrectEffect(
            row: 0,
            col: 1,
            setState: run,
            isMounted: () => true,
          );
          expect(c.waveActive['0,1'], isTrue);

          // 펄스가 자연히 꺼지기 전(120ms 미만)에 B를 채워 행을 완성한다.
          async.elapse(const Duration(milliseconds: 40));
          expect(c.waveActive['0,1'], isTrue);

          board[0][5] = solved[0][5];
          delta = c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          expect(delta.completedRows, 1);
          c.triggerCorrectEffect(
            row: 0,
            col: 5,
            setState: run,
            isMounted: () => true,
          );

          // A는 더 이상 일반 정답 색이 아니라 줄 완성 강조로 보여야 한다.
          expect(c.waveActive['0,1'], isNull);
          expect(c.lineCompleteActive['0,1'], isTrue);

          // A의 옛 펄스가 원래 사라졌을 시점이 지나도 줄 완성 강조는
          // 그대로다.
          async.elapse(const Duration(milliseconds: 100));
          expect(c.lineCompleteActive['0,1'], isTrue);
        });
      });

      test(
          'an earlier line-complete effect does not clear a later one on '
          'shared cells', () {
        fakeAsync((async) {
          final board = copy();
          board[2][2] = 0; // 박스0(과 열2)의 유일한 빈 칸
          board[0][7] = 0; // 행0(과 열7, 박스2)의 유일한 빈 칸
          board[8][8] = 0; // 이 테스트 동안 계속 비워 둬 퍼즐 전체 완료를 막는다
          final c = fresh(board);

          // 이벤트 1: 박스0을 완성한다.
          board[2][2] = solved[2][2];
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          expect(c.lineCompleteActive['1,0'], isTrue); // 박스0 전용 칸
          expect(c.lineCompleteActive['0,0'], isTrue); // 박스0·행0 공유 칸

          // 100ms 뒤, 이벤트 2: 행0을 완성한다(공유 칸 (0,0)(0,1)(0,2) 포함).
          async.elapse(const Duration(milliseconds: 100));
          board[0][7] = solved[0][7];
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          expect(c.lineCompleteActive['0,7'], isTrue);

          // 이벤트1이 원래 끝났어야 할 시점(t=490): 전용 칸은 꺼지지만,
          // 공유 칸은 이벤트2가 새로 가져가 켜진 채로 남아야 한다.
          async.elapse(const Duration(milliseconds: 390));
          expect(c.lineCompleteActive['1,0'], isFalse);
          expect(c.lineCompleteActive['0,0'], isTrue);

          // 이벤트2가 끝나는 시점(t=590)에는 공유 칸도 함께 꺼진다.
          async.elapse(const Duration(milliseconds: 100));
          expect(c.lineCompleteActive['0,0'], isFalse);
          expect(c.lineCompleteActive['0,7'], isFalse);
        });
      });

      test(
          'turning on reduce motion mid-shake resets the offset immediately '
          'and further scheduled frames stay quiet', () {
        fakeAsync((async) {
          final board = partial();
          final c = fresh(board);

          board[0][1] = 9; // wrong, solved[0][1] == 3
          c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: run,
            isMounted: () => true,
          );
          c.triggerErrorEffect(
            row: 0,
            col: 1,
            setState: run,
            isMounted: () => true,
          );

          async.elapse(const Duration(milliseconds: 30));
          expect(c.errorOffset['0,1'], isNot(0));

          c.reduceMotion = true;
          expect(c.errorOffset['0,1'], 0);

          // 이미 예약돼 있던 다음 흔들림 프레임들이 실행돼도 다시
          // 움직이지 않는다.
          async.elapse(const Duration(milliseconds: 120));
          expect(c.errorOffset['0,1'] ?? 0, 0);
        });
      });
    });

    group('undo highlight', () {
      test('highlights only the undone cell, then clears', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerUndoEffect(
            row: 3,
            col: 5,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          expect(
            c.undoActive.entries.where((e) => e.value).map((e) => e.key),
            ['3,5'],
          );
          // hold(140ms) 동안은 켜져 있고, hold가 끝나면 꺼진다(그 뒤
          // 위젯 쪽 60ms 색 페이드는 별개 — 문서화된 총 200ms 지속 시간의
          // 나머지 절반). 상태 플래그 자체는 hold 시점에 딱 맞춰 꺼진다.
          async.elapse(const Duration(milliseconds: 100));
          expect(c.undoActive['3,5'], isTrue);
          async.elapse(const Duration(milliseconds: 50));
          expect(c.undoActive['3,5'], isFalse);
        });
      });

      test(
          'a second undo before the first fades moves the highlight '
          'immediately, without waiting', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerUndoEffect(
            row: 0,
            col: 0,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          async.elapse(const Duration(milliseconds: 40));
          expect(c.undoActive['0,0'], isTrue);

          c.triggerUndoEffect(
            row: 1,
            col: 1,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          // 이전 칸은 자신의 hold(140ms)를 기다리지 않고 즉시 꺼진다.
          expect(c.undoActive['0,0'], isFalse);
          expect(c.undoActive['1,1'], isTrue);

          // 이전 칸의 원래 타이머가 지나도 이미 꺼진 상태를 다시 건드리지 않는다.
          async.elapse(const Duration(milliseconds: 120));
          expect(c.undoActive['0,0'], isFalse);
          expect(c.undoActive['1,1'], isTrue);

          async.elapse(const Duration(milliseconds: 80));
          expect(c.undoActive['1,1'], isFalse);
        });
      });

      test('does not touch correct/error/line-complete state', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerUndoEffect(
            row: 2,
            col: 2,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          expect(c.waveActive, isEmpty);
          expect(c.errorActive, isEmpty);
          expect(c.lineCompleteActive, isEmpty);
          async.elapse(const Duration(milliseconds: 200));
        });
      });

      test(
          'starting a correct/error effect on the same cell clears its '
          'undo highlight', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerUndoEffect(
            row: 4,
            col: 4,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          expect(c.undoActive['4,4'], isTrue);
          c.triggerCorrectEffect(
            row: 4,
            col: 4,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          // _claim()이 그 칸의 이전 undoActive 항목을 지운다(false가 아니라
          // 키 자체가 사라짐 — 보드 쪽 판정은 `== true`라 결과는 동일하다).
          expect(c.undoActive['4,4'], isNull);
          async.elapse(const Duration(milliseconds: 200));
        });
      });

      test(
          'clearTransientEffects (pause/dispose/background) clears it '
          'immediately', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerUndoEffect(
            row: 5,
            col: 6,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          c.clearTransientEffects();
          expect(c.undoActive, isEmpty);
          // 취소된 뒤 원래 타이머가 지나도 아무것도 다시 켜지지 않는다.
          async.elapse(const Duration(milliseconds: 200));
          expect(c.undoActive, isEmpty);
        });
      });

      test('a stale timer never calls setState after dispose', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          var mounted = true;
          var setStateCalls = 0;
          c.triggerUndoEffect(
            row: 0,
            col: 0,
            setState: (fn) {
              setStateCalls++;
              fn();
            },
            isMounted: () => mounted,
          );
          expect(setStateCalls, 1);
          mounted = false; // 화면 dispose를 흉내낸다.
          async.elapse(const Duration(milliseconds: 200));
          // 종료 콜백은 isMounted()==false라 setState를 다시 호출하지 않는다.
          expect(setStateCalls, 1);
        });
      });
    });

    group('hint-applied cell highlight', () {
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

      test('highlights only the hinted cell', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerHintAppliedEffect(
            row: 2,
            col: 6,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          expect(
            c.hintAppliedActive.entries.where((e) => e.value).map((e) => e.key),
            ['2,6'],
          );
          async.elapse(const Duration(milliseconds: 200));
        });
      });

      test('fades after the hold (total ~200ms, within 180-220ms)', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerHintAppliedEffect(
            row: 0,
            col: 0,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          async.elapse(const Duration(milliseconds: 100));
          expect(c.hintAppliedActive['0,0'], isTrue);
          async.elapse(const Duration(milliseconds: 50));
          expect(c.hintAppliedActive['0,0'], isFalse);
        });
      });

      test(
          'is skipped when this input also completed a line — the line '
          'effect wins', () {
        fakeAsync((async) {
          // (4,4)도 함께 비워 둬, 행 0을 완성해도 퍼즐 전체가 끝나지 않게
          // 한다(끝나면 _clearVisibleEffects가 lineCompleteActive까지
          // 지워버려 이 테스트의 전제가 깨진다).
          final board = copy()
            ..[0][2] = 0
            ..[4][4] = 0;
          final c = GameEffectsController()
            ..resetForBoard(board: board, solution: solved);
          board[0][2] = 4; // 행 0 완성
          final delta = c.handleBoardChanged(
            board: board,
            solution: solved,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          expect(delta.completedRows, 1);
          expect(c.lineCompleteActive['0,2'], isTrue);

          // 힌트로 이 값을 채웠다고 가정하고 강조를 시도해도, 줄 완성 효과가
          // 이미 이 칸을 차지하고 있으므로 힌트 강조는 걸리지 않는다.
          c.triggerHintAppliedEffect(
            row: 0,
            col: 2,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          expect(c.hintAppliedActive['0,2'], isNull);
          expect(c.lineCompleteActive['0,2'], isTrue);
          async.elapse(const Duration(milliseconds: 600));
        });
      });

      test('is skipped when this input completed the puzzle', () {
        final board = copy()..[8][8] = 0;
        final c = GameEffectsController()
          ..resetForBoard(board: board, solution: solved);
        board[8][8] = 9;
        final delta = c.handleBoardChanged(
          board: board,
          solution: solved,
          setState: (fn) => fn(),
          isMounted: () => true,
        );
        expect(delta.isPuzzleComplete, isTrue);

        c.triggerHintAppliedEffect(
          row: 8,
          col: 8,
          setState: (fn) => fn(),
          isMounted: () => true,
        );
        expect(c.hintAppliedActive, isEmpty);
      });

      test('does not touch correct/error/line-complete/undo state', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerHintAppliedEffect(
            row: 3,
            col: 3,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          expect(c.waveActive, isEmpty);
          expect(c.errorActive, isEmpty);
          expect(c.lineCompleteActive, isEmpty);
          expect(c.undoActive, isEmpty);
          async.elapse(const Duration(milliseconds: 200));
        });
      });

      test(
          'clearTransientEffects (pause/dispose/background) clears it '
          'immediately', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          c.triggerHintAppliedEffect(
            row: 1,
            col: 1,
            setState: (fn) => fn(),
            isMounted: () => true,
          );
          c.clearTransientEffects();
          expect(c.hintAppliedActive, isEmpty);
          async.elapse(const Duration(milliseconds: 200));
          expect(c.hintAppliedActive, isEmpty);
        });
      });

      test('a stale timer never calls setState after dispose', () {
        fakeAsync((async) {
          final c = GameEffectsController();
          var mounted = true;
          var setStateCalls = 0;
          c.triggerHintAppliedEffect(
            row: 0,
            col: 0,
            setState: (fn) {
              setStateCalls++;
              fn();
            },
            isMounted: () => mounted,
          );
          expect(setStateCalls, 1);
          mounted = false;
          async.elapse(const Duration(milliseconds: 200));
          expect(setStateCalls, 1);
        });
      });
    });
  });
}
