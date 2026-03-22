/// 기록/통계 화면의 난이도 필터.
///
/// DB의 [level_name]은 한글 키(초급, 중급, …)를 그대로 쓰고,
/// "모든 난이도"만 UI 언어와 무관한 상수로 구분합니다.
abstract final class RecordsLevelFilter {
  RecordsLevelFilter._();

  /// 모든 난이도(칩/드롭다운에서 선택 시 이 값을 상태로 둠).
  static const String allLevels = '__ALL_LEVELS__';

  static bool isAllLevels(String value) => value == allLevels;
}
