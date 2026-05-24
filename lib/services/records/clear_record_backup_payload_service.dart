import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/services/identity/install_id_service.dart';

class ClearRecordBackupPayloadService {
  ClearRecordBackupPayloadService({
    DatabaseHelper? databaseHelper,
    InstallIdService? installIdService,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _installIdService = installIdService ?? InstallIdService();

  final DatabaseHelper _databaseHelper;
  final InstallIdService _installIdService;

  Future<Map<String, dynamic>> buildPayload() async {
    final installId = await _installIdService.getOrCreate();
    final clearRecords = await _databaseHelper.getAllClearRecords();
    final clearEvents = await _databaseHelper.getRecentClearEvents(limit: 2000);
    final exportedAt = DateTime.now().toUtc().toIso8601String();

    return {
      'schema_version': 1,
      'install_id': installId,
      'exported_at': exportedAt,
      'clear_records': clearRecords.map(_normalizeClearRecord).toList(),
      'clear_events': clearEvents.map(_normalizeClearEvent).toList(),
    };
  }

  Map<String, dynamic> _normalizeClearRecord(Map<String, dynamic> row) {
    return {
      'level_name': row['level_name'],
      'game_number': row['game_number'],
      'clear_time': row['clear_time'],
      'wrong_count': row['wrong_count'],
      'clear_date': row['clear_date'],
    };
  }

  Map<String, dynamic> _normalizeClearEvent(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'level_name': row['level_name'],
      'game_number': row['game_number'],
      'clear_time': row['clear_time'],
      'wrong_count': row['wrong_count'],
      'clear_date': row['clear_date'],
    };
  }
}
