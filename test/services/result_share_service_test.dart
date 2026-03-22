import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/services/result_share_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('ResultShareService', () {
    final service = ResultShareService();

    test('builds clear result text with best badge', () {
      final text = service.buildClearResultText(
        levelName: '중급',
        gameNumber: 12,
        clearTimeSeconds: 185,
        wrongCount: 1,
        isNewBestRecord: true,
      );

      expect(text, contains('NEW BEST'));
      expect(text, contains('중급 · 게임 12'));
      expect(text, contains('03:05 · 오답 1회'));
    });

    test('formats clear summary for dialog card', () {
      final summary = service.formatClearSummary(
        clearTimeSeconds: 125,
        wrongCount: 2,
      );

      expect(summary, '02:05 · 오답 2회');
    });
  });
}
