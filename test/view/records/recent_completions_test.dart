import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/services/records/recent_completions_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/records/recent_completion_tile.dart';
import 'package:sudoku159/view/records/recent_completions_screen.dart';

class _FakeService extends RecentCompletionsService {
  _FakeService(this.produce) : super(databaseHelper: _NoDb());
  final Future<List<RecentCompletion>> Function() produce;

  @override
  Future<List<RecentCompletion>> load() => produce();
}

/// 게임 데이터를 찾지 못하는 DB(게임 화면까지 가지 않고 분기만 확인한다).
class _NoDb implements DatabaseHelper {
  int gameEntryCalls = 0;

  @override
  Future<Map<String, dynamic>?> getGameEntry(
      String levelName, int gameNumber) async {
    gameEntryCalls++;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _SessionStateService extends GameStateService {
  _SessionStateService({required this.hasSession});
  final bool hasSession;

  @override
  Future<GameSessionState?> loadSession({
    required String levelName,
    required int gameNumber,
  }) async {
    if (!hasSession) return null;
    return GameSessionState(
      board: List.generate(9, (_) => List.filled(9, 0)),
      notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      elapsedSeconds: 10,
      hintsRemaining: 3,
      wrongCount: 0,
      isMemoMode: false,
      hintCells: <String>{},
      isGameComplete: false,
      isGameOver: false,
    );
  }
}

RecentCompletion _entry({
  int number = 4,
  String date = '2026-10-10',
  int time = 242,
  int wrong = 1,
  int hints = 0,
  List<RecentCompletionTag> tags = const [],
}) =>
    RecentCompletion(
      levelName: '초급',
      gameNumber: number,
      clearDate: date,
      clearTime: time,
      wrongCount: wrong,
      hintsUsed: hints,
      tags: tags,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  final today = DateTime(2026, 10, 10);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: child,
      ),
    );
    await tester.pump();
  }

  group('RecentCompletionTile', () {
    testWidgets('title, date · mistakes · hints, time and tags',
        (tester) async {
      await pump(
        tester,
        Scaffold(
          body: RecentCompletionTile(
            entry: _entry(
              hints: 1,
              tags: const [
                RecentCompletionTag.dailyChallenge,
                RecentCompletionTag.best,
              ],
            ),
            onTap: () {},
            today: today,
          ),
        ),
      );
      expect(find.text('Beginner 004'), findsOneWidget);
      expect(find.text('Today · 1 mistake · Hints: 1'), findsOneWidget);
      expect(find.text('04:02'), findsOneWidget);
      expect(find.text("Today's challenge"), findsOneWidget);
      expect(find.text('Best run'), findsOneWidget);
    });

    testWidgets('no hints part when none were used; replay tag',
        (tester) async {
      await pump(
        tester,
        Scaffold(
          body: RecentCompletionTile(
            entry: _entry(wrong: 0, tags: const [RecentCompletionTag.replay]),
            onTap: () {},
            today: today,
          ),
        ),
      );
      expect(find.text('Today · 0 mistakes'), findsOneWidget);
      expect(find.text('Replay'), findsOneWidget);
    });

    testWidgets('yesterday, this year and an earlier year', (tester) async {
      for (final (date, label) in [
        ('2026-10-09', 'Yesterday'),
        ('2026-10-03', 'Oct 3'),
        ('2025-12-31', 'Dec 31, 2025'),
      ]) {
        await pump(
          tester,
          Scaffold(
            body: RecentCompletionTile(
              entry: _entry(date: date),
              onTap: () {},
              today: today,
            ),
          ),
        );
        expect(find.textContaining(label), findsOneWidget, reason: date);
      }
    });

    testWidgets('time sits on the right, under the title with large text',
        (tester) async {
      for (final (scale, stacked) in [(1.0, false), (2.0, true)]) {
        await pump(
          tester,
          Scaffold(
            body: ListView(
              children: [
                RecentCompletionTile(
                    entry: _entry(), onTap: () {}, today: today),
              ],
            ),
          ),
          textScale: scale,
        );
        final title = tester.getRect(find.text('Beginner 004'));
        final time = tester.getRect(find.text('04:02'));
        if (stacked) {
          expect(time.top, greaterThanOrEqualTo(title.bottom));
          expect(time.left, title.left);
        } else {
          expect(time.left, greaterThan(title.right));
        }
      }
    });

    testWidgets('one button node for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        Scaffold(
          body: RecentCompletionTile(
            entry: _entry(tags: const [RecentCompletionTag.best]),
            onTap: () {},
            today: today,
          ),
        ),
      );
      final node = find.bySemanticsLabel(
          'Beginner, Puzzle 4, Today · 1 mistake, 04:02, Best run');
      expect(node, findsOneWidget);
      expect(tester.getSemantics(node), isSemantics(isButton: true));
      handle.dispose();
    });

    for (final lang in ['en', 'ko', 'ja', 'es', 'zh']) {
      testWidgets('no overflow at 320 wide, 2x text: $lang', (tester) async {
        await pump(
          tester,
          Scaffold(
            // 실제 화면처럼 스크롤 목록 안에 둔다(큰 글씨에서는 줄이 길어진다).
            body: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                RecentCompletionTile(
                  entry: _entry(
                    time: 3725,
                    wrong: 12,
                    hints: 5,
                    date: '2025-12-31',
                    tags: const [
                      RecentCompletionTag.dailyChallenge,
                      RecentCompletionTag.best,
                    ],
                  ),
                  onTap: () {},
                  today: today,
                ),
              ],
            ),
          ),
          size: const Size(320, 568),
          textScale: 2.0,
          locale: Locale(lang),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('openRecentCompletion', () {
    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext captured;
      await pump(
        tester,
        Scaffold(
          body: Builder(builder: (context) {
            captured = context;
            return const SizedBox.expand();
          }),
        ),
      );
      return captured;
    }

    testWidgets('no saved session: asks to replay; cancel opens nothing',
        (tester) async {
      final db = _NoDb();
      final context = await pumpHost(tester);
      final done = openRecentCompletion(
        context,
        _entry(),
        gameStateService: _SessionStateService(hasSession: false),
        databaseHelper: db,
      );
      await tester.pumpAndSettle();
      expect(find.text('Replay puzzle 4?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await done;
      expect(db.gameEntryCalls, 0);
    });

    testWidgets('no saved session: confirming loads the puzzle',
        (tester) async {
      final db = _NoDb();
      final context = await pumpHost(tester);
      final done = openRecentCompletion(
        context,
        _entry(),
        gameStateService: _SessionStateService(hasSession: false),
        databaseHelper: db,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
      await tester.pumpAndSettle();
      await done;
      expect(db.gameEntryCalls, 1);
      // 이 DB에는 퍼즐이 없어 게임 화면 대신 안내만 나온다.
      expect(find.text('Could not load puzzle data.'), findsOneWidget);
    });

    testWidgets('a saved replay session opens directly without asking',
        (tester) async {
      final db = _NoDb();
      final context = await pumpHost(tester);
      final done = openRecentCompletion(
        context,
        _entry(),
        gameStateService: _SessionStateService(hasSession: true),
        databaseHelper: db,
      );
      await tester.pumpAndSettle();
      await done;
      expect(find.text('Replay puzzle 4?'), findsNothing);
      expect(db.gameEntryCalls, 1);
    });
  });

  group('RecentCompletionsScreen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('lists every completion, newest first', (tester) async {
      final entries = [for (var i = 1; i <= 12; i++) _entry(number: i)];
      await pump(
        tester,
        RecentCompletionsScreen(service: _FakeService(() async => entries)),
      );
      await tester.pump();
      expect(find.text('Recent completions'), findsOneWidget);
      expect(find.text('Beginner 001'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Beginner 012'), 200);
      expect(find.text('Beginner 012'), findsOneWidget);
    });

    testWidgets('load failure shows retry, which recovers', (tester) async {
      var calls = 0;
      await pump(
        tester,
        RecentCompletionsScreen(
          service: _FakeService(() async {
            calls++;
            if (calls == 1) throw StateError('db down');
            return [_entry()];
          }),
        ),
      );
      await tester.pump();
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Beginner 004'), findsOneWidget);
    });
  });
}
