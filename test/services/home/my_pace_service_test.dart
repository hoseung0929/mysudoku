import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/services/home/my_pace_service.dart';

void main() {
  group('MyPaceService', () {
    test('uses continue game first without querying puzzle sources', () async {
      final continueSummary = _buildContinueSummary(
        levelName: '중급',
        gameNumber: 7,
      );
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async {
          fail('최근 클리어 이벤트를 조회하면 안 됩니다.');
        },
        findFirstUnclearedGameNumber: (levelName) async {
          fail('미클리어 게임을 조회하면 안 됩니다.');
        },
        findFirstUnclearedGameNumberAfter: (levelName, after) async {
          fail('미클리어 after 조회를 하면 안 됩니다.');
        },
        loadGameEntry: (levelName, gameNumber) async {
          fail('게임 엔트리를 조회하면 안 됩니다.');
        },
      );

      final target = await service.resolveTarget(
        preferContinueGame: continueSummary,
      );

      expect(target, isNotNull);
      expect(target!.level.name, '중급');
      expect(target.game.gameNumber, 7);
      expect(target.restoreSavedSession, isTrue);
    });

    test(
        'continue game with past clear record is still resumed (retry session)',
        () async {
      final continueSummary = _buildContinueSummary(
        levelName: '초급',
        gameNumber: 1,
      );
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async {
          fail('최근 클리어 이벤트를 조회하면 안 됩니다.');
        },
        findFirstUnclearedGameNumber: (levelName) async {
          fail('미클리어 게임을 조회하면 안 됩니다.');
        },
        findFirstUnclearedGameNumberAfter: (levelName, after) async {
          fail('미클리어 after 조회를 하면 안 됩니다.');
        },
        loadGameEntry: (levelName, gameNumber) async {
          fail('게임 엔트리를 조회하면 안 됩니다.');
        },
      );

      final target = await service.resolveTarget(
        preferContinueGame: continueSummary,
      );

      expect(target!.game.gameNumber, 1);
      expect(target.restoreSavedSession, isTrue);
    });

    test(
      'starts from next level after last clear and skips missing entries',
      () async {
        final requestedLevels = <String>[];
        final requestedEntries = <String>[];
        final service = MyPaceService(
          loadRecentClearEvents: ({int limit = 1}) async => const [
            {'level_name': '중급'},
          ],
          findFirstUnclearedGameNumberAfter: (levelName, after) async => null,
          findFirstUnclearedGameNumber: (levelName) async {
            requestedLevels.add(levelName);
            switch (levelName) {
              case '고급':
                return 11;
              case '전문가':
                return 21;
              default:
                return null;
            }
          },
          loadGameEntry: (levelName, gameNumber) async {
            requestedEntries.add('$levelName#$gameNumber');
            if (levelName == '전문가' && gameNumber == 21) {
              return _entry(gameNumber: gameNumber);
            }
            return null;
          },
        );

        final target = await service.resolveTarget();

        expect(requestedLevels, orderedEquals(const ['고급', '전문가']));
        expect(requestedEntries, orderedEquals(const ['고급#11', '전문가#21']));
        expect(target, isNotNull);
        expect(target!.level.name, '전문가');
        expect(target.game.gameNumber, 21);
        expect(target.restoreSavedSession, isFalse);
      },
    );

    test('wraps to beginner when last cleared level is master', () async {
      // 마스터는 홈에서 숨겨진 비활성 난이도라 이어하기 순회 대상에 없다.
      // 앵커 레벨(마지막 클리어 레벨)이 마스터면 그 100번이라는 문제 번호는
      // 초급에 아무 의미가 없으므로(실제 DB의 AFTER 조회는 "100보다 큰
      // 번호"만 반환할 수 있어 초급 1~99번을 모두 건너뛰게 된다),
      // findFirstUnclearedGameNumberAfter를 아예 부르지 않고 초급을
      // findFirstUnclearedGameNumber로 처음부터 새로 탐색해야 한다.
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [
          {'level_name': '마스터', 'game_number': 100},
        ],
        findFirstUnclearedGameNumberAfter: (levelName, after) async {
          fail('비활성 난이도(마스터)의 문제 번호를 다른 난이도의 after 기준으로 '
              '쓰면 안 됩니다: level=$levelName, after=$after');
        },
        findFirstUnclearedGameNumber: (levelName) async {
          expect(levelName, '초급');
          return 3;
        },
        loadGameEntry: (levelName, gameNumber) async {
          if (levelName == '초급' && gameNumber == 3) {
            return _entry(gameNumber: gameNumber);
          }
          return null;
        },
      );

      final target = await service.resolveTarget();

      expect(target, isNotNull);
      expect(target!.level.name, '초급');
      expect(target.game.gameNumber, 3);
      expect(target.restoreSavedSession, isFalse);
    });

    test(
        'master record with no beginner puzzles left recommends the first '
        'intermediate puzzle', () async {
      final requestedLevels = <String>[];
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [
          {'level_name': '마스터', 'game_number': 100},
        ],
        findFirstUnclearedGameNumberAfter: (levelName, after) async {
          fail('비활성 난이도(마스터)의 문제 번호를 다른 난이도의 after 기준으로 '
              '쓰면 안 됩니다: level=$levelName, after=$after');
        },
        findFirstUnclearedGameNumber: (levelName) async {
          requestedLevels.add(levelName);
          if (levelName == '중급') return 5;
          return null; // 초급은 플레이 가능한 문제가 없음
        },
        loadGameEntry: (levelName, gameNumber) async {
          if (levelName == '중급' && gameNumber == 5) {
            return _entry(gameNumber: gameNumber);
          }
          return null;
        },
      );

      final target = await service.resolveTarget();

      expect(requestedLevels, orderedEquals(const ['초급', '중급']));
      expect(target, isNotNull);
      expect(target!.level.name, '중급');
      expect(target.game.gameNumber, 5);
      expect(target.restoreSavedSession, isFalse);
    });

    test(
        'an unknown/removed level name in the last record starts from '
        'beginner', () async {
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [
          {'level_name': '삭제된난이도', 'game_number': 42},
        ],
        findFirstUnclearedGameNumberAfter: (levelName, after) async {
          fail('비활성/알 수 없는 난이도의 문제 번호를 다른 난이도의 after 기준으로 '
              '쓰면 안 됩니다: level=$levelName, after=$after');
        },
        findFirstUnclearedGameNumber: (levelName) async {
          expect(levelName, '초급');
          return 1;
        },
        loadGameEntry: (levelName, gameNumber) async {
          if (levelName == '초급' && gameNumber == 1) {
            return _entry(gameNumber: gameNumber);
          }
          return null;
        },
      );

      final target = await service.resolveTarget();

      expect(target, isNotNull);
      expect(target!.level.name, '초급');
      expect(target.game.gameNumber, 1);
    });

    test(
        'an active-level record (beginner #15) still searches after that '
        'number in the same level', () async {
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [
          {'level_name': '초급', 'game_number': 15},
        ],
        findFirstUnclearedGameNumberAfter: (levelName, after) async {
          expect(levelName, '초급');
          expect(after, 15);
          return 16;
        },
        findFirstUnclearedGameNumber: (levelName) async {
          fail('같은 활성 난이도에서 after(...)로 충분할 때 다른 조회는 생략되어야 함');
        },
        loadGameEntry: (levelName, gameNumber) async {
          if (levelName == '초급' && gameNumber == 16) {
            return _entry(gameNumber: gameNumber);
          }
          return null;
        },
      );

      final target = await service.resolveTarget();

      expect(target, isNotNull);
      expect(target!.level.name, '초급');
      expect(target.game.gameNumber, 16);
    });

    test(
        'an active-level record with nothing higher wraps to a lower-numbered '
        'uncleared puzzle in the same level before trying the next level',
        () async {
      final calls = <String>[];
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [
          {'level_name': '초급', 'game_number': 159},
        ],
        findFirstUnclearedGameNumberAfter: (levelName, after) async {
          calls.add('after:$levelName:$after');
          expect(levelName, '초급');
          expect(after, 159);
          return null;
        },
        findFirstUnclearedGameNumber: (levelName) async {
          calls.add('first:$levelName');
          if (levelName == '초급') return 3;
          fail('초급 3번을 로드하기 전에 다른 난이도를 조회하면 안 됩니다: $levelName');
        },
        loadGameEntry: (levelName, gameNumber) async {
          if (levelName == '초급' && gameNumber == 3) {
            return _entry(gameNumber: gameNumber);
          }
          return null;
        },
      );

      final target = await service.resolveTarget();

      expect(calls, orderedEquals(const ['after:초급:159', 'first:초급']));
      expect(target, isNotNull);
      expect(target!.level.name, '초급');
      expect(target.game.gameNumber, 3);
      expect(target.restoreSavedSession, isFalse);
    });

    test(
        'an active-level record fully cleared (no higher, no lower puzzle) '
        'moves on to the next active level', () async {
      final calls = <String>[];
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [
          {'level_name': '초급', 'game_number': 159},
        ],
        findFirstUnclearedGameNumberAfter: (levelName, after) async {
          calls.add('after:$levelName:$after');
          return null;
        },
        findFirstUnclearedGameNumber: (levelName) async {
          calls.add('first:$levelName');
          if (levelName == '중급') return 5;
          return null;
        },
        loadGameEntry: (levelName, gameNumber) async {
          if (levelName == '중급' && gameNumber == 5) {
            return _entry(gameNumber: gameNumber);
          }
          return null;
        },
      );

      final target = await service.resolveTarget();

      // 초급의 낮은 번호 미완료 여부를 먼저 확인한 뒤에만 중급으로 넘어간다.
      expect(
          calls, orderedEquals(const ['after:초급:159', 'first:초급', 'first:중급']));
      expect(target, isNotNull);
      expect(target!.level.name, '중급');
      expect(target.game.gameNumber, 5);
    });

    test(
        'an active-level record fully cleared and no other active level has '
        'a puzzle returns null', () async {
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [
          {'level_name': '초급', 'game_number': 159},
        ],
        findFirstUnclearedGameNumberAfter: (levelName, after) async => null,
        findFirstUnclearedGameNumber: (levelName) async => null,
        loadGameEntry: (levelName, gameNumber) async {
          fail('찾은 문제 번호가 없으므로 게임 엔트리를 조회하면 안 됩니다.');
        },
      );

      final target = await service.resolveTarget();

      expect(target, isNull);
    });

    test('returns null when there is no playable puzzle across all levels',
        () async {
      final requestedLevels = <String>[];
      final requestedEntries = <String>[];
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [],
        findFirstUnclearedGameNumberAfter: (levelName, after) async => null,
        findFirstUnclearedGameNumber: (levelName) async {
          requestedLevels.add(levelName);
          return null;
        },
        loadGameEntry: (levelName, gameNumber) async {
          requestedEntries.add('$levelName#$gameNumber');
          return null;
        },
      );

      final target = await service.resolveTarget();

      expect(target, isNull);
      // 마스터는 홈에서 숨겨진 비활성 난이도라 순회 대상이 아니다.
      expect(
        requestedLevels,
        orderedEquals(SudokuLevel.levels
            .where((level) => !level.isMasterLevel)
            .map((level) => level.name)),
      );
      expect(requestedEntries, isEmpty);
    });

    test(
      'after clearing beginner game 1, next target is beginner game 2',
      () async {
        final service = MyPaceService(
          loadRecentClearEvents: ({int limit = 1}) async => const [
            {'level_name': '초급', 'game_number': 1},
          ],
          findFirstUnclearedGameNumberAfter: (levelName, after) async {
            expect(levelName, '초급');
            expect(after, 1);
            return 2;
          },
          findFirstUnclearedGameNumber: (levelName) async {
            fail('같은 레벨에서 after(...)로 충분할 때 다른 조회는 생략되어야 함');
          },
          loadGameEntry: (levelName, gameNumber) async {
            if (levelName == '초급' && gameNumber == 2) {
              return _entry(gameNumber: gameNumber);
            }
            return null;
          },
        );

        final target = await service.resolveTarget();

        expect(target, isNotNull);
        expect(target!.level.name, '초급');
        expect(target.game.gameNumber, 2);
        expect(target.restoreSavedSession, isFalse);
      },
    );
  });
}

ContinueGameSummary _buildContinueSummary({
  required String levelName,
  required int gameNumber,
}) {
  final level = SudokuLevel.levels.firstWhere((item) => item.name == levelName);
  return ContinueGameSummary(
    level: level,
    game: SudokuGame(
      board: _board(seed: 1),
      solution: _board(seed: 2),
      emptyCells: level.emptyCells,
      levelName: levelName,
      gameNumber: gameNumber,
    ),
    progress: 0.5,
    elapsedFilledCells: 20,
    lastPlayedAtMillis: 0,
    elapsedSeconds: 120,
    wrongCount: 0,
    isMemoMode: false,
    noteCount: 0,
  );
}

Map<String, dynamic> _entry({required int gameNumber}) {
  return {
    'game_number': gameNumber,
    'board': _board(seed: 3),
    'solution': _board(seed: 4),
  };
}

List<List<int>> _board({required int seed}) {
  return List.generate(
    9,
    (row) => List.generate(
      9,
      (col) => ((row * 3 + col + seed) % 9) + 1,
    ),
  );
}
