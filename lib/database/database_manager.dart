import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/firestore_puzzle_service.dart';
import 'package:mysudoku/services/remote_puzzle_service.dart';
import 'package:mysudoku/utils/sudoku_generator.dart';
import 'package:mysudoku/utils/board_codec.dart';

class PuzzleCatalogStatus {
  const PuzzleCatalogStatus({
    required this.isRunning,
    required this.generatedCounts,
    required this.targetPerLevel,
  });

  final bool isRunning;
  final Map<String, int> generatedCounts;
  final int targetPerLevel;

  int get totalGenerated =>
      generatedCounts.values.fold(0, (sum, count) => sum + count);

  int get totalTarget => SudokuLevel.levels.length * targetPerLevel;

  int get remaining => totalTarget - totalGenerated;

  bool get isComplete => remaining <= 0;

  PuzzleCatalogStatus copyWith({
    bool? isRunning,
    Map<String, int>? generatedCounts,
    int? targetPerLevel,
  }) {
    return PuzzleCatalogStatus(
      isRunning: isRunning ?? this.isRunning,
      generatedCounts: generatedCounts ?? this.generatedCounts,
      targetPerLevel: targetPerLevel ?? this.targetPerLevel,
    );
  }
}

/// 데이터베이스 초기화와 기본 관리를 담당하는 클래스
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  static Database? _database;
  static const String _catalogSourceMetadataKey = 'catalog_source';
  static const String _catalogSourceLocal = 'local';
  static const String _catalogSourceRemote = 'remote';
  static const int _targetGamesPerLevel = 100;
  static const int _initialSeedGamesPerLevel = 12;
  bool _isTopUpRunning = false;
  bool _shouldShowInitialCatalogIntro = false;
  final FirestorePuzzleService _firestorePuzzleService = FirestorePuzzleService();
  final RemotePuzzleService _remotePuzzleService = RemotePuzzleService();
  final ValueNotifier<PuzzleCatalogStatus> catalogStatus =
      ValueNotifier<PuzzleCatalogStatus>(
    PuzzleCatalogStatus(
      isRunning: false,
      generatedCounts: {
        for (final level in SudokuLevel.levels) level.name: 0,
      },
      targetPerLevel: _targetGamesPerLevel,
    ),
  );

  factory DatabaseManager() => _instance;

  DatabaseManager._internal();

  bool get shouldShowInitialCatalogIntro => _shouldShowInitialCatalogIntro;

  void markInitialCatalogIntroSeen() {
    _shouldShowInitialCatalogIntro = false;
  }

  /// 데이터베이스 인스턴스를 반환합니다.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 데이터베이스를 초기화합니다.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sudoku_games.db');
    _shouldShowInitialCatalogIntro = false;

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        final catalogSource = await _ensureCatalogSource(db);
        if (catalogSource == _catalogSourceLocal) {
          await _ensureInitialSeed(db);
        }
        await _refreshCatalogStatus(db, isRunning: false);
        if (catalogSource == _catalogSourceRemote) {
          unawaited(_syncRemoteCatalogInBackground(db));
        } else {
          unawaited(_topUpGamesInBackground(db));
        }
      },
    );
  }

  /// 데이터베이스 테이블을 생성하고 초기 데이터를 삽입합니다.
  Future<void> _onCreate(Database db, int version) async {
    _shouldShowInitialCatalogIntro = true;

    // 게임 테이블 생성
    await db.execute('''
      CREATE TABLE IF NOT EXISTS games(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level_name TEXT NOT NULL,
        game_number INTEGER NOT NULL,
        board TEXT NOT NULL,
        solution TEXT NOT NULL,
        UNIQUE(level_name, game_number)
      )
    ''');

    // 클리어 기록 테이블 생성
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clear_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level_name TEXT NOT NULL,
        game_number INTEGER NOT NULL,
        clear_time INTEGER NOT NULL,
        wrong_count INTEGER NOT NULL,
        clear_date TEXT NOT NULL,
        UNIQUE(level_name, game_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_challenge_completions(
        completion_date TEXT PRIMARY KEY NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata(
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    await _seedInitialCatalog(db);
  }

  /// 데이터베이스 업그레이드 처리
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 클리어 기록 테이블 추가
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clear_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          level_name TEXT NOT NULL,
          game_number INTEGER NOT NULL,
          clear_time INTEGER NOT NULL,
          wrong_count INTEGER NOT NULL,
          clear_date TEXT NOT NULL,
          UNIQUE(level_name, game_number)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_challenge_completions(
          completion_date TEXT PRIMARY KEY NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_metadata(
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  /// 초기 게임 데이터를 생성하여 데이터베이스에 삽입합니다.
  Future<void> _ensureInitialSeed(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM games'),
        ) ??
        0;
    if (count > 0) {
      return;
    }

    _shouldShowInitialCatalogIntro = true;
    await _insertInitialGames(
      db,
      gamesPerLevel: _initialSeedGamesPerLevel,
      logAsSeed: true,
    );
  }

  Future<void> _seedInitialCatalog(Database db) async {
    final remoteSeeded = await _trySeedRemoteCatalog(
      db,
      targetPerLevel: _targetGamesPerLevel,
    );
    if (remoteSeeded) {
      _shouldShowInitialCatalogIntro = false;
      await _setCatalogSource(db, _catalogSourceRemote);
      return;
    }

    _shouldShowInitialCatalogIntro = true;
    await _setCatalogSource(db, _catalogSourceLocal);
    await _insertInitialGames(
      db,
      gamesPerLevel: _initialSeedGamesPerLevel,
      logAsSeed: true,
    );
  }

  Future<void> _topUpGamesInBackground(Database db) async {
    if (_isTopUpRunning) {
      return;
    }

    _isTopUpRunning = true;
    await _refreshCatalogStatus(db, isRunning: true);
    try {
      for (final level in SudokuLevel.levels) {
        final existingGameNumbers = await _loadExistingGameNumbers(
          db,
          level.name,
        );
        final currentCount = existingGameNumbers.length;
        final missingGameNumbers = _missingGameNumbersForTarget(
          existingGameNumbers,
        );

        if (missingGameNumbers.isEmpty) {
          continue;
        }

        await _insertSpecificGamesForLevel(
          db,
          level: level,
          gameNumbers: missingGameNumbers,
          initialCount: currentCount,
          logProgress: false,
          onProgress: (generatedCount) {
            _updateLevelCount(level.name, generatedCount, isRunning: true);
          },
        );
      }

      if (kDebugMode) {
        AppLogger.debug('백그라운드 퍼즐 보충 완료');
      }
    } finally {
      _isTopUpRunning = false;
      await _refreshCatalogStatus(db, isRunning: false);
    }
  }

  Future<void> _syncRemoteCatalogInBackground(Database db) async {
    if (_isTopUpRunning ||
        (!_remotePuzzleService.isConfigured &&
            !_firestorePuzzleService.isConfigured)) {
      return;
    }

    _isTopUpRunning = true;
    await _refreshCatalogStatus(db, isRunning: true);
    try {
      final synced = await _trySeedRemoteCatalog(
        db,
        targetPerLevel: _targetGamesPerLevel,
      );
      if (kDebugMode) {
        AppLogger.debug(
          synced ? '원격 퍼즐 카탈로그 동기화 완료' : '원격 퍼즐 카탈로그 동기화 건너뜀',
        );
      }
    } finally {
      _isTopUpRunning = false;
      await _refreshCatalogStatus(db, isRunning: false);
    }
  }

  Future<void> _insertInitialGames(
    Database db, {
    required int gamesPerLevel,
    required bool logAsSeed,
  }) async {
    if (kDebugMode) {
      AppLogger.debug(logAsSeed ? '초기 시드 퍼즐 생성 시작' : '초기 게임 데이터 생성 시작');
    }
    int totalGames = 0;

    for (var level in SudokuLevel.levels) {
      if (kDebugMode) {
        AppLogger.debug('${level.name} 레벨 게임 생성 중... ($gamesPerLevel개)');
      }
      totalGames += gamesPerLevel;
      await _insertGamesForLevel(
        db,
        level: level,
        startGameNumber: 1,
        count: gamesPerLevel,
        logProgress: true,
        onProgress: (generatedCount) {
          _updateLevelCount(level.name, generatedCount, isRunning: false);
        },
      );
      if (kDebugMode) {
        AppLogger.debug('${level.name} 레벨 완료: $gamesPerLevel개');
      }
    }

    if (kDebugMode) {
      AppLogger.debug(
        logAsSeed
            ? '초기 시드 퍼즐 생성 완료: 총 $totalGames개'
            : '초기 게임 데이터 생성 완료: 총 $totalGames개',
      );
    }
  }

  Future<void> _insertGamesForLevel(
    Database db, {
    required SudokuLevel level,
    required int startGameNumber,
    required int count,
    required bool logProgress,
    void Function(int generatedCount)? onProgress,
  }) async {
    for (var offset = 0; offset < count; offset++) {
      final board = SudokuGenerator.generateSudoku(level.emptyCells);
      final solution = SudokuGenerator.getSolution(board);

      final boardStr = BoardCodec.encode(board);
      final solutionStr = BoardCodec.encode(solution);

      await db.insert(
        'games',
        {
          'level_name': level.name,
          'game_number': startGameNumber + offset,
          'board': boardStr,
          'solution': solutionStr,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      onProgress?.call(startGameNumber + offset);

      if (kDebugMode && logProgress && (offset + 1) == count) {
        AppLogger.debug(
          '${level.name} 레벨: ${startGameNumber + offset}/${startGameNumber + count - 1} 완료',
        );
      }
    }
  }

  Future<void> _insertSpecificGamesForLevel(
    Database db, {
    required SudokuLevel level,
    required List<int> gameNumbers,
    required int initialCount,
    required bool logProgress,
    void Function(int generatedCount)? onProgress,
  }) async {
    for (var index = 0; index < gameNumbers.length; index++) {
      final board = SudokuGenerator.generateSudoku(level.emptyCells);
      final solution = SudokuGenerator.getSolution(board);

      final boardStr = BoardCodec.encode(board);
      final solutionStr = BoardCodec.encode(solution);

      await db.insert(
        'games',
        {
          'level_name': level.name,
          'game_number': gameNumbers[index],
          'board': boardStr,
          'solution': solutionStr,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      onProgress?.call(initialCount + index + 1);

      if (kDebugMode && logProgress && (index + 1) == gameNumbers.length) {
        AppLogger.debug(
          '${level.name} 레벨: ${initialCount + index + 1}개 보충 완료',
        );
      }
    }
  }

  Future<List<int>> _loadExistingGameNumbers(Database db, String levelName) async {
    final maps = await db.query(
      'games',
      columns: ['game_number'],
      where: 'level_name = ?',
      whereArgs: [levelName],
      orderBy: 'game_number ASC',
    );
    return maps
        .map((map) => map['game_number'] as int)
        .where((gameNumber) => gameNumber > 0)
        .toList();
  }

  List<int> _missingGameNumbersForTarget(List<int> existingGameNumbers) {
    final existingSet = existingGameNumbers.toSet();
    final missing = <int>[];
    for (var gameNumber = 1; gameNumber <= _targetGamesPerLevel; gameNumber++) {
      if (!existingSet.contains(gameNumber)) {
        missing.add(gameNumber);
      }
    }
    return missing;
  }

  Future<String> _ensureCatalogSource(Database db) async {
    final stored = await _getCatalogSource(db);
    if (stored != null) {
      return stored;
    }

    final currentCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM games'),
        ) ??
        0;
    if (currentCount > 0) {
      await _setCatalogSource(db, _catalogSourceLocal);
      return _catalogSourceLocal;
    }

    final remoteSeeded = await _trySeedRemoteCatalog(
      db,
      targetPerLevel: _targetGamesPerLevel,
    );
    final source =
        remoteSeeded ? _catalogSourceRemote : _catalogSourceLocal;
    await _setCatalogSource(db, source);
    return source;
  }

  Future<String?> _getCatalogSource(Database db) async {
    final rows = await db.query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_catalogSourceMetadataKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> _setCatalogSource(Database db, String source) async {
    await db.insert(
      'app_metadata',
      {
        'key': _catalogSourceMetadataKey,
        'value': source,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> _trySeedRemoteCatalog(
    Database db, {
    required int targetPerLevel,
  }) async {
    final entriesByLevel = <String, List<RemotePuzzleEntry>>{};
    for (final level in SudokuLevel.levels) {
      final entries = await _loadSharedCatalogEntries(
        levelName: level.name,
        limit: targetPerLevel,
      );
      if (entries.isEmpty) {
        return false;
      }
      entriesByLevel[level.name] = entries;
    }

    final batch = db.batch();
    for (final level in SudokuLevel.levels) {
      final entries = entriesByLevel[level.name]!;
      for (final entry in entries) {
        batch.insert(
          'games',
          {
            'level_name': entry.levelName,
            'game_number': entry.gameNumber,
            'board': BoardCodec.encode(entry.board),
            'solution': BoardCodec.encode(entry.solution),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      _updateLevelCount(level.name, entries.length, isRunning: true);
    }
    await batch.commit(noResult: true);
    return true;
  }

  Future<List<RemotePuzzleEntry>> _loadSharedCatalogEntries({
    required String levelName,
    required int limit,
  }) async {
    final firestoreEntries = await _firestorePuzzleService.fetchCatalogForLevel(
      levelName: levelName,
      limit: limit,
    );
    if (firestoreEntries.isNotEmpty) {
      return firestoreEntries;
    }

    if (!_remotePuzzleService.isConfigured) {
      return const [];
    }
    return _remotePuzzleService.fetchCatalogForLevel(
      levelName: levelName,
      limit: limit,
    );
  }

  Future<bool> isRemoteCatalogActive() async {
    final db = await database;
    return (await _ensureCatalogSource(db)) == _catalogSourceRemote;
  }

  Future<void> _refreshCatalogStatus(
    Database db, {
    required bool isRunning,
  }) async {
    final counts = <String, int>{};
    for (final level in SudokuLevel.levels) {
      counts[level.name] = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM games WHERE level_name = ?',
              [level.name],
            ),
          ) ??
          0;
    }

    catalogStatus.value = PuzzleCatalogStatus(
      isRunning: isRunning,
      generatedCounts: counts,
      targetPerLevel: _targetGamesPerLevel,
    );
  }

  void _updateLevelCount(
    String levelName,
    int generatedCount, {
    required bool isRunning,
  }) {
    final nextCounts = Map<String, int>.from(catalogStatus.value.generatedCounts);
    nextCounts[levelName] = generatedCount;
    catalogStatus.value = catalogStatus.value.copyWith(
      isRunning: isRunning,
      generatedCounts: nextCounts,
    );
  }

  /// 데이터베이스 연결을 닫습니다.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
