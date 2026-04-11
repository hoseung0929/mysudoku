import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mysudoku/services/remote_puzzle_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('RemotePuzzleService', () {
    test('parses catalog entries from remote response', () async {
      final service = RemotePuzzleService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) async {
          expect(request.url.toString(), contains('/api/catalog'));
          return http.Response.bytes(
            utf8.encode('''
            {
              "items": [
                {
                  "level_name": "초급",
                  "game_number": 7,
                  "board": "1,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0;0,0,0,0,0,0,0,0,0",
                  "solution": [[1,2,3,4,5,6,7,8,9],[4,5,6,7,8,9,1,2,3],[7,8,9,1,2,3,4,5,6],[2,3,4,5,6,7,8,9,1],[5,6,7,8,9,1,2,3,4],[8,9,1,2,3,4,5,6,7],[3,4,5,6,7,8,9,1,2],[6,7,8,9,1,2,3,4,5],[9,1,2,3,4,5,6,7,8]]
                }
              ]
            }
            '''),
            200,
            headers: const {
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      final entries = await service.fetchCatalogForLevel(
        levelName: '초급',
        limit: 100,
      );

      expect(entries, hasLength(1));
      expect(entries.first.levelName, '초급');
      expect(entries.first.gameNumber, 7);
      expect(entries.first.board[0][0], 1);
      expect(entries.first.solution[8][8], 8);
    });

    test('parses remote daily challenge target', () async {
      final service = RemotePuzzleService(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) async {
          expect(request.url.toString(), contains('/api/daily-challenge'));
          return http.Response.bytes(
            utf8.encode('{"level_name":"중급","game_number":19}'),
            200,
            headers: const {
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      final target = await service.fetchDailyChallengeTarget(
        date: DateTime(2026, 4, 12),
      );

      expect(target, isNotNull);
      expect(target!.levelName, '중급');
      expect(target.gameNumber, 19);
    });
  });
}
