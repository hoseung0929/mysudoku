import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations_en.dart';
import 'package:sudoku159/model/today_challenge_target.dart';
import 'package:sudoku159/services/challenge/achievement_service.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('HomeDashboardService', () {
    test('builds continue summary from saved session details', () async {
      final challengeFake = _FakeChallengeProgressService();
      final service = HomeDashboardService(
        gameStateService: _FakeGameStateService(),
        challengeProgressService: challengeFake,
        achievementService: AchievementService(
          challengeProgressService: challengeFake,
          loadOverallStatistics: () async => const {
            'total_cleared': 0,
            'total_games': 1,
          },
          loadRecentRecords: () async => const [],
        ),
        loadGameEntry: (levelName, gameNumber) async {
          return {
            'game_number': gameNumber,
            'board': [
              [5, 0, 0, 6, 7, 8, 9, 1, 2],
              [0, 3, 4, 1, 9, 5, 6, 7, 8],
              [6, 7, 8, 2, 3, 4, 1, 5, 9],
              [1, 2, 3, 4, 5, 6, 7, 8, 9],
              [4, 5, 6, 7, 8, 9, 2, 3, 1],
              [7, 8, 9, 3, 1, 2, 4, 6, 5],
              [2, 1, 5, 8, 6, 7, 3, 9, 4],
              [3, 4, 7, 9, 2, 1, 5, 8, 6],
              [8, 9, 6, 5, 4, 3, 0, 2, 7],
            ],
            'solution': [
              [5, 4, 1, 6, 7, 8, 9, 1, 2],
              [9, 3, 4, 1, 9, 5, 6, 7, 8],
              [6, 7, 8, 2, 3, 4, 1, 5, 9],
              [1, 2, 3, 4, 5, 6, 7, 8, 9],
              [4, 5, 6, 7, 8, 9, 2, 3, 1],
              [7, 8, 9, 3, 1, 2, 4, 6, 5],
              [2, 1, 5, 8, 6, 7, 3, 9, 4],
              [3, 4, 7, 9, 2, 1, 5, 8, 6],
              [8, 9, 6, 5, 4, 3, 1, 2, 7],
            ],
          };
        },
      );

      final data = await service.load(AppLocalizationsEn());
      final continueGame = data.continueGame;

      expect(continueGame, isNotNull);
      expect(data.continueGames, hasLength(2));
      expect(continueGame!.elapsedFilledCells, 2);
      expect(continueGame.progress, closeTo(2 / 4, 0.0001));
      expect(continueGame.lastPlayedAtMillis, 20);
      expect(continueGame.elapsedSeconds, 185);
      expect(continueGame.wrongCount, 1);
      expect(continueGame.isMemoMode, isTrue);
      expect(continueGame.noteCount, 3);
      expect(data.continueGames[1].lastPlayedAtMillis, 10);
    });

    test('skips continue entries with invalid saved board shape', () async {
      final challengeFake = _FakeChallengeProgressService();
      final service = HomeDashboardService(
        gameStateService: _InvalidSavedBoardGameStateService(),
        challengeProgressService: challengeFake,
        achievementService: AchievementService(
          challengeProgressService: challengeFake,
          loadOverallStatistics: () async => const <String, dynamic>{},
          loadRecentRecords: () async => const [],
        ),
        loadGameEntry: (levelName, gameNumber) async {
          return {
            'game_number': gameNumber,
            'board': List.generate(9, (_) => List.filled(9, 0)),
            'solution': List.generate(9, (_) => List.filled(9, 1)),
          };
        },
      );

      final summaries = await service.loadContinueGames();

      expect(summaries, isEmpty);
    });

    test('continue list keeps notes-only, drops opened-only and terminal',
        () async {
      final challengeFake = _FakeChallengeProgressService();
      final service = HomeDashboardService(
        gameStateService: _FilteringGameStateService(),
        challengeProgressService: challengeFake,
        achievementService: AchievementService(
          challengeProgressService: challengeFake,
          loadOverallStatistics: () async => const <String, dynamic>{},
          loadRecentRecords: () async => const [],
        ),
        loadGameEntry: (levelName, gameNumber) async => {
          'game_number': gameNumber,
          'board': _filterBoard,
          'solution': _filterBoard
              .map((r) => r.map((v) => v == 0 ? 1 : v).toList())
              .toList(),
        },
      );

      final summaries = await service.loadContinueGames();

      // 2: 메모만(진행률 0%), 1: 숫자 입력. 3: 열어보기만, 4: 게임오버는 제외.
      expect(summaries.map((s) => s.game.gameNumber), [2, 1]);
      expect(summaries.first.progress, 0);
      expect(summaries.first.noteCount, 2);
    });

    test('does not substitute another puzzle when the target cannot be loaded',
        () async {
      final challengeFake = _FakeChallengeProgressService(
        target: const TodayChallengeTarget(levelName: '초급', gameNumber: 99),
      );
      final service = HomeDashboardService(
        gameStateService: _FakeGameStateService(),
        challengeProgressService: challengeFake,
        achievementService: AchievementService(
          challengeProgressService: challengeFake,
          loadOverallStatistics: () async => const <String, dynamic>{},
          loadRecentRecords: () async => const [],
        ),
        loadGameEntry: (levelName, gameNumber) async => null,
      );

      final data = await service.load(AppLocalizationsEn());

      expect(data.todayChallenge, isNull);
      expect(data.todayChallengeHasSession, isFalse);
    });

    test('reports a resumable session only for the challenge puzzle itself',
        () async {
      Future<HomeDashboardData> loadFor(int gameNumber) {
        final challengeFake = _FakeChallengeProgressService(
          target: TodayChallengeTarget(levelName: '초급', gameNumber: gameNumber),
        );
        return HomeDashboardService(
          gameStateService: _FilteringGameStateService(),
          challengeProgressService: challengeFake,
          achievementService: AchievementService(
            challengeProgressService: challengeFake,
            loadOverallStatistics: () async => const <String, dynamic>{},
            loadRecentRecords: () async => const [],
          ),
          loadGameEntry: (levelName, gameNumber) async => {
            'game_number': gameNumber,
            'board': _filterBoard,
            'solution': _filterBoard
                .map((r) => r.map((v) => v == 0 ? 1 : v).toList())
                .toList(),
          },
        ).load(AppLocalizationsEn());
      }

      // 저장 세션이 있는 문제(1, 2)만 이어하기. 열어보기만 한 3은 새 시작.
      expect((await loadFor(1)).todayChallengeHasSession, isTrue);
      expect((await loadFor(2)).todayChallengeHasSession, isTrue);
      expect((await loadFor(3)).todayChallengeHasSession, isFalse);
      // 다른 저장 게임이 있어도 오늘의 도전 타깃은 표시된 문제 그대로.
      final data = await loadFor(3);
      expect(data.todayChallenge!.gameNumber, 3);
      expect(data.continueGame!.game.gameNumber, 2);
    });
  });
}

