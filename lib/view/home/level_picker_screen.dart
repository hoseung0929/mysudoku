import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/database/database_manager.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/services/home/level_progress_service.dart';
import 'package:sudoku159/theme/app_colors.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';

enum _PuzzleFilter { all, fresh, inProgress, completed }

enum _PuzzleCardKind { fresh, recent, inProgress, completed }

class LevelPickerScreen extends StatefulWidget {
  final SudokuLevel level;

  const LevelPickerScreen({super.key, required this.level});

  @override
  State<LevelPickerScreen> createState() => _LevelPickerScreenState();
}

class _LevelPickerScreenState extends State<LevelPickerScreen> {
  static const int _perfLogThresholdMs = 120;
  final DatabaseManager _databaseManager = DatabaseManager();
  final LevelProgressService _levelProgressService = LevelProgressService();
  final GameStateService _gameStateService = GameStateService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Map<String, List<int>> _gameCache = {};
  final Map<String, Future<List<int>>> _gameFutureCache = {};
  final Map<String, Map<int, SudokuGame>> _playGameCache = {};
  final Map<String, Stopwatch> _levelLoadStopwatch = {};
  final Map<String, Set<int>> _clearedGameNumbers = {};
  final Map<String, Map<int, SavedGameState>> _savedGameStates = {};
  final Map<String, Map<int, Map<String, dynamic>>> _clearRecords = {};
  final Map<String, int?> _recentSavedGameNumber = {};
  final Map<String, Future<void>> _puzzleMetadataFutureCache = {};
  List<SudokuLevel> _levels = List<SudokuLevel>.from(SudokuLevel.levels);
  _PuzzleFilter _selectedFilter = _PuzzleFilter.all;
  bool _isGameTransitioning = false;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';

  @override
  void initState() {
    super.initState();
    _gamesFutureForLevel(widget.level.name);
    _puzzleMetadataFutureForLevel(widget.level.name);
  }

  Future<List<int>> _loadGames(String level) async {
    final sw = _levelLoadStopwatch.putIfAbsent(level, Stopwatch.new);
    if (!sw.isRunning) {
      sw
        ..reset()
        ..start();
    }
    if (!_clearedGameNumbers.containsKey(level)) {
      _loadClearedGameNumbers(level).then((_) {
        if (mounted) setState(() {});
      });
    }
    if (_gameCache.containsKey(level)) {
      if (sw.isRunning) sw.stop();
      if (kDebugMode && sw.elapsedMilliseconds >= _perfLogThresholdMs) {
        debugPrint(
            '[perf] level_list(cache) level=$level count=${_gameCache[level]!.length} elapsed_ms=${sw.elapsedMilliseconds}');
      }
      return _gameCache[level]!;
    }
    final gameNumbers = await _dbHelper.getGameNumbersForLevel(level);
    _gameCache[level] = gameNumbers;
    if (sw.isRunning) sw.stop();
    if (kDebugMode && sw.elapsedMilliseconds >= _perfLogThresholdMs) {
      debugPrint(
          '[perf] level_list(db) level=$level count=${gameNumbers.length} elapsed_ms=${sw.elapsedMilliseconds}');
    }
    return gameNumbers;
  }

  Future<List<int>> _gamesFutureForLevel(String level) {
    return _gameFutureCache.putIfAbsent(level, () => _loadGames(level));
  }

  Future<void> _loadClearedGameNumbers(String levelName) async {
    final numbers = await _dbHelper.getClearedGameNumbersForLevel(levelName);
    _clearedGameNumbers[levelName] = numbers.toSet();
  }

