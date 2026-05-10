import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/utils/app_logger.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  await testMain();
}
