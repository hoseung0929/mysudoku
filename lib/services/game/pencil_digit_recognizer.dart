/// Pencil 필기 인식 결과.
///
/// - [digit]이 있으면 명확한 결과(1~9).
/// - [candidates]가 2개 이상이면 애매한 결과: 후보를 사용자가 고른다.
/// - 둘 다 비어 있으면 실패(0·문자·여러 자리 숫자 포함).
class DigitRecognitionResult {
  const DigitRecognitionResult.clear(int this.digit) : candidates = const [];
  const DigitRecognitionResult.ambiguous(this.candidates) : digit = null;
  const DigitRecognitionResult.failure()
      : digit = null,
        candidates = const [];

  final int? digit;
  final List<int> candidates;

  bool get isClear => digit != null;
  bool get isAmbiguous => digit == null && candidates.length >= 2;
  bool get isFailure => digit == null && candidates.length < 2;
}

/// 숫자 인식기 인터페이스. 인식은 기기 안에서만 처리하고 원본 획은 밖으로 보내거나
/// 저장하지 않는다. 구현은 교체 가능하다(Scribble 텍스트, Vision, Core ML 등).
abstract interface class PencilDigitRecognizer {
  /// [raw]는 인식기가 낸 원문(Scribble 텍스트 등).
  Future<DigitRecognitionResult> recognize(String raw);
}

/// iPadOS Scribble이 이미 텍스트로 바꿔 준 결과를 해석한다. 정확히 한 글자의
/// `1~9`만 성공으로 보고, 그 외(0·문자·여러 자리)는 실패로 처리한다.
class ScribbleTextDigitRecognizer implements PencilDigitRecognizer {
  const ScribbleTextDigitRecognizer();

  @override
  Future<DigitRecognitionResult> recognize(String raw) async {
    final text = raw.trim();
    if (text.length == 1) {
      final value = int.tryParse(text);
      if (value != null && value >= 1 && value <= 9) {
        return DigitRecognitionResult.clear(value);
      }
    }
    return const DigitRecognitionResult.failure();
  }
}

/// 테스트·미리 보기용 인식기: 미리 정한 결과를 그대로 돌려준다.
class FakePencilDigitRecognizer implements PencilDigitRecognizer {
  FakePencilDigitRecognizer(this.result);

  DigitRecognitionResult result;

  @override
  Future<DigitRecognitionResult> recognize(String raw) async => result;
}