class _FakeGameStateService extends GameStateService {
  @override
  Future<List<SavedGameState>> getSavedGames() async {
    return const [
      SavedGameState(
        levelName: '초급',
        gameNumber: 1,
        board: [
          [5, 4, 0, 6, 7, 8, 9, 1, 2],
          [9, 3, 4, 1, 9, 5, 6, 7, 8],
          [6, 7, 8, 2, 3, 4, 1, 5, 9],
          [1, 2, 3, 4, 5, 6, 7, 8, 9],
          [4, 5, 6, 7, 8, 9, 2, 3, 1],
          [7, 8, 9, 3, 1, 2, 4, 6, 5],
          [2, 1, 5, 8, 6, 7, 3, 9, 4],
          [3, 4, 7, 9, 2, 1, 5, 8, 6],
          [8, 9, 6, 5, 4, 3, 0, 2, 7],
        ],
        lastPlayedAtMillis: 20,
        session: GameSessionState(
          board: [
            [5, 4, 0, 6, 7, 8, 9, 1, 2],
            [9, 3, 4, 1, 9, 5, 6, 7, 8],
            [6, 7, 8, 2, 3, 4, 1, 5, 9],
            [1, 2, 3, 4, 5, 6, 7, 8, 9],
            [4, 5, 6, 7, 8, 9, 2, 3, 1],
            [7, 8, 9, 3, 1, 2, 4, 6, 5],
            [2, 1, 5, 8, 6, 7, 3, 9, 4],
            [3, 4, 7, 9, 2, 1, 5, 8, 6],
            [8, 9, 6, 5, 4, 3, 0, 2, 7],
          ],
          notes: [
            [
              <int>{},
              <int>{},
              <int>{2, 4},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{1},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
          ],
          elapsedSeconds: 185,
          hintsRemaining: 2,
          wrongCount: 1,
          isMemoMode: true,
          hintCells: {'0,1'},
          isGameComplete: false,
          isGameOver: false,
        ),
      ),
      SavedGameState(
        levelName: '중급',
        gameNumber: 2,
        board: [
          [5, 4, 0, 6, 7, 8, 9, 1, 2],
          [9, 3, 4, 1, 9, 5, 6, 7, 8],
          [6, 7, 8, 2, 3, 4, 1, 5, 9],
          [1, 2, 3, 4, 5, 6, 7, 8, 9],
          [4, 5, 6, 7, 8, 9, 2, 3, 1],
          [7, 8, 9, 3, 1, 2, 4, 6, 5],
          [2, 1, 5, 8, 6, 7, 3, 9, 4],
          [3, 4, 7, 9, 2, 1, 5, 8, 6],
          [8, 9, 6, 5, 4, 3, 0, 2, 7],
        ],
        lastPlayedAtMillis: 10,
        session: GameSessionState(
          board: [
            [5, 4, 0, 6, 7, 8, 9, 1, 2],
            [9, 3, 4, 1, 9, 5, 6, 7, 8],
            [6, 7, 8, 2, 3, 4, 1, 5, 9],
            [1, 2, 3, 4, 5, 6, 7, 8, 9],
            [4, 5, 6, 7, 8, 9, 2, 3, 1],
            [7, 8, 9, 3, 1, 2, 4, 6, 5],
            [2, 1, 5, 8, 6, 7, 3, 9, 4],
            [3, 4, 7, 9, 2, 1, 5, 8, 6],
            [8, 9, 6, 5, 4, 3, 0, 2, 7],
          ],
          notes: [
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
            [
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{},
              <int>{}
            ],
          ],
          elapsedSeconds: 90,
          hintsRemaining: 3,
          wrongCount: 0,
          isMemoMode: false,
          hintCells: {},
          isGameComplete: false,
          isGameOver: false,
        ),
      ),
    ];
  }
}

class _FakeChallengeProgressService extends ChallengeProgressService {
  _FakeChallengeProgressService({
    this.target = const TodayChallengeTarget(levelName: '초급', gameNumber: 1),
  });

