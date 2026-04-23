import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';
import 'package:mysudoku/services/my_pace_service.dart';

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
      'starts from next level after last clear and skips missing entries',
      () async {
        final requestedLevels = <String>[];
        final requestedEntries = <String>[];
        final service = MyPaceService(
          loadRecentClearEvents: ({int limit = 1}) async => const [
            {'level_name': '중급'},
          ],
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
      final requestedLevels = <String>[];
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [
          {'level_name': '마스터'},
        ],
        findFirstUnclearedGameNumber: (levelName) async {
          requestedLevels.add(levelName);
          if (levelName == '초급') {
            return 3;
          }
          return null;
        },
        loadGameEntry: (levelName, gameNumber) async {
          if (levelName == '초급' && gameNumber == 3) {
            return _entry(gameNumber: gameNumber);
          }
          return null;
        },
      );

      final target = await service.resolveTarget();

      expect(requestedLevels.first, '초급');
      expect(target, isNotNull);
      expect(target!.level.name, '초급');
      expect(target.game.gameNumber, 3);
      expect(target.restoreSavedSession, isFalse);
    });

    test('returns null when there is no playable puzzle across all levels', () async {
      final requestedLevels = <String>[];
      final requestedEntries = <String>[];
      final service = MyPaceService(
        loadRecentClearEvents: ({int limit = 1}) async => const [],
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
      expect(
        requestedLevels,
        orderedEquals(SudokuLevel.levels.map((level) => level.name)),
      );
      expect(requestedEntries, isEmpty);
    });
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
