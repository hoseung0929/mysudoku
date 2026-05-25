import 'package:sudoku159/model/sudoku_level.dart';

enum SudokuGameFeature {
  memo,
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
    required this.hintEnabled,
    required this.maxHints,
    required this.maxWrongCount,
  });

  final SudokuGameFeatureTier tier;
  final bool memoEnabled;
  final bool hintEnabled;
  final int maxHints;
  final int maxWrongCount;

  // 초급 5/5, 중급 4/4, 고급 3/3, 전문가 2/3, 마스터 1/3
  static SudokuGameFeaturePolicy forLevel(SudokuLevel level) {
    final (maxHints, maxWrongCount) = switch (level.difficulty) {
      1 => (5, 5),
      2 => (4, 4),
      3 => (3, 3),
      4 => (2, 3),
      _ => (1, 3),
    };
    return SudokuGameFeaturePolicy(
      tier: tierForLevel(level),
      memoEnabled: true,
      hintEnabled: true,
      maxHints: maxHints,
      maxWrongCount: maxWrongCount,
    );
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
      case SudokuGameFeature.hint:
        return hintEnabled;
    }
  }
}
