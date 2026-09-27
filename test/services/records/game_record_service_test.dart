import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/services/records/game_record_service.dart';

void main() {
  const existing = {'clear_time': 300, 'wrong_count': 2};

  test('faster time is a better record', () {
    expect(
      GameRecordService.isBetterThan(existing, clearTime: 299, wrongCount: 5),
      isTrue,
    );
  });

  test('same time with fewer mistakes is a better record', () {
    expect(
      GameRecordService.isBetterThan(existing, clearTime: 300, wrongCount: 1),
      isTrue,
    );
  });

  test('slower or equal results are not better', () {
    expect(
      GameRecordService.isBetterThan(existing, clearTime: 301, wrongCount: 0),
      isFalse,
    );
    expect(
      GameRecordService.isBetterThan(existing, clearTime: 300, wrongCount: 2),
      isFalse,
    );
  });
}
