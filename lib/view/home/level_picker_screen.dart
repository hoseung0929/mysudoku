import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/database/database_manager.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/navigation/app_page_route.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/services/home/level_progress_service.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
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
  static const int _maxInProgressPuzzles = 5;
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

      // 실제로 한 칸이라도 채운 퍼즐만 "최근 플레이" 후보로 삼는다.
      // (열어보기만 하고 아무것도 안 채운 세션이 최근 것을 밀어내지 않도록)
      final filledCells =
          saved.board.expand((row) => row).where((cell) => cell != 0).length;
      final originalFilledCells = 81 - widget.level.emptyCells;
      final filledByPlayer =
          (filledCells - originalFilledCells).clamp(0, widget.level.emptyCells);
      if (filledByPlayer <= 0) continue;

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
    if (kind == _PuzzleCardKind.fresh &&
        _inProgressGameNumbers().length >= _maxInProgressPuzzles) {
      final picked = await _showInProgressLimitDialog();
      if (!mounted || picked == null) return;
      return _onGameSelected(picked, level);
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
        buildAppPageRoute(
          builder: (context) => SudokuGameScreen(
            game: game,
            level: level,
            restoreSavedSession: _shouldRestoreSavedSession(kind),
          ),
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
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.levelReplayTitle),
          content: Text(l10n.levelReplayBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.levelReplayConfirm),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _showInProgressLimitDialog() {
    final inProgressNumbers = _inProgressGameNumbers();
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final mascotImage = _levelImage(_currentLevelInfo());
        final colors = LevelStatusPalette.of(dialogContext);
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mascotImage != null) ...[
                Image.asset(mascotImage, width: 56, height: 56),
                const SizedBox(height: 8),
              ],
              Text(
                l10n.levelInProgressLimitTitle(inProgressNumbers.length),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryText,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    l10n.levelInProgressLimitBody(_maxInProgressPuzzles),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.secondaryText),
                  ),
                ),
                const SizedBox(height: 12),
                for (final number in inProgressNumbers) ...[
                  _buildContinueRow(
                    number,
                    onTap: () => Navigator.of(dialogContext).pop(number),
                  ),
                  if (number != inProgressNumbers.last)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.levelInProgressLimitLater),
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
      backgroundColor: LevelStatusPalette.of(context).screenBackground,
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
    final colors = LevelStatusPalette.of(context);
    return AppBar(
      toolbarHeight: 52,
      backgroundColor: colors.screenBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
        color: colors.primaryText,
      ),
      title: Text(
        level.localizedName(l10n),
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: colors.primaryText,
        ),
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
            actionLabel: AppLocalizations.of(context)!.levelTryAgain,
            onAction: _retryLoadGames,
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          final lc = Localizations.localeOf(context).languageCode;
          return _buildStateMessage(
            lc == 'ko'
                ? '선택 가능한 게임이 없습니다.'
                : lc == 'ja'
                    ? 'このレベルのパズルがありません。'
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
              child: _buildProgressCard(totalCount: games.length),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFilterChips(),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: filteredGames.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.levelNoResults,
                        style: TextStyle(
                          fontSize: 14,
                          color: LevelStatusPalette.of(context).disabledText,
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

  // ─── Progress card ────────────────────────────────────────────────────────

  Widget _buildProgressCard({required int totalCount}) {
    final level = _currentLevelInfo();
    final l10n = AppLocalizations.of(context)!;
    final message = l10n.levelProgressCardMessage(level.localizedName(l10n));
    final accentColor = _levelAccentColor(level);
    final inProgressNumbers = _inProgressGameNumbers();
    final colors = LevelStatusPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_levelImage(level) != null)
                Image.asset(
                  _levelImage(level)!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                )
              else
                Icon(_levelIcon(level), size: 48, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProgressStrip(totalCount: totalCount),
                  ],
                ),
              ),
            ],
          ),
          if (inProgressNumbers.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final number in inProgressNumbers) ...[
              _buildContinueRow(number),
              if (number != inProgressNumbers.last) const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildContinueRow(int recentNumber, {VoidCallback? onTap}) {
    final colors = LevelStatusPalette.of(context);
    final inProgressColor = colors.inProgressPrimary;
    final l10n = AppLocalizations.of(context)!;
    final progressPct = _savedProgressPercent(recentNumber);
    final timeLabel = _lastPlayedLabel(recentNumber);

    return _InteractiveTile(
      onTap: _isGameTransitioning
          ? null
          : onTap ?? () => _onGameSelected(recentNumber, widget.level),
      pulse: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.inProgressBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.play_arrow_rounded, size: 16, color: inProgressColor),
            const SizedBox(width: 7),
            Text(
              recentNumber.toString().padLeft(3, '0'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: inProgressColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.levelStatusInProgress,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: inProgressColor,
              ),
            ),
            const Spacer(),
            if (timeLabel.isNotEmpty) ...[
              Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '$progressPct%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: inProgressColor,
              ),
            ),
          ],
        ),
      ),
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
    final colors = LevelStatusPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: colors.secondaryText,
                ),
                children: [
                  TextSpan(
                    text: '$cleared',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.primaryPurple,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' ${AppLocalizations.of(context)!.levelProgressCompleted(totalCount)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '$progressPercent%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primaryPurple,
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
            backgroundColor: colors.progressTrack,
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
    final colors = LevelStatusPalette.of(context);
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.filterSelectedBackground
              : colors.cardBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected ? colors.filterSelectedBorder : colors.defaultBorder,
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
                  ? colors.primaryPurple
                  : colors.filterUnselectedText,
            ),
          ),
        ),
      ),
    );
  }

  String _filterLabel(_PuzzleFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    switch (filter) {
      case _PuzzleFilter.all:
        return l10n.levelFilterAll;
      case _PuzzleFilter.fresh:
        return l10n.levelFilterNew;
      case _PuzzleFilter.inProgress:
        return l10n.levelFilterInProgress;
      case _PuzzleFilter.completed:
        return l10n.levelFilterDone;
    }
  }

  // ─── Puzzle grid ──────────────────────────────────────────────────────────

  static const int _gridCols = 4;
  static const double _cellGap = 3.0;
  static const double _groupGap = 6.0;
  static const int _rowsPerGroup = 3;

  Widget _buildPuzzleGrid(List<int> games, double bottomPadding) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - 32;
        final cols = _gridColumnsForWidth(contentWidth);
        final totalRows = (games.length / cols).ceil();
        final rows = <Widget>[];

        for (int r = 0; r < totalRows; r++) {
          final start = r * cols;
          final end = (start + cols).clamp(0, games.length);
          final rowGames = games.sublist(start, end);

          rows.add(Row(
            children: [
              for (int c = 0; c < cols; c++) ...[
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.52,
                    child: c < rowGames.length
                        ? _buildPuzzleCell(rowGames[c])
                        : const SizedBox(),
                  ),
                ),
                if (c < cols - 1) const SizedBox(width: _cellGap),
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
      },
    );
  }

  // 태블릿 폭에서 카드가 헐렁하게 늘어나지 않도록 컬럼 수를 넓힌다.
  int _gridColumnsForWidth(double contentWidth) {
    if (contentWidth >= 900) return 8;
    if (contentWidth >= 600) return 6;
    return _gridCols;
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
    final Color iconColor;
    final Color borderColor;
    final double borderWidth;
    final colors = LevelStatusPalette.of(context);
    final accentColor = _levelAccentColor(_currentLevelInfo());

    if (isCompleted) {
      bgColor = colors.completedBackground;
      textColor = colors.completedNumberText;
      iconColor = accentColor;
      borderColor = colors.completedBorder;
      borderWidth = 1.0;
    } else if (isInProgress) {
      // 상단 "이어서 풀기" 배너와 동일한 파란 팔레트로 통일 (레벨 accent색과 무관하게 고정).
      final inProgressColor = colors.inProgressPrimary;
      bgColor = colors.inProgressBackground;
      textColor = inProgressColor;
      iconColor = inProgressColor;
      borderColor = colors.inProgressBorder;
      borderWidth = LevelStatusColors.inProgressBorderWidth;
    } else {
      bgColor = colors.cardBackground;
      textColor = colors.primaryText;
      iconColor = textColor.withValues(alpha: 0.55);
      borderColor = colors.defaultBorder;
      borderWidth = 1.0;
    }

    final progressPct = isInProgress ? _savedProgressPercent(gameNumber) : 0;
    final clearTimeLabel = isCompleted ? _clearTimeLabel(gameNumber) : null;

    const baseShadow = BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 5,
      offset: Offset(0, 1),
    );
    final List<BoxShadow> shadow = [
      baseShadow,
      if (isRecent)
        BoxShadow(
            color: colors.inProgressPrimary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 1.5)),
      if (isCompleted)
        BoxShadow(
            color: colors.primaryPurple.withValues(alpha: 0.06),
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
              alignment: (isInProgress || clearTimeLabel != null)
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
                  if (isInProgress)
                    Text(
                      isRecent
                          ? '${AppLocalizations.of(context)!.levelRecentBadge} · $progressPct%'
                          : '$progressPct%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isRecent ? FontWeight.w700 : FontWeight.w500,
                        color: colors.inProgressPrimary,
                        height: 1.4,
                      ),
                    ),
                  if (clearTimeLabel != null)
                    Text(
                      clearTimeLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: colors.secondaryText,
                        height: 1.4,
                        fontFeatures: const [FontFeature.tabularFigures()],
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
                    size: isCompleted
                        ? LevelStatusColors.completedCheckIconSize
                        : 12,
                    color: isCompleted
                        ? iconColor.withValues(
                            alpha: LevelStatusColors.completedCheckIconOpacity)
                        : iconColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _lastPlayedLabel(int gameNumber) {
    final saved = _savedGameStates[widget.level.name]?[gameNumber];
    if (saved == null) return '';
    final diffMs =
        DateTime.now().millisecondsSinceEpoch - saved.lastPlayedAtMillis;
    final days = (diffMs / 86400000).floor();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ko') {
      if (days == 0) return '오늘';
      if (days == 1) return '어제';
      return '$days일 전';
    }
    if (languageCode == 'ja') {
      if (days == 0) return '今日';
      if (days == 1) return '昨日';
      return '$days日前';
    }
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    return '${days}d ago';
  }

  // ─── Status styling ───────────────────────────────────────────────────────

  IconData _statusIcon(_PuzzleCardKind kind) {
    switch (kind) {
      case _PuzzleCardKind.completed:
        return Icons.check_rounded;
      case _PuzzleCardKind.recent:
      case _PuzzleCardKind.inProgress:
        return Icons.play_arrow_rounded;
      case _PuzzleCardKind.fresh:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  // 마스코트 이미지가 레벨과 무관하게 항상 보라색이라, 화면 전체 accent도 통일.
  Color _levelAccentColor(SudokuLevel level) {
    return LevelStatusPalette.of(context).primaryPurple;
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

  String? _levelImage(SudokuLevel level) {
    switch (level.difficulty) {
      case 1:
        return 'assets/images/level1.png';
      case 2:
        return 'assets/images/level2.png';
      case 3:
        return 'assets/images/level3.png';
      case 4:
        return 'assets/images/level4.png';
      default:
        return null;
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

  List<int> _inProgressGameNumbers() {
    final saved = _savedGameStates[widget.level.name];
    if (saved == null || saved.isEmpty) return const [];
    final entries = saved.entries.where((entry) {
      final pct = _savedProgressPercent(entry.key);
      return pct > 0 && pct < 100;
    }).toList()
      ..sort((a, b) =>
          b.value.lastPlayedAtMillis.compareTo(a.value.lastPlayedAtMillis));
    return entries.map((entry) => entry.key).toList();
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

  String? _clearTimeLabel(int gameNumber) {
    final clearTime =
        (_clearRecords[widget.level.name]?[gameNumber]?['clear_time'] as num?)
            ?.toInt();
    if (clearTime == null) return null;
    final hours = clearTime ~/ 3600;
    final minutes = (clearTime % 3600) ~/ 60;
    final seconds = clearTime % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
                        color: LevelStatusPalette.of(context)
                            .inProgressPrimary
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerLow : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6B4F00).withValues(alpha: 0.6)
              : const Color(0xFFF0D48A),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, size: 16, color: Color(0xFFDA8B00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.levelCatalogPreparingShort(
                  status.totalGenerated, status.totalTarget),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFEED280) : const Color(0xFF6A4C00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
