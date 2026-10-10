import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';

enum _SavedGameSort { recent, progress, playTime }

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
  // 삭제 요청이 진행 중인 행(확인 대화상자 대기 포함). 이 행에만 로딩 표시.
  String? _deletingKey;
  // 삭제가 확정돼 사라지는 애니메이션 중인 행.
  String? _removingKey;
  _SavedGameSort _selectedSort = _SavedGameSort.recent;
  String? _selectedLevelName;

  String _keyFor(ContinueGameSummary summary) =>
      '${summary.level.name}#${summary.game.gameNumber}';

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  List<ContinueGameSummary> get _visibleGames {
    final filtered = _selectedLevelName == null
        ? List<ContinueGameSummary>.from(_savedGames)
        : _savedGames
            .where((game) => game.level.name == _selectedLevelName)
            .toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case _SavedGameSort.recent:
          return b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis);
        case _SavedGameSort.progress:
          final progressDiff = b.progress.compareTo(a.progress);
          if (progressDiff != 0) {
            return progressDiff;
          }
          return b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis);
        case _SavedGameSort.playTime:
          final timeDiff = b.elapsedSeconds.compareTo(a.elapsedSeconds);
          if (timeDiff != 0) {
            return timeDiff;
          }
          return b.lastPlayedAtMillis.compareTo(a.lastPlayedAtMillis);
      }
    });

    return filtered;
  }

  List<String> get _levelFilters {
    final levels = _savedGames.map((game) => game.level.name).toSet().toList();
    levels.sort();
    return levels;
  }

  Future<void> _delete(ContinueGameSummary summary) async {
    final key = _keyFor(summary);
    setState(() {
      _deletingKey = key;
    });
    try {
      final refreshedGames = await widget.onDelete(summary);
      if (!mounted) return;
      // onDelete 안의 확인 대화상자에서 취소하면 대상이 그대로 남아 돌아온다.
      final cancelled = refreshedGames.any((g) => _keyFor(g) == key);
      if (cancelled) {
        return;
      }
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() {
          _savedGames = List.of(refreshedGames);
        });
      } else {
        setState(() {
          _removingKey = key;
        });
        await Future<void>.delayed(_removeDuration);
        if (!mounted) return;
        setState(() {
          _savedGames = List.of(refreshedGames);
          _removingKey = null;
        });
      }
      if (_savedGames.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 삭제 실패: 대상 행은 그대로 두고 실패를 알린다. 화면은 닫지 않는다.
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description,
                style: TextStyle(
                  // 아이패드: 설명 16(폰은 테마 기본).
                  fontSize: MediaQuery.sizeOf(context).width > 600 ? 16 : null,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<_SavedGameSort>(
                    value: _selectedSort,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedSort = value;
                      });
                    },
                    items: _SavedGameSort.values
                        .map(
                          (sort) => DropdownMenuItem<_SavedGameSort>(
                            value: sort,
                            child: Text(_sortLabel(sort)),
                          ),
                        )
                        .toList(),
                  ),
                  ChoiceChip(
                    label: Text(_allLevelsLabel()),
                    selected: _selectedLevelName == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedLevelName = null;
                      });
                    },
                  ),
                  ..._levelFilters.map(
                    (levelName) => ChoiceChip(
                      label: Text(levelName),
                      selected: _selectedLevelName == levelName,
                      onSelected: (_) {
                        setState(() {
                          _selectedLevelName = levelName;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_visibleGames.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _emptyStateLabel(),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _visibleGames.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final summary = _visibleGames[index];
                      final key = _keyFor(summary);
                      final isDeleting = _deletingKey == key;
                      final isRemoving = _removingKey == key;
                      final tile = _SavedGameListTile(
                        title: widget.itemTitleBuilder(summary),
                        subtitle: widget.itemSubtitleBuilder(summary),
                        isLoading: isDeleting,
                        // 다른 삭제(확인 대기 포함)가 진행 중이면 동시 삭제를
                        // 막기 위해 모든 삭제 버튼을 잠근다. 열기는 막지 않는다.
                        deleteEnabled: _deletingKey == null,
                        tapEnabled: !isDeleting && !isRemoving,
                        deleteTooltip: widget.deleteTooltip,
                        onTap: () => Navigator.of(context).pop(summary),
                        onDelete: () => _delete(summary),
                      );
                      if (!isRemoving) {
                        return KeyedSubtree(key: ValueKey(key), child: tile);
                      }
                      return KeyedSubtree(
                        key: ValueKey(key),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1, end: 0),
                          duration: _removeDuration,
                          curve: Curves.easeOutCubic,
                          builder: (context, t, child) => ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: t,
                              child: Opacity(opacity: t, child: child),
                            ),
                          ),
                          child: tile,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(_SavedGameSort sort) {
    switch (sort) {
      case _SavedGameSort.recent:
        return _l10n.savedGamesSortRecent;
      case _SavedGameSort.progress:
        return _l10n.savedGamesSortProgress;
      case _SavedGameSort.playTime:
        return _l10n.savedGamesSortPlayTime;
    }
  }

  String _allLevelsLabel() {
    return _l10n.levelFilterAll;
  }

  String _emptyStateLabel() {
    return _l10n.savedGamesEmpty;
  }
}

class _SavedGameListTile extends StatelessWidget {
  const _SavedGameListTile({
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.deleteEnabled,
    required this.tapEnabled,
    required this.deleteTooltip,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final bool isLoading;
  final bool deleteEnabled;
  final bool tapEnabled;
  final String deleteTooltip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: tapEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: MediaQuery.sizeOf(context).width > 600 ? 16 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize:
                            MediaQuery.sizeOf(context).width > 600 ? 17 : null,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize:
                            MediaQuery.sizeOf(context).width > 600 ? 14 : 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  onPressed: deleteEnabled ? onDelete : null,
                  tooltip: deleteTooltip,
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
