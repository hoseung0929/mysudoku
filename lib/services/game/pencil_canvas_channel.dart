import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sudoku159/services/game/pencil_digit_recognizer.dart';

/// 네이티브(iOS) Apple Pencil 필기 오버레이와 통신하는 채널.
///
/// 네이티브 오버레이는 보드 전체 위에 하나만 올라가고 Pencil 터치만 받는다
/// (손가락은 그대로 Flutter 보드로 전달). 짧은 Pencil 탭은 [onTap]으로 셀
/// 선택을, 일정 거리 이상의 획은 필기로 처리해 [onStrokeBegan] →
/// [onStrokeEnded] → [onResult] 순서로 알려 준다. 인식은 기기 안에서만
/// 처리되고 원본 획은 밖으로 보내거나 저장하지 않는다.
class PencilCanvasChannel {
  PencilCanvasChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName) {
    _active = this;
    _channel.setMethodCallHandler(_handle);
  }

  /// 채널 핸들러는 하나뿐이라 가장 최근에 만든 인스턴스만 소유한다. 다음 게임
  /// 화면이 먼저 만들어진 뒤 이전 화면이 dispose돼도 새 핸들러를 지우지 않는다.
  static PencilCanvasChannel? _active;

  static const String channelName = 'sudoku159/pencil_canvas';

  /// 네이티브 오버레이를 쓸 수 있는 플랫폼(iOS)인지. 테스트(macOS 호스트)와
  /// 안드로이드에서는 false.
  static bool get isSupported => !kIsWeb && Platform.isIOS;

  final MethodChannel _channel;

  /// 짧은 Pencil 탭: 셀 선택.
  void Function(int row, int col)? onTap;

  /// 필기 시작(대상 셀이 고정됨).
  void Function(int row, int col)? onStrokeBegan;

  /// 마지막 획 종료: 추가 획을 기다리며 인식을 준비 중.
  void Function(int row, int col)? onStrokeEnded;

  /// 인식 결과(명확·애매·실패).
  void Function(int row, int col, DigitRecognitionResult result)? onResult;

  /// 네이티브가 필기를 스스로 취소함(다른 셀에서 새 획 시작 등).
  void Function()? onCancelled;

  Future<dynamic> _handle(MethodCall call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    switch (call.method) {
      case 'tap':
        onTap?.call(args['row'] as int, args['col'] as int);
      case 'strokeBegan':
        onStrokeBegan?.call(args['row'] as int, args['col'] as int);
      case 'strokeEnded':
        onStrokeEnded?.call(args['row'] as int, args['col'] as int);
      case 'result':
        final digit = args['digit'] as int?;
        final candidates =
            ((args['candidates'] as List?) ?? const []).cast<int>();
        final result = digit != null
            ? DigitRecognitionResult.clear(digit)
            : candidates.length >= 2
                ? DigitRecognitionResult.ambiguous(candidates)
                : const DigitRecognitionResult.failure();
        onResult?.call(args['row'] as int, args['col'] as int, result);
      case 'cancelled':
        onCancelled?.call();
    }
    return null;
  }

  /// 오버레이 위치·활성 상태를 알린다. [boardRect]는 Flutter 전역 좌표(논리
  /// 픽셀 = iOS 포인트)이고, [blocked]는 필기를 시작할 수 없는 셀(주어진 숫자·
  /// 힌트 셀) 81개의 마스크(row-major)다.
  Future<void> configure({
    required bool enabled,
    required Rect boardRect,
    required List<bool> blocked,
    required int strokeColor,
    int settleMillis = 260,
  }) async {
    try {
      await _channel.invokeMethod<void>('configure', {
        'enabled': enabled,
        'x': boardRect.left,
        'y': boardRect.top,
        'width': boardRect.width,
        'height': boardRect.height,
        'blocked': blocked,
        'strokeColor': strokeColor,
        'settleMillis': settleMillis,
      });
    } on MissingPluginException {
      // 네이티브 구현이 없는 환경(테스트 등)에서는 무시한다.
    } on PlatformException {
      // 오버레이를 만들 수 없어도 숫자패드 입력은 계속 가능하다.
    }
  }

  /// 화면에 그려진 획을 지운다(인식 성공·취소·실패 안내 종료 시).
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clear');
    } on MissingPluginException {
      // 무시.
    } on PlatformException {
      // 무시.
    }
  }

  void dispose() {
    if (!identical(_active, this)) return;
    _active = null;
    _channel.setMethodCallHandler(null);
    // 게임 화면을 떠나면 오버레이를 숨기고 남은 획을 지운다.
    unawaited(configure(
      enabled: false,
      boardRect: Rect.zero,
      blocked: const [],
      strokeColor: 0,
    ));
  }
}
