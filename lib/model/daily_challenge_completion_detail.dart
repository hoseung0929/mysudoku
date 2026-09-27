/// 오늘의 도전 월간 달력에 쓰는 하루치 완료 세부 정보.
/// 마이그레이션 이전의 오래된 행은 [levelName] 등이 없어 "일반 완료"로만
/// 표시된다(완벽 완료 여부는 판단하지 않음).
class DailyChallengeCompletionDetail {
  const DailyChallengeCompletionDetail({
    required this.date,
    this.levelName,
    this.gameNumber,
    this.clearTime,
    this.wrongCount,
    this.hintsUsed,
    this.autoNotesUsed = false,
    this.streakEligible = true,
  });

  final String date;
  final String? levelName;
  final int? gameNumber;
  final int? clearTime;
  final int? wrongCount;
  final int? hintsUsed;
  final bool autoNotesUsed;

  /// 이 날짜가 연속 일수 계산에 들어가도 되는지. 오늘의 도전을 정상적으로
  /// 시작해 완료했으면 true, 과거 달력에서 다시 시작해 완료했으면 false다.
  final bool streakEligible;

  /// 실수 0회로 클리어했는지. 세부 기록이 없는(마이그레이션 이전) 행은
  /// 판단할 수 없으므로 false다.
  bool get isPerfect => wrongCount == 0;

  factory DailyChallengeCompletionDetail.fromRow(Map<String, dynamic> row) {
    int? asInt(Object? value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return DailyChallengeCompletionDetail(
      date: row['completion_date'] as String,
      levelName: row['level_name'] as String?,
      gameNumber: asInt(row['game_number']),
      clearTime: asInt(row['clear_time']),
      wrongCount: asInt(row['wrong_count']),
      hintsUsed: asInt(row['hints_used']),
      autoNotesUsed: (asInt(row['auto_notes_used']) ?? 0) != 0,
      streakEligible: (asInt(row['streak_eligible']) ?? 1) != 0,
    );
  }

  /// [other]가 이 기록보다 더 좋은 결과인지: 오답이 더 적음 → 힌트가 더 적음
  /// → 시간이 더 짧음 순으로 비교한다. 세부 기록이 아예 없던 기존 행은
  /// 어떤 새 결과와 비교해도 "개선"으로 본다(비교할 근거가 없으므로).
  bool isImprovedBy(DailyChallengeCompletionDetail other) {
    if (wrongCount == null) return true;
    final otherWrong = other.wrongCount ?? 0;
    if (otherWrong != wrongCount) return otherWrong < wrongCount!;
    final thisHints = hintsUsed ?? 0;
    final otherHints = other.hintsUsed ?? 0;
    if (otherHints != thisHints) return otherHints < thisHints;
    final thisTime = clearTime ?? 0;
    final otherTime = other.clearTime ?? 0;
    return otherTime < thisTime;
  }
}
