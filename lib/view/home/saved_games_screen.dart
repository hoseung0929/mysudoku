import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/theme/app_colors.dart';
import 'package:sudoku159/theme/level_status_colors.dart';

enum _SavedGameSort { recent, progress, playTime }

enum _SavedGameCardAction { delete }

class SavedGamesScreen extends StatefulWidget {
  const SavedGamesScreen({
    super.key,
    required this.initialGames,
    required this.title,
    required this.description,
    required this.itemTitleBuilder,
    required this.itemSubtitleBuilder,
    required this.deleteTooltip,
    required this.onDelete,
  });

  final List<ContinueGameSummary> initialGames;
  final String title;
  final String description;
  final String Function(ContinueGameSummary summary) itemTitleBuilder;
  final String Function(ContinueGameSummary summary) itemSubtitleBuilder;
  final String deleteTooltip;
  final Future<List<ContinueGameSummary>> Function(ContinueGameSummary summary)
      onDelete;

  @override
  State<SavedGamesScreen> createState() => _SavedGamesScreenState();
}

class _SavedGamesScreenState extends State<SavedGamesScreen> {
  static const _removeDuration = Duration(milliseconds: 170);
  late List<ContinueGameSummary> _savedGames = List.of(widget.initialGames);
  final ScrollController _levelFilterController = ScrollController();
  String? _deletingKey;
  String? _removingKey;
  _SavedGameSort _selectedSort = _SavedGameSort.recent;
  String? _selectedLevelName;
  bool _canScrollFilterLeft = false;
  bool _canScrollFilterRight = false;

  @override
  void initState() {
    super.initState();
    _levelFilterController.addListener(_syncFilterScrollHints);
  }

  @override
  void dispose() {
    _levelFilterController
      ..removeListener(_syncFilterScrollHints)
      ..dispose();
    super.dispose();
  }

  void _syncFilterScrollHints() {
    if (!mounted || !_levelFilterController.hasClients) return;
    final position = _levelFilterController.position;
    final canScrollLeft = position.extentBefore > 1;
    final canScrollRight = position.extentAfter > 1;
    if (canScrollLeft == _canScrollFilterLeft &&
        canScrollRight == _canScrollFilterRight) {
      return;
    }
    setState(() {
      _canScrollFilterLeft = canScrollLeft;
      _canScrollFilterRight = canScrollRight;
    });
  }

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  String _keyFor(ContinueGameSummary summary) =>
      '${summary.level.name}#${summary.game.gameNumber}';

