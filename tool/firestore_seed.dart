import 'dart:convert';
import 'dart:io';

const List<String> _defaultLevelOrder = <String>[
  '초급',
  '중급',
  '고급',
  '전문가',
  '마스터',
];

void main(List<String> arguments) async {
  try {
    final config = _SeedCommandConfig.parse(arguments);
    final bundle = await _buildSeedBundle(config);

    switch (config.command) {
      case 'export':
        await _exportBundle(config, bundle);
      case 'upload':
        await _uploadBundle(config, bundle);
      default:
        throw _UsageException('지원하지 않는 명령입니다: ${config.command}');
    }
  } on _UsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('');
    stderr.writeln(_usageText);
    exitCode = 64;
  } catch (error, stackTrace) {
    stderr.writeln('시드 작업 실패: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<_SeedBundle> _buildSeedBundle(_SeedCommandConfig config) async {
  final inputFile = File(config.inputPath);
  if (!inputFile.existsSync()) {
    throw _UsageException('입력 CSV 파일을 찾을 수 없습니다: ${config.inputPath}');
  }

  final lines = await inputFile.readAsLines();
  if (lines.isEmpty) {
    throw const _UsageException('입력 CSV 파일이 비어 있습니다.');
  }

  final header = _parseCsvLine(lines.first);
  if (header.length < 5) {
    throw const _UsageException('CSV 헤더 형식이 올바르지 않습니다.');
  }

  final rows = <_PuzzleSeedRow>[];
  for (var index = 1; index < lines.length; index++) {
    final rawLine = lines[index].trim();
    if (rawLine.isEmpty) {
      continue;
    }

    final columns = _parseCsvLine(rawLine);
    if (columns.length < 5) {
      stderr.writeln('건너뜀: ${index + 1}행 컬럼 수가 부족합니다.');
      continue;
    }

    final hasRequiredFields = columns[0].trim().isNotEmpty &&
        columns[1].trim().isNotEmpty &&
        columns[2].trim().isNotEmpty &&
        columns[3].trim().isNotEmpty &&
        columns[4].trim().isNotEmpty;
    if (!hasRequiredFields) {
      stderr.writeln('건너뜀: ${index + 1}행 필수 값이 비어 있습니다.');
      continue;
    }

    try {
      rows.add(
        _PuzzleSeedRow(
          id: int.parse(columns[0]),
          levelName: columns[1],
          gameNumber: int.parse(columns[2]),
          board: _decodeBoard(columns[3]),
          solution: _decodeBoard(columns[4]),
        ),
      );
    } catch (error) {
      throw FormatException(
        'CSV ${index + 1}행 파싱 실패: $error\n원본: $rawLine',
      );
    }
  }

  if (rows.isEmpty) {
    throw const _UsageException('유효한 퍼즐 행을 찾지 못했습니다.');
  }

  final puzzleDocuments = config.scope != _SeedScope.daily
      ? rows
          .map((row) => _SeedDocument(
                path:
                    'puzzle_catalog/${config.catalogVersion}/levels/${row.levelName}/games/${row.gameId}',
                data: <String, Object?>{
                  'levelName': row.levelName,
                  'gameNumber': row.gameNumber,
                  'board': row.board,
                  'solution': row.solution,
                  'emptyCells': row.emptyCells,
                  'version': 1,
                },
                serverTimestampFields: const <String>['createdAt'],
              ))
          .toList()
      : const <_SeedDocument>[];

  final dailyChallengeDocuments =
      config.scope != _SeedScope.catalog && config.includeDailyChallenges
          ? _buildDailyChallengeDocuments(rows, config)
          : const <_SeedDocument>[];

  return _SeedBundle(
    sourceCsvPath: config.inputPath,
    catalogVersion: config.catalogVersion,
    puzzles: puzzleDocuments,
    dailyChallenges: dailyChallengeDocuments,
  );
}

List<_SeedDocument> _buildDailyChallengeDocuments(
  List<_PuzzleSeedRow> rows,
  _SeedCommandConfig config,
) {
  final grouped = <String, List<_PuzzleSeedRow>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row.levelName, () => <_PuzzleSeedRow>[]).add(row);
  }

  for (final levelRows in grouped.values) {
    levelRows.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
  }

  final availableLevels = <String>[
    ..._defaultLevelOrder.where(grouped.containsKey),
    ...grouped.keys.where((level) => !_defaultLevelOrder.contains(level)),
  ];

  if (availableLevels.isEmpty) {
    return const <_SeedDocument>[];
  }

  final documents = <_SeedDocument>[];
  for (var offset = 0; offset < config.dailyDays; offset++) {
    final date = config.dailyStartDate.add(Duration(days: offset));
    final levelName = availableLevels[offset % availableLevels.length];
    final levelRows = grouped[levelName]!;
    final rotation = offset ~/ availableLevels.length;
    final selectedRow = levelRows[rotation % levelRows.length];
    final dateKey = _formatDate(date);

    documents.add(
      _SeedDocument(
        path: 'daily_challenges/$dateKey',
        data: <String, Object?>{
          'date': dateKey,
          'catalogVersion': config.catalogVersion,
          'levelName': selectedRow.levelName,
          'gameId': selectedRow.gameId,
          'gameNumber': selectedRow.gameNumber,
        },
        serverTimestampFields: const <String>['updatedAt'],
      ),
    );
  }

  return documents;
}

