import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 글로벌·일본 플레이버는 CFBundleLocalizations만 다른 별도 Info.plist를 쓴다.
/// 두 파일이 언어 목록 외에 어긋나거나, Flutter ARB 언어와 달라지면 실패한다.
void main() {
  final localizationsBlock = RegExp(
    r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
    dotAll: true,
  );

  List<String> bundleLanguages(String plist) {
    final block = localizationsBlock.firstMatch(plist)!.group(1)!;
    return RegExp(r'<string>([^<]+)</string>')
        .allMatches(block)
        .map((m) => m.group(1)!)
        .toList();
  }

  /// ARB 파일명(app_zh.arb)을 iOS 언어 ID로 바꾼다(중국어는 간체).
  Set<String> arbLanguages(String flavor) => Directory('arb/$flavor')
      .listSync()
      .map((f) => f.uri.pathSegments.last)
      .where((name) => name.startsWith('app_') && name.endsWith('.arb'))
      .map((name) => name.substring(4, name.length - 4))
      .map((code) => code == 'zh' ? 'zh-Hans' : code)
      .toSet();

  final global = File('ios/Runner/Info.plist').readAsStringSync();
  final japan = File('ios/Runner/Info-japan.plist').readAsStringSync();

  test('global bundle languages match the global ARB languages', () {
    expect(bundleLanguages(global), ['en', 'ko', 'ja', 'es', 'zh-Hans']);
    expect(bundleLanguages(global).toSet(), arbLanguages('global'));
  });

  test('japan bundle languages match the japan ARB languages', () {
    expect(bundleLanguages(japan), ['en', 'ko', 'ja']);
    expect(bundleLanguages(japan).toSet(), arbLanguages('japan'));
  });

  test('the two Info.plist files differ only in CFBundleLocalizations', () {
    String withoutLanguages(String plist) =>
        plist.replaceFirst(localizationsBlock, '');
    expect(withoutLanguages(japan), withoutLanguages(global));
  });

  test('every japan build configuration uses Info-japan.plist', () {
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final configs = RegExp(
      r'/\* ([^*]+) \*/ = \{\s*isa = XCBuildConfiguration;(.*?)\n\t\t\};',
      dotAll: true,
    ).allMatches(project).where((m) => m.group(2)!.contains('INFOPLIST_FILE'));

    final byName = <String, String>{};
    for (final m in configs) {
      final plist = RegExp(r'INFOPLIST_FILE = "?([^";]+)"?;')
          .firstMatch(m.group(2)!)
          ?.group(1);
      if (plist != null && plist.startsWith('Runner/')) {
        byName[m.group(1)!.trim()] = plist;
      }
    }
    expect(byName.keys, hasLength(9));
    byName.forEach((name, plist) {
      expect(
        plist,
        name.endsWith('-japan')
            ? 'Runner/Info-japan.plist'
            : 'Runner/Info.plist',
        reason: name,
      );
    });
    expect(
      RegExp(r'TARGETED_DEVICE_FAMILY = "?1,2').hasMatch(project),
      isFalse,
    );
  });
}
