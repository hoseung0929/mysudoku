import 'package:flutter/foundation.dart';

/// 게임 클리어 기록/챌린지 진행이 변경되었음을 앱 전역에 알려주는 간단한 버전 카운터.
///
/// 홈/챌린지/기록 화면은 탭 전환 시 [IndexedStack] 에 의해 `initState` 가
/// 다시 호출되지 않기 때문에, 다른 탭에서 게임을 완료해도 자동으로 데이터를
/// 갱신하지 못하는 문제가 있다. 이 문제를 해결하기 위해 클리어 저장 시점에
/// [notifyChanged] 를 호출하면 구독 중인 화면들이 각자 재로드할 수 있다.
class GameRecordNotifier {
  GameRecordNotifier._();

  static final GameRecordNotifier instance = GameRecordNotifier._();

  /// 기록이 변경될 때마다 값이 1씩 증가하는 카운터.
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  /// 클리어 기록/이벤트 저장 등 기록에 영향을 주는 작업 이후에 호출한다.
  void notifyChanged() {
    version.value = version.value + 1;
  }
}