Future<void> _exportBundle(
  _SeedCommandConfig config,
  _SeedBundle bundle,
) async {
  final outputFile = File(config.outputPath);
  await outputFile.parent.create(recursive: true);

  final payload = <String, Object?>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sourceCsvPath': bundle.sourceCsvPath,
    'catalogVersion': bundle.catalogVersion,
    'puzzles': bundle.puzzles.map((doc) => doc.toJson()).toList(),
    'dailyChallenges': bundle.dailyChallenges.map((doc) => doc.toJson()).toList(),
  };

  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  stdout.writeln(
    '내보내기 완료: 퍼즐 ${bundle.puzzles.length}건, 오늘의 도전 ${bundle.dailyChallenges.length}건 -> ${outputFile.path}',
  );
}

Future<void> _uploadBundle(
  _SeedCommandConfig config,
  _SeedBundle bundle,
) async {
  final projectId = config.projectId;
  final accessToken = config.accessToken;
  if (projectId == null || projectId.isEmpty) {
    throw const _UsageException(
      'upload에는 --project-id 또는 FIREBASE_PROJECT_ID가 필요합니다.',
    );
  }
  if (accessToken == null || accessToken.isEmpty) {
    throw const _UsageException(
      'upload에는 --access-token 또는 FIREBASE_ACCESS_TOKEN이 필요합니다.',
    );
  }

  final documents = <_SeedDocument>[
    ...bundle.puzzles,
    ...bundle.dailyChallenges,
  ];
  if (documents.isEmpty) {
    stdout.writeln('업로드할 문서가 없습니다.');
    return;
  }

  final endpoint = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/${config.databaseId}/documents:commit',
  );
  final client = HttpClient();

  try {
    for (var start = 0; start < documents.length; start += config.batchSize) {
      final end = (start + config.batchSize > documents.length)
          ? documents.length
          : start + config.batchSize;
      final batch = documents.sublist(start, end);

      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(
        utf8.encode(
          jsonEncode(
            <String, Object?>{
              'writes': batch.map((doc) => doc.toFirestoreWrite(projectId, config.databaseId)).toList(),
            },
          ),
        ),
      );

      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Firestore 업로드 실패 (${response.statusCode}): $responseBody',
        );
      }

      stdout.writeln(
        '업로드 완료: ${start + 1}~$end / ${documents.length}',
      );
    }
  } finally {
    client.close();
  }
}

