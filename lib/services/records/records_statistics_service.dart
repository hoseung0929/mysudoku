import 'package:mysudoku/constants/records_level_filter.dart';
import 'package:mysudoku/database/database_helper.dart';

class RecordsStatisticsData {
  const RecordsStatisticsData({
    required this.overall,
    required this.levels,
    required this.recent,
  });

  final Map<String, dynamic> overall;
  final List<Map<String, dynamic>> levels;
  final List<Map<String, dynamic>> recent;
}

class RecordsStatisticsService {
  RecordsStatisticsService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  static const List<String> levelOrder = ['초급', '중급', '고급', '전문가', '마스터'];

  /// [buildDailyTrend]가 항상 최근 7일 버킷을 채우려면, 기간 필터가 짧아도
  /// 최소 이만큼(오늘 포함 7일 → 오늘 기준 6일 전)까지 클리어를 불러와야 한다.
  static const int _kTrendPastDaysInclusive = 6;

  final DatabaseHelper _databaseHelper;

  Future<RecordsStatisticsData> load({
    required int selectedPeriodDays,
  }) async {
    final overall = await _databaseHelper.getOverallStatistics();
    final levels = await _databaseHelper.getAllLevelStatistics();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Map<String, dynamic>> recent;
    if (selectedPeriodDays == 0) {
      recent = await _databaseHelper.getRecentClearRecords();
    } else {
      final periodFirstDay =
          today.subtract(Duration(days: selectedPeriodDays - 1));
      final trendFirstDay =
          today.subtract(const Duration(days: _kTrendPastDaysInclusive));
      final queryFirstDay = periodFirstDay.isBefore(trendFirstDay)
          ? periodFirstDay
          : trendFirstDay;
      recent = await _databaseHelper.getClearRecordsByDateRange(
        startDate: _formatDate(queryFirstDay),
        endDate: _formatDate(now),
      );
    }

    return RecordsStatisticsData(
      overall: overall,
      levels: levels,
      recent: recent,
    );
  }

