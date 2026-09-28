/// 하단 탭을 다시 누르면 그 탭 화면이 스스로 최상단으로 스크롤하도록,
/// 화면의 State를 직접 노출하지 않고 콜백 하나만 주고받는 얇은 연결 고리.
///
/// 각 탭 화면은 `initState`에서 자신의 최상단 이동 함수를 [attach]하고
/// `dispose`에서 [detach]한다. [MyHomePage]는 탭별로 인스턴스 하나씩만
/// 만들어 두고, 같은 탭이 다시 선택됐을 때 [scrollToTop]을 부른다.
class TabScrollController {
  Future<void> Function()? _scrollToTop;

  void attach(Future<void> Function() callback) {
    _scrollToTop = callback;
  }

  void detach(Future<void> Function() callback) {
    if (_scrollToTop == callback) {
      _scrollToTop = null;
    }
  }

  Future<void> scrollToTop() async {
    await _scrollToTop?.call();
  }
}
