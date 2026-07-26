import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/services/settings/force_update_service.dart';

void main() {
  group('ForceUpdateService.isVersionBelow', () {
    test('returns true when current version is lower', () {
      expect(ForceUpdateService.isVersionBelow('1.1.0', '1.2.0'), isTrue);
    });

    test('returns false when current version meets minimum', () {
      expect(ForceUpdateService.isVersionBelow('1.2.0', '1.2.0'), isFalse);
    });

    test('returns false when current version exceeds minimum', () {
      expect(ForceUpdateService.isVersionBelow('1.3.0', '1.2.0'), isFalse);
    });

    test('compares differing segment counts correctly', () {
      expect(ForceUpdateService.isVersionBelow('1.2', '1.2.1'), isTrue);
      expect(ForceUpdateService.isVersionBelow('1.2.0', '1.2'), isFalse);
    });

    test('compares patch-level differences', () {
      expect(ForceUpdateService.isVersionBelow('1.2.3', '1.2.10'), isTrue);
    });

    test('treats malformed segments as zero', () {
      expect(ForceUpdateService.isVersionBelow('1.x.0', '1.1.0'), isTrue);
    });
  });
}
