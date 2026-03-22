import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/utils/app_logger.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  await testMain();
}
