import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/theme/system_ui_style.dart';

void main() {
  test('light theme: dark status icons; iOS reports a light app screen', () {
    final style = systemOverlayStyleFor(Brightness.light);
    expect(style.statusBarIconBrightness, Brightness.dark); // Android
    expect(style.statusBarBrightness, Brightness.light); // iOS
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
  });

  test('dark theme: light status icons; iOS reports a dark app screen', () {
    final style = systemOverlayStyleFor(Brightness.dark);
    expect(style.statusBarIconBrightness, Brightness.light); // Android
    expect(style.statusBarBrightness, Brightness.dark); // iOS
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });
}
