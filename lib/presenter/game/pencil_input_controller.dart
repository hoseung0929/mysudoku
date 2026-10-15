import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sudoku159/services/game/pencil_digit_recognizer.dart';

/// 필기 대상 셀의 상태.
enum PencilCellPhase {
  /// 기본(필기 대기).
  idle,

  /// 필기 중(획이 들어오는 동안).
  writing,

  /// 마지막 획 뒤 대기·인식 중.
  recognizing,

  /// 인식 성공: 앱 숫자로 바뀌기 전 미리 보기.
  recognized,

  /// 결과가 애매해 후보를 고르는 중.
  ambiguous,

  /// 인식 실패.
  error,
}

/// Pencil 필기 → 숫자 입력 흐름을 관리한다. 인식 단계와 스도쿠 정답 판정은
/// 분리되어 있어서, 실패·후보 대기는 오답으로 계산하지 않고 확정된 숫자만
/// [onConfirmed]로 넘어가 기존 입력 로직(정답 검사·Memo·Undo)을 탄다.
class PencilInputController extends ChangeNotifier {
  PencilInputController({
    required this.recognizer,
    required this.onConfirmed,
    this.settleDelay = const Duration(milliseconds: 380),
    this.previewDelay = const Duration(milliseconds: 150),
    this.errorHold = const Duration(milliseconds: 1400),
  });

  final PencilDigitRecognizer recognizer;

  /// 확정된 숫자를 전달한다(대상 셀은 호출 시점의 선택 셀).
  final void Function(int row, int col, int digit) onConfirmed;

  /// 마지막 획이 끝난 뒤 추가 획을 기다리는 시간(300~450ms).
  final Duration settleDelay;

  /// 인식 결과 미리 보기를 보여 주는 시간.
  final Duration previewDelay;

  /// 실패 표시를 유지하는 시간.
  final Duration errorHold;

  PencilCellPhase _phase = PencilCellPhase.idle;
  int? _row;
  int? _col;
  int? _previewDigit;
  List<int> _candidates = const [];
  Timer? _timer;
  String _pendingText = '';
  int _generation = 0;

  PencilCellPhase get phase => _phase;
  int? get row => _row;
  int? get col => _col;
  int? get previewDigit => _previewDigit;
  List<int> get candidates => _candidates;

  bool get isBusy =>
      _phase == PencilCellPhase.recognizing ||
      _phase == PencilCellPhase.recognized;

  /// 인식기가 낸 원문을 받는다. 연속으로 들어오면(여러 획) 타이머를 다시
  /// 시작하고 마지막 값을 기준으로 인식한다. 시작 셀을 대상으로 고정한다.
  void submitText(int row, int col, String text) {
    if (_phase == PencilCellPhase.ambiguous) {
      // 후보 선택을 기다리는 중에 새로 쓰면 이전 후보는 버린다.
      _candidates = const [];
    }
    if (_row != row || _col != col) {
      _cancelTimers();
    }
    _row = row;
    _col = col;
    _pendingText = text;
    _previewDigit = null;
    _setPhase(PencilCellPhase.recognizing);
    _timer?.cancel();
    final generation = ++_generation;
    _timer = Timer(settleDelay, () => _evaluate(generation));
  }

  /// 네이티브 오버레이: 필기가 시작되어 대상 셀이 고정됐다.
  void beginWriting(int row, int col) {
    _cancelTimers();
    _generation++;
    _row = row;
    _col = col;
    _previewDigit = null;
    _candidates = const [];
    _setPhase(PencilCellPhase.writing, force: true);
  }

  /// 네이티브 오버레이: 마지막 획이 끝나 인식 결과를 기다린다.
  void markRecognizing(int row, int col) {
    if (_row != row || _col != col) return;
    _setPhase(PencilCellPhase.recognizing);
  }

  /// 네이티브 오버레이가 이미 대기·인식을 마친 결과를 전달한다.
  void submitResult(int row, int col, DigitRecognitionResult result) {
    _cancelTimers();
    final generation = ++_generation;
    _row = row;
    _col = col;
    _pendingText = '';
    _applyResult(generation, row, col, result);
  }

  Future<void> _evaluate(int generation) async {
    final row = _row;
    final col = _col;
    if (row == null || col == null) return;
    final result = await recognizer.recognize(_pendingText);
    if (generation != _generation) return; // 그 사이 추가 입력·취소됨.
    _applyResult(generation, row, col, result);
  }

  void _applyResult(
    int generation,
    int row,
    int col,
    DigitRecognitionResult result,
  ) {
    if (result.isClear) {
      _previewDigit = result.digit;
      _setPhase(PencilCellPhase.recognized);
      _timer = Timer(previewDelay, () {
        if (generation != _generation) return;
        final digit = _previewDigit;
        _reset();
        if (digit != null) onConfirmed(row, col, digit);
      });
    } else if (result.isAmbiguous) {
      _candidates = List.unmodifiable(result.candidates);
      _setPhase(PencilCellPhase.ambiguous);
    } else {
      _setPhase(PencilCellPhase.error);
      _timer = Timer(errorHold, () {
        if (generation != _generation) return;
        _reset();
      });
    }
  }

  /// 후보 중 하나를 골랐다.
  void chooseCandidate(int digit) {
    if (_phase != PencilCellPhase.ambiguous) return;
    final row = _row;
    final col = _col;
    if (row == null || col == null || !_candidates.contains(digit)) return;
    _reset();
    onConfirmed(row, col, digit);
  }

  /// "다시 쓰기": 후보를 버리고 대기 상태로.
  void rewrite() => cancel();

  /// 다른 셀 선택·필기 OFF·화면 회전·백그라운드 전환 등으로 진행 중인 필기를
  /// 취소한다. 오답으로 계산되지 않는다.
  void cancel() {
    if (_phase == PencilCellPhase.idle && _row == null && _candidates.isEmpty) {
      return;
    }
    _reset();
  }

  void _reset() {
    _cancelTimers();
    _generation++;
    _pendingText = '';
    _previewDigit = null;
    _candidates = const [];
    _row = null;
    _col = null;
    _setPhase(PencilCellPhase.idle, force: true);
  }

  void _cancelTimers() {
    _timer?.cancel();
    _timer = null;
  }

  void _setPhase(PencilCellPhase phase, {bool force = false}) {
    if (!force && _phase == phase) {
      notifyListeners();
      return;
    }
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