  List<ContinueGameSummary> get _visibleGames {
    final games = _selectedLevelName == null
        ? List<ContinueGameSummary>.from(_savedGames)
        : _savedGames
            .where((game) => game.level.name == _selectedLevelName)
            .toList();
    games.sort((a, b) {
      switch (_selectedSort) {
        case _SavedGameSort.recent:
          return b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis);
        case _SavedGameSort.progress:
          final result = b.progress.compareTo(a.progress);
          return result != 0
              ? result
              : b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis);
        case _SavedGameSort.playTime:
          final result = b.elapsedSeconds.compareTo(a.elapsedSeconds);
          return result != 0
              ? result
              : b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis);
      }
    });
    return games;
  }

  List<SudokuLevel> get _levelFilters {
    final levelsByName = <String, SudokuLevel>{
      for (final game in _savedGames) game.level.name: game.level,
    };
    final levels = levelsByName.values.toList()
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    return levels;
  }

  Future<void> _delete(ContinueGameSummary summary) async {
    final key = _keyFor(summary);
    setState(() => _deletingKey = key);
    try {
      final refreshedGames = await widget.onDelete(summary);
      if (!mounted) return;
      if (refreshedGames.any((game) => _keyFor(game) == key)) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() => _savedGames = List.of(refreshedGames));
      } else {
        setState(() => _removingKey = key);
        await Future<void>.delayed(_removeDuration);
        if (!mounted) return;
        setState(() {
          _savedGames = List.of(refreshedGames);
          _removingKey = null;
        });
      }
      if (_savedGames.isEmpty && mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.savedGamesDeleteFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingKey = null;
          _removingKey = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final colors = context.colors;
    final palette = LevelStatusPalette.of(context);
    final chips = <Widget>[
      _levelChip(
        _l10n.levelFilterAll,
        selected: _selectedLevelName == null,
        palette: palette,
        isTablet: isTablet,
        onTap: () => setState(() => _selectedLevelName = null),
      ),
      ..._levelFilters.map(
        (level) => _levelChip(
          level.localizedName(_l10n),
          selected: _selectedLevelName == level.name,
          palette: palette,
          isTablet: isTablet,
          onTap: () => setState(() => _selectedLevelName = level.name),
        ),
      ),
    ];
    // 슬라이드 하이라이트용(레벨 선택 화면 필터와 같은 방식): 이름·선택 여부·탭.
    final filterItems = <({String label, bool selected, VoidCallback onTap})>[
      (
        label: _l10n.levelFilterAll,
        selected: _selectedLevelName == null,
        onTap: () => setState(() => _selectedLevelName = null),
      ),
      for (final level in _levelFilters)
        (
          label: level.localizedName(_l10n),
          selected: _selectedLevelName == level.name,
          onTap: () => setState(() => _selectedLevelName = level.name),
        ),
    ];
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncFilterScrollHints());

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 1000 : 640),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 32 : 20,
                isTablet ? 28 : 20,
                isTablet ? 32 : 20,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 15,
                      height: 1.55,
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          key: const ValueKey('saved-games-level-filter'),
                          height: isTablet ? 52 : 48,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: palette.filterSelectedBackground,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 4.0;
                              final slotWidth = (constraints.maxWidth -
                                      gap * (filterItems.length - 1)) /
                                  filterItems.length;
                              // 모든 이름이 같은 폭 칸에 한 줄로 들어갈 때만 하이라이트가
                              // 미끄러져 이동한다. 길면 기존 가로 스크롤 목록을 쓴다.
                              final scaler = MediaQuery.textScalerOf(context);
                              var fits = true;
                              for (final item in filterItems) {
                                final painter = TextPainter(
                                  text: TextSpan(
                                    text: item.label,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  textDirection: Directionality.of(context),
                                  textScaler: scaler,
                                  maxLines: 1,
                                )..layout();
                                if (painter.width + 16 > slotWidth) {
                                  fits = false;
                                }
                                painter.dispose();
                              }
                              if (!fits) {
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ListView.separated(
                                        key: const ValueKey(
                                          'saved-games-level-filter-list',
                                        ),
                                        controller: _levelFilterController,
                                        padding: EdgeInsets.only(
                                          left: _canScrollFilterLeft ? 18 : 0,
                                          right: _canScrollFilterRight ? 18 : 0,
                                        ),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: chips.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 4),
                                        itemBuilder: (_, index) => chips[index],
                                      ),
                                    ),
                                    if (_canScrollFilterLeft)
                                      _filterScrollHint(
                                        palette,
                                        alignment: Alignment.centerLeft,
                                        icon: Icons.chevron_left_rounded,
                                        key: const ValueKey(
                                          'saved-games-filter-more-left',
                                        ),
                                      ),
                                    if (_canScrollFilterRight)
                                      _filterScrollHint(
                                        palette,
                                        alignment: Alignment.centerRight,
                                        icon: Icons.chevron_right_rounded,
                                        key: const ValueKey(
                                          'saved-games-filter-more-right',
                                        ),
                                      ),
                                  ],
                                );
                              }
                              final selectedIndex = filterItems
                                  .indexWhere((item) => item.selected);
                              final duration =
                                  MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220);
                              return Stack(
                                key: const ValueKey(
                                  'saved-games-level-filter-slide',
                                ),
                                children: [
                                  AnimatedPositioned(
                                    duration: duration,
                                    curve: Curves.easeOutCubic,
                                    left: math.max(0, selectedIndex) *
                                        (slotWidth + gap),
                                    width: slotWidth,
                                    top: 0,
                                    bottom: 0,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: palette.cardBackground,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x1A000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      for (var i = 0;
                                          i < filterItems.length;
                                          i++) ...[
                                        if (i > 0) const SizedBox(width: gap),
                                        Expanded(
                                          child: Semantics(
                                            selected: filterItems[i].selected,
                                            button: true,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: filterItems[i].onTap,
                                              child: Center(
                                                child: AnimatedDefaultTextStyle(
                                                  duration: duration,
                                                  style: TextStyle(
                                                    fontSize:
                                                        isTablet ? 14 : 13,
                                                    fontWeight:
                                                        filterItems[i].selected
                                                            ? FontWeight.w700
                                                            : FontWeight.w600,
                                                    color: filterItems[i]
                                                            .selected
                                                        ? palette.primaryPurple
                                                        : palette
                                                            .filterUnselectedText,
                                                  ),
                                                  child: Text(
                                                    filterItems[i].label,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _sortMenu(colors, isTablet),
                    ],
                  ),
                  if (_visibleGames.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.extension_outlined,
                              size: isTablet ? 44 : 38,
                              color: colors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _l10n.savedGamesEmpty,
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.only(
                          top: isTablet ? 18 : 16,
                          bottom: 24,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 2 : 1,
                          mainAxisExtent: isTablet ? 204 : 192,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: isTablet ? 16 : 12,
                        ),
                        itemCount: _visibleGames.length,
                        itemBuilder: (_, index) {
                          final summary = _visibleGames[index];
                          final key = _keyFor(summary);
                          final isDeleting = _deletingKey == key;
                          final isRemoving = _removingKey == key;
                          final card = _SavedGameCard(
                            difficulty: summary.level.difficulty,
                            title: widget.itemTitleBuilder(summary),
                            subtitle: widget.itemSubtitleBuilder(summary),
                            progress: summary.progress,
                            isLoading: isDeleting,
                            deleteEnabled: _deletingKey == null,
                            continueEnabled: !isDeleting && !isRemoving,
                            deleteTooltip: widget.deleteTooltip,
                            continueLabel: _l10n.levelContinueButton,
                            onContinue: () =>
                                Navigator.of(context).pop(summary),
                            onDelete: () => _delete(summary),
                          );
                          return KeyedSubtree(
                            key: ValueKey(key),
                            child: isRemoving
                                ? TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 1, end: 0),
                                    duration: _removeDuration,
                                    curve: Curves.easeOutCubic,
                                    builder: (_, value, child) => Opacity(
                                      opacity: value,
                                      child: Transform.scale(
                                        scale: 0.96 + (0.04 * value),
                                        child: child,
                                      ),
                                    ),
                                    child: card,
                                  )
                                : card,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortMenu(AppColorsExtension colors, bool isTablet) {
    return PopupMenuButton<_SavedGameSort>(
      key: const ValueKey('saved-games-sort-menu'),
      tooltip: _sortLabel(_selectedSort),
      initialValue: _selectedSort,
      onSelected: (value) => setState(() => _selectedSort = value),
      itemBuilder: (_) => _SavedGameSort.values
          .map(
            (sort) => PopupMenuItem(
              value: sort,
              child: Text(_sortLabel(sort)),
            ),
          )
          .toList(),
      child: Container(
        height: isTablet ? 52 : 48,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: isTablet ? 22 : 20,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              _sortLabel(_selectedSort),
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: isTablet ? 21 : 19,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterScrollHint(
    LevelStatusPalette palette, {
    required Alignment alignment,
    required IconData icon,
    required Key key,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    return Positioned(
      key: key,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: 28,
          alignment: alignment,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              colors: [
                palette.filterSelectedBackground.withValues(alpha: 0),
                palette.filterSelectedBackground,
              ],
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: palette.filterUnselectedText,
          ),
        ),
      ),
    );
  }

  Widget _levelChip(
    String label, {
    required bool selected,
    required LevelStatusPalette palette,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? palette.cardBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        elevation: selected ? 1 : 0,
        shadowColor: const Color(0x1A000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 13),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? palette.primaryPurple
                      : palette.filterUnselectedText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _sortLabel(_SavedGameSort sort) => switch (sort) {
        _SavedGameSort.recent => _l10n.savedGamesSortRecent,
        _SavedGameSort.progress => _l10n.savedGamesSortProgress,
        _SavedGameSort.playTime => _l10n.savedGamesSortPlayTime,
      };
}

class _SavedGameCard extends StatelessWidget {
  const _SavedGameCard({
    required this.difficulty,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.isLoading,
    required this.deleteEnabled,
    required this.continueEnabled,
    required this.deleteTooltip,
    required this.continueLabel,
    required this.onContinue,
    required this.onDelete,
  });

  final int difficulty;
  final String title;
  final String subtitle;
  final double progress;
  final bool isLoading;
  final bool deleteEnabled;
  final bool continueEnabled;
  final String deleteTooltip;
  final String continueLabel;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  String? get _imagePath => switch (difficulty) {
        1 => 'assets/images/level1.png',
        2 => 'assets/images/level2.png',
        3 => 'assets/images/level3.png',
        4 => 'assets/images/level4.png',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = LevelStatusPalette.of(context);
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: isTablet ? 88 : 76,
                    height: isTablet ? 88 : 76,
                    child: _imagePath == null
                        ? DecoratedBox(
                            key: const ValueKey('saved-game-level-image'),
                            decoration: BoxDecoration(
                              color: palette.filterSelectedBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: palette.primaryPurple,
                              size: isTablet ? 42 : 36,
                            ),
                          )
                        : Image.asset(
                            _imagePath!,
                            key: const ValueKey('saved-game-level-image'),
                            fit: BoxFit.contain,
                          ),
                  ),
                  SizedBox(width: isTablet ? 16 : 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: isTablet ? 20 : 18,
                        height: isTablet ? 20 : 18,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    PopupMenuButton<_SavedGameCardAction>(
                      key: const ValueKey('saved-game-actions-menu'),
                      enabled: deleteEnabled,
                      tooltip: deleteTooltip,
                      onSelected: (_) => onDelete(),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _SavedGameCardAction.delete,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: colors.attention,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  deleteTooltip,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: deleteEnabled
                            ? colors.textSecondary
                            : colors.textDisabled,
                      ),
                    ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: isTablet ? 7 : 6,
                backgroundColor: palette.progressTrack,
                color: palette.primaryPurple,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 14),
            SizedBox(
              height: isTablet ? 48 : 44,
              child: FilledButton.icon(
                onPressed: continueEnabled ? onContinue : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.textPrimary,
                  foregroundColor: colors.background,
                  disabledBackgroundColor: colors.border,
                  disabledForegroundColor: colors.textDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(Icons.play_arrow_rounded, size: isTablet ? 22 : 20),
                label: Text(
                  continueLabel,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
