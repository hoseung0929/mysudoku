import 'dart:async';

class GameTimerController {
  GameTimerController({
    required this.onTick,
    required this.canTick,
  });

  final void Function(int seconds) onTick;
  final bool Function() canTick;

  Timer? _timer;
  int _seconds = 0;

  int get seconds => _seconds;

  String get formattedTime {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!canTick()) return;
      _seconds++;
      onTick(_seconds);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    _seconds = 0;
    onTick(_seconds);
  }

  void update(int seconds) {
    _seconds = seconds;
    onTick(_seconds);
  }

  void dispose() {
    stop();
  }
}
