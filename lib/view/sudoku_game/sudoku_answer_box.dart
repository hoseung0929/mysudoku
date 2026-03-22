import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mysudoku/utils/app_logger.dart';

/// 선택된 셀의 정답 미리보기 박스
class SudokuAnswerBox extends StatelessWidget {
  const SudokuAnswerBox({
    super.key,
    required this.answer,
    required this.answerLabel,
  });

  /// null이면 '?' 표시
  final int? answer;
  final String answerLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    try {
      if (answer != null) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            border: Border.all(color: cs.outline, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                answerLabel,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                answer.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('정답 표시 중 오류 발생: $e');
      }
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border.all(color: cs.outlineVariant, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
