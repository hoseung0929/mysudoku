import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/model/daily_challenge_completion_detail.dart';

/// 최근 완료 목록 한 줄에 붙는 표시.
enum RecentCompletionTag {
  /// 그날의 오늘의 도전을 그날 완료한 판.
  dailyChallenge,

  /// 같은 퍼즐을 여러 번 완료했을 때 가장 좋은 판(시간 → 실수 순).
  best,

  /// 같은 퍼즐의 두 번째 이후 완료 중 최고 기록이 아닌 판.
  replay,
}

/// 완료 한 판(`clear_events` 한 행). 다시 푼 판도 각각 한 줄이다.
class RecentCompletion {
  const RecentCompletion({
    required this.levelName,
    required this.gameNumber,
    required this.clearDate,
    required this.clearTime,
    required this.wrongCount,
    required this.hintsUsed,
    this.tags = const [],
  });

  final String levelName;
  final int gameNumber;

  /// 완료한 로컬 날짜(YYYY-MM-DD). 시각은 저장하지 않는다.
  final String clearDate;
  final int clearTime;
  final int wrongCount;
  final int hintsUsed;
  final List<RecentCompletionTag> tags;
}

class RecentCompletionsService {
  RecentCompletionsService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  /// 최신 완료부터 전체 목록을 불러온다.
  Future<List<RecentCompletion>> load() async {
    final events = await _databaseHelper.getAllClearEvents();
    final challenges = await _databaseHelper.getAllDailyChallengeCompletions();
    return build(events: events, challenges: challenges);
  }

  /// [events]는 `clear_events` 행(`id` 포함). 결과는 최신 완료가 먼저다.
  /// 아직 공개하지 않은 마스터 난이도는 기록 화면처럼 제외한다.
  static List<RecentCompletion> build({
    required List<Map<String, dynamic>> events,
    required List<DailyChallengeCompletionDetail> challenges,
  }) {
    final rows = events.where((e) => e['level_name'] != '마스터').toList()
      // 같은 날 안의 순서는 저장 순서(id)로 정한다.
      ..sort((a, b) {
        final byDate =
            (a['clear_date'] as String).compareTo(b['clear_date'] as String);
        if (byDate != 0) return byDate;
        return (a['id'] as int).compareTo(b['id'] as int);
      });

    String puzzleKey(Map<String, dynamic> e) =>
        '${e['level_name']}#${e['game_number']}';

    // 퍼즐별: 판 수, 첫 판, 최고 판(시간이 짧을수록, 같으면 실수가 적을수록,
    // 그래도 같으면 먼저 낸 판 — 기록 저장 정책과 같다).
    final counts = <String, int>{};
    final firstIds = <String, int>{};
    final bestRows = <String, Map<String, dynamic>>{};
    for (final e in rows) {
      final key = puzzleKey(e);
      counts[key] = (counts[key] ?? 0) + 1;
      firstIds.putIfAbsent(key, () => e['id'] as int);
      final best = bestRows[key];
      if (best == null || _isBetter(e, best)) bestRows[key] = e;
    }

    // 도전 표시는 그날·그 퍼즐의 첫 완료 한 판에만 붙인다.
    final challengeKeys = <String>{
      for (final c in challenges)
        if (c.levelName != null && c.gameNumber != null)
          '${c.date}|${c.levelName}#${c.gameNumber}',
    };
    final taggedChallengeKeys = <String>{};

    final result = <RecentCompletion>[];
    for (final e in rows) {
      final key = puzzleKey(e);
      final id = e['id'] as int;
      final isBest = (counts[key] ?? 0) > 1 && bestRows[key]?['id'] == id;
      final challengeKey = '${e['clear_date']}|$key';
      final isChallenge = challengeKeys.contains(challengeKey) &&
          taggedChallengeKeys.add(challengeKey);
      result.add(RecentCompletion(
        levelName: e['level_name'] as String,
        gameNumber: e['game_number'] as int,
        clearDate: e['clear_date'] as String,
        clearTime: e['clear_time'] as int,
        wrongCount: e['wrong_count'] as int? ?? 0,
        hintsUsed: e['hints_used'] as int? ?? 0,
        tags: [
          if (isChallenge) RecentCompletionTag.dailyChallenge,
          if (isBest) RecentCompletionTag.best,
          if (!isBest && firstIds[key] != id) RecentCompletionTag.replay,
        ],
      ));
    }
    return result.reversed.toList(growable: false);
  }

  static bool _isBetter(Map<String, dynamic> a, Map<String, dynamic> b) {
    final timeA = a['clear_time'] as int;
    final timeB = b['clear_time'] as int;
    if (timeA != timeB) return timeA < timeB;
    return (a['wrong_count'] as int? ?? 0) < (b['wrong_count'] as int? ?? 0);
  }
}
