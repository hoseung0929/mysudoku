class ResultShareService {
  String buildClearResultText({
    required String levelName,
    required int gameNumber,
    required int clearTimeSeconds,
    required int wrongCount,
    required bool isNewBestRecord,
  }) {
    final badge = isNewBestRecord ? 'NEW BEST\n' : '';
    return [
      badge,
      'My Sudoku 완료',
      '$levelName · 게임 $gameNumber',
      '기록 ${_formatSeconds(clearTimeSeconds)} · 오답 $wrongCount회',
      '#MySudoku #SudokuChallenge',
    ].where((line) => line.isNotEmpty).join('\n');
  }

  String formatClearSummary({
    required int clearTimeSeconds,
    required int wrongCount,
  }) {
    return '${_formatSeconds(clearTimeSeconds)} · 오답 $wrongCount회';
  }

  String _formatSeconds(int value) {
    final minutes = value ~/ 60;
    final seconds = value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
