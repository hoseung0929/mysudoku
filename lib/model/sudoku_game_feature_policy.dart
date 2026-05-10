import 'package:sudoku159/model/sudoku_level.dart';

enum SudokuGameFeature {
  memo,
  undo,
  hint,
}

enum SudokuGameFeatureTier {
  beginner,
  intermediate,
  advanced,
}

class SudokuGameFeaturePolicy {
  const SudokuGameFeaturePolicy({
    required this.tier,
    required this.memoEnabled,
    required this.undoEnabled,
    required this.hintEnabled,
  });

  final SudokuGameFeatureTier tier;
  final bool memoEnabled;
  final bool undoEnabled;
  final bool hintEnabled;

  static const beginner = SudokuGameFeaturePolicy(
    tier: SudokuGameFeatureTier.beginner,
    memoEnabled: true,
    undoEnabled: true,
    hintEnabled: true,
  );

  static const intermediate = SudokuGameFeaturePolicy(
    tier: SudokuGameFeatureTier.intermediate,
    memoEnabled: true,
    undoEnabled: true,
    hintEnabled: false,
  );

  static const advanced = SudokuGameFeaturePolicy(
    tier: SudokuGameFeatureTier.advanced,
    memoEnabled: true,
    undoEnabled: false,
    hintEnabled: false,
  );

  static SudokuGameFeaturePolicy forLevel(SudokuLevel level) {
    switch (tierForLevel(level)) {
      case SudokuGameFeatureTier.beginner:
        return beginner;
      case SudokuGameFeatureTier.intermediate:
        return intermediate;
      case SudokuGameFeatureTier.advanced:
        return advanced;
    }
  }

  static SudokuGameFeatureTier tierForLevel(SudokuLevel level) {
    if (level.difficulty <= 1) {
      return SudokuGameFeatureTier.beginner;
    }
    if (level.difficulty == 2) {
      return SudokuGameFeatureTier.intermediate;
    }
    return SudokuGameFeatureTier.advanced;
  }

  bool isEnabled(SudokuGameFeature feature) {
    switch (feature) {
      case SudokuGameFeature.memo:
        return memoEnabled;
      case SudokuGameFeature.undo:
        return undoEnabled;
      case SudokuGameFeature.hint:
        return hintEnabled;
    }
  }
}
