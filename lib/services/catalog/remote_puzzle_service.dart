import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mysudoku/model/today_challenge_target.dart';
import 'package:mysudoku/utils/board_codec.dart';

class RemotePuzzleEntry {
  const RemotePuzzleEntry({
    required this.levelName,
    required this.gameNumber,
    required this.board,
    required this.solution,
  });

  final String levelName;
  final int gameNumber;
  final List<List<int>> board;
  final List<List<int>> solution;
}

class RemotePuzzleService {
  RemotePuzzleService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client,
        _baseUrl =
            baseUrl ??
            const String.fromEnvironment(
              'SUDOKU_API_BASE_URL',
              defaultValue: '',
            );

  http.Client? _client;
  final String _baseUrl;

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  http.Client get _resolvedClient => _client ??= http.Client();

  Future<List<RemotePuzzleEntry>> fetchCatalogForLevel({
    required String levelName,
    required int limit,
  }) async {
    if (!isConfigured) {
      return const [];
    }

    try {
      final response = await _resolvedClient.get(
        Uri.parse(_baseUrl).replace(
          path: _joinPath('catalog'),
          queryParameters: {
            'level_name': levelName,
            'limit': '$limit',
          },
        ),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final decoded = jsonDecode(response.body);
      final rawItems = _extractCatalogItems(decoded);
      final items = <RemotePuzzleEntry>[];
      for (final rawItem in rawItems) {
        if (rawItem is! Map<String, dynamic>) {
          continue;
        }
        final gameNumber = _readInt(rawItem, 'game_number', 'gameNumber');
        final board = _readBoard(rawItem['board']);
        final solution = _readBoard(rawItem['solution']);
        final entryLevelName =
            _readString(rawItem, 'level_name', 'levelName') ?? levelName;
        if (gameNumber == null || board == null || solution == null) {
          continue;
        }
        items.add(
          RemotePuzzleEntry(
            levelName: entryLevelName,
            gameNumber: gameNumber,
            board: board,
            solution: solution,
          ),
        );
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<TodayChallengeTarget?> fetchDailyChallengeTarget({
    required DateTime date,
  }) async {
    if (!isConfigured) {
      return null;
    }

    try {
      final yyyyMmDd =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _resolvedClient.get(
        Uri.parse(_baseUrl).replace(
          path: _joinPath('daily-challenge'),
          queryParameters: {
            'date': yyyyMmDd,
          },
        ),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final levelName = _readString(decoded, 'level_name', 'levelName');
      final gameNumber = _readInt(decoded, 'game_number', 'gameNumber');
      if (levelName == null || gameNumber == null) {
        return null;
      }

      return TodayChallengeTarget(
        levelName: levelName,
        gameNumber: gameNumber,
      );
    } catch (_) {
      return null;
    }
  }

  String _joinPath(String segment) {
    final baseUri = Uri.parse(_baseUrl);
    final normalizedBase = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    return '$normalizedBase/$segment';
  }

  List<dynamic> _extractCatalogItems(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'] ?? decoded['games'] ?? decoded['puzzles'];
      if (items is List<dynamic>) {
        return items;
      }
    }
    return const [];
  }

  String? _readString(
    Map<String, dynamic> json,
    String snakeCase,
    String camelCase,
  ) {
    final value = json[snakeCase] ?? json[camelCase];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  int? _readInt(
    Map<String, dynamic> json,
    String snakeCase,
    String camelCase,
  ) {
    final value = json[snakeCase] ?? json[camelCase];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  List<List<int>>? _readBoard(dynamic rawBoard) {
    if (rawBoard is String) {
      return BoardCodec.decode(rawBoard);
    }
    if (rawBoard is List<dynamic>) {
      try {
        return rawBoard
            .map(
              (row) => (row as List<dynamic>)
                  .map((cell) => (cell as num).toInt())
                  .toList(),
            )
            .toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
