import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/model/daily_challenge_completion_detail.dart';
import 'package:sudoku159/services/records/recent_completions_service.dart';

var _nextId = 0;

Map<String, dynamic> _event(
  String level,
  int number,
  String date, {
  int time = 300,
  int wrong = 0,
  int hints = 0,
}) =>
    {
      'id': ++_nextId,
      'level_name': level,
      'game_number': number,
      'clear_time': time,
      'wrong_count': wrong,
      'clear_date': date,
      'hints_used': hints,
    };

List<RecentCompletionTag> _tagsOf(
  List<RecentCompletion> list,
  int number, {
  int time = -1,
}) =>
    list
        .firstWhere(
            (e) => e.gameNumber == number && (time < 0 || e.clearTime == time))
        .tags;

void main() {
  setUp(() => _nextId = 0);

  test('newest first: by date, then by save order within the same day', () {
    final events = [
      _event('초급', 1, '2026-10-08'),
      _event('초급', 2, '2026-10-10'),
      _event('초급', 3, '2026-10-10'),
      _event('초급', 4, '2026-10-09'),
    ];
    final list = RecentCompletionsService.build(
      events: events..shuffle(),
      challenges: const [],
    );
    expect(list.map((e) => e.gameNumber), [3, 2, 4, 1]);
  });

  test('a puzzle completed once has no tags', () {
    final list = RecentCompletionsService.build(
      events: [_event('초급', 1, '2026-10-10', wrong: 2, hints: 1)],
      challenges: const [],
    );
    expect(list.single.tags, isEmpty);
    expect(list.single.wrongCount, 2);
    expect(list.single.hintsUsed, 1);
  });

  test('replays: the best run gets "best", other later runs get "replay"', () {
    final list = RecentCompletionsService.build(
      events: [
        _event('초급', 1, '2026-10-01', time: 400),
        _event('초급', 1, '2026-10-02', time: 250),
        _event('초급', 1, '2026-10-03', time: 300),
      ],
      challenges: const [],
    );
    expect(_tagsOf(list, 1, time: 400), isEmpty); // 첫 판
    expect(_tagsOf(list, 1, time: 250), [RecentCompletionTag.best]);
    expect(_tagsOf(list, 1, time: 300), [RecentCompletionTag.replay]);
  });

  test('ties: fewer mistakes wins, then the earlier run', () {
    final list = RecentCompletionsService.build(
      events: [
        _event('중급', 5, '2026-10-01', time: 200, wrong: 1),
        _event('중급', 5, '2026-10-02', time: 200, wrong: 1),
        _event('중급', 5, '2026-10-03', time: 200, wrong: 0),
      ],
      challenges: const [],
    );
    // 같은 시간이면 실수가 적은 판, 그것도 같으면 먼저 낸 판이 최고 기록.
    expect(list[0].tags, [RecentCompletionTag.best]); // 10-03, 실수 0
    expect(list[1].tags, [RecentCompletionTag.replay]);
    expect(list[2].tags, isEmpty); // 첫 판
  });

  test('daily challenge: only the first same-day run of that puzzle', () {
    final list = RecentCompletionsService.build(
      events: [
        _event('고급', 7, '2026-10-10', time: 500),
        _event('고급', 7, '2026-10-10', time: 600),
        _event('고급', 8, '2026-10-10'),
      ],
      challenges: const [
        DailyChallengeCompletionDetail(
            date: '2026-10-10', levelName: '고급', gameNumber: 7),
      ],
    );
    expect(_tagsOf(list, 7, time: 500),
        [RecentCompletionTag.dailyChallenge, RecentCompletionTag.best]);
    expect(_tagsOf(list, 7, time: 600), [RecentCompletionTag.replay]);
    expect(_tagsOf(list, 8), isEmpty);
  });

  test('a challenge completed on a later day (calendar) is not tagged', () {
    final list = RecentCompletionsService.build(
      events: [_event('고급', 7, '2026-10-10')],
      challenges: const [
        DailyChallengeCompletionDetail(
            date: '2026-10-08', levelName: '고급', gameNumber: 7),
        // 마이그레이션 이전 행: 퍼즐 정보가 없으면 무시한다.
        DailyChallengeCompletionDetail(date: '2026-10-10'),
      ],
    );
    expect(list.single.tags, isEmpty);
  });

  test('Master is excluded, like the rest of the records screen', () {
    final list = RecentCompletionsService.build(
      events: [
        _event('마스터', 1, '2026-10-10'),
        _event('전문가', 1, '2026-10-10'),
      ],
      challenges: const [],
    );
    expect(list.map((e) => e.levelName), ['전문가']);
  });
}
