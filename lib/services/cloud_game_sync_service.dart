import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mysudoku/services/firebase_bootstrap_service.dart';

class CloudGameSavePayload {
  const CloudGameSavePayload({
    required this.levelName,
    required this.gameNumber,
    required this.board,
    required this.notes,
    required this.elapsedSeconds,
    required this.hintsRemaining,
    required this.wrongCount,
    required this.isMemoMode,
    required this.hintCells,
    required this.isGameComplete,
    required this.isGameOver,
    required this.updatedAtMillis,
  });

  final String levelName;
  final int gameNumber;
  final List<List<int>> board;
  final List<List<Set<int>>> notes;
  final int elapsedSeconds;
  final int hintsRemaining;
  final int wrongCount;
  final bool isMemoMode;
  final Set<String> hintCells;
  final bool isGameComplete;
  final bool isGameOver;
  final int updatedAtMillis;
}

abstract class CloudGameSyncService {
  Future<void> upsertSave(CloudGameSavePayload payload);

  Future<void> deleteSave({
    required String levelName,
    required int gameNumber,
  });

  Future<List<CloudGameSavePayload>> fetchSaves();
}

class FirestoreCloudGameSyncService implements CloudGameSyncService {
  FirestoreCloudGameSyncService({
    FirebaseBootstrapService? bootstrapService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _bootstrapService = bootstrapService ?? FirebaseBootstrapService.instance,
        _firestore = firestore,
        _auth = auth;

  final FirebaseBootstrapService _bootstrapService;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseFirestore get _resolvedFirestore =>
      _firestore ??= FirebaseFirestore.instance;

  FirebaseAuth get _resolvedAuth => _auth ??= FirebaseAuth.instance;

  User? get _currentUser =>
      _bootstrapService.isReady ? _resolvedAuth.currentUser : null;

  DocumentReference<Map<String, dynamic>> _saveDoc(
    String levelName,
    int gameNumber,
  ) {
    return _resolvedFirestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('save_games')
        .doc('${levelName}_$gameNumber');
  }

  @override
  Future<void> upsertSave(CloudGameSavePayload payload) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    await _saveDoc(payload.levelName, payload.gameNumber).set({
      'levelName': payload.levelName,
      'gameNumber': payload.gameNumber,
      'board': payload.board,
      'notes': payload.notes
          .map(
            (row) => row
                .map((cellNotes) => cellNotes.toList()..sort())
                .toList(),
          )
          .toList(),
      'elapsedSeconds': payload.elapsedSeconds,
      'hintsRemaining': payload.hintsRemaining,
      'wrongCount': payload.wrongCount,
      'isMemoMode': payload.isMemoMode,
      'hintCells': payload.hintCells.toList()..sort(),
      'isGameComplete': payload.isGameComplete,
      'isGameOver': payload.isGameOver,
      'updatedAtMillis': payload.updatedAtMillis,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteSave({
    required String levelName,
    required int gameNumber,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    await _saveDoc(levelName, gameNumber).delete();
  }

  @override
  Future<List<CloudGameSavePayload>> fetchSaves() async {
    final user = _currentUser;
    if (user == null) {
      return const [];
    }

    final snapshot = await _resolvedFirestore
        .collection('users')
        .doc(user.uid)
        .collection('save_games')
        .get();

    final saves = <CloudGameSavePayload>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final levelName = data['levelName'];
      final gameNumber = data['gameNumber'];
      final board = _readBoard(data['board']);
      final notes = _readNotes(data['notes']);
      final hintCells = _readHintCells(data['hintCells']);
      if (levelName is! String ||
          gameNumber is! int ||
          board == null ||
          notes == null ||
          hintCells == null) {
        continue;
      }

      saves.add(
        CloudGameSavePayload(
          levelName: levelName,
          gameNumber: gameNumber,
          board: board,
          notes: notes,
          elapsedSeconds: (data['elapsedSeconds'] as num?)?.toInt() ?? 0,
          hintsRemaining: (data['hintsRemaining'] as num?)?.toInt() ?? 3,
          wrongCount: (data['wrongCount'] as num?)?.toInt() ?? 0,
          isMemoMode: data['isMemoMode'] as bool? ?? false,
          hintCells: hintCells,
          isGameComplete: data['isGameComplete'] as bool? ?? false,
          isGameOver: data['isGameOver'] as bool? ?? false,
          updatedAtMillis: (data['updatedAtMillis'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return saves;
  }

  List<List<int>>? _readBoard(dynamic value) {
    if (value is! List<dynamic>) {
      return null;
    }
    try {
      return value
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

  List<List<Set<int>>>? _readNotes(dynamic value) {
    if (value is! List<dynamic>) {
      return null;
    }
    try {
      return List.generate(9, (row) {
        final rowData = row < value.length ? value[row] as List<dynamic>? : null;
        return List.generate(9, (col) {
          final cellData = rowData != null && col < rowData.length
              ? rowData[col] as List<dynamic>? ?? const []
              : const <dynamic>[];
          return cellData.map((item) => (item as num).toInt()).toSet();
        });
      });
    } catch (_) {
      return null;
    }
  }

  Set<String>? _readHintCells(dynamic value) {
    if (value is! List<dynamic>) {
      return null;
    }
    try {
      return value.map((item) => item as String).toSet();
    } catch (_) {
      return null;
    }
  }
}
