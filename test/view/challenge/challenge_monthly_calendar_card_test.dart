import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/challenge/challenge_monthly_calendar_card.dart';

class _ThrowingProgressService extends ChallengeProgressService {
  _ThrowingProgressService({this.failFirstCallOnly = false});

  final bool failFirstCallOnly;
  int callCount = 0;

  @override
  Future<ChallengeMonthCalendar> loadMonthCalendar({
    required int year,
    required int month,
  }) async {
    callCount++;
    if (failFirstCallOnly && callCount > 1) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      return ChallengeMonthCalendar(
        year: year,
        month: month,
        statusByDate: {
          for (var d = 1; d <= daysInMonth; d++)
            '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}':
                ChallengeDayStatus.notCompleted,
        },
        isMonthFullyCompleted: false,
      );
    }
    throw Exception('boom');
  }
}

class _FakeProgressService extends ChallengeProgressService {
  _FakeProgressService(this.calendarByMonth, {this.delay});

  final Map<String, ChallengeMonthCalendar> calendarByMonth;
  final Future<void>? delay;
  int callCount = 0;
  final List<String> requestedMonths = [];

  @override
  Future<ChallengeMonthCalendar> loadMonthCalendar({
    required int year,
    required int month,
  }) async {
    callCount++;
    final key = '$year-${month.toString().padLeft(2, '0')}';
    requestedMonths.add(key);
    if (delay != null) await delay;
    return calendarByMonth[key] ??
        ChallengeMonthCalendar(
          year: year,
          month: month,
          statusByDate: {
            for (var d = 1; d <= DateTime(year, month + 1, 0).day; d++)
              '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}':
                  ChallengeDayStatus.notCompleted,
          },
          isMonthFullyCompleted: false,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  Future<void> pumpCard(
    WidgetTester tester, {
    required ChallengeProgressService service,
    Future<void> Function(DateTime date)? onOpenDate,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(
          body: ChallengeMonthlyCalendarCard(
            challengeProgressService: service,
            onOpenDate: onOpenDate ?? (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows the correct number of day cells for a 28-day month',
      (tester) async {
    final past = DateTime.now().subtract(const Duration(days: 400));
    final key =
        '${past.year}-${DateTime(past.year, 2, 1).month.toString().padLeft(2, '0')}';
    final service = _FakeProgressService({
      key: ChallengeMonthCalendar(
        year: past.year,
        month: 2,
        statusByDate: {
          for (var d = 1; d <= (_isLeap(past.year) ? 29 : 28); d++)
            '$past.year-02-${d.toString().padLeft(2, '0')}':
                ChallengeDayStatus.notCompleted,
        },
        isMonthFullyCompleted: false,
      ),
    });
    await pumpCard(tester, service: service);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed and perfect days show distinct icons, not just color',
      (tester) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    String dateStr(int d) =>
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final service = _FakeProgressService({
      key: ChallengeMonthCalendar(
        year: now.year,
        month: now.month,
        statusByDate: {
          dateStr(1): ChallengeDayStatus.completed,
          dateStr(2): ChallengeDayStatus.perfectCompleted,
          dateStr(3): ChallengeDayStatus.inProgress,
          dateStr(4): ChallengeDayStatus.notCompleted,
        },
        isMonthFullyCompleted: false,
      ),
    });
    await pumpCard(tester, service: service);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    expect(find.byIcon(Icons.star), findsWidgets);
    expect(find.byIcon(Icons.edit_note), findsWidgets);
  });

  testWidgets(
      'tapping a valid day only selects it; the detail button then calls '
      'onOpenDate with that date', (tester) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    DateTime? opened;
    final service = _FakeProgressService({
      key: ChallengeMonthCalendar(
        year: now.year,
        month: now.month,
        statusByDate: {dateStr: ChallengeDayStatus.completed},
        isMonthFullyCompleted: false,
      ),
    });
    await pumpCard(
      tester,
      service: service,
      onOpenDate: (date) async => opened = date,
    );
    await tester.tap(find.text('1').first);
    await tester.pump();
    // 날짜를 누른 것만으로는 아직 아무것도 열리지 않는다.
    expect(opened, isNull);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(opened, isNotNull);
    expect(opened!.day, 1);
  });

  testWidgets('tapping the same day again clears the selection',
      (tester) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final service = _FakeProgressService({
      key: ChallengeMonthCalendar(
        year: now.year,
        month: now.month,
        statusByDate: {dateStr: ChallengeDayStatus.notCompleted},
        isMonthFullyCompleted: false,
      ),
    });
    await pumpCard(tester, service: service);
    await tester.tap(find.text('1').first);
    await tester.pump();
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(find.text('1').first);
    await tester.pump();
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('tapping a future day does nothing', (tester) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (daysInMonth <= now.day) return; // 이번 달에 미래 날짜가 없으면 스킵
    var opened = false;
    final statusByDate = <String, ChallengeDayStatus>{
      for (var d = 1; d <= daysInMonth; d++)
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}':
            d > now.day
                ? ChallengeDayStatus.future
                : ChallengeDayStatus.notCompleted,
    };
    final service = _FakeProgressService({
      key: ChallengeMonthCalendar(
        year: now.year,
        month: now.month,
        statusByDate: statusByDate,
        isMonthFullyCompleted: false,
      ),
    });
    await pumpCard(
      tester,
      service: service,
      onOpenDate: (_) async => opened = true,
    );
    await tester.tap(find.text('$daysInMonth').first);
    await tester.pump();
    expect(opened, isFalse);
  });

  testWidgets('navigating to the next month is blocked at the current month',
      (tester) async {
    final service = _FakeProgressService({});
    await pumpCard(tester, service: service);
    final nextButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('previous month button loads the previous month once',
      (tester) async {
    final service = _FakeProgressService({});
    await pumpCard(tester, service: service);
    final callsBefore = service.callCount;
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.callCount, callsBefore + 1);
    expect(find.text('This month'), findsOneWidget);
  });

  testWidgets('"This month" returns to the current month', (tester) async {
    final service = _FakeProgressService({});
    await pumpCard(tester, service: service);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('This month'), findsOneWidget);

    await tester.tap(find.text('This month'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('This month'), findsNothing);
  });

  testWidgets('rapid month navigation only reflects the latest requested month',
      (tester) async {
    final service = _FakeProgressService(
      {},
      delay: Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await pumpCard(tester, service: service);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    // 마지막으로 요청한 달(2개월 전)의 이름만 최종적으로 보여야 한다.
    final now = DateTime.now();
    final expectedMonth = DateTime(now.year, now.month - 2);
    expect(service.requestedMonths.last,
        '${expectedMonth.year}-${expectedMonth.month.toString().padLeft(2, '0')}');
  });

  testWidgets('reduce motion applies without error', (tester) async {
    final service = _FakeProgressService({});
    await pumpCard(tester, service: service, reduceMotion: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading uses a calendar skeleton instead of a spinner',
      (tester) async {
    final completer = Completer<void>();
    final service = _FakeProgressService({}, delay: completer.future);
    await pumpCard(tester, service: service, reduceMotion: true);

    expect(
        find.byKey(const Key('challenge_calendar_skeleton')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('challenge_calendar_skeleton')), findsNothing);
  });

  testWidgets('a fully completed past month shows the month-complete badge',
      (tester) async {
    final past = DateTime.now().subtract(const Duration(days: 400));
    final key = '${past.year}-${past.month.toString().padLeft(2, '0')}';
    final daysInMonth = DateTime(past.year, past.month + 1, 0).day;
    final service = _FakeProgressService({
      key: ChallengeMonthCalendar(
        year: past.year,
        month: past.month,
        statusByDate: {
          for (var d = 1; d <= daysInMonth; d++)
            '${past.year}-${past.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}':
                ChallengeDayStatus.completed,
        },
        isMonthFullyCompleted: true,
      ),
    });
    // 카드가 시작할 땐 "이번 달"이지만, 과거 달로 이동시켜 확인한다.
    await pumpCard(tester, service: service);
    final now = DateTime.now();
    final monthsBack = (now.year - past.year) * 12 + (now.month - past.month);
    for (var i = 0; i < monthsBack; i++) {
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets(
      'a calendar load failure shows an error with retry instead of an '
      'endless skeleton', (tester) async {
    final service = _ThrowingProgressService(failFirstCallOnly: true);
    await pumpCard(tester, service: service);

    expect(find.byKey(const Key('challenge_calendar_skeleton')), findsNothing);
    expect(find.text('Unable to load the challenge calendar.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Unable to load the challenge calendar.'), findsNothing);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets(
      'selecting a past (non-today) date shows the streak-excluded note',
      (tester) async {
    final now = DateTime.now();
    final pastDay = now.day > 1 ? 1 : null;
    if (pastDay == null) return; // 이번 달 1일이면 과거 날짜가 없어 스킵.
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final service = _FakeProgressService({
      key: ChallengeMonthCalendar(
        year: now.year,
        month: now.month,
        statusByDate: {dateStr: ChallengeDayStatus.notCompleted},
        isMonthFullyCompleted: false,
      ),
    });
    await pumpCard(tester, service: service);
    await tester.tap(find.text('1').first);
    await tester.pump();
    expect(
      find.text("Completing a past challenge doesn't count toward your streak"),
      findsOneWidget,
    );
  });
}

bool _isLeap(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