  final TodayChallengeTarget target;

  @override
  Future<ChallengeProgressSummary> load({
    List<Map<String, dynamic>>? recentRecords,
    List<Map<String, dynamic>>? recentClearEvents,
  }) async {
    return ChallengeProgressSummary(
      streakDays: 0,
      isTodayChallengeCleared: false,
      todayChallengeLevelName: target.levelName,
      todayChallengeGameNumber: target.gameNumber,
      lastClearDate: null,
      weeklyClearCount: 0,
      weeklyGoalTarget: 5,
      perfectClearCount: 0,
    );
  }

  @override
  Future<TodayChallengeTarget> getTodayChallengeTarget() async {
    return target;
  }
}

class _InvalidSavedBoardGameStateService extends GameStateService {
  @override
  Future<List<SavedGameState>> getSavedGames() async {
    return const [
      SavedGameState(
        levelName: '초급',
        gameNumber: 1,
        board: [
          [1, 2, 3],
        ],
        lastPlayedAtMillis: 1,
        session: GameSessionState(
          board: [
            [1, 2, 3],
          ],
          notes: [
            [<int>{}],
          ],
          elapsedSeconds: 10,
          hintsRemaining: 3,
          wrongCount: 0,
          isMemoMode: false,
          hintCells: <String>{},
          isGameComplete: false,
          isGameOver: false,
        ),
      ),
    ];
  }
}

final _filterBoard = [
  [0, 0, 3, 4, 5, 6, 7, 8, 9],
  ...List.generate(8, (_) => List.filled(9, 1)),
];

class _FilteringGameStateService extends GameStateService {
  SavedGameState _saved(int number, int millis,
      {int fill = 0, bool notes = false, bool over = false}) {
    final board = _filterBoard.map((r) => List<int>.from(r)).toList();
    if (fill > 0) board[0][0] = 1;
    final noteGrid = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    if (notes) noteGrid[0][1] = {2, 5};
    return SavedGameState(
      levelName: '초급',
      gameNumber: number,
      board: board,
      lastPlayedAtMillis: millis,
      session: GameSessionState(
        board: board,
        notes: noteGrid,
        elapsedSeconds: 300,
        hintsRemaining: 3,
        wrongCount: 0,
        isMemoMode: notes,
        hintCells: const {},
        isGameComplete: false,
        isGameOver: over,
      ),
    );
  }

  @override
  Future<List<SavedGameState>> getSavedGames() async => [
        _saved(3, 40), // 열어보기만 (가장 최근)
        _saved(4, 30, fill: 1, over: true),
        _saved(2, 20, notes: true),
        _saved(1, 10, fill: 1),
      ];
}
