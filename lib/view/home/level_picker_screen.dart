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

/// 난이도 선택 화면
/// 사용자가 스도쿠 게임의 난이도를 선택할 수 있는 화면입니다.
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
  // 게임 데이터 캐시
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
    // 단일 진입 흐름: 홈 -> 특정 레벨 게임 목록
    _gamesFutureForLevel(widget.level.name);
    _puzzleMetadataFutureForLevel(widget.level.name);
  }

  /// 특정 난이도의 게임 목록을 로드합니다.
  /// 캐시된 데이터가 있으면 캐시에서 반환하고,
  /// 없으면 데이터베이스에서 로드하여 캐시에 저장합니다.
  Future<List<int>> _loadGames(String level) async {
    final sw = _levelLoadStopwatch.putIfAbsent(level, Stopwatch.new);
    if (!sw.isRunning) {
      sw
        ..reset()
        ..start();
    }
    if (!_clearedGameNumbers.containsKey(level)) {
      _loadClearedGameNumbers(level).then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
    if (_gameCache.containsKey(level)) {
      if (sw.isRunning) {
        sw.stop();
      }
      if (kDebugMode && sw.elapsedMilliseconds >= _perfLogThresholdMs) {
        debugPrint(
          '[perf] level_list(cache) level=$level count=${_gameCache[level]!.length} '
          'elapsed_ms=${sw.elapsedMilliseconds}',
        );
      }
      return _gameCache[level]!;
    }
    final gameNumbers = await _dbHelper.getGameNumbersForLevel(level);
    _gameCache[level] = gameNumbers;
    if (sw.isRunning) {
      sw.stop();
    }
    if (kDebugMode && sw.elapsedMilliseconds >= _perfLogThresholdMs) {
      debugPrint(
        '[perf] level_list(db) level=$level count=${gameNumbers.length} '
        'elapsed_ms=${sw.elapsedMilliseconds}',
      );
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
      if (kDebugMode && sw.elapsedMilliseconds >= _perfLogThresholdMs) {
        debugPrint(
          '[perf] game_entry(cache) level=$levelName game=$gameNumber '
          'elapsed_ms=${sw.elapsedMilliseconds}',
        );
      }
      return cached;
    }

    final levelInfo = SudokuLevel.levels.firstWhere(
      (item) => item.name == levelName,
      orElse: () => SudokuLevel.levels.first,
    );
    final entry = await _dbHelper.getGameEntry(levelName, gameNumber);
    if (entry == null) {
      sw.stop();
      if (kDebugMode && sw.elapsedMilliseconds >= _perfLogThresholdMs) {
        debugPrint(
          '[perf] game_entry(miss) level=$levelName game=$gameNumber '
          'elapsed_ms=${sw.elapsedMilliseconds}',
        );
      }
      return null;
    }

    final game = SudokuGame(
      board: entry['board'] as List<List<int>>,
      solution: entry['solution'] as List<List<int>>,
      emptyCells: levelInfo.emptyCells,
      levelName: levelName,
      gameNumber: gameNumber,
    );

    (_playGameCache[levelName] ??= <int, SudokuGame>{})[gameNumber] = game;
    sw.stop();
    if (kDebugMode && sw.elapsedMilliseconds >= _perfLogThresholdMs) {
      debugPrint(
        '[perf] game_entry(db) level=$levelName game=$gameNumber '
        'elapsed_ms=${sw.elapsedMilliseconds}',
      );
    }
    return game;
  }

  Future<void> _onGameSelected(int gameNumber, SudokuLevel level) async {
    if (_isGameTransitioning || !mounted) {
      return;
    }
    final kind = _puzzleCardKind(gameNumber);
    if (kind == _PuzzleCardKind.completed) {
      final shouldReplay = await _confirmReplayCompletedPuzzle();
      if (!mounted || shouldReplay != true) {
        return;
      }
    }

    setState(() {
      _isGameTransitioning = true;
    });
    final game = await _loadGameForPlay(level.name, gameNumber);
    if (!mounted) return;
    if (game == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.recordsGameLoadError)),
      );
      if (mounted) {
        setState(() {
          _isGameTransitioning = false;
        });
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
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );

      await _loadClearedGameNumbers(level.name);
      _puzzleMetadataFutureCache.remove(level.name);
      await _loadPuzzleMetadata(level.name);
      final currentLevel = _levels.firstWhere(
        (item) => item.name == level.name,
        orElse: () => level,
      );
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

      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGameTransitioning = false;
        });
      } else {
        _isGameTransitioning = false;
      }
    }
  }

  Future<bool?> _confirmReplayCompletedPuzzle() {
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isKorean ? '완료한 퍼즐을 다시 풀까요?' : 'Replay this puzzle?'),
          content: Text(
            isKorean
                ? '기존 완료 기록은 유지되며, 새 기록이 더 좋으면 갱신됩니다.'
                : 'Your completed record is kept, and it updates only if the new result is better.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(isKorean ? '취소' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isKorean ? '다시 풀기' : 'Replay'),
            ),
          ],
        );
      },
    );
  }

  bool _shouldRestoreSavedSession(_PuzzleCardKind kind) {
    return kind == _PuzzleCardKind.inProgress || kind == _PuzzleCardKind.recent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildGameSelectionAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<PuzzleCatalogStatus>(
              valueListenable: _databaseManager.catalogStatus,
              builder: (context, status, child) {
                if (!status.isRunning) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _CatalogStatusBar(
                    status: status,
                    l10n: AppLocalizations.of(context)!,
                  ),
                );
              },
            ),
            Expanded(
              child: isTablet
                  ? _buildGameSelectionTabletLayout(l10n)
                  : _buildGameSelectionMobileLayout(l10n),
            ),
          ],
        ),
      ),
    );
  }

  /// 게임 선택 화면용 앱바 위젯
  PreferredSizeWidget _buildGameSelectionAppBar() {
    return AppBar(
      toolbarHeight: 48,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// 게임 선택 화면용 태블릿 레이아웃
  Widget _buildGameSelectionTabletLayout(AppLocalizations l10n) {
    return _buildGameSelectionContent(l10n, horizontalPadding: 24);
  }

  /// 게임 선택 화면용 모바일 레이아웃
  Widget _buildGameSelectionMobileLayout(AppLocalizations l10n) {
    return _buildGameSelectionContent(l10n, horizontalPadding: 16);
  }

  Widget _buildGameSelectionContent(
    AppLocalizations l10n, {
    required double horizontalPadding,
  }) {
    _puzzleMetadataFutureForLevel(widget.level.name);
    return FutureBuilder<List<int>>(
      future: _gamesFutureForLevel(widget.level.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildGameListStateMessage(
            l10n.levelLoadingGames,
            showSpinner: true,
          );
        }
        if (snapshot.hasError) {
          return _buildGameListStateMessage(
            l10n.recordsGameLoadError,
            icon: Icons.error_outline_rounded,
            actionLabel: _retryLabel(context),
            onAction: _retryLoadGames,
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildGameListStateMessage(
            _emptyGamesMessage(l10n),
            icon: Icons.inbox_outlined,
          );
        }

        final games = snapshot.data!;
        final filteredGames = _filteredGames(games);
        final bottomPadding = MediaQuery.paddingOf(context).bottom + 32;
        return Padding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLevelProgressStrip(l10n, totalCount: games.length),
              const SizedBox(height: 18),
              _buildPuzzleListHeader(l10n, totalCount: games.length),
              const SizedBox(height: 8),
              _buildFilterChips(),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.34,
                  ),
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    return _buildGameSelectionCard(filteredGames[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameListStateMessage(
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner) ...[
                const CircularProgressIndicator(strokeWidth: 2.2),
                const SizedBox(height: 14),
              ] else if (icon != null) ...[
                Icon(icon, size: 28, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 10),
              ],
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  SudokuLevel _currentLevelInfo() {
    return _levels.firstWhere(
      (item) => item.name == widget.level.name,
      orElse: () => widget.level,
    );
  }

  String _emptyGamesMessage(AppLocalizations l10n) {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '선택 가능한 게임이 없습니다.'
        : 'No puzzles are available for this level.';
  }

  String _retryLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '다시 시도'
        : 'Try again';
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
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildLevelProgressStrip(
    AppLocalizations l10n, {
    required int totalCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = _currentLevelInfo();
    final cleared = _clearedGameNumbers[level.name]?.length ?? 0;
    final progress = totalCount == 0 ? 0.0 : cleared / totalCount;
    final visibleProgress = progress > 0 ? progress.clamp(0.015, 1.0) : 0.0;
    final progressPercent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level.localizedName(l10n),
          style: const TextStyle(
            fontSize: 23,
            height: 1.08,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              _completedInlineLabel(cleared, totalCount),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '$progressPercent%',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: visibleProgress,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getLevelColor(level).withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzleListHeader(
    AppLocalizations l10n, {
    required int totalCount,
  }) {
    return Row(
      children: [
        Text(
          l10n.levelPuzzlesSectionTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          l10n.levelPuzzleCountSummary(totalCount),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    const filters = _PuzzleFilter.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            _buildFilterChip(filter),
            if (filter != filters.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(_PuzzleFilter filter) {
    final isSelected = _selectedFilter == filter;
    return SizedBox(
      height: 38,
      child: ChoiceChip(
        label: Text(_filterLabel(filter)),
        selected: isSelected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(
          color: isSelected ? AppColors.textPrimary : AppColors.border,
        ),
        selectedColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (_) {
          setState(() {
            _selectedFilter = filter;
          });
        },
      ),
    );
  }

  String _completedInlineLabel(int cleared, int total) {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '$cleared / $total 완료'
        : '$cleared / $total completed';
  }

  String _filterLabel(_PuzzleFilter filter) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    switch (filter) {
      case _PuzzleFilter.all:
        return isKo ? '전체' : 'All';
      case _PuzzleFilter.fresh:
        return isKo ? '새 퍼즐' : 'New';
      case _PuzzleFilter.inProgress:
        return isKo ? '진행 중' : 'In progress';
      case _PuzzleFilter.completed:
        return isKo ? '완료' : 'Done';
    }
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

  /// 게임 선택용 카드 위젯
  Widget _buildGameSelectionCard(int gameNumber) {
    final kind = _puzzleCardKind(gameNumber);
    final isCleared = kind == _PuzzleCardKind.completed;
    final isInProgress = _isInProgressKind(kind);
    final supportingLabel = _puzzleSecondLineLabel(gameNumber, kind);
    return _GameCardFrame(
      deemphasized: isCleared,
      highlighted: isInProgress,
      isEnabled: !_isGameTransitioning,
      onTap: () async {
        await _onGameSelected(gameNumber, widget.level);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _compactGameNumberLabel(gameNumber),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isInProgress)
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                )
              else if (isCleared)
                const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: Color(0xFF6F8F82),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            supportingLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ],
      ),
    );
  }

  _PuzzleCardKind _puzzleCardKind(int gameNumber) {
    final levelName = widget.level.name;
    if (_isCleared(levelName, gameNumber)) {
      return _PuzzleCardKind.completed;
    }
    if (_savedGameStates[levelName]?.containsKey(gameNumber) ?? false) {
      if (_savedProgressPercent(gameNumber) <= 0) {
        return _PuzzleCardKind.fresh;
      }
      return _recentSavedGameNumber[levelName] == gameNumber
          ? _PuzzleCardKind.recent
          : _PuzzleCardKind.inProgress;
    }
    return _PuzzleCardKind.fresh;
  }

  bool _isInProgressKind(_PuzzleCardKind kind) {
    return kind == _PuzzleCardKind.inProgress || kind == _PuzzleCardKind.recent;
  }

  String _compactGameNumberLabel(int gameNumber) {
    return '#${gameNumber.toString().padLeft(3, '0')}';
  }

  String _puzzleSecondLineLabel(
    int gameNumber,
    _PuzzleCardKind kind,
  ) {
    switch (kind) {
      case _PuzzleCardKind.fresh:
        return '0%';
      case _PuzzleCardKind.recent:
      case _PuzzleCardKind.inProgress:
        return '${_savedProgressPercent(gameNumber)}%';
      case _PuzzleCardKind.completed:
        final seconds = (_clearRecords[widget.level.name]?[gameNumber]
                ?['clear_time'] as num?)
            ?.toInt();
        return seconds == null ? '--:--' : _formatShortDuration(seconds);
    }
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

  String _formatShortDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 난이도별 색상 반환
  Color _getLevelColor(SudokuLevel level) {
    switch (level.difficulty) {
      case 1:
        return const Color(0xFFBFE2D0);
      case 2:
        return const Color(0xFFCDE7E0);
      case 3:
        return const Color(0xFFE6D4B8);
      case 4:
        return const Color(0xFFE6B8C8);
      case 5:
        return const Color(0xFFB8D4E6);
      default:
        return const Color(0xFFBFE2D0);
    }
  }
}

class _CatalogStatusBar extends StatelessWidget {
  const _CatalogStatusBar({
    required this.status,
    required this.l10n,
  });

  final PuzzleCatalogStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0D48A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, color: Color(0xFFDA8B00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.levelCatalogPreparingShort(
                status.totalGenerated,
                status.totalTarget,
              ),
              style: const TextStyle(
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

class _GameCardFrame extends StatelessWidget {
  const _GameCardFrame({
    required this.onTap,
    required this.child,
    required this.isEnabled,
    this.deemphasized = false,
    this.highlighted = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool isEnabled;
  final bool deemphasized;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF7FAF8) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              highlighted ? const Color(0xFFD2E3D8) : const Color(0xFFE0E0DD),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: deemphasized ? 0.045 : 0.065),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: isEnabled ? 1 : 0.72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
