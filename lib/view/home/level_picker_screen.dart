import 'package:flutter/material.dart';
import 'package:sudoku159/widgets/press_scale.dart';
import 'package:flutter/foundation.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/database/database_manager.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/navigation/app_page_route.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/services/home/level_progress_service.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/utils/time_format.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';

enum _PuzzleFilter { all, fresh, inProgress, completed }

enum _PuzzleCardKind { fresh, recent, inProgress, completed }

class LevelPickerScreen extends StatefulWidget {
  final SudokuLevel level;

  /// 테스트에서 저장소를 대체하기 위한 선택적 주입. 기본값은 실제 구현.
  final DatabaseHelper? databaseHelper;
  final GameStateService? gameStateService;
  final LevelProgressService? levelProgressService;

  const LevelPickerScreen({
    super.key,
    required this.level,
    this.databaseHelper,
    this.gameStateService,
    this.levelProgressService,
  });

  @override
  State<LevelPickerScreen> createState() => _LevelPickerScreenState();
}

class _LevelPickerScreenState extends State<LevelPickerScreen> {
  static const int _perfLogThresholdMs = 120;
  static const int _maxInProgressPuzzles = 5;
  final DatabaseManager _databaseManager = DatabaseManager();
  late final LevelProgressService _levelProgressService =
      widget.levelProgressService ?? LevelProgressService();
  late final GameStateService _gameStateService =
      widget.gameStateService ?? GameStateService();
  late final DatabaseHelper _dbHelper =
      widget.databaseHelper ?? DatabaseHelper();
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
  bool _selectionInFlight = false;
  // 저장 상태(진행 중·완료 기록) 로딩이 끝난 레벨. 끝나기 전에는 목록·시작 버튼을
  // 확정 표시하지 않는다.
  final Set<String> _metadataReady = <String>{};
  final Set<String> _metadataFailed = <String>{};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _filterKey = GlobalKey();

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
    try {
      await _loadPuzzleMetadataUnsafe(levelName);
      _metadataFailed.remove(levelName);
      _metadataReady.add(levelName);
    } catch (e) {
      if (kDebugMode) debugPrint('[level_picker] metadata load failed: $e');
      if (!_metadataReady.contains(levelName)) _metadataFailed.add(levelName);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadPuzzleMetadataUnsafe(String levelName) async {
    final savedGames = await _gameStateService.getSavedGames();
    final savedForLevel = <int, SavedGameState>{};
    int? recentGameNumber;
    var latestMillis = -1;

    for (final saved in savedGames) {
      if (saved.levelName != levelName) continue;
      // 이어할 수 있는 세션(입력·메모 흔적이 있는 미완료 세션)만 등록한다.
      // 열어보기만 한 세션이 최근 이어하기를 밀어내지 않고, 완료 기록보다
      // 재도전 세션이 우선하도록 이 기준을 카드 분류에 그대로 쓴다.
      if (!_isResumable(saved)) continue;
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
    // 저장 상태 로딩 전에는 잘못된 판정으로 시작하지 않고, 연타로 화면/다이얼로그가
    // 중복으로 열리지 않게 한다.
    if (_selectionInFlight || !_metadataReady.contains(level.name)) return;
    _selectionInFlight = true;
    try {
      await _startGame(gameNumber, level);
    } finally {
      _selectionInFlight = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _startGame(int gameNumber, SudokuLevel level) async {
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
      return _startGame(picked, level);
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
    final levelName = widget.level.name;
    _puzzleMetadataFutureForLevel(levelName);
    return FutureBuilder<List<int>>(
      future: _gamesFutureForLevel(levelName),
      builder: (context, snapshot) {
        if (snapshot.hasError || _metadataFailed.contains(levelName)) {
          return _buildStateMessage(
            l10n.recordsGameLoadError,
            icon: Icons.error_outline_rounded,
            actionLabel: l10n.levelTryAgain,
            onAction: _retryLoadGames,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting ||
            !_metadataReady.contains(levelName)) {
          return _buildStateMessage(l10n.levelLoadingGames, showSpinner: true);
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

        final games = [...snapshot.data!]..sort();
        final filteredGames = _filteredGames(games);
        final bottomPadding = MediaQuery.paddingOf(context).bottom + 24;
        final inProgress = _inProgressGameNumbers();
        final recentNumber = _recentSavedGameNumber[levelName];
        final nextFresh = _nextFreshGameNumber(games);
        final allCompleted = games.every((g) => _isCleared(levelName, g));

        return LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth - 32;
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final cols = _gridColumnsForWidth(contentWidth, textScale);
            final totalRows = (filteredGames.length / cols).ceil();
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummary(totalCount: games.length),
                        if (recentNumber != null &&
                            _savedGameStates[levelName]
                                    ?.containsKey(recentNumber) ==
                                true) ...[
                          const SizedBox(height: 10),
                          _buildRecentCard(recentNumber, inProgress.length),
                        ],
                        if (nextFresh != null) ...[
                          const SizedBox(height: 8),
                          _buildStartNewButton(
                            nextFresh,
                            primary: inProgress.isEmpty,
                          ),
                        ] else if (allCompleted) ...[
                          const SizedBox(height: 8),
                          _buildInfoLine(l10n.levelAllCompleted),
                        ],
                        const SizedBox(height: 10),
                        KeyedSubtree(
                          key: _filterKey,
                          child: _buildFilterChips(games),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (filteredGames.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildFilterEmptyState(
                      games,
                      nextFresh: nextFresh,
                      allCompleted: allCompleted,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, r) {
                          final start = r * cols;
                          final end =
                              (start + cols).clamp(0, filteredGames.length);
                          final rowGames = filteredGames.sublist(start, end);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: r < totalRows - 1
                                  ? ((r + 1) % _rowsPerGroup == 0
                                      ? _groupGap
                                      : _cellGap)
                                  : 0,
                            ),
                            child: Row(
                              children: [
                                for (int c = 0; c < cols; c++) ...[
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio:
                                          textScale > 1.15 ? 1.2 : 1.52,
                                      child: c < rowGames.length
                                          ? _buildPuzzleCell(rowGames[c])
                                          : const SizedBox(),
                                    ),
                                  ),
                                  if (c < cols - 1)
                                    const SizedBox(width: _cellGap),
                                ],
                              ],
                            ),
                          );
                        },
                        childCount: totalRows,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// 현재 난이도의 새 퍼즐 중 번호가 가장 앞선 것: 미완료이고 이어할 세션이 없는 문제.
  int? _nextFreshGameNumber(List<int> sortedGames) {
    for (final number in sortedGames) {
      if (_puzzleCardKind(number) == _PuzzleCardKind.fresh) return number;
    }
    return null;
  }

  void _selectFilter(_PuzzleFilter filter, {bool scrollToFilter = false}) {
    setState(() => _selectedFilter = filter);
    if (!scrollToFilter) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _filterKey.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0,
      );
    });
  }

  /// 진행 중 개수 제한 다이얼로그 안의 한 줄.
  Widget _buildContinueRow(int recentNumber, {VoidCallback? onTap}) {
    final colors = LevelStatusPalette.of(context);
    final inProgressColor = colors.inProgressPrimary;
    final l10n = AppLocalizations.of(context)!;
    final progressPct = _savedProgressPercent(recentNumber);
    final timeLabel = _lastPlayedLabel(recentNumber);

    return _InteractiveTile(
      onTap: onTap,
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
            Flexible(
              child: Text(
                l10n.levelStatusInProgress,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: inProgressColor,
                ),
              ),
            ),
            const Spacer(),
            if (timeLabel.isNotEmpty) ...[
              Text(
                timeLabel,
                style: TextStyle(fontSize: 11, color: colors.secondaryText),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              progressPct > 0 ? '$progressPct%' : l10n.gameMemoShort,
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

  // ─── Summary / continue / start ───────────────────────────────────────────

  Widget _buildSummary({required int totalCount}) {
    final level = _currentLevelInfo();
    final l10n = AppLocalizations.of(context)!;
    final colors = LevelStatusPalette.of(context);
    final cleared = _clearedGameNumbers[level.name]?.length ?? 0;
    final progress = totalCount == 0 ? 0.0 : cleared / totalCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.defaultBorder),
      ),
      child: Row(
        children: [
          if (_levelImage(level) != null)
            Image.asset(_levelImage(level)!, width: 36, height: 36)
          else
            Icon(_levelIcon(level), size: 36, color: _levelAccentColor(level)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 13, color: colors.secondaryText),
                    children: [
                      TextSpan(
                        text: '$cleared',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.primaryPurple,
                        ),
                      ),
                      TextSpan(
                        text: ' ${l10n.levelProgressCompleted(totalCount)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    backgroundColor: colors.progressTrack,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _levelAccentColor(level),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String text) {
    final colors = LevelStatusPalette.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, color: colors.secondaryText),
    );
  }

  /// 진행 상태 한 줄 설명: "62%" 또는 메모만 있으면 "메모 작성 중".
  String _progressDetail(int gameNumber) {
    final l10n = AppLocalizations.of(context)!;
    final pct = _savedProgressPercent(gameNumber);
    return pct > 0 ? '$pct%' : l10n.levelNotesInProgress;
  }

  Widget _buildRecentCard(int number, int inProgressCount) {
    final colors = LevelStatusPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final timeLabel = _lastPlayedLabel(number);
    final detail = [
      _progressDetail(number),
      if (timeLabel.isNotEmpty) timeLabel,
    ].join(' · ');
    final busy = _isGameTransitioning || _selectionInFlight;
    // 큰 글씨에서는 버튼을 아래로 내려 좁은 화면에서도 잘리지 않게 한다.
    final stacked = MediaQuery.textScalerOf(context).scale(1.0) > 1.3;
    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '#${number.toString().padLeft(3, '0')}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.inProgressPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          detail,
          maxLines: stacked ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colors.secondaryText),
        ),
      ],
    );
    final continueButton = FilledButton(
      onPressed: busy ? null : () => _onGameSelected(number, widget.level),
      style: FilledButton.styleFrom(
        backgroundColor: colors.inProgressPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(l10n.levelContinueButton),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: colors.inProgressBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.inProgressBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked) ...[
            infoColumn,
            const SizedBox(height: 8),
            continueButton,
          ] else
            Row(
              children: [
                Expanded(child: infoColumn),
                const SizedBox(width: 8),
                continueButton,
              ],
            ),
          if (inProgressCount > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _selectFilter(
                  _PuzzleFilter.inProgress,
                  scrollToFilter: true,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: colors.inProgressPrimary,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(l10n.levelViewInProgress(inProgressCount)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartNewButton(int number, {required bool primary}) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LevelStatusPalette.of(context);
    final busy = _isGameTransitioning || _selectionInFlight;
    final label = l10n.levelStartNextNew(number.toString().padLeft(3, '0'));
    final onPressed = busy ? null : () => _onGameSelected(number, widget.level);
    const minSize = Size.fromHeight(48);
    return primary
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primaryPurple,
              // 다크 모드의 연한 보라 배경 위에서 흰 글씨는 대비가 낮다.
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1440)
                  : Colors.white,
              minimumSize: minSize,
            ),
            child: Text(label, textAlign: TextAlign.center),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primaryPurple,
              minimumSize: minSize,
            ),
            child: Text(label, textAlign: TextAlign.center),
          );
  }

  // ─── Filter chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips(List<int> games) {
    // 가로 스크롤 대신 줄바꿈: 개수·긴 번역이 붙어도 칩이 화면 밖으로 숨지 않는다.
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final filter in _PuzzleFilter.values)
          _buildFilterChip(filter, _filteredGamesFor(filter, games).length),
      ],
    );
  }

  Widget _buildFilterChip(_PuzzleFilter filter, int count) {
    final isSelected = _selectedFilter == filter;
    final colors = LevelStatusPalette.of(context);
    final label = '${_filterLabel(filter)} $count';
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _selectFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.filterSelectedBackground
                : colors.cardBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? colors.filterSelectedBorder
                  : colors.defaultBorder,
              width: 1,
            ),
          ),
          child: Center(
            // 칩이 줄 전체 폭으로 늘어나지 않고 글자 폭에 맞게 줄바꿈되도록 한다.
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 1,
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

  // ─── Empty states ─────────────────────────────────────────────────────────

  Widget _buildFilterEmptyState(
    List<int> games, {
    required int? nextFresh,
    required bool allCompleted,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LevelStatusPalette.of(context);
    final String message;
    final actions = <Widget>[];

    Widget filterAction(String label, _PuzzleFilter filter) => TextButton(
          onPressed: () => _selectFilter(filter),
          child: Text(label),
        );
    Widget startAction() => FilledButton(
          onPressed: _isGameTransitioning || _selectionInFlight
              ? null
              : () => _onGameSelected(nextFresh!, widget.level),
          child: Text(l10n.levelStartNextNew(
            nextFresh!.toString().padLeft(3, '0'),
          )),
        );
    final hasInProgress = _inProgressGameNumbers().isNotEmpty;

    switch (_selectedFilter) {
      case _PuzzleFilter.inProgress:
        message = l10n.levelEmptyInProgress;
        if (nextFresh != null) {
          actions.add(startAction());
          actions
              .add(filterAction(l10n.levelActionShowNew, _PuzzleFilter.fresh));
        } else {
          actions.add(filterAction(l10n.levelActionShowAll, _PuzzleFilter.all));
        }
      case _PuzzleFilter.completed:
        message = l10n.levelEmptyCompleted;
        if (nextFresh != null) {
          actions.add(startAction());
        } else if (hasInProgress) {
          actions.add(filterAction(
              l10n.levelActionShowInProgress, _PuzzleFilter.inProgress));
        } else {
          actions.add(filterAction(l10n.levelActionShowAll, _PuzzleFilter.all));
        }
      case _PuzzleFilter.fresh:
        message = allCompleted ? l10n.levelAllCompleted : l10n.levelEmptyFresh;
        if (hasInProgress) {
          actions.add(filterAction(
              l10n.levelActionShowInProgress, _PuzzleFilter.inProgress));
        }
        actions.add(filterAction(l10n.levelActionShowAll, _PuzzleFilter.all));
      case _PuzzleFilter.all:
        message = l10n.levelNoResults;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.secondaryText),
          ),
          const SizedBox(height: 8),
          ...actions,
        ],
      ),
    );
  }

  // ─── Puzzle grid ──────────────────────────────────────────────────────────

  static const int _gridCols = 4;
  static const double _cellGap = 6.0;
  static const double _groupGap = 8.0;
  static const int _rowsPerGroup = 3;

  // 태블릿 폭에서 카드가 헐렁하게 늘어나지 않도록 컬럼 수를 넓히고, 폰에서는
  // 4열을 유지하되 매우 좁거나 큰 글씨일 때만 3열로 줄인다.
  int _gridColumnsForWidth(double contentWidth, double textScale) {
    if (contentWidth >= 900) return 8;
    if (contentWidth >= 600) return 6;
    if (textScale > 1.5 || contentWidth < 300) return 3;
    return _gridCols;
  }

  Widget _buildPuzzleCell(int gameNumber) {
    final l10n = AppLocalizations.of(context)!;
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

    final pct = isInProgress ? _savedProgressPercent(gameNumber) : 0;
    final notesOnly = isInProgress && pct == 0;
    final clearTimeLabel = isCompleted ? _clearTimeLabel(gameNumber) : null;
    final numberText = gameNumber.toString().padLeft(3, '0');
    final statusText = isCompleted
        ? l10n.levelFilterDone
        : isInProgress
            ? l10n.levelStatusInProgress
            : l10n.levelFilterNew;
    final semanticsDetail = isInProgress
        ? _progressDetail(gameNumber)
        : clearTimeLabel != null
            ? l10n.levelBestTime(clearTimeLabel)
            : null;
    final semanticsLabel = l10n.levelCellSemantics(
      numberText,
      semanticsDetail == null ? statusText : '$statusText, $semanticsDetail',
    );

    return Semantics(
      button: true,
      enabled: !(_isGameTransitioning || _selectionInFlight),
      label: semanticsLabel,
      excludeSemantics: true,
      child: _InteractiveTile(
        onTap: _isGameTransitioning || _selectionInFlight
            ? null
            : () => _onGameSelected(gameNumber, widget.level),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          numberText,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: isFresh
                                ? FontWeight.w400
                                : isCompleted
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            color: textColor,
                            height: 1.1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (isInProgress)
                          Text(
                            notesOnly ? l10n.gameMemoShort : '$pct%',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  isRecent ? FontWeight.w700 : FontWeight.w500,
                              color: colors.inProgressPrimary,
                              height: 1.4,
                            ),
                          ),
                        if (clearTimeLabel != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 11,
                                color: colors.secondaryText,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                clearTimeLabel,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: colors.secondaryText,
                                  height: 1.4,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isFresh)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(
                    notesOnly ? Icons.edit_note_rounded : _statusIcon(kind),
                    size: isCompleted
                        ? LevelStatusColors.completedCheckIconSize
                        : 12,
                    color: isCompleted
                        ? iconColor.withValues(
                            alpha: LevelStatusColors.completedCheckIconOpacity)
                        : iconColor,
                  ),
                ),
            ],
          ),
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
    if (languageCode == 'zh') {
      if (days == 0) return '今天';
      if (days == 1) return '昨天';
      return '$days天前';
    }
    if (languageCode == 'es') {
      if (days == 0) return 'hoy';
      if (days == 1) return 'ayer';
      return 'hace $days días';
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
    // 재도전 세션이 있으면 과거 완료 기록(기록 자체는 유지)보다 이어하기가 우선.
    if (_savedGameStates[levelName]?.containsKey(gameNumber) ?? false) {
      return _recentSavedGameNumber[levelName] == gameNumber
          ? _PuzzleCardKind.recent
          : _PuzzleCardKind.inProgress;
    }
    if (_isCleared(levelName, gameNumber)) return _PuzzleCardKind.completed;
    return _PuzzleCardKind.fresh;
  }

  List<int> _filteredGames(List<int> games) =>
      _filteredGamesFor(_selectedFilter, games);

  List<int> _filteredGamesFor(_PuzzleFilter filter, List<int> games) {
    return games.where((gameNumber) {
      final kind = _puzzleCardKind(gameNumber);
      switch (filter) {
        case _PuzzleFilter.all:
          return true;
        case _PuzzleFilter.fresh:
          return kind == _PuzzleCardKind.fresh;
        case _PuzzleFilter.inProgress:
          return kind == _PuzzleCardKind.inProgress ||
              kind == _PuzzleCardKind.recent;
        case _PuzzleFilter.completed:
          return kind == _PuzzleCardKind.completed;
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
    final entries = saved.entries.toList()
      ..sort((a, b) =>
          b.value.lastPlayedAtMillis.compareTo(a.value.lastPlayedAtMillis));
    return entries.map((entry) => entry.key).toList();
  }

  int _userFilledCells(SavedGameState saved) {
    final filledCells =
        saved.board.expand((row) => row).where((cell) => cell != 0).length;
    final originalFilledCells = 81 - widget.level.emptyCells;
    return (filledCells - originalFilledCells)
        .clamp(0, widget.level.emptyCells);
  }

  bool _isResumable(SavedGameState saved) {
    return saved.session.isResumable(
      userFilledCells: _userFilledCells(saved),
      emptyCells: widget.level.emptyCells,
      maxWrongCount:
          SudokuGameFeaturePolicy.forLevel(widget.level).maxWrongCount,
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

  String? _clearTimeLabel(int gameNumber) {
    final clearTime =
        (_clearRecords[widget.level.name]?[gameNumber]?['clear_time'] as num?)
            ?.toInt();
    if (clearTime == null) return null;
    return formatElapsedSeconds(clearTime);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    _metadataReady.remove(levelName);
    _metadataFailed.remove(levelName);
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
  const _InteractiveTile({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_InteractiveTile> createState() => _InteractiveTileState();
}

class _InteractiveTileState extends State<_InteractiveTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: PressScale(pressed: _pressed, child: widget.child),
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
