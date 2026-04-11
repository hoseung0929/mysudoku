import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mysudoku/model/today_challenge_target.dart';
import 'package:mysudoku/services/firebase_bootstrap_service.dart';
import 'package:mysudoku/services/remote_puzzle_service.dart';
import 'package:mysudoku/utils/board_codec.dart';

class FirestorePuzzleService {
  FirestorePuzzleService({
    FirebaseFirestore? firestore,
    FirebaseBootstrapService? bootstrapService,
    String? catalogVersion,
  })  : _firestore = firestore,
        _bootstrapService = bootstrapService ?? FirebaseBootstrapService.instance,
        _catalogVersion =
            catalogVersion ??
            const String.fromEnvironment(
              'SUDOKU_CATALOG_VERSION',
              defaultValue: 'v1',
            );

  FirebaseFirestore? _firestore;
  final FirebaseBootstrapService _bootstrapService;
  final String _catalogVersion;

  bool get isConfigured => _bootstrapService.isReady;

  FirebaseFirestore get _resolvedFirestore =>
      _firestore ??= FirebaseFirestore.instance;

  Future<List<RemotePuzzleEntry>> fetchCatalogForLevel({
    required String levelName,
    required int limit,
  }) async {
    if (!isConfigured) {
      return const [];
    }

    final snapshot = await _resolvedFirestore
        .collection('puzzle_catalog')
        .doc(_catalogVersion)
        .collection('levels')
        .doc(levelName)
        .collection('games')
        .orderBy('gameNumber')
        .limit(limit)
        .get();

    final entries = <RemotePuzzleEntry>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final gameNumber = _readInt(data['gameNumber'] ?? data['game_number']);
      final board = _readBoard(data['board']);
      final solution = _readBoard(data['solution']);
      if (gameNumber == null || board == null || solution == null) {
        continue;
      }
      entries.add(
        RemotePuzzleEntry(
          levelName: (data['levelName'] ?? data['level_name'] ?? levelName) as String,
          gameNumber: gameNumber,
          board: board,
          solution: solution,
        ),
      );
    }
    return entries;
  }

  Future<TodayChallengeTarget?> fetchDailyChallengeTarget({
    required DateTime date,
  }) async {
    if (!isConfigured) {
      return null;
    }

    final yyyyMmDd =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final snapshot = await _resolvedFirestore
        .collection('daily_challenges')
        .doc(yyyyMmDd)
        .get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    final levelName = data['levelName'] ?? data['level_name'];
    final gameNumber = _readInt(data['gameNumber'] ?? data['game_number']);
    if (levelName is! String || levelName.isEmpty || gameNumber == null) {
      return null;
    }

    return TodayChallengeTarget(
      levelName: levelName,
      gameNumber: gameNumber,
    );
  }

  int? _readInt(dynamic value) {
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
