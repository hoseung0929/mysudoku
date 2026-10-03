import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/records/game_record_service.dart';
import 'package:sudoku159/services/settings/notification_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/sudoku_game/game_completion_coordinator.dart';
import 'package:sudoku159/view/sudoku_game/game_end_flow.dart';
import 'package:sudoku159/widgets/game_complete_dialog.dart';

/// 완료 저장 경로만 흉내 내는 가짜 DB. 각 저장을 개별적으로 실패시킬 수 있다.
class _FakeDb implements DatabaseHelper {
  bool failEvent = false;
  bool failDailyHas = false;
  bool failDailyRecord = false;
  final List<String> calls = [];

  @override
  Future<void> saveClearEvent({
    required String levelName,
    required int gameNumber,
    required int clearTime,
    required int wrongCount,
    required int hintsUsed,
    bool autoNotesUsed = false,
    DateTime? clearedAtLocal,
  }) async {
    calls.add('event');
    if (failEvent) throw StateError('event save failed');
  }

  @override
  Future<bool> hasDailyChallengeCompletionForDate(String yyyyMmDd) async {
    calls.add('dailyHas');
    if (failDailyHas) throw StateError('daily lookup failed');
    return false;
  }

  @override
  Future<void> recordDailyChallengeCompletion(
    DateTime clearedAtLocal, {
    String? levelName,
    int? gameNumber,
    int? clearTime,
    int? wrongCount,
    int? hintsUsed,
    bool autoNotesUsed = false,
    bool streakEligible = true,
  }) async {
    calls.add('dailyRecord');
    if (failDailyRecord) throw StateError('daily record failed');
  }

  @override
  Future<int?> findFirstUnclearedGameNumberAfter(
    String levelName,
    int gameNumber,
  ) async =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeRecordService extends GameRecordService {
  _FakeRecordService(this.db, {this.fail = false}) : super(databaseHelper: db);
  final _FakeDb db;
  final bool fail;

  @override
  Future<({bool saved, bool improvedPrevious})> saveClearRecordIfBest({
    required String levelName,
    required int gameNumber,
    required int clearTime,
    required int wrongCount,
    required int hintsUsed,
    bool autoNotesUsed = false,
  }) async {
    db.calls.add('record');
    if (fail) throw StateError('record save failed');
    return (saved: true, improvedPrevious: true);
  }
}

class _FakeChallengeService extends ChallengeProgressService {
  @override
  Future<DateTime?> resolveCompletionDay({
    required String levelName,
    required int gameNumber,
    String? challengeDate,
    DateTime? now,
  }) async =>
      DateTime(2026, 10, 3);
}

class _FakeNotifications extends NotificationService {
  @override
  Future<void> syncReminders() async {}
}

class _ThrowingCoordinator extends GameCompletionCoordinator {
  @override
  Future<GameCompletionData> prepare({
    required AppLocalizations l10n,
    required SudokuLevel level,
    required SudokuGame game,
    required int clearTimeSeconds,
    required int wrongCount,
    required int hintsUsed,
    bool autoNotesUsed = false,
    String? challengeDate,
    bool challengeCountsForStreak = true,
  }) async {
    throw StateError('prepare blew up');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  final level = SudokuLevel.levels.first;
  final game = SudokuGame(
    board: List.generate(9, (_) => List.filled(9, 1)),
    solution: List.generate(9, (_) => List.filled(9, 1)),
    emptyCells: level.emptyCells,
    levelName: level.name,
    gameNumber: 1,
  );

  GameCompletionCoordinator coordinator(_FakeDb db,
          {bool failRecord = false}) =>
      GameCompletionCoordinator(
        gameRecordService: _FakeRecordService(db, fail: failRecord),
        challengeProgressService: _FakeChallengeService(),
        notificationService: _FakeNotifications(),
        databaseHelper: db,
      );

  Future<GameCompletionData> prepare(
    WidgetTester tester,
    GameCompletionCoordinator c,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(builder: (context) {
          l10n = AppLocalizations.of(context)!;
          return const SizedBox();
        }),
      ),
    );
    return c.prepare(
      l10n: l10n,
      level: level,
      game: game,
      clearTimeSeconds: 100,
      wrongCount: 0,
      hintsUsed: 0,
      challengeDate: '2026-10-03',
    );
  }

