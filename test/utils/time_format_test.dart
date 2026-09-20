import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/utils/time_format.dart';

void main() {
  test('formats elapsed time as MM:SS below an hour and H:MM:SS from one hour',
      () {
    expect(formatElapsedSeconds(0), '00:00');
    expect(formatElapsedSeconds(59), '00:59');
    expect(formatElapsedSeconds(60), '01:00');
    expect(formatElapsedSeconds(59 * 60 + 59), '59:59');
    expect(formatElapsedSeconds(3600), '1:00:00');
    expect(formatElapsedSeconds(3600 + 5 * 60 + 7), '1:05:07');
    expect(formatElapsedSeconds(10 * 3600), '10:00:00');
  });
}
