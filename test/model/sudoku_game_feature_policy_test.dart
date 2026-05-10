import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
import 'package:sudoku159/model/sudoku_level.dart';

void main() {
  group('SudokuGameFeaturePolicy', () {
    test('maps sudoku levels to feature tiers', () {
      expect(
        SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[0]).tier,
        SudokuGameFeatureTier.beginner,
      );
      expect(
        SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[1]).tier,
        SudokuGameFeatureTier.intermediate,
      );
      expect(
        SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[2]).tier,
        SudokuGameFeatureTier.advanced,
      );
      expect(
        SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[4]).tier,
        SudokuGameFeatureTier.advanced,
      );
    });

    test('enables gameplay assists by feature tier', () {
      expect(SudokuGameFeaturePolicy.beginner.memoEnabled, isTrue);
      expect(SudokuGameFeaturePolicy.beginner.undoEnabled, isTrue);
      expect(SudokuGameFeaturePolicy.beginner.hintEnabled, isTrue);

      expect(SudokuGameFeaturePolicy.intermediate.memoEnabled, isTrue);
      expect(SudokuGameFeaturePolicy.intermediate.undoEnabled, isTrue);
      expect(SudokuGameFeaturePolicy.intermediate.hintEnabled, isFalse);

      expect(SudokuGameFeaturePolicy.advanced.memoEnabled, isTrue);
      expect(SudokuGameFeaturePolicy.advanced.undoEnabled, isFalse);
      expect(SudokuGameFeaturePolicy.advanced.hintEnabled, isFalse);
    });

    test('checks individual feature flags', () {
      expect(
        SudokuGameFeaturePolicy.advanced.isEnabled(SudokuGameFeature.memo),
        isTrue,
      );
      expect(
        SudokuGameFeaturePolicy.advanced.isEnabled(SudokuGameFeature.undo),
        isFalse,
      );
      expect(
        SudokuGameFeaturePolicy.advanced.isEnabled(SudokuGameFeature.hint),
        isFalse,
      );
    });
  });
}