  group('GameCompletionCoordinator.prepare keeps going when a save fails', () {
    testWidgets('all saves succeed: every step runs, data is complete',
        (tester) async {
      final db = _FakeDb();
      final data = await prepare(tester, coordinator(db));
      expect(db.calls, ['event', 'record', 'dailyHas', 'dailyRecord']);
      expect(data.isNewBestRecord, isTrue);
      expect(data.challengeMessage, isNotNull);
    });

    testWidgets('clear-event save fails: record and daily still saved',
        (tester) async {
      final db = _FakeDb()..failEvent = true;
      final data = await prepare(tester, coordinator(db));
      expect(db.calls, ['event', 'record', 'dailyHas', 'dailyRecord']);
      expect(data.isNewBestRecord, isTrue);
      expect(data.challengeMessage, isNotNull);
    });

    testWidgets('best-record save fails: daily challenge still saved',
        (tester) async {
      final db = _FakeDb();
      final data = await prepare(tester, coordinator(db, failRecord: true));
      expect(db.calls, ['event', 'record', 'dailyHas', 'dailyRecord']);
      expect(data.isNewBestRecord, isFalse);
      expect(data.challengeMessage, isNotNull);
    });

    testWidgets('daily-challenge save fails: no message, no exception',
        (tester) async {
      final db = _FakeDb()..failDailyRecord = true;
      final data = await prepare(tester, coordinator(db));
      expect(db.calls, ['event', 'record', 'dailyHas', 'dailyRecord']);
      expect(data.isNewBestRecord, isTrue);
      // 기록이 저장되지 않았으니 "도전 완료" 문구도 내지 않는다.
      expect(data.challengeMessage, isNull);
    });

    testWidgets('daily lookup fails: no exception, other saves done',
        (tester) async {
      final db = _FakeDb()..failDailyHas = true;
      final data = await prepare(tester, coordinator(db));
      expect(db.calls, ['event', 'record', 'dailyHas']);
      expect(data.challengeMessage, isNull);
    });

    testWidgets('every save fails: still returns default data', (tester) async {
      final db = _FakeDb()
        ..failEvent = true
        ..failDailyRecord = true;
      final data = await prepare(tester, coordinator(db, failRecord: true));
      expect(data.isNewBestRecord, isFalse);
      expect(data.challengeMessage, isNull);
      expect(data.nextGame, isNull);
    });
  });

  Future<void> pumpHost(
    WidgetTester tester,
    GameEndFlow flow,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => flow.showCompletion(
                context: context,
                level: level,
                game: game,
                clearTimeSeconds: 95,
                wrongCount: 1,
                hintsUsed: 0,
                onRestart: () async {},
                onGoToLevelSelection: () async {},
                onNextPuzzle: (_) async {},
              ),
              child: const Text('finish'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('finish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('GameEndFlow always shows the result dialog', () {
    testWidgets('even when prepare() throws', (tester) async {
      await pumpHost(
        tester,
        GameEndFlow(completionCoordinator: _ThrowingCoordinator()),
      );
      expect(find.byType(GameCompleteDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('when the clear-event save fails', (tester) async {
      final db = _FakeDb()..failEvent = true;
      await pumpHost(
        tester,
        GameEndFlow(completionCoordinator: coordinator(db)),
      );
      expect(find.byType(GameCompleteDialog), findsOneWidget);
    });

    testWidgets('when the best-record save fails', (tester) async {
      final db = _FakeDb();
      await pumpHost(
        tester,
        GameEndFlow(completionCoordinator: coordinator(db, failRecord: true)),
      );
      expect(find.byType(GameCompleteDialog), findsOneWidget);
    });

    testWidgets('when the daily-challenge save fails', (tester) async {
      final db = _FakeDb()..failDailyRecord = true;
      await pumpHost(
        tester,
        GameEndFlow(completionCoordinator: coordinator(db)),
      );
      expect(find.byType(GameCompleteDialog), findsOneWidget);
    });
  });
}
