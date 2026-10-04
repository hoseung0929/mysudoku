import 'package:sudoku159/view/sudoku_game/game_effects_controller.dart';

/// 한 번의 입력에서 발생한 피드백 이벤트 모음. 콜백이 같은 동기 호출 안에서
/// 순서대로 채우고, 입력이 끝난 뒤 [GameFeedbackResolver]가 한 번에 정리한다.
class InputFeedbackEvents {
  /// 사용자가 숫자패드·셀 탭·펜슬로 직접 입력했다(힌트·복원은 false).
  bool fromInput = false;

  /// 숫자 고정 상태에서 칸을 눌러 입력했다.
  bool fromLock = false;

  /// 메모 후보 입력이다(칸에 숫자가 들어가지 않는다).
  bool memo = false;

  bool correct = false;
  bool wrong = false;
  bool puzzleComplete = false;
  bool gameOver = false;

  /// 이번 입력으로 새로 완성된 행·열·박스.
  BoardCompletionDelta? lineDelta;

  /// 이번 입력으로 9개가 모두 채워진 숫자.
  int? completedDigit;

  /// 이번 입력으로 새로 지나간 진행률(25·50·75).
  int? progressMilestone;

  /// 오답 안내용 (현재 횟수, 최대 횟수). 게임 오버면 null.
  (int, int)? wrongCount;

  bool get hasNewLine => lineDelta?.hasNewCompletion ?? false;
}

enum FeedbackMessage { none, line, wrong, digit, progress }

enum FeedbackHaptic {
  none,
  selectionClick,
  lightImpact,
  mediumImpact,
  heavyImpact,

  /// 게임 오버: 짧은 2회 패턴.
  gameOver,
}

class ResolvedFeedback {
  const ResolvedFeedback({
    this.message = FeedbackMessage.none,
    this.haptic = FeedbackHaptic.none,
    this.digitBoardHighlight = false,
    this.digitPop = false,
    this.progressPenguin = false,
    this.hideMessage = false,
  });

  /// 상단 안내로 보여 줄 하나의 문구 종류.
  final FeedbackMessage message;

  /// 이 입력에서 실행할 진동(하나뿐이다).
  final FeedbackHaptic haptic;

  /// 숫자 9칸 전체 강조.
  final bool digitBoardHighlight;

  /// 숫자 버튼의 짧은 팝.
  final bool digitPop;

  /// 진행률 달성에 대한 짧은 펭귄 반응.
  final bool progressPenguin;

  /// 떠 있는 안내를 치워야 한다(퍼즐 완료).
  final bool hideMessage;
}

/// 피드백 우선순위: 퍼즐 완료 > 게임 오버·오답 > 행·열·박스 완성 > 숫자 1종 완료
/// > 진행률 > 일반 정답. 상위 이벤트가 있는 입력에서는 하위 이벤트의 안내
/// 문구와 진동을 생략한다.
abstract final class GameFeedbackResolver {
  static ResolvedFeedback resolve(InputFeedbackEvents e) {
    if (e.puzzleComplete) {
      // 완료 진동(heavy)은 결과 화면 직전 연출에서 따로 한 번 실행한다.
      return const ResolvedFeedback(hideMessage: true);
    }
    if (e.gameOver) {
      return const ResolvedFeedback(haptic: FeedbackHaptic.gameOver);
    }
    if (e.wrong) {
      return ResolvedFeedback(
        message:
            e.wrongCount == null ? FeedbackMessage.none : FeedbackMessage.wrong,
        haptic: FeedbackHaptic.mediumImpact,
      );
    }
    if (e.hasNewLine) {
      return ResolvedFeedback(
        message: FeedbackMessage.line,
        haptic: FeedbackHaptic.mediumImpact,
        // 숫자 버튼의 팝·체크는 허용하되 9칸 전체 강조는 생략한다.
        digitPop: e.completedDigit != null,
      );
    }
    if (e.completedDigit != null) {
      return const ResolvedFeedback(
        message: FeedbackMessage.digit,
        haptic: FeedbackHaptic.mediumImpact,
        digitBoardHighlight: true,
        digitPop: true,
      );
    }
    if (e.progressMilestone != null) {
      return const ResolvedFeedback(
        message: FeedbackMessage.progress,
        haptic: FeedbackHaptic.selectionClick,
        progressPenguin: true,
      );
    }
    if (e.correct && e.fromInput) {
      return ResolvedFeedback(
        haptic: e.fromLock
            ? FeedbackHaptic.selectionClick
            : FeedbackHaptic.lightImpact,
      );
    }
    if (e.memo && e.fromInput) {
      return const ResolvedFeedback(haptic: FeedbackHaptic.selectionClick);
    }
    return const ResolvedFeedback();
  }
}
