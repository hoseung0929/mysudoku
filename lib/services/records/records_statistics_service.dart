import 'package:sudoku159/constants/records_level_filter.dart';
import 'package:sudoku159/database/database_helper.dart';

class RecordsStatisticsData {
  const RecordsStatisticsData({
    required this.overall,
    required this.levels,
    required this.recent,
    required this.activitySummary,
    required this.events,
  });

  final Map<String, dynamic> overall;
  final List<Map<String, dynamic>> levels;
  final List<Map<String, dynamic>> recent;
  final Map<String, dynamic> activitySummary;
  /// 히트맵 표시 범위에 해당하는 클리어 이벤트
  final List<Map<String, dynamic>> events;
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
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final heatmapStartWeek = currentWeekStart.subtract(const Duration(days: 175));

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

    final totalClearEvents = await _databaseHelper.getClearEventCount();
    final playedDays = await _databaseHelper.getDistinctClearEventDates();
    final activitySummary = _buildActivitySummaryFromPlayedDays(
      totalClears: totalClearEvents,
      playedDays: playedDays.toSet(),
    );
    final events = await _databaseHelper.getClearEventsByDateRange(
      startDate: _formatDate(heatmapStartWeek),
      endDate: _formatDate(now),
    );

    return RecordsStatisticsData(
      overall: overall,
      levels: levels,
      recent: recent,
      activitySummary: activitySummary,
      events: events,
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
    return recent.where((record) {
      final d = record['clear_date']?.toString();
      return d != null && d.compareTo(cutoff) >= 0;
    }).toList(growable: false);
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
      final perfectRate = cleared > 0 ? (perfectClears / cleared) * 100 : 0.0;
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
    bool thisWeek = false,
  }) {
    final filtered = filterRecentRecords(
      recent: recent,
      selectedLevel: selectedLevel,
    );
    final today = DateTime.now();
    final todayKey = _formatDate(today);
    final buckets = <String, List<Map<String, dynamic>>>{};

    if (thisWeek) {
      final monday = today.subtract(Duration(days: today.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        buckets[_formatDate(date)] = <Map<String, dynamic>>[];
      }
    } else {
      for (int i = days - 1; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        buckets[_formatDate(date)] = <Map<String, dynamic>>[];
      }
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

  Map<String, dynamic> buildActivitySummary({
    required List<Map<String, dynamic>> events,
    required String selectedLevel,
  }) {
    final filtered = filterRecentRecords(
      recent: events,
      selectedLevel: selectedLevel,
    );

    final playedDays = filtered
        .map((e) => e['clear_date']?.toString())
        .whereType<String>()
        .where((d) => d.isNotEmpty)
        .toSet();

    return _buildActivitySummaryFromPlayedDays(
      totalClears: filtered.length,
      playedDays: playedDays,
    );
  }

  Map<String, dynamic> buildActivityHeatmap({
    required List<Map<String, dynamic>> events,
    required String selectedLevel,
    int weeks = 12,
  }) {
    final records = filterRecentRecords(
      recent: events,
      selectedLevel: selectedLevel,
    );
    final today = _dateOnly(DateTime.now());
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final startWeek =
        currentWeekStart.subtract(Duration(days: (weeks - 1) * 7));
    final clearCountsByDate = <String, int>{};

    for (final record in records) {
      final clearDate = record['clear_date']?.toString();
      if (clearDate == null || clearDate.isEmpty) {
        continue;
      }
      clearCountsByDate.update(
        clearDate,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final weekColumns = <List<Map<String, dynamic>>>[];
    final monthLabels = <Map<String, dynamic>>[];
    String? previousMonthKey;

    for (int weekIndex = 0; weekIndex < weeks; weekIndex++) {
      final weekStart = startWeek.add(Duration(days: weekIndex * 7));
      final monthKey = '${weekStart.year}-${weekStart.month}';
      if (monthKey != previousMonthKey) {
        monthLabels.add({
          'week_index': weekIndex,
          'date': weekStart,
        });
        previousMonthKey = monthKey;
      }

      final days = <Map<String, dynamic>>[];
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = weekStart.add(Duration(days: dayOffset));
        final dateKey = _formatDate(date);
        final clears = clearCountsByDate[dateKey] ?? 0;
        days.add({
          'date': date,
          'date_key': dateKey,
          'clears': clears,
          'intensity': _activityIntensity(clears),
          'is_today': dateKey == _formatDate(today),
          'is_future': date.isAfter(today),
        });
      }
      weekColumns.add(days);
    }

    return {
      'weeks': weekColumns,
      'month_labels': monthLabels,
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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _activityIntensity(int clears) {
    if (clears <= 0) return 0;
    if (clears == 1) return 1;
    if (clears <= 3) return 2;
    if (clears <= 6) return 3;
    return 4;
  }

  Map<String, dynamic> _buildActivitySummaryFromPlayedDays({
    required int totalClears,
    required Set<String> playedDays,
  }) {
    final today = _dateOnly(DateTime.now());

    int currentStreakDays = 0;
    final startOffset = playedDays.contains(_formatDate(today)) ? 0 : 1;
    while (playedDays.contains(
      _formatDate(today.subtract(Duration(days: startOffset + currentStreakDays))),
    )) {
      currentStreakDays++;
    }

    final sortedDays = playedDays.toList()..sort();
    int bestStreakDays = 0;
    int runningStreak = 0;
    DateTime? previousDay;
    for (final dayKey in sortedDays) {
      final currentDay = DateTime.parse(dayKey);
      if (previousDay != null &&
          currentDay.difference(previousDay).inDays == 1) {
        runningStreak++;
      } else {
        runningStreak = 1;
      }
      if (runningStreak > bestStreakDays) {
        bestStreakDays = runningStreak;
      }
      previousDay = currentDay;
    }

    return {
      'total_clears': totalClears,
      'current_streak_days': currentStreakDays,
      'best_streak_days': bestStreakDays,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
