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
        {'level_name': '초급', 'clear_time': 100, 'wrong_count': 1},
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
      expect(stats['total_average_time'], 150.0);
      expect(stats['total_average_wrong_count'], 2.0);
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
  });
}
