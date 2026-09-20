class TodayChallengeTarget {
  const TodayChallengeTarget({
    required this.levelName,
    required this.gameNumber,
    this.date,
  });

  final String levelName;
  final int gameNumber;

  /// 이 타깃이 정해진 로컬 달력 일자(YYYY-MM-DD). 표시·시작·완료 귀속이
  /// 같은 날짜의 같은 타깃을 가리키도록 전달하는 용도.
  final String? date;
}
