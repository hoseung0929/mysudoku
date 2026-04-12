import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/constants/records_level_filter.dart';
import 'package:mysudoku/services/records_statistics_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('RecordsStatisticsService', () {
    final service = RecordsStatisticsService();

    test('filters recent records by selected level', () {
      final recent = [
        {'level_name': '초급', 'clear_time': 100, 'wrong_count': 1},
        {'level_name': '중급', 'clear_time': 200, 'wrong_count': 2},
      ];

      final filtered = service.filterRecentRecords(
        recent: recent,
        selectedLevel: '초급',
      );

      expect(filtered.length, 1);
      expect(filtered.first['level_name'], '초급');
    });

    test('all-levels filter keeps every record (locale-independent constant)', () {
      final recent = [
        {'level_name': '초급', 'clear_time': 100, 'wrong_count': 1},
        {'level_name': '중급', 'clear_time': 200, 'wrong_count': 2},
      ];

      final filtered = service.filterRecentRecords(
        recent: recent,
        selectedLevel: RecordsLevelFilter.allLevels,
      );

      expect(filtered.length, 2);
    });

    test('builds overall stats from filtered records', () {
      final overall = {'total_games': 200};
      final levels = [
        {'level_name': '초급', 'total_count': 100},
        {'level_name': '중급', 'total_count': 100},
      ];
      final recent = [
        {'level_name': '초급', 'clear_time': 100, 'wrong_count': 0},
        {'level_name': '초급', 'clear_time': 200, 'wrong_count': 3},
        {'level_name': '중급', 'clear_time': 300, 'wrong_count': 2},
      ];

      final stats = service.buildOverallStats(
        overall: overall,
        levels: levels,
        recent: recent,
        selectedLevel: '초급',
      );

      expect(stats['total_cleared'], 2);
      expect(stats['total_games'], 100);
      expect(stats['perfect_clears'], 1);
      expect(stats['perfect_clear_rate'], 50.0);
      expect(stats['total_average_time'], 150.0);
      expect(stats['total_average_wrong_count'], 1.5);
    });

    test('treats clear_time and wrong_count as num (e.g. SQLite double)', () {
      final recent = [
        {
          'level_name': '초급',
          'game_number': 1,
          'clear_time': 120.0,
          'wrong_count': 2.0,
        },
      ];

      final topRecords = service.buildTopRecords(
        recent: recent,
        selectedLevel: '초급',
      );

      expect(topRecords, hasLength(1));
      expect(topRecords.single['game_number'], 1);
      final stats = service.buildOverallStats(
        overall: const {'total_games': 10},
        levels: const [
          {'level_name': '초급', 'total_count': 10},
        ],
        recent: recent,
        selectedLevel: '초급',
      );
      expect(stats['total_average_time'], 120.0);
      expect(stats['total_average_wrong_count'], 2.0);
    });

    test('treats total_games and total_count as num', () {
      final recent = [
        {
          'level_name': '초급',
          'clear_time': 120,
          'wrong_count': 0,
        },
      ];

      final stats = service.buildOverallStats(
        overall: const {'total_games': 10.0},
        levels: const [
          {'level_name': '초급', 'total_count': 10.0},
        ],
        recent: recent,
        selectedLevel: '초급',
      );

      expect(stats['total_games'], 10);
      expect(stats['total_clear_rate'], 10.0);
      expect(stats['perfect_clears'], 1);
    });

    test('sorts top records by clear time then wrong count', () {
      final recent = [
        {
          'level_name': '초급',
          'game_number': 1,
          'clear_time': 120,
          'wrong_count': 2,
        },
        {
          'level_name': '초급',
          'game_number': 2,
          'clear_time': 120,
          'wrong_count': 1,
        },
        {
          'level_name': '초급',
          'game_number': 3,
          'clear_time': 90,
          'wrong_count': 3,
        },
      ];

      final topRecords = service.buildTopRecords(
        recent: recent,
        selectedLevel: '초급',
      );

      expect(topRecords.map((record) => record['game_number']).toList(), [3, 2, 1]);
    });

    test('builds best record list by level', () {
      final recent = [
        {
          'level_name': '초급',
          'game_number': 1,
          'clear_time': 150,
          'wrong_count': 1,
        },
        {
          'level_name': '초급',
          'game_number': 2,
          'clear_time': 120,
          'wrong_count': 0,
        },
        {
          'level_name': '중급',
          'game_number': 5,
          'clear_time': 220,
          'wrong_count': 2,
        },
      ];

      final bestByLevel = service.buildBestByLevel(
        recent: recent,
        selectedLevel: RecordsLevelFilter.allLevels,
      );

      expect(bestByLevel.length, 2);
      expect(bestByLevel.first['level_name'], '초급');
      expect(bestByLevel.first['game_number'], 2);
      expect(bestByLevel.first['is_perfect'], isTrue);
      expect(bestByLevel.last['level_name'], '중급');
    });

    test('builds daily trend for the recent seven days', () {
      final today = DateTime.now();
      String fmt(DateTime date) =>
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final recent = [
        {
          'level_name': '초급',
          'clear_date': fmt(today),
          'clear_time': 120,
          'wrong_count': 1,
        },
        {
          'level_name': '초급',
          'clear_date': fmt(today),
          'clear_time': 180,
          'wrong_count': 0,
        },
        {
          'level_name': '초급',
          'clear_date': fmt(today.subtract(const Duration(days: 2))),
          'clear_time': 200,
          'wrong_count': 2,
        },
      ];

      final trend = service.buildDailyTrend(
        recent: recent,
        selectedLevel: '초급',
      );

      expect(trend.length, 7);
      expect(trend.last['clears'], 2);
      expect(trend.last['average_time'], 150.0);
      expect(trend[4]['clears'], 1);
    });

    test('builds trend summary from recent daily trend window', () {
      final today = DateTime.now();
      String fmt(DateTime date) =>
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final recent = [
        {
          'level_name': '초급',
          'clear_date': fmt(today),
          'clear_time': 100,
          'wrong_count': 1,
        },
        {
          'level_name': '초급',
          'clear_date': fmt(today.subtract(const Duration(days: 1))),
          'clear_time': 140,
          'wrong_count': 0,
        },
      ];

      final summary = service.buildTrendSummary(
        recent: recent,
        selectedLevel: '초급',
      );

      expect(summary['total_clears'], 2);
      expect(summary['active_days'], 2);
      expect(summary['average_time'], 120.0);
      expect(summary['average_wrong'], 0.5);
    });
  });
}