  /// 상단 카드·레벨 통계 등 **표시용 기간**이 `selectedPeriodDays`일 때만 자른 목록.
  /// [load]로 받은 원본 [recent]를 넣고, 7일 추세는 원본으로 [buildDailyTrend]에 넘긴다.
  List<Map<String, dynamic>> filterRecentToDisplayedPeriod({
    required List<Map<String, dynamic>> recent,
    required int selectedPeriodDays,
  }) {
    if (selectedPeriodDays <= 0) {
      return List<Map<String, dynamic>>.from(recent);
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periodFirstDay =
        today.subtract(Duration(days: selectedPeriodDays - 1));
    final cutoff = _formatDate(periodFirstDay);
    return recent
        .where((record) {
          final d = record['clear_date']?.toString();
          return d != null && d.compareTo(cutoff) >= 0;
        })
        .toList(growable: false);
  }

  String formatSeconds(num value) {
    final total = value.round();
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> filterRecentRecords({
    required List<Map<String, dynamic>> recent,
    required String selectedLevel,
  }) {
    if (RecordsLevelFilter.isAllLevels(selectedLevel)) {
      return recent;
    }
    return recent
        .where((record) => record['level_name'] == selectedLevel)
        .toList();
  }

  Map<String, dynamic> buildOverallStats({
    required Map<String, dynamic> overall,
    required List<Map<String, dynamic>> levels,
    required List<Map<String, dynamic>> recent,
    required String selectedLevel,
  }) {
    final filtered = filterRecentRecords(
      recent: recent,
      selectedLevel: selectedLevel,
    );
    final totalsByLevel = buildTotalByLevel(levels);

    final totalGames = RecordsLevelFilter.isAllLevels(selectedLevel)
        ? _recordInt(overall, 'total_games')
        : totalsByLevel[selectedLevel] ?? 0;

    final cleared = filtered.length;
    final perfectClears = filtered.where((record) {
      return _recordInt(record, 'wrong_count') == 0;
    }).length;
    final avgTime = _averageIntField(filtered, 'clear_time');
    final avgWrong = _averageIntField(filtered, 'wrong_count');
    final clearRate = totalGames > 0 ? (cleared / totalGames) * 100 : 0.0;
    final perfectRate = cleared > 0 ? (perfectClears / cleared) * 100 : 0.0;

    return {
      'total_cleared': cleared,
      'total_games': totalGames,
      'total_clear_rate': clearRate,
      'perfect_clears': perfectClears,
      'perfect_clear_rate': perfectRate,
      'total_average_time': avgTime,
      'total_average_wrong_count': avgWrong,
    };
  }

  List<Map<String, dynamic>> buildLevelStats({
    required List<Map<String, dynamic>> levels,
    required List<Map<String, dynamic>> recent,
    required String selectedLevel,
  }) {
    final totals = buildTotalByLevel(levels);
    final stats = <Map<String, dynamic>>[];

    for (final level in levelOrder) {
      if (!RecordsLevelFilter.isAllLevels(selectedLevel) &&
          selectedLevel != level) {
        continue;
      }

      final records = recent.where((e) => e['level_name'] == level).toList();
      final total = totals[level] ?? 0;
      final cleared = records.length;
      final avgTime = _averageIntField(records, 'clear_time');
      final avgWrong = _averageIntField(records, 'wrong_count');
      final perfectClears = records
          .where((record) => _recordInt(record, 'wrong_count') == 0)
          .length;
      final perfectRate =
          cleared > 0 ? (perfectClears / cleared) * 100 : 0.0;
      final bestTime = records.isEmpty
          ? 0
          : records
              .map((record) => _recordInt(record, 'clear_time'))
              .reduce((a, b) => a < b ? a : b);
      final clearRate = total > 0 ? (cleared / total) * 100 : 0.0;

      stats.add({
        'level_name': level,
        'cleared_count': cleared,
        'total_count': total,
        'clear_rate': clearRate,
        'average_time': avgTime,
        'average_wrong': avgWrong,
        'perfect_clears': perfectClears,
        'perfect_rate': perfectRate,
        'best_time': bestTime,
      });
    }

    return stats;
  }

  List<Map<String, dynamic>> buildTopRecords({
    required List<Map<String, dynamic>> recent,
    required String selectedLevel,
    int limit = 5,
  }) {
    final records = List<Map<String, dynamic>>.from(
      filterRecentRecords(
        recent: recent,
        selectedLevel: selectedLevel,
      ),
    )..sort((a, b) {
        final clearTimeA = _recordInt(a, 'clear_time');
        final clearTimeB = _recordInt(b, 'clear_time');
        if (clearTimeA != clearTimeB) {
          return clearTimeA.compareTo(clearTimeB);
        }
        final wrongA = _recordInt(a, 'wrong_count');
        final wrongB = _recordInt(b, 'wrong_count');
        return wrongA.compareTo(wrongB);
      });

    return records.take(limit).toList();
  }

  List<Map<String, dynamic>> buildBestByLevel({
    required List<Map<String, dynamic>> recent,
    required String selectedLevel,
  }) {
    final result = <Map<String, dynamic>>[];

    for (final level in levelOrder) {
      if (!RecordsLevelFilter.isAllLevels(selectedLevel) &&
          selectedLevel != level) {
        continue;
      }

      final records =
          recent.where((record) => record['level_name'] == level).toList()
            ..sort((a, b) {
              final clearTimeA = _recordInt(a, 'clear_time');
              final clearTimeB = _recordInt(b, 'clear_time');
              if (clearTimeA != clearTimeB) {
                return clearTimeA.compareTo(clearTimeB);
              }
              final wrongA = _recordInt(a, 'wrong_count');
              final wrongB = _recordInt(b, 'wrong_count');
              return wrongA.compareTo(wrongB);
            });

      if (records.isEmpty) {
        continue;
      }

      final best = records.first;
      result.add({
        'level_name': level,
        'game_number': best['game_number'],
        'clear_time': best['clear_time'],
        'wrong_count': best['wrong_count'],
        'is_perfect': _recordInt(best, 'wrong_count') == 0,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> buildDailyTrend({
    required List<Map<String, dynamic>> recent,
    required String selectedLevel,
    int days = 7,
  }) {
    final filtered = filterRecentRecords(
      recent: recent,
      selectedLevel: selectedLevel,
    );
    final today = DateTime.now();
    final todayKey = _formatDate(today);
    final buckets = <String, List<Map<String, dynamic>>>{};

    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      buckets[_formatDate(date)] = <Map<String, dynamic>>[];
    }

    for (final record in filtered) {
      final clearDate = record['clear_date'] as String?;
      if (clearDate == null || !buckets.containsKey(clearDate)) {
        continue;
      }
      buckets[clearDate]!.add(record);
    }

    return buckets.entries.map((entry) {
      final records = entry.value;
      return {
        'date': entry.key,
        'label': entry.key.substring(5),
        'is_today': entry.key == todayKey,
        'clears': records.length,
        'average_time': _averageIntField(records, 'clear_time'),
        'average_wrong': _averageIntField(records, 'wrong_count'),
      };
    }).toList();
  }

  Map<String, dynamic> buildTrendSummary({
    required List<Map<String, dynamic>> recent,
    required String selectedLevel,
    int days = 7,
  }) {
    final trend = buildDailyTrend(
      recent: recent,
      selectedLevel: selectedLevel,
      days: days,
    );
    final totalClears = trend.fold<int>(
      0,
      (sum, day) => sum + (day['clears'] as int),
    );
    final activeDays = trend.where((day) => (day['clears'] as int) > 0).length;
    final records = filterRecentRecords(
      recent: recent,
      selectedLevel: selectedLevel,
    ).where((record) {
      final clearDate = record['clear_date'] as String?;
      if (clearDate == null) {
        return false;
      }
      return trend.any((day) => day['date'] == clearDate);
    }).toList();

    return {
      'days': days,
      'total_clears': totalClears,
      'active_days': activeDays,
      'average_time': _averageIntField(records, 'clear_time'),
      'average_wrong': _averageIntField(records, 'wrong_count'),
    };
  }

  Map<String, dynamic>? buildRecommendedLevelByMistakes({
    required List<Map<String, dynamic>> recent,
    int days = 7,
  }) {
    final today = DateTime.now();
    final earliest = _formatDate(today.subtract(Duration(days: days - 1)));
    final latest = _formatDate(today);

    Map<String, dynamic>? best;
    for (final level in levelOrder) {
      final records = recent.where((record) {
        final levelName = record['level_name']?.toString();
        if (levelName != level) {
          return false;
        }
        final clearDate = record['clear_date']?.toString();
        if (clearDate == null || clearDate.isEmpty) {
          return false;
        }
        return clearDate.compareTo(earliest) >= 0 &&
            clearDate.compareTo(latest) <= 0;
      }).toList();

      if (records.isEmpty) {
        continue;
      }
      final averageWrong = _averageIntField(records, 'wrong_count');
      final candidate = <String, dynamic>{
        'level_name': level,
        'sample_count': records.length,
        'average_wrong': averageWrong,
      };

      if (best == null) {
        best = candidate;
        continue;
      }

      final bestWrong = best['average_wrong'] as double;
      final bestSample = best['sample_count'] as int;
      if (averageWrong > bestWrong ||
          (averageWrong == bestWrong && records.length > bestSample)) {
        best = candidate;
      }
    }

    return best;
  }

  Map<String, int> buildTotalByLevel(List<Map<String, dynamic>> levels) {
    final map = <String, int>{};
    for (final level in levels) {
      final levelName = level['level_name']?.toString();
      if (levelName == null || levelName.isEmpty) {
        continue;
      }
      map[levelName] = _recordInt(level, 'total_count');
    }
    return map;
  }

  double _averageIntField(List<Map<String, dynamic>> items, String field) {
    if (items.isEmpty) {
      return 0.0;
    }
    return items
            .map((item) => _recordInt(item, field).toDouble())
            .reduce((a, b) => a + b) /
        items.length;
  }

  /// SQLite·JSON 등에서 `int` / `double`이 섞여 올 때 통계 연산을 안전하게 한다.
  static int _recordInt(Map<String, dynamic> record, String field) {
    final Object? value = record[field];
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
