import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/l10n/app_localizations_en.dart';
import 'package:mysudoku/model/today_challenge_target.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

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

    test('falls back to first playable challenge entry when target is missing', () async {
      final challengeFake = _FakeChallengeProgressService(
        target: const TodayChallengeTarget(levelName: '초급', gameNumber: 99),
      );
      final fallbackBoard = List.generate(
        9,
        (row) => List.generate(9, (col) => row == col ? 0 : ((row + col) % 9) + 1),
      );
      final fallbackSolution = List.generate(
        9,
        (row) => List.generate(9, (col) => ((row * 3) + col) % 9 + 1),
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
        loadGameEntriesForLevel: (levelName) async {
          return [
            {
              'game_number': 3,
              'board': fallbackBoard,
              'solution': fallbackSolution,
            },
          ];
        },
      );

      final data = await service.load(AppLocalizationsEn());

      expect(data.todayChallenge.gameNumber, 3);
      expect(data.todayChallenge.board, fallbackBoard);
      expect(data.todayChallenge.solution, fallbackSolution);
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
            [<int>{}, <int>{}, <int>{2, 4}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{1}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
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
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
            [<int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}, <int>{}],
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