List<String> _parseCsvLine(String line) {
  final columns = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    if (char == '"') {
      final hasEscapedQuote =
          inQuotes && index + 1 < line.length && line[index + 1] == '"';
      if (hasEscapedQuote) {
        buffer.write('"');
        index++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char == ',' && !inQuotes) {
      columns.add(buffer.toString());
      buffer.clear();
      continue;
    }

    buffer.write(char);
  }

  columns.add(buffer.toString());
  return columns;
}

List<List<int>> _decodeBoard(String rawBoard) {
  final rows = rawBoard.split(';');
  if (rows.length != 9) {
    throw const FormatException('보드 행 수가 9가 아닙니다.');
  }

  return rows.map((row) {
    final cells = row.split(',');
    if (cells.length != 9) {
      throw const FormatException('보드 열 수가 9가 아닙니다.');
    }
    return cells.map((value) => int.parse(value)).toList();
  }).toList();
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

Map<String, Object?> _toFirestoreValue(Object? value) {
  if (value == null) {
    return <String, Object?>{'nullValue': null};
  }
  if (value is String) {
    return <String, Object?>{'stringValue': value};
  }
  if (value is bool) {
    return <String, Object?>{'booleanValue': value};
  }
  if (value is int) {
    return <String, Object?>{'integerValue': value.toString()};
  }
  if (value is double) {
    return <String, Object?>{'doubleValue': value};
  }
  if (value is List) {
    return <String, Object?>{
      'arrayValue': <String, Object?>{
        'values': value.map(_toFirestoreValue).toList(),
      },
    };
  }
  if (value is Map<String, Object?>) {
    return <String, Object?>{
      'mapValue': <String, Object?>{
        'fields': value.map(
          (key, entryValue) => MapEntry(key, _toFirestoreValue(entryValue)),
        ),
      },
    };
  }

  throw UnsupportedError('지원하지 않는 Firestore 값 타입입니다: ${value.runtimeType}');
}

class _PuzzleSeedRow {
  const _PuzzleSeedRow({
    required this.id,
    required this.levelName,
    required this.gameNumber,
    required this.board,
    required this.solution,
  });

  final int id;
  final String levelName;
  final int gameNumber;
  final List<List<int>> board;
  final List<List<int>> solution;

  String get gameId => '${levelName}_$gameNumber';

  int get emptyCells => board
      .expand((row) => row)
      .where((cell) => cell == 0)
      .length;
}

class _SeedDocument {
  const _SeedDocument({
    required this.path,
    required this.data,
    this.serverTimestampFields = const <String>[],
  });

  final String path;
  final Map<String, Object?> data;
  final List<String> serverTimestampFields;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'path': path,
      'data': data,
      'serverTimestampFields': serverTimestampFields,
    };
  }

  Map<String, Object?> toFirestoreWrite(String projectId, String databaseId) {
    final documentName =
        'projects/$projectId/databases/$databaseId/documents/$path';
    return <String, Object?>{
      'update': <String, Object?>{
        'name': documentName,
        'fields': data.map(
          (key, value) => MapEntry(key, _toFirestoreValue(value)),
        ),
      },
      if (serverTimestampFields.isNotEmpty)
        'updateTransforms': serverTimestampFields
            .map(
              (field) => <String, Object?>{
                'fieldPath': field,
                'setToServerValue': 'REQUEST_TIME',
              },
            )
            .toList(),
    };
  }
}

class _SeedBundle {
  const _SeedBundle({
    required this.sourceCsvPath,
    required this.catalogVersion,
    required this.puzzles,
    required this.dailyChallenges,
  });

  final String sourceCsvPath;
  final String catalogVersion;
  final List<_SeedDocument> puzzles;
  final List<_SeedDocument> dailyChallenges;
}

class _SeedCommandConfig {
  const _SeedCommandConfig({
    required this.command,
    required this.scope,
    required this.inputPath,
    required this.catalogVersion,
    required this.outputPath,
    required this.dailyStartDate,
    required this.dailyDays,
    required this.includeDailyChallenges,
    required this.batchSize,
    required this.databaseId,
    this.projectId,
    this.accessToken,
  });