  Future<void> _loadPuzzleMetadata(String levelName) async {
    final savedGames = await _gameStateService.getSavedGames();
    final savedForLevel = <int, SavedGameState>{};
    int? recentGameNumber;
    var latestMillis = -1;

    for (final saved in savedGames) {
      if (saved.levelName != levelName || saved.session.isGameComplete) {
        continue;
      }
      savedForLevel[saved.gameNumber] = saved;
      if (saved.lastPlayedAtMillis > latestMillis) {
        latestMillis = saved.lastPlayedAtMillis;
        recentGameNumber = saved.gameNumber;
      }
    }

    final records = await _dbHelper.getClearRecordsForLevel(levelName);
    final recordsByGame = <int, Map<String, dynamic>>{};
    for (final record in records) {
      final gameNumber = (record['game_number'] as num?)?.toInt();
      if (gameNumber == null) continue;
      recordsByGame[gameNumber] = record;
    }

    if (!mounted) return;
    setState(() {
      _savedGameStates[levelName] = savedForLevel;
      _clearRecords[levelName] = recordsByGame;
      _recentSavedGameNumber[levelName] = recentGameNumber;
      _clearedGameNumbers[levelName] = recordsByGame.keys.toSet();
    });
  }

  Future<void> _puzzleMetadataFutureForLevel(String levelName) {
    return _puzzleMetadataFutureCache.putIfAbsent(
      levelName,
      () => _loadPuzzleMetadata(levelName),
    );
  }

  bool _isCleared(String levelName, int gameNumber) {
    return _clearedGameNumbers[levelName]?.contains(gameNumber) ?? false;
  }

  Future<SudokuGame?> _loadGameForPlay(String levelName, int gameNumber) async {
    final sw = Stopwatch()..start();
    final cached = _playGameCache[levelName]?[gameNumber];
    if (cached != null) {
      sw.stop();
      return cached;
    }

    final levelInfo = SudokuLevel.levels.firstWhere(
      (item) => item.name == levelName,
      orElse: () => SudokuLevel.levels.first,
    );
    final entry = await _dbHelper.getGameEntry(levelName, gameNumber);
    if (entry == null) return null;

    final game = SudokuGame(
      board: entry['board'] as List<List<int>>,
      solution: entry['solution'] as List<List<int>>,
      emptyCells: levelInfo.emptyCells,
      levelName: levelName,
      gameNumber: gameNumber,
    );

    (_playGameCache[levelName] ??= <int, SudokuGame>{})[gameNumber] = game;
    return game;
  }

