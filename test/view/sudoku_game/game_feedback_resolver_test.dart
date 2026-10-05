import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/view/sudoku_game/game_effects_controller.dart';
import 'package:sudoku159/view/sudoku_game/game_feedback_resolver.dart';

void main() {
  const rowDelta = BoardCompletionDelta(
    completedRows: 1,
    completedCols: 0,
    completedBoxes: 0,
  );

  ResolvedFeedback resolve(void Function(InputFeedbackEvents e) fill) {
    final e = InputFeedbackEvents();
    fill(e);
    return GameFeedbackResolver.resolve(e);
  }

  test('plain correct input: one medium impact and no message', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..correct = true);
    expect(r.haptic, FeedbackHaptic.mediumImpact);
    expect(r.message, FeedbackMessage.none);
  });

  test('correct input from a number lock is a light impact, not a click', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..fromLock = true
      ..correct = true);
    expect(r.haptic, FeedbackHaptic.lightImpact);
  });

  test('a hint fill is not a plain-input haptic', () {
    final r = resolve((e) => e.correct = true);
    expect(r.haptic, FeedbackHaptic.none);
  });

  test('notes input is a selection click', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..memo = true);
    expect(r.haptic, FeedbackHaptic.selectionClick);
  });

  test('a completed digit: its message, one heavy impact, board highlight', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..correct = true
      ..completedDigit = 7);
    expect(r.message, FeedbackMessage.digit);
    expect(r.haptic, FeedbackHaptic.heavyImpact);
    expect(r.digitBoardHighlight, isTrue);
    expect(r.digitPop, isTrue);
  });

  test('a row and a digit together: row message, one haptic, no 9-cell glow',
      () {
    final r = resolve((e) => e
      ..fromInput = true
      ..correct = true
      ..lineDelta = rowDelta
      ..completedDigit = 7);
    expect(r.message, FeedbackMessage.line);
    expect(r.haptic, FeedbackHaptic.heavyImpact);
    expect(r.digitBoardHighlight, isFalse);
    expect(r.digitPop, isTrue); // 숫자 버튼 팝은 허용
  });

  test('a row and a progress milestone together: the row wins', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..correct = true
      ..lineDelta = rowDelta
      ..progressMilestone = 50);
    expect(r.message, FeedbackMessage.line);
    expect(r.haptic, FeedbackHaptic.heavyImpact);
    expect(r.progressPenguin, isFalse);
  });

  test('a digit and a progress milestone together: the digit wins', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..correct = true
      ..completedDigit = 4
      ..progressMilestone = 25);
    expect(r.message, FeedbackMessage.digit);
    expect(r.progressPenguin, isFalse);
  });

  test('a progress milestone alone: message, light impact, penguin', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..correct = true
      ..progressMilestone = 75);
    expect(r.message, FeedbackMessage.progress);
    expect(r.haptic, FeedbackHaptic.lightImpact);
    expect(r.progressPenguin, isTrue);
  });

  test('a wrong answer: its message and one heavy impact only', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..wrong = true
      ..wrongCount = (1, 3));
    expect(r.message, FeedbackMessage.wrong);
    expect(r.haptic, FeedbackHaptic.heavyImpact);
  });

  test('game over beats a wrong answer and has its own short pattern', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..wrong = true
      ..gameOver = true);
    expect(r.haptic, FeedbackHaptic.gameOver);
    expect(r.message, FeedbackMessage.none);
  });

  test('puzzle complete suppresses every lower feedback', () {
    final r = resolve((e) => e
      ..fromInput = true
      ..correct = true
      ..lineDelta = rowDelta
      ..completedDigit = 9
      ..progressMilestone = 75
      ..puzzleComplete = true);
    expect(r.message, FeedbackMessage.none);
    expect(r.haptic, FeedbackHaptic.none);
    expect(r.digitBoardHighlight, isFalse);
    expect(r.digitPop, isFalse);
    expect(r.progressPenguin, isFalse);
    expect(r.hideMessage, isTrue);
  });
}
