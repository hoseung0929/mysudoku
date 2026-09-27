import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/model/daily_challenge_completion_detail.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/utils/app_logger.dart';

class _FakeDb implements DatabaseHelper {
  _FakeDb(this.completionsByMonth);
  final Map<String, Map<String, DailyChallengeCompletionDetail>>
      completionsByMonth;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  Future<Map<String, DailyChallengeCompletionDetail>>
      getDailyChallengeCompletionsForMonth(int year, int month) async {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    return completionsByMonth[key] ?? const {};
  }
}

class _FakeStates extends GameStateService {
  _FakeStates(this.saved);
  final List<SavedGameState> saved;

  @override
  Future<List<SavedGameState>> getSavedGames() async => saved;
}

SavedGameState _sessionForDate(
  String challengeDate, {
  bool hasNotes = true,
  int wrongCount = 0,
  bool isGameComplete = false,
  int userFilledCells = 0,
  int? initialHints,
  int? hintsRemaining,
}) {
  final board = List.generate(9, (_) => List.generate(9, (_) => 0));
  final notes = List.generate(
    9,
    (r) => List.generate(
        9, (c) => r == 0 && c == 0 && hasNotes ? {1, 2} : <int>{}),
  );
  return SavedGameState(
    levelName: '초급',
    gameNumber: 1,
    board: board,
    lastPlayedAtMillis: 0,
    session: GameSessionState(
      board: board,
      notes: notes,
      elapsedSeconds: 10,
      hintsRemaining: hintsRemaining ?? 3,
      wrongCount: wrongCount,
      isMemoMode: false,
      hintCells: const {},
      userFilledCells: userFilledCells,
      initialHints: initialHints,
      isGameComplete: isGameComplete,
      isGameOver: false,
      challengeDate: challengeDate,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  test('classifies each day as not completed, in progress, or done', () async {
    // "오늘"과 무관하게 판정되도록 먼 과거 달을 쓴다.
    final past = DateTime.now().subtract(const Duration(days: 400));
    final y = past.year;
    final m = past.month.toString().padLeft(2, '0');
    final service = ChallengeProgressService(
      databaseHelper: _FakeDb({
        '$y-$m': {
          '$y-$m-01': DailyChallengeCompletionDetail(
            date: '$y-$m-01',
            wrongCount: 1,
          ),
          '$y-$m-02': DailyChallengeCompletionDetail(
            date: '$y-$m-02',
            wrongCount: 0,
          ),
        },
      }),
      gameStateService: _FakeStates([
        _sessionForDate('$y-$m-03'),
      ]),
    );

    final calendar =
        await service.loadMonthCalendar(year: y, month: past.month);
    expect(calendar.statusByDate['$y-$m-01'], ChallengeDayStatus.completed);
    expect(
      calendar.statusByDate['$y-$m-02'],
      ChallengeDayStatus.perfectCompleted,
    );
    expect(calendar.statusByDate['$y-$m-03'], ChallengeDayStatus.inProgress);
  });

  test('a day beyond today is always future, regardless of any detail',
      () async {
    final farFuture = DateTime.now().add(const Duration(days: 3650));
    final service = ChallengeProgressService(
      databaseHelper: _FakeDb({}),
      gameStateService: _FakeStates(const []),
    );
    final calendar = await service.loadMonthCalendar(
      year: farFuture.year,
      month: farFuture.month,
    );
    expect(calendar.statusByDate[calendar.statusByDate.keys.last],
        ChallengeDayStatus.future);
  });

  test('a day with no completion and no session is not completed', () async {
    final service = ChallengeProgressService(
      databaseHelper: _FakeDb({}),
      gameStateService: _FakeStates(const []),
    );
    final past = DateTime.now().subtract(const Duration(days: 400));
    final calendar = await service.loadMonthCalendar(
      year: past.year,
      month: past.month,
    );
    expect(
      calendar.statusByDate.values,
      everyElement(ChallengeDayStatus.notCompleted),
    );
  });

  test('a completed session does not count as in-progress even with notes',
      () async {
    final past = DateTime.now().subtract(const Duration(days: 400));
    final dateStr = '${past.year}-${past.month.toString().padLeft(2, '0')}-01';
    final service = ChallengeProgressService(
      databaseHelper: _FakeDb({}),
      gameStateService: _FakeStates([
        _sessionForDate(dateStr, isGameComplete: true),
      ]),
    );
    final calendar = await service.loadMonthCalendar(
      year: past.year,
      month: past.month,
    );
    expect(calendar.statusByDate[dateStr], ChallengeDayStatus.notCompleted);
  });

  test('a fully completed past month is flagged fully completed', () async {
    final past = DateTime(2025, 2, 1); // 28 days
    final completions = <String, DailyChallengeCompletionDetail>{
      for (var day = 1; day <= 28; day++)
        '2025-02-${day.toString().padLeft(2, '0')}':
            DailyChallengeCompletionDetail(
          date: '2025-02-${day.toString().padLeft(2, '0')}',
          wrongCount: 0,
        ),
    };
    final service = ChallengeProgressService(
      databaseHelper: _FakeDb({'2025-02': completions}),
      gameStateService: _FakeStates(const []),
    );
    final calendar = await service.loadMonthCalendar(
      year: past.year,
      month: past.month,
    );
    expect(calendar.isMonthFullyCompleted, isTrue);
  });

  test(
      'the current month is never flagged fully completed before it ends, even if every day so far is done',
      () async {
    final now = DateTime.now();
    final completions = <String, DailyChallengeCompletionDetail>{
      for (var day = 1; day <= now.day; day++)
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}':
            DailyChallengeCompletionDetail(
          date:
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          wrongCount: 0,
        ),
    };
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final service = ChallengeProgressService(
      databaseHelper: _FakeDb({key: completions}),
      gameStateService: _FakeStates(const []),
    );
    final calendar = await service.loadMonthCalendar(
      year: now.year,
      month: now.month,
    );
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (now.day < daysInMonth) {
      expect(calendar.isMonthFullyCompleted, isFalse);
    }
  });

  test('an incomplete past month is not flagged fully completed', () async {
    final completions = <String, DailyChallengeCompletionDetail>{
      for (var day = 1; day <= 27; day++) // 하루 부족
        '2025-02-${day.toString().padLeft(2, '0')}':
            DailyChallengeCompletionDetail(
          date: '2025-02-${day.toString().padLeft(2, '0')}',
          wrongCount: 0,
        ),
    };
    final service = ChallengeProgressService(
      databaseHelper: _FakeDb({'2025-02': completions}),
      gameStateService: _FakeStates(const []),
    );
    final calendar = await service.loadMonthCalendar(year: 2025, month: 2);
    expect(calendar.isMonthFullyCompleted, isFalse);
  });

  group('"in progress" detection uses userFilledCells', () {
    // 세션의 challengeDate를 이 달의 실제 날짜로 덮어써서 달력 판정에
    // 그대로 반영되게 한다.
    Future<ChallengeDayStatus?> statusFor(SavedGameState template) async {
      final past = DateTime.now().subtract(const Duration(days: 400));
      final y = past.year;
      final m = past.month.toString().padLeft(2, '0');
      final dateStr = '$y-$m-05';
      final session = SavedGameState(
        levelName: template.levelName,
        gameNumber: template.gameNumber,
        board: template.board,
        lastPlayedAtMillis: template.lastPlayedAtMillis,
        session: GameSessionState(
          board: template.session.board,
          notes: template.session.notes,
          elapsedSeconds: template.session.elapsedSeconds,
          hintsRemaining: template.session.hintsRemaining,
          wrongCount: template.session.wrongCount,
          isMemoMode: template.session.isMemoMode,
          hintCells: template.session.hintCells,
          userFilledCells: template.session.userFilledCells,
          initialHints: template.session.initialHints,
          isGameComplete: template.session.isGameComplete,
          isGameOver: template.session.isGameOver,
          challengeDate: dateStr,
        ),
      );
      final service = ChallengeProgressService(
        databaseHelper: _FakeDb({}),
        gameStateService: _FakeStates([session]),
      );
      final calendar =
          await service.loadMonthCalendar(year: y, month: past.month);
      return calendar.statusByDate[dateStr];
    }

    test('only correct digits filled (userFilledCells > 0) is in progress',
        () async {
      final status = await statusFor(
        _sessionForDate('ignored', hasNotes: false, userFilledCells: 3),
      );
      expect(status, ChallengeDayStatus.inProgress);
    });

    test('notes only is in progress', () async {
      final status = await statusFor(
        _sessionForDate('ignored', hasNotes: true, userFilledCells: 0),
      );
      expect(status, ChallengeDayStatus.inProgress);
    });

    test('wrong count only is in progress', () async {
      final status = await statusFor(
        _sessionForDate(
          'ignored',
          hasNotes: false,
          userFilledCells: 0,
          wrongCount: 1,
        ),
      );
      expect(status, ChallengeDayStatus.inProgress);
    });

    test('hint used only is in progress', () async {
      final status = await statusFor(
        _sessionForDate(
          'ignored',
          hasNotes: false,
          userFilledCells: 0,
          initialHints: 3,
          hintsRemaining: 2,
        ),
      );
      expect(status, ChallengeDayStatus.inProgress);
    });

    test(
        'filled then fully erased (userFilledCells 0, no other trace) is not completed',
        () async {
      final status = await statusFor(
        _sessionForDate('ignored', hasNotes: false, userFilledCells: 0),
      );
      expect(status, ChallengeDayStatus.notCompleted);
    });

    test('a completed session is never in progress even with userFilledCells',
        () async {
      final status = await statusFor(
        _sessionForDate(
          'ignored',
          hasNotes: false,
          userFilledCells: 9,
          isGameComplete: true,
        ),
      );
      expect(status, isNot(ChallengeDayStatus.inProgress));
    });

    test('a game-over session is never in progress', () async {
      final past = DateTime.now().subtract(const Duration(days: 400));
      final y = past.year;
      final m = past.month.toString().padLeft(2, '0');
      final dateStr = '$y-$m-05';
      final service = ChallengeProgressService(
        databaseHelper: _FakeDb({}),
        gameStateService: _FakeStates([
          SavedGameState(
            levelName: '초급',
            gameNumber: 1,
            board: List.generate(9, (_) => List.generate(9, (_) => 0)),
            lastPlayedAtMillis: 0,
            session: GameSessionState(
              board: List.generate(9, (_) => List.generate(9, (_) => 0)),
              notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
              elapsedSeconds: 10,
              hintsRemaining: 3,
              wrongCount: 3,
              isMemoMode: false,
              hintCells: const {},
              userFilledCells: 5,
              isGameComplete: false,
              isGameOver: true,
              challengeDate: dateStr,
            ),
          ),
        ]),
      );
      final calendar =
          await service.loadMonthCalendar(year: y, month: past.month);
      expect(
        calendar.statusByDate[dateStr],
        isNot(ChallengeDayStatus.inProgress),
      );
    });
  });
}
