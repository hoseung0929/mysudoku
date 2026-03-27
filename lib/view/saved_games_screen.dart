import 'package:flutter/material.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';

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
  late List<ContinueGameSummary> _savedGames = List.of(widget.initialGames);
  bool _isDeleting = false;
  _SavedGameSort _selectedSort = _SavedGameSort.recent;
  String? _selectedLevelName;

  bool get _isKorean => Localizations.localeOf(context).languageCode == 'ko';

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
    setState(() {
      _isDeleting = true;
    });
    try {
      final refreshedGames = await widget.onDelete(summary);
      if (!mounted) return;
      setState(() {
        _savedGames = List.of(refreshedGames);
      });
      if (_savedGames.isEmpty) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
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
                    return _SavedGameListTile(
                      title: widget.itemTitleBuilder(summary),
                      subtitle: widget.itemSubtitleBuilder(summary),
                      isBusy: _isDeleting,
                      deleteTooltip: widget.deleteTooltip,
                      onTap: () => Navigator.of(context).pop(summary),
                      onDelete: () => _delete(summary),
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
        return _isKorean ? '최근 플레이순' : 'Recent';
      case _SavedGameSort.progress:
        return _isKorean ? '진행률순' : 'Progress';
      case _SavedGameSort.playTime:
        return _isKorean ? '플레이 시간순' : 'Play time';
    }
  }

  String _allLevelsLabel() {
    return _isKorean ? '전체' : 'All';
  }

  String _emptyStateLabel() {
    return _isKorean
        ? '선택한 조건에 맞는 저장 게임이 없어요.'
        : 'No saved games match this filter.';
  }
}

class _SavedGameListTile extends StatelessWidget {
  const _SavedGameListTile({
    required this.title,
    required this.subtitle,
    required this.isBusy,
    required this.deleteTooltip,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final bool isBusy;
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
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isBusy ? null : onDelete,
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