  Future<void> _onGameSelected(int gameNumber, SudokuLevel level) async {
    if (_isGameTransitioning || !mounted) return;
    final kind = _puzzleCardKind(gameNumber);
    if (kind == _PuzzleCardKind.completed) {
      final shouldReplay = await _confirmReplayCompletedPuzzle();
      if (!mounted || shouldReplay != true) return;
    }

    setState(() => _isGameTransitioning = true);
    final game = await _loadGameForPlay(level.name, gameNumber);
    if (!mounted) return;
    if (game == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.recordsGameLoadError)),
      );
      if (mounted) {
        setState(() => _isGameTransitioning = false);
      } else {
        _isGameTransitioning = false;
      }
      return;
    }
    try {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SudokuGameScreen(
            game: game,
            level: level,
            restoreSavedSession: _shouldRestoreSavedSession(kind),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      await _loadClearedGameNumbers(level.name);
      _puzzleMetadataFutureCache.remove(level.name);
      await _loadPuzzleMetadata(level.name);
      final currentLevel = _levels.firstWhere((item) => item.name == level.name,
          orElse: () => level);
      final refreshedLevel =
          await _levelProgressService.refreshLevel(currentLevel);
      if (mounted) {
        setState(() {
          _levels = _levels
              .map((item) =>
                  item.name == refreshedLevel.name ? refreshedLevel : item)
              .toList();
        });
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) {
        setState(() => _isGameTransitioning = false);
      } else {
        _isGameTransitioning = false;
      }
    }
  }

  Future<bool?> _confirmReplayCompletedPuzzle() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_isKo ? '완료한 퍼즐을 다시 풀까요?' : 'Replay this puzzle?'),
          content: Text(
            _isKo
                ? '기존 완료 기록은 유지되며, 새 기록이 더 좋으면 갱신됩니다.'
                : 'Your completed record is kept, and it updates only if the new result is better.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_isKo ? '취소' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_isKo ? '다시 풀기' : 'Replay'),
            ),
          ],
        );
      },
    );
  }

  bool _shouldRestoreSavedSession(_PuzzleCardKind kind) {
    return kind == _PuzzleCardKind.inProgress || kind == _PuzzleCardKind.recent;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<PuzzleCatalogStatus>(
              valueListenable: _databaseManager.catalogStatus,
              builder: (context, status, child) {
                if (!status.isRunning) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _CatalogStatusBar(
                    status: status,
                    l10n: AppLocalizations.of(context)!,
                  ),
                );
              },
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    final level = _currentLevelInfo();
    return AppBar(
      toolbarHeight: 52,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
        color: const Color(0xFF1A1A1A),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_levelIcon(level), size: 20, color: _levelIconColor(level)),
          const SizedBox(width: 8),
          Text(
            level.localizedName(l10n),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    _puzzleMetadataFutureForLevel(widget.level.name);
    return FutureBuilder<List<int>>(
      future: _gamesFutureForLevel(widget.level.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStateMessage(l10n.levelLoadingGames, showSpinner: true);
        }
        if (snapshot.hasError) {
          return _buildStateMessage(
            l10n.recordsGameLoadError,
            icon: Icons.error_outline_rounded,
            actionLabel: _isKo ? '다시 시도' : 'Try again',
            onAction: _retryLoadGames,
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildStateMessage(
            _isKo
                ? '선택 가능한 게임이 없습니다.'
                : 'No puzzles are available for this level.',
            icon: Icons.inbox_outlined,
          );
        }

        final games = snapshot.data!;
        final filteredGames = _filteredGames(games);
        final bottomPadding = MediaQuery.paddingOf(context).bottom + 24;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _buildProgressStrip(totalCount: games.length),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFilterChips(),
            ),
            const SizedBox(height: 6),
            _buildRecentPlayBanner(),
            Expanded(
              child: filteredGames.isEmpty
                  ? Center(
                      child: Text(
                        _isKo ? '해당 항목이 없습니다.' : 'No results.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFBDBDBD),
                        ),
                      ),
                    )
                  : _buildPuzzleGrid(filteredGames, bottomPadding),
            ),
          ],
        );
      },
    );
  }

  // ─── Progress strip ───────────────────────────────────────────────────────

  Widget _buildProgressStrip({required int totalCount}) {
    final level = _currentLevelInfo();
    final cleared = _clearedGameNumbers[level.name]?.length ?? 0;
    final progress = totalCount == 0 ? 0.0 : cleared / totalCount;
    final visibleProgress = progress > 0 ? progress.clamp(0.015, 1.0) : 0.0;
    final progressPercent = (progress * 100).round();
    final barColor = _levelAccentColor(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: '$cleared',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: _isKo
                        ? ' / $totalCount 완료'
                        : ' / $totalCount completed',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '$progressPercent%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: visibleProgress,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  // ─── Filter chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    const filters = _PuzzleFilter.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            _buildFilterChip(filter),
            if (filter != filters.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(_PuzzleFilter filter) {
    final isSelected = _selectedFilter == filter;
    final level = _currentLevelInfo();
    final selectedFill = _levelAccentColor(level).withValues(alpha: 0.14);
    final selectedBorder = _levelAccentColor(level).withValues(alpha: 0.28);
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? selectedBorder : AppColors.border,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            _filterLabel(filter),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? _levelAccentColor(level)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _filterLabel(_PuzzleFilter filter) {
    switch (filter) {
      case _PuzzleFilter.all:
        return _isKo ? '전체' : 'All';
      case _PuzzleFilter.fresh:
        return _isKo ? '새 퍼즐' : 'New';
      case _PuzzleFilter.inProgress:
        return _isKo ? '진행 중' : 'In progress';
      case _PuzzleFilter.completed:
        return _isKo ? '완료' : 'Done';
    }
  }

  // ─── Puzzle grid ──────────────────────────────────────────────────────────

  static const int _gridCols = 4;
  static const double _cellGap = 3.0;
  static const double _groupGap = 6.0;
  static const int _rowsPerGroup = 3;

  Widget _buildPuzzleGrid(List<int> games, double bottomPadding) {
    final totalRows = (games.length / _gridCols).ceil();
    final rows = <Widget>[];

    for (int r = 0; r < totalRows; r++) {
      final start = r * _gridCols;
      final end = (start + _gridCols).clamp(0, games.length);
      final rowGames = games.sublist(start, end);

      rows.add(Row(
        children: [
          for (int c = 0; c < _gridCols; c++) ...[
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.52,
                child: c < rowGames.length
                    ? _buildPuzzleCell(rowGames[c])
                    : const SizedBox(),
              ),
            ),
            if (c < _gridCols - 1) const SizedBox(width: _cellGap),
          ],
        ],
      ));

      if (r < totalRows - 1) {
        final isGroupBoundary = (r + 1) % _rowsPerGroup == 0;
        rows.add(SizedBox(height: isGroupBoundary ? _groupGap : _cellGap));
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  Widget _buildPuzzleCell(int gameNumber) {
    final kind = _puzzleCardKind(gameNumber);
    final isFresh = kind == _PuzzleCardKind.fresh;
    final isInProgress =
        kind == _PuzzleCardKind.inProgress || kind == _PuzzleCardKind.recent;
    final isRecent = kind == _PuzzleCardKind.recent;
    final isCompleted = kind == _PuzzleCardKind.completed;

    final Color bgColor;
    final Color textColor;
    final Color borderColor;
    final double borderWidth;

    if (isCompleted) {
      bgColor = const Color(0xFFDDF3E7);
      textColor = const Color(0xFF1B6A46);
      borderColor = const Color(0xFFC7E5D4);
      borderWidth = 1.0;
    } else if (isInProgress) {
      bgColor = const Color(0xFFEAF3FB);
      textColor = const Color(0xFF2E6B99);
      borderColor = const Color(0xFF97B9D6);
      borderWidth = isRecent ? 1.6 : 1.2;
    } else {
      bgColor = AppColors.surface;
      textColor = const Color(0xFF6C6C6C);
      borderColor = AppColors.border;
      borderWidth = 1.0;
    }

    final progressPct = isInProgress ? _savedProgressPercent(gameNumber) : 0;

    const baseShadow = BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 5,
      offset: Offset(0, 1),
    );
    final List<BoxShadow> shadow = [
      baseShadow,
      if (isRecent)
        BoxShadow(
            color: const Color(0xFF4E7FAD).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 1.5)),
      if (isCompleted)
        BoxShadow(
            color: const Color(0xFF27865A).withValues(alpha: 0.06),
            blurRadius: 5,
            offset: const Offset(0, 1)),
    ];

    return _InteractiveTile(
      onTap: _isGameTransitioning
          ? null
          : () => _onGameSelected(gameNumber, widget.level),
      pulse: isInProgress,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadow,
        ),
        child: Stack(
          children: [
            Align(
              alignment: isInProgress
                  ? const Alignment(0, -0.15)
                  : const Alignment(0, -0.08),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gameNumber.toString().padLeft(3, '0'),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: isFresh
                          ? FontWeight.w400
                          : isCompleted
                              ? FontWeight.w700
                              : FontWeight.w500,
                      color: textColor,
                      letterSpacing: 0,
                      height: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (isInProgress || isCompleted)
                    Text(
                      isCompleted ? '100%' : '$progressPct%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            if (!isFresh)
              Positioned(
                top: 5,
                right: 5,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    _statusIcon(kind),
                    key: ValueKey(kind),
                    size: isCompleted ? 14 : 12,
                    color:
                        textColor.withValues(alpha: isCompleted ? 0.82 : 0.72),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Recent play banner ───────────────────────────────────────────────────

  Widget _buildRecentPlayBanner() {
    final levelName = widget.level.name;
    final recentNumber = _recentSavedGameNumber[levelName];
    if (recentNumber == null) return const SizedBox.shrink();
    if (_selectedFilter == _PuzzleFilter.fresh ||
        _selectedFilter == _PuzzleFilter.completed) {
      return const SizedBox.shrink();
    }
    final progressPct = _savedProgressPercent(recentNumber);
    if (progressPct <= 0 || progressPct >= 100) return const SizedBox.shrink();

    final timeLabel = _lastPlayedLabel(recentNumber);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isKo ? '최근 플레이' : 'Continue playing',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _InteractiveTile(
            onTap: _isGameTransitioning
                ? null
                : () => _onGameSelected(recentNumber, widget.level),
            pulse: false,
            child: Container(
              height: 68,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF97B9D6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4E7FAD).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 1.5),
                  ),
                  const BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recentNumber.toString().padLeft(3, '0'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C6FA8),
                            letterSpacing: 1.0,
                            height: 1.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFF4E7FAD).withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isKo ? '진행 중' : 'In progress',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C6FA8),
                            ),
                          ),
                          if (timeLabel.isNotEmpty)
                            Text(
                              timeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '$progressPct%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C6FA8).withValues(alpha: 0.9),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lastPlayedLabel(int gameNumber) {
    final saved = _savedGameStates[widget.level.name]?[gameNumber];
    if (saved == null) return '';
    final diffMs =
        DateTime.now().millisecondsSinceEpoch - saved.lastPlayedAtMillis;
    final days = (diffMs / 86400000).floor();
    if (_isKo) {
      if (days == 0) return '오늘';
      if (days == 1) return '어제';
      return '$days일 전';
    }
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    return '${days}d ago';
  }

  // ─── Status styling ───────────────────────────────────────────────────────

  IconData _statusIcon(_PuzzleCardKind kind) {
    switch (kind) {
      case _PuzzleCardKind.completed:
        return Icons.check_circle_rounded;
      case _PuzzleCardKind.recent:
      case _PuzzleCardKind.inProgress:
        return Icons.play_circle_rounded;
      case _PuzzleCardKind.fresh:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  Color _levelAccentColor(SudokuLevel level) {
    switch (level.difficulty) {
      case 1:
        return const Color(0xFF4EAD7C);
      case 2:
        return const Color(0xFF4EA8AD);
      case 3:
        return const Color(0xFFAD904E);
      case 4:
        return const Color(0xFFAD4E7C);
      case 5:
        return const Color(0xFF4E7FAD);
      default:
        return const Color(0xFF4EAD7C);
    }
  }

  IconData _levelIcon(SudokuLevel level) {
    switch (level.difficulty) {
      case 1:
        return Icons.eco_rounded;
      case 2:
        return Icons.local_fire_department_rounded;
      case 3:
        return Icons.star_rounded;
      case 4:
        return Icons.diamond_rounded;
      case 5:
        return Icons.emoji_events_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  Color _levelIconColor(SudokuLevel level) {
    switch (level.difficulty) {
      case 1:
        return const Color(0xFF4EAD7C);
      case 2:
        return const Color(0xFF4FA89F);
      case 3:
        return const Color(0xFFC4A05A);
      case 4:
        return const Color(0xFFC07898);
      case 5:
        return const Color(0xFFC9A227);
      default:
        return const Color(0xFF4EAD7C);
    }
  }

  // ─── Game logic helpers ───────────────────────────────────────────────────

  _PuzzleCardKind _puzzleCardKind(int gameNumber) {
    final levelName = widget.level.name;
    if (_isCleared(levelName, gameNumber)) return _PuzzleCardKind.completed;
    if (_savedGameStates[levelName]?.containsKey(gameNumber) ?? false) {
      if (_savedProgressPercent(gameNumber) <= 0) return _PuzzleCardKind.fresh;
      return _recentSavedGameNumber[levelName] == gameNumber
          ? _PuzzleCardKind.recent
          : _PuzzleCardKind.inProgress;
    }
    return _PuzzleCardKind.fresh;
  }

  List<int> _filteredGames(List<int> games) {
    return games.where((gameNumber) {
      switch (_selectedFilter) {
        case _PuzzleFilter.all:
          return true;
        case _PuzzleFilter.fresh:
          return _puzzleCardKind(gameNumber) == _PuzzleCardKind.fresh;
        case _PuzzleFilter.inProgress:
          final kind = _puzzleCardKind(gameNumber);
          return kind == _PuzzleCardKind.inProgress ||
              kind == _PuzzleCardKind.recent;
        case _PuzzleFilter.completed:
          return _puzzleCardKind(gameNumber) == _PuzzleCardKind.completed;
      }
    }).toList();
  }

  SudokuLevel _currentLevelInfo() {
    return _levels.firstWhere(
      (item) => item.name == widget.level.name,
      orElse: () => widget.level,
    );
  }

  int _savedProgressPercent(int gameNumber) {
    final saved = _savedGameStates[widget.level.name]?[gameNumber];
    if (saved == null) return 0;
    final filledCells =
        saved.board.expand((row) => row).where((cell) => cell != 0).length;
    final originalFilledCells = 81 - widget.level.emptyCells;
    final filledByPlayer =
        (filledCells - originalFilledCells).clamp(0, widget.level.emptyCells);
    if (widget.level.emptyCells == 0) return 0;
    return ((filledByPlayer / widget.level.emptyCells) * 100).round();
  }

  @override
  void dispose() {
    _gameCache.clear();
    _gameFutureCache.clear();
    _playGameCache.clear();
    _levelLoadStopwatch.clear();
    _clearedGameNumbers.clear();
    _savedGameStates.clear();
    _clearRecords.clear();
    _recentSavedGameNumber.clear();
    _puzzleMetadataFutureCache.clear();
    super.dispose();
  }

  void _retryLoadGames() {
    final levelName = widget.level.name;
    _gameFutureCache.remove(levelName);
    _puzzleMetadataFutureCache.remove(levelName);
    _gameCache.remove(levelName);
    _playGameCache.remove(levelName);
    _clearedGameNumbers.remove(levelName);
    _savedGameStates.remove(levelName);
    _clearRecords.remove(levelName);
    _recentSavedGameNumber.remove(levelName);
    _levelLoadStopwatch.remove(levelName);
    if (mounted) setState(() {});
  }

  Widget _buildStateMessage(
    String message, {
    bool showSpinner = false,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner) ...[
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 14),
            ] else if (icon != null) ...[
              Icon(icon, size: 28, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 10),
            ],
            Text(
              message,
              style:
                  TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Interactive tile wrapper ─────────────────────────────────────────────

class _InteractiveTile extends StatefulWidget {
  const _InteractiveTile(
      {required this.onTap, required this.child, this.pulse = false});

  final VoidCallback? onTap;
  final Widget child;
  final bool pulse;

  @override
  State<_InteractiveTile> createState() => _InteractiveTileState();
}

class _InteractiveTileState extends State<_InteractiveTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.pulse) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_InteractiveTile old) {
    super.didUpdateWidget(old);
    if (widget.pulse != old.pulse) {
      if (widget.pulse) {
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.pulse
            ? AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4E7FAD)
                            .withValues(alpha: 0.05 + _pulseAnim.value * 0.08),
                        blurRadius: 6 + _pulseAnim.value * 6,
                        spreadRadius: _pulseAnim.value,
                      ),
                    ],
                  ),
                  child: child!,
                ),
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }
}

// ─── Catalog status bar ────────────────────────────────────────────────────

class _CatalogStatusBar extends StatelessWidget {
  const _CatalogStatusBar({required this.status, required this.l10n});

  final PuzzleCatalogStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0D48A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, size: 16, color: Color(0xFFDA8B00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.levelCatalogPreparingShort(
                  status.totalGenerated, status.totalTarget),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A4C00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
