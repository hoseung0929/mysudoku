import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _messageKeys(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  for (final entry in {
    'global': ['en', 'es', 'ja', 'ko', 'zh'],
    'japan': ['en', 'ja', 'ko'],
  }.entries) {
    test('${entry.key} ARB files have the same message keys', () {
      final template = _messageKeys('arb/${entry.key}/app_en.arb');

      for (final language in entry.value) {
        final path = 'arb/${entry.key}/app_$language.arb';
        expect(
          _messageKeys(path),
          template,
          reason: '$path must not rely on fallback text or retain retired keys',
        );
      }
    });
  }
}
