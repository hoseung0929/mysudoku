import '../database/database_helper.dart';

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

  final DatabaseHelper _databaseHelper;

  Future<RecordsStatisticsData> load({
    required int selectedPeriodDays,
  }) async {
    final overall = await _databaseHelper.getOverallStatistics();
    final levels = await _databaseHelper.getAllLevelStatistics();

    final recent = selectedPeriodDays == 0
        ? await _databaseHelper.getRecentClearRecords(limit: 10000)
        : await _databaseHelper.getClearRecordsByDateRange(
            startDate: _formatDate(
              DateTime.now().subtract(Duration(days: selectedPeriodDays - 1)),
            ),
            endDate: _formatDate(DateTime.now()),
          );

    return RecordsStatisticsData(
      overall: overall,
      levels: levels,
      recent: recent,
    );
  }

  String formatSeconds(num value) {
    final total = value.round();
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> filterRecentRecords({
    required List<Map<String, dynamic>> recent,
    required String selectedLevel,
  }) {
    if (selectedLevel == '전체') {
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

    final totalGames = selectedLevel == '전체'
        ? (overall['total_games'] ?? 0) as int
        : totalsByLevel[selectedLevel] ?? 0;

    final cleared = filtered.length;
    final avgTime = _averageIntField(filtered, 'clear_time');
    final avgWrong = _averageIntField(filtered, 'wrong_count');
    final clearRate = totalGames > 0 ? (cleared / totalGames) * 100 : 0.0;

    return {
      'total_cleared': cleared,
      'total_games': totalGames,
      'total_clear_rate': clearRate,
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
      if (selectedLevel != '전체' && selectedLevel != level) {
        continue;
      }

      final records = recent.where((e) => e['level_name'] == level).toList();
      final total = totals[level] ?? 0;
      final cleared = records.length;
      final avgTime = _averageIntField(records, 'clear_time');
      final clearRate = total > 0 ? (cleared / total) * 100 : 0.0;

      stats.add({
        'level_name': level,
        'cleared_count': cleared,
        'total_count': total,
        'clear_rate': clearRate,
        'average_time': avgTime,
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
        final clearTimeA = a['clear_time'] as int;
        final clearTimeB = b['clear_time'] as int;
        if (clearTimeA != clearTimeB) {
          return clearTimeA.compareTo(clearTimeB);
        }
        final wrongA = a['wrong_count'] as int;
        final wrongB = b['wrong_count'] as int;
        return wrongA.compareTo(wrongB);
      });

    return records.take(limit).toList();
  }

  Map<String, int> buildTotalByLevel(List<Map<String, dynamic>> levels) {
    final map = <String, int>{};
    for (final level in levels) {
      map[level['level_name'] as String] = level['total_count'] as int;
    }
    return map;
  }

  double _averageIntField(List<Map<String, dynamic>> items, String field) {
    if (items.isEmpty) {
      return 0.0;
    }
    return items
            .map((item) => (item[field] as int).toDouble())
            .reduce((a, b) => a + b) /
        items.length;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
