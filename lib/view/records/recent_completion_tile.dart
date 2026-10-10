import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/navigation/app_page_route.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/services/records/recent_completions_service.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/utils/time_format.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:sudoku159/widgets/replay_confirm_dialog.dart';

/// 최근 완료 목록의 한 줄: `초급 004` · 날짜 · 실수 · 힌트 · 표시 / 오른쪽 시간.
class RecentCompletionTile extends StatelessWidget {
  const RecentCompletionTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.today,
  });

  final RecentCompletion entry;
  final VoidCallback? onTap;

  /// 날짜 표기(오늘·어제)의 기준일. 테스트에서만 지정한다.
  final DateTime? today;

  String _dateLabel(AppLocalizations l10n, String locale) {
    final date = DateTime.parse(entry.clearDate);
    final now = today ?? DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final days = base.difference(DateTime(date.year, date.month, date.day));
    if (days.inDays == 0) return l10n.recordsTrendTodayLabel;
    if (days.inDays == 1) return l10n.recordsRecentYesterday;
    return date.year == now.year
        ? DateFormat.MMMd(locale).format(date)
        : DateFormat.yMMMd(locale).format(date);
  }

  String _tagLabel(AppLocalizations l10n, RecentCompletionTag tag) {
    return switch (tag) {
      RecentCompletionTag.dailyChallenge => l10n.challengeTodaysChallengeTitle,
      RecentCompletionTag.best => l10n.recordsSectionBestRecordTitle,
      RecentCompletionTag.replay => l10n.levelReplayConfirm,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final palette = LevelStatusPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final levelName = entry.levelName.localizedSudokuLevelName(l10n);
    final title = '$levelName ${entry.gameNumber.toString().padLeft(3, '0')}';
    final details = [
      _dateLabel(l10n, locale),
      l10n.recordsTimelineMistakesValue(entry.wrongCount),
      if (entry.hintsUsed > 0) l10n.dialogHintsUsed(entry.hintsUsed),
    ].join(' · ');
    final time = formatElapsedSeconds(entry.clearTime);
    final tags = [for (final t in entry.tags) _tagLabel(l10n, t)];
    // 큰 글씨에서는 시간을 오른쪽에 두면 왼쪽 글이 너무 좁아지므로 제목 아래로
    // 내린다(글씨는 줄이지 않는다).
    final stackTime = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final timeText = Text(
      time,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    Widget tag(RecentCompletionTag kind, String label) {
      // 최고 기록·도전은 강조, 다시 푼 판은 중립색.
      final emphasized = kind != RecentCompletionTag.replay;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: emphasized
              ? palette.completedBackground
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: emphasized ? palette.primaryPurple : cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: [
        '$levelName, ${l10n.levelPuzzleNumber(entry.gameNumber)}',
        details,
        time,
        ...tags,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (stackTime) timeText,
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (var i = 0; i < tags.length; i++)
                              tag(entry.tags[i], tags[i]),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!stackTime) ...[
                  const SizedBox(width: 12),
                  timeText,
                ],
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 최근 완료 한 줄을 눌렀을 때: 그 퍼즐을 다시 풀던 세션이 있으면 바로 이어서
/// 열고(퍼즐 선택 화면의 진행 중 칸과 같다), 없으면 다시 풀기 확인 후 처음부터
/// 연다.
Future<void> openRecentCompletion(
  BuildContext context,
  RecentCompletion entry, {
  GameStateService? gameStateService,
  DatabaseHelper? databaseHelper,
}) async {
  final session = await (gameStateService ?? GameStateService()).loadSession(
    levelName: entry.levelName,
    gameNumber: entry.gameNumber,
  );
  if (!context.mounted) return;
  final hasSession = session != null;
  if (!hasSession) {
    final confirmed =
        await showReplayConfirmDialog(context, gameNumber: entry.gameNumber);
    if (!context.mounted || confirmed != true) return;
  }

  final level = SudokuLevel.levels.firstWhere(
    (item) => item.name == entry.levelName,
    orElse: () => SudokuLevel.levels.first,
  );
  final gameEntry = await (databaseHelper ?? DatabaseHelper())
      .getGameEntry(entry.levelName, entry.gameNumber);
  if (!context.mounted) return;
  if (gameEntry == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.recordsGameLoadError)),
    );
    return;
  }
  final game = SudokuGame(
    board: gameEntry['board'] as List<List<int>>,
    solution: gameEntry['solution'] as List<List<int>>,
    emptyCells: level.emptyCells,
    levelName: entry.levelName,
    gameNumber: entry.gameNumber,
  );
  await Navigator.of(context).push(
    buildAppPageRoute(
      builder: (_) => SudokuGameScreen(
        game: game,
        level: level,
        restoreSavedSession: hasSession,
      ),
    ),
  );
}
