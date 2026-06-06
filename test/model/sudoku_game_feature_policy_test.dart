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
      final beginner = SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[0]);
      final intermediate =
          SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[1]);
      final advanced = SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[2]);
      final expert = SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[3]);
      final master = SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[4]);

      expect(beginner.memoEnabled, isTrue);
      expect(beginner.hintEnabled, isTrue);
      expect(beginner.maxHints, 5);
      expect(beginner.maxWrongCount, 5);

      expect(intermediate.memoEnabled, isTrue);
      expect(intermediate.hintEnabled, isTrue);
      expect(intermediate.maxHints, 4);
      expect(intermediate.maxWrongCount, 4);

      expect(advanced.memoEnabled, isTrue);
      expect(advanced.hintEnabled, isTrue);
      expect(advanced.maxHints, 3);
      expect(advanced.maxWrongCount, 3);

      expect(expert.maxHints, 2);
      expect(expert.maxWrongCount, 3);

      expect(master.maxHints, 1);
      expect(master.maxWrongCount, 3);
    });

    test('checks individual feature flags', () {
      final advanced = SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels[2]);

      expect(
        advanced.isEnabled(SudokuGameFeature.memo),
        isTrue,
      );
      expect(
        advanced.isEnabled(SudokuGameFeature.hint),
        isTrue,
      );
    });
  });
}
