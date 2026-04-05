import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/l10n/app_localizations_en.dart';
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
  @override
  Future<ChallengeProgressSummary> load({
    List<Map<String, dynamic>>? recentRecords,
  }) async {
    return const ChallengeProgressSummary(
      streakDays: 0,
      isTodayChallengeCleared: false,
      todayChallengeLevelName: '초급',
      todayChallengeGameNumber: 1,
      lastClearDate: null,
      weeklyClearCount: 0,
      weeklyGoalTarget: 5,
      perfectClearCount: 0,
    );
  }

  @override
  Future<TodayChallengeTarget> getTodayChallengeTarget() async {
    return const TodayChallengeTarget(levelName: '초급', gameNumber: 1);
  }
}