  final String command;
  final _SeedScope scope;
  final String inputPath;
  final String catalogVersion;
  final String outputPath;
  final DateTime dailyStartDate;
  final int dailyDays;
  final bool includeDailyChallenges;
  final int batchSize;
  final String databaseId;
  final String? projectId;
  final String? accessToken;

  static _SeedCommandConfig parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const _UsageException(
        '명령이 필요합니다. export 또는 upload를 사용해 주세요.',
      );
    }

    final command = arguments.first;
    final options = <String, String>{};
    for (final argument in arguments.skip(1)) {
      if (!argument.startsWith('--')) {
        throw _UsageException('옵션 형식이 올바르지 않습니다: $argument');
      }
      final separatorIndex = argument.indexOf('=');
      if (separatorIndex == -1) {
        options[argument.substring(2)] = 'true';
        continue;
      }
      options[argument.substring(2, separatorIndex)] =
          argument.substring(separatorIndex + 1);
    }

    final now = DateTime.now();
    return _SeedCommandConfig(
      command: command,
      scope: _SeedScope.parse(options['scope'] ?? 'all'),
      inputPath: options['input'] ?? 'sudoku_games.csv',
      catalogVersion: options['catalog-version'] ?? 'v1',
      outputPath: options['output'] ??
          'tool/out/firestore_seed_${options['catalog-version'] ?? 'v1'}.json',
      dailyStartDate: _parseDate(options['daily-start-date']) ??
          DateTime(now.year, now.month, now.day),
      dailyDays: int.tryParse(options['daily-days'] ?? '365') ?? 365,
      includeDailyChallenges: (options['include-daily'] ?? 'true') != 'false',
      batchSize: int.tryParse(options['batch-size'] ?? '200') ?? 200,
      databaseId: options['database-id'] ?? '(default)',
      projectId: options['project-id'] ?? Platform.environment['FIREBASE_PROJECT_ID'],
      accessToken:
          options['access-token'] ?? Platform.environment['FIREBASE_ACCESS_TOKEN'],
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final parts = value.split('-');
    if (parts.length != 3) {
      throw _UsageException('날짜는 YYYY-MM-DD 형식이어야 합니다: $value');
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}

enum _SeedScope {
  all,
  catalog,
  daily;

  static _SeedScope parse(String rawValue) {
    switch (rawValue) {
      case 'all':
        return _SeedScope.all;
      case 'catalog':
        return _SeedScope.catalog;
      case 'daily':
        return _SeedScope.daily;
      default:
        throw _UsageException(
          'scope는 all, catalog, daily 중 하나여야 합니다: $rawValue',
        );
    }
  }
}

const String _usageText = '''
사용법:
  dart run tool/firestore_seed.dart export [옵션]
  dart run tool/firestore_seed.dart upload [옵션]

공통 옵션:
  --scope=all|catalog|daily   생성/업로드 범위 (기본값: all)
  --input=PATH                 입력 CSV 경로 (기본값: sudoku_games.csv)
  --catalog-version=VALUE      Firestore catalogVersion (기본값: v1)
  --daily-start-date=YYYY-MM-DD 오늘의 도전 시작 날짜 (기본값: 오늘)
  --daily-days=COUNT           오늘의 도전 생성 일수 (기본값: 365)
  --include-daily=true|false   오늘의 도전 문서 포함 여부 (기본값: true)

export 전용 옵션:
  --output=PATH                JSON 출력 경로

upload 전용 옵션:
  --project-id=VALUE           Firebase 프로젝트 ID
  --access-token=VALUE         OAuth access token
  --database-id=VALUE          Firestore database ID (기본값: (default))
  --batch-size=COUNT           commit 배치 크기 (기본값: 200)

예시:
  dart run tool/firestore_seed.dart export --daily-start-date=2026-04-12 --daily-days=30
  FIREBASE_PROJECT_ID=my-project FIREBASE_ACCESS_TOKEN=\$(gcloud auth application-default print-access-token) \\
    dart run tool/firestore_seed.dart upload --daily-start-date=2026-04-12 --daily-days=365
''';
