import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/presenter/game_timer_controller.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('GameTimerController', () {
    test('formats updated time as mm:ss', () {
      int? lastTick;
      final controller = GameTimerController(
        onTick: (seconds) {
          lastTick = seconds;
        },
        canTick: () => true,
      );

      controller.update(125);

      expect(lastTick, 125);
      expect(controller.seconds, 125);
      expect(controller.formattedTime, '02:05');
    });

    test('reset clears elapsed time', () {
      final controller = GameTimerController(
        onTick: (_) {},
        canTick: () => true,
      );

      controller.update(59);
      controller.reset();

      expect(controller.seconds, 0);
      expect(controller.formattedTime, '00:00');
    });
  });
}
