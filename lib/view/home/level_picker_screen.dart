import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:sudoku159/utils/light_haptic.dart';
import 'package:sudoku159/widgets/animated_progress_bar.dart';
import 'package:sudoku159/widgets/press_scale.dart';
import 'package:sudoku159/widgets/press_scale_listener.dart';
import 'package:sudoku159/widgets/puzzle_result_sticker.dart';
import 'package:sudoku159/widgets/replay_confirm_dialog.dart';
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
import 'package:sudoku159/services/onboarding/beginner_tutorial_service.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/view/onboarding/beginner_tutorial_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';

enum _PuzzleFilter { all, fresh, inProgress, completed }

enum _PuzzleCardKind { fresh, recent, inProgress, completed }

/// 진행 카드의 상태: 이어하기 / 첫 방문 / 진행 없음(다음 퍼즐) / 전부 완료.
enum _SummaryKind { continuePlay, first, next, allDone }

class LevelPickerScreen extends StatefulWidget {
  final SudokuLevel level;

  /// 테스트에서 저장소를 대체하기 위한 선택적 주입. 기본값은 실제 구현.
  final DatabaseHelper? databaseHelper;
  final GameStateService? gameStateService;
  final LevelProgressService? levelProgressService;
  final BeginnerTutorialService? tutorialService;

  const LevelPickerScreen({
    super.key,
    required this.level,
    this.databaseHelper,
    this.gameStateService,
    this.levelProgressService,
    this.tutorialService,
  });

  @override
  State<LevelPickerScreen> createState() => _LevelPickerScreenState();
}

class _LevelPickerScreenState extends State<LevelPickerScreen> {
  static const int _perfLogThresholdMs = 120;
  static const int _maxInProgressPuzzles = 5;
  final DatabaseManager _databaseManager = DatabaseManager();
  final AppSettingsService _appSettingsService = AppSettingsService();
  late final LevelProgressService _levelProgressService =
      widget.levelProgressService ?? LevelProgressService();
  late final GameStateService _gameStateService =
      widget.gameStateService ?? GameStateService();
  late final DatabaseHelper _dbHelper =
      widget.databaseHelper ?? DatabaseHelper();
  late final BeginnerTutorialService _tutorialService =
      widget.tutorialService ?? BeginnerTutorialService();
  final Map<String, List<int>> _gameCache = {};
  final Map<String, Future<List<int>>> _gameFutureCache = {};
  final Map<String, Map<int, SudokuGame>> _playGameCache = {};
  final Map<String, Stopwatch> _levelLoadStopwatch = {};
  final Map<String, Set<int>> _clearedGameNumbers = {};
  final Map<String, Map<int, SavedGameState>> _savedGameStates = {};
  final Map<String, Map<int, Map<String, dynamic>>> _clearRecords = {};

  /// 힌트와 실수 없이 한 판이라도 완료한 퍼즐 번호(★ 표시).
  final Map<String, Set<int>> _perfectGameNumbers = {};
  final Map<String, int?> _recentSavedGameNumber = {};
  final Map<String, Future<void>> _puzzleMetadataFutureCache = {};
  List<SudokuLevel> _levels = List<SudokuLevel>.from(SudokuLevel.levels);
  _PuzzleFilter _selectedFilter = _PuzzleFilter.all;
  bool _isGameTransitioning = false;
  bool _selectionInFlight = false;
  // 실제 퍼즐 로딩이 시작된 카드 번호(확인/한도 대화상자가 떠 있는 동안은 null).
  int? _openingGameNumber;
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
    final perfect = _perfectNumbers(
      records: recordsByGame,
      events: await _dbHelper.getClearEventsForLevel(levelName),
    );

    if (!mounted) return;
    setState(() {
      _savedGameStates[levelName] = savedForLevel;
      _clearRecords[levelName] = recordsByGame;
      _recentSavedGameNumber[levelName] = recentGameNumber;
      _clearedGameNumbers[levelName] = recordsByGame.keys.toSet();
      _perfectGameNumbers[levelName] = perfect;
    });
  }

  /// 힌트·실수 없이 한 판이라도 완료한 퍼즐. 기록 화면의 "힌트 없이 / 실수 없이"
  /// 집계와 같은 기준으로, 완료 이력(`clear_events`)이 없는 오래된 퍼즐은 최고 기록
  /// 한 판으로 판단한다.
  static Set<int> _perfectNumbers({
    required Map<int, Map<String, dynamic>> records,
    required List<Map<String, dynamic>> events,
  }) {
    bool isPerfect(Map<String, dynamic> row) =>
        ((row['hints_used'] as num?)?.toInt() ?? 0) == 0 &&
        ((row['wrong_count'] as num?)?.toInt() ?? 0) == 0;
    final withEvents = <int>{};
    final perfect = <int>{};
    for (final event in events) {
      final number = (event['game_number'] as num?)?.toInt();
      if (number == null) continue;
      withEvents.add(number);
      if (isPerfect(event)) perfect.add(number);
    }
    for (final entry in records.entries) {
      if (!withEvents.contains(entry.key) && isPerfect(entry.value)) {
        perfect.add(entry.key);
      }
    }
    return perfect.intersection(records.keys.toSet());
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
      final shouldReplay = await showReplayConfirmDialog(
        context,
        gameNumber: gameNumber,
        bestRecord: _clearRecords[level.name]?[gameNumber],
      );
      if (!mounted || shouldReplay != true) return;
    }
    if (kind == _PuzzleCardKind.fresh &&
        _inProgressGameNumbers().length >= _maxInProgressPuzzles) {
      final picked = await _showInProgressLimitDialog();
      if (!mounted || picked == null) return;
      return _startGame(picked, level);
    }
    if (kind == _PuzzleCardKind.fresh &&
        level.name == SudokuLevel.levels.first.name) {
      final shouldContinue = await _maybeShowBeginnerTutorial();
      if (!mounted || !shouldContinue) return;
    }

    setState(() {
      _isGameTransitioning = true;
      _openingGameNumber = gameNumber;
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
          _openingGameNumber = null;
        });
      } else {
        _isGameTransitioning = false;
        _openingGameNumber = null;
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
        setState(() {
          _isGameTransitioning = false;
          _openingGameNumber = null;
        });
      } else {
        _isGameTransitioning = false;
        _openingGameNumber = null;
      }
    }
  }

  /// 초급 새 문제를 처음 시작할 때만 가이드 선택 안내를 보여준다. 건너뛰면
  /// 다시 묻지 않고(dismissed로 저장) true를 돌려줘 원래 문제를 그대로 연다.
  /// 가이드를 시작해 완료(또는 중간에 닫아도) 화면에서 돌아오면 역시 true를
  /// 돌려줘 원래 선택한 문제를 연다. 반환값이 false면 아무것도 하지 않는다
  /// (이 함수 자체는 항상 true를 반환하지만, mounted 가드를 위해 bool로 둔다).
  /// 첫 초급 퍼즐 앞의 연습 퍼즐 안내(팝업) 노출 여부. 현재는 숨기고 바로 퍼즐을 연다.
  static const bool _showBeginnerTutorialPrompt = false;

  Future<bool> _maybeShowBeginnerTutorial() async {
    if (!_showBeginnerTutorialPrompt) return true;
    final state = await _tutorialService.getState();
    if (!mounted) return false;
    if (state != BeginnerTutorialState.unseen) return true;

    final l10n = AppLocalizations.of(context)!;
    final startGuide = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.beginnerTutorialPromptTitle),
        content: Text(l10n.beginnerTutorialPromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.beginnerTutorialSkip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.beginnerTutorialStart),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (startGuide != true) {
      await _tutorialService.markDismissed();
      return mounted;
    }
    await Navigator.push(
      context,
      buildAppPageRoute(
        builder: (context) =>
            BeginnerTutorialScreen(tutorialService: _tutorialService),
      ),
    );
    return mounted;
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
          return _buildStateMessage(
            l10n.levelNoPuzzlesAvailable,
            icon: Icons.inbox_outlined,
          );
        }

        final games = [...snapshot.data!]..sort();
        final filteredGames = _filteredGames(games);
        final bottomPadding = MediaQuery.paddingOf(context).bottom + 24;
        final inProgress = _inProgressGameNumbers();
        final recentNumber = _recentSavedGameNumber[levelName];
        final hasRecent = recentNumber != null &&
            _savedGameStates[levelName]?.containsKey(recentNumber) == true;
        final nextFresh = _nextFreshGameNumber(games);
        final allCompleted = games.every((g) => _isCleared(levelName, g));

        // 넓은 화면(아이패드 가로 등)에서 카드·필터·그리드가 화면 전체로 늘어나지
        // 않도록 가운데 정렬하고 최대 폭을 둔다. 열 수는 이 폭 기준으로 계산된다.
        return Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: LayoutBuilder(
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
                          _buildSummary(
                            continueNumber: hasRecent ? recentNumber : null,
                            // 이어할 퍼즐이 없을 때만 다음 새 퍼즐이 카드의 주 행동.
                            nextNumber: hasRecent ? null : nextFresh,
                            allCompleted: !hasRecent && allCompleted,
                            inProgressCount: inProgress.length,
                          ),
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
          ),
        ));
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
    // 아이패드: 번호 15 · 상태 14 · 시간 13 · 진행률 15 (폰 13/12/11/13).
    final isTablet = MediaQuery.of(context).size.width > 600;

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
                fontSize: isTablet ? 15 : 13,
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
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: inProgressColor,
                ),
              ),
            ),
            const Spacer(),
            if (timeLabel.isNotEmpty) ...[
              Text(
                timeLabel,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11,
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              progressPct > 0 ? '$progressPct%' : l10n.gameMemoShort,
              style: TextStyle(
                fontSize: isTablet ? 15 : 13,
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

  String _levelProgressBackground(SudokuLevel level) {
    switch (level.difficulty) {
      case 1:
        return 'assets/images/level_beginner_progress_card_bg.png';
      case 2:
        return 'assets/images/level_intermediate_progress_card_bg.png';
      case 3:
        return 'assets/images/level_advanced_progress_card_bg.png';
      case 4:
        return 'assets/images/level_expert_progress_card_bg.png';
      default:
        return 'assets/images/level_master_progress_card_bg.png';
    }
  }

  /// 난이도 진행 카드: 현황판이 아니라 "지금 할 일"을 안내하는 카드.
  /// - 이어할 퍼즐이 있으면 "N번 퍼즐 / 13% · 오늘" + 진행바 + 이어서 풀기
  ///   (카드 전체 탭 가능)
  /// - 완료 0개(첫 방문) / 진행 없음 / 전부 완료는 각각 다른 안내와 버튼.
  /// 완료 개수는 왼쪽 위의 작은 배지로만 보여준다(전체 개수는 필터에 있다).
  Widget _buildSummary({
    int? continueNumber,
    int? nextNumber,
    required bool allCompleted,
    int inProgressCount = 0,
  }) {
    final level = _currentLevelInfo();
    final l10n = AppLocalizations.of(context)!;
    final cleared = _clearedGameNumbers[level.name]?.length ?? 0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final busy = _isGameTransitioning || _selectionInFlight;
    final isTablet = MediaQuery.of(context).size.width > 600;

    final _SummaryKind? kind = continueNumber != null
        ? _SummaryKind.continuePlay
        : allCompleted
            ? _SummaryKind.allDone
            : nextNumber != null
                ? (cleared == 0 ? _SummaryKind.first : _SummaryKind.next)
                : null;

    final card = ClipRRect(
      key: const Key('level_progress_card'),
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _levelProgressBackground(level),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromRGBO(255, 255, 255, 0.30),
                    Color.fromRGBO(255, 255, 255, 0.10),
                    Color.fromRGBO(255, 255, 255, 0.0),
                  ],
                  stops: [0.0, 0.38, 0.65],
                ),
              ),
            ),
          ),
          _summaryContent(
            isTablet: isTablet,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: cleared > 0
                        ? Container(
                            key: const Key('level_completed_badge'),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 10,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.78),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.levelCompletedCount(cleared),
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4A3F9A),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              if (kind != null)
                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey('$kind-${continueNumber ?? nextNumber}'),
                    child: _buildSummaryAction(
                      kind: kind,
                      number: continueNumber ?? nextNumber,
                      inProgressCount: inProgressCount,
                      busy: busy,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    // 아이패드: 배경 일러스트(3:1)가 가로로 길게 늘어나 위아래가 잘리지 않도록
    // 폭에 맞춰 높이를 확보한다(최대 280). 아이폰은 기존 내용 높이 그대로.
    final sizedCard = isTablet
        ? LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: math.min(constraints.maxWidth / 3, 280),
              child: card,
            ),
          )
        : card;
    if (kind != _SummaryKind.continuePlay) return sizedCard;
    // 카드 어디를 눌러도 이어서 풀기가 실행된다(안쪽 버튼은 같은 동작).
    return _InteractiveTile(
      onTap: busy ? null : () => _startFromCard(continueNumber!),
      child: sizedCard,
    );
  }

  /// 요약 카드 내용. 아이폰은 내용 높이만큼, 아이패드는 카드 높이를 채우고
  /// 헤더(배지)는 위, 행동 영역은 아래에 둔다.
  Widget _summaryContent({
    required bool isTablet,
    required List<Widget> children,
  }) {
    if (!isTablet) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return Positioned.fill(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          children.first,
          const Spacer(),
          ...children.skip(1),
        ],
      ),
    );
  }

  /// 카드 하단의 주 행동 영역. 어두운 그라데이션 위에 흰 글자로 둔다.
  Widget _buildSummaryAction({
    required _SummaryKind kind,
    required int? number,
    required int inProgressCount,
    required bool busy,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isContinue = kind == _SummaryKind.continuePlay;
    final isDone = kind == _SummaryKind.allDone;
    final pct = isContinue ? _savedProgressPercent(number!) : 0;

    final title = isDone
        ? l10n.levelCardAllDoneTitle(_currentLevelInfo().localizedName(l10n))
        : l10n.levelPuzzleNumber(number!);
    final String sub;
    switch (kind) {
      case _SummaryKind.continuePlay:
        final time = _lastPlayedLabel(number!);
        sub = [_progressDetail(number), if (time.isNotEmpty) time].join(' · ');
      case _SummaryKind.first:
        sub = l10n.levelCardFirstSub;
      case _SummaryKind.next:
        sub = l10n.levelCardNextSub;
      case _SummaryKind.allDone:
        sub = l10n.levelCardAllDoneSub;
    }
    final buttonLabel = switch (kind) {
      _SummaryKind.continuePlay => l10n.levelContinueButton,
      _SummaryKind.allDone => l10n.levelCardViewCompleted,
      _ => l10n.levelStartNewButton,
    };
    final VoidCallback? onPressed = busy
        ? null
        : isDone
            ? () => _selectFilter(_PuzzleFilter.completed, scrollToFilter: true)
            : () => _startFromCard(number!);

    // 큰 글씨, 그리고 긴 문장 제목+긴 버튼 라벨의 전부 완료 상태는 버튼을 아래로 내린다.
    final stacked = isDone || MediaQuery.textScalerOf(context).scale(1.0) > 1.3;
    // 밝은 일러스트 위에서도 읽히도록 이중 그림자.
    const shadow = [
      Shadow(color: Color(0x80000000), blurRadius: 6, offset: Offset(0, 1)),
      Shadow(color: Color(0x4D000000), blurRadius: 2),
    ];

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isTablet ? 30 : 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: shadow,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (sub.isNotEmpty)
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isTablet ? 19 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: shadow,
            ),
          ),
      ],
    );
    // 배경 이미지·그라데이션이 테마와 무관하게 고정이라 버튼도 고정색:
    // 반투명(약 55%) 흰 유리 버튼 + 보라 글씨. 뒤를 살짝만 블러해 일러스트가
    // 비쳐 보이게 하면서 글씨는 읽히게 한다.
    final button = PressScaleListener(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0x8CFFFFFF),
              foregroundColor: const Color(0xFF4A3F9A),
              disabledBackgroundColor: const Color(0x80FFFFFF),
              side: const BorderSide(color: Color(0x66FFFFFF)),
              // 아이패드: 버튼 높이 56 · 글자 18 · 좌우 28(폰 40/기본/18).
              minimumSize: Size(0, isTablet ? 56 : 40),
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 18),
              textStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 18 : null,
              ),
            ),
            child:
                Text(buttonLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // 순수 검정 대신 앱 보라 계열의 어두운 색으로 일러스트와 어울리게.
          colors: [Color(0x002A2250), Color(0x992A2250)],
        ),
      ),
      child: Padding(
        padding: isTablet
            ? const EdgeInsets.fromLTRB(28, 28, 24, 24)
            : const EdgeInsets.fromLTRB(16, 28, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stacked) ...[
              info,
              const SizedBox(height: 8),
              button,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 8),
                  button,
                ],
              ),
            // 현재 퍼즐 진행바: 정보(13% · 오늘) 바로 아래. 0에서 현재 값까지 채워진다.
            if (pct > 0) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AnimatedProgressBar(
                  key: const Key('level_card_puzzle_progress'),
                  value: pct / 100,
                  fillColor: Colors.white,
                  trackColor: const Color(0x40FFFFFF),
                ),
              ),
            ],
            if (isContinue && inProgressCount > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _selectFilter(
                    _PuzzleFilter.inProgress,
                    scrollToFilter: true,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(l10n.levelViewInProgress(inProgressCount)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 카드에서 퍼즐을 시작할 때: 가벼운 햅틱(설정이 켜져 있을 때만) + 시작.
  void _startFromCard(int number) {
    unawaited(lightHaptic(settings: _appSettingsService));
    _onGameSelected(number, widget.level);
  }

  /// 진행 상태 한 줄 설명: "62%" 또는 메모만 있으면 "메모 작성 중".
  String _progressDetail(int gameNumber) {
    final l10n = AppLocalizations.of(context)!;
    final pct = _savedProgressPercent(gameNumber);
    return pct > 0 ? '$pct%' : l10n.levelNotesInProgress;
  }

  // ─── Filter chips ─────────────────────────────────────────────────────────

  TextStyle get _filterChipTextStyle => TextStyle(
        // 아이패드 14 · 폰 12.5.
        fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12.5,
        fontWeight: FontWeight.w600,
      );

  Widget _buildFilterChips(List<int> games) {
    final colors = LevelStatusPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    const filters = _PuzzleFilter.values;
    final counts = [
      for (final f in filters) _filteredGamesFor(f, games).length,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colors.filterSelectedBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 4.0;
              final slotWidth =
                  (constraints.maxWidth - gap * (filters.length - 1)) /
                      filters.length;
              // 모든 라벨이 같은 폭 칸에 한 줄로 들어갈 때만 하이라이트가
              // 이동한다. 긴 번역·큰 글자에서는 줄바꿈 Wrap으로 되돌린다.
              final scaler = MediaQuery.textScalerOf(context);
              var fits = true;
              for (var i = 0; i < filters.length; i++) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: '${_filterLabel(filters[i])} ${counts[i]}',
                    style: _filterChipTextStyle,
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: scaler,
                  maxLines: 1,
                )..layout();
                if (painter.width + 12 > slotWidth) fits = false;
                painter.dispose();
              }
              if (!fits) {
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < filters.length; i++)
                      _buildFilterChip(filters[i], counts[i], slide: false),
                  ],
                );
              }
              final selectedIndex = filters.indexOf(_selectedFilter);
              final duration = MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220);
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * (slotWidth + gap),
                    width: slotWidth,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
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
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        Expanded(
                          child: _buildFilterChip(
                            filters[i],
                            counts[i],
                            slide: true,
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
        // 개수는 위 필터에 이미 있으므로, 완료한 퍼즐이 있을 때만 ★ 뜻을 알려 준다.
        if (_clearedGameNumbers[widget.level.name]?.isNotEmpty ?? false) ...[
          const SizedBox(height: 14),
          Wrap(
            key: const Key('level-perfect-legend'),
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 실제 칸과 같은 스티커 견본(CLEAR는 완료, PERFECT는 힌트·실수 없음).
              _buildLegendItem(
                PuzzleResultSticker(
                  perfect: false,
                  width: MediaQuery.of(context).size.width > 600 ? 72 : 50,
                  tiltDegrees: -6,
                ),
                l10n.levelFilterDone,
                colors,
              ),
              _buildLegendItem(
                PuzzleResultSticker(
                  perfect: true,
                  width: MediaQuery.of(context).size.width > 600 ? 72 : 50,
                  tiltDegrees: -6,
                ),
                l10n.levelPerfectLegend,
                colors,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(
    Widget sticker,
    String label,
    LevelStatusPalette colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        sticker,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width > 600 ? 15 : 13,
              fontWeight: FontWeight.w600,
              color: colors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    _PuzzleFilter filter,
    int count, {
    required bool slide,
  }) {
    final isSelected = _selectedFilter == filter;
    final colors = LevelStatusPalette.of(context);
    final label = '${_filterLabel(filter)} $count';
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);
    final textStyle = _filterChipTextStyle.copyWith(
      color: isSelected ? colors.primaryPurple : colors.filterUnselectedText,
    );
    final text = slide
        ? AnimatedDefaultTextStyle(
            duration: duration,
            style: textStyle,
            child: Text(label, maxLines: 1, textAlign: TextAlign.center),
          )
        : Text(label, maxLines: 1, style: textStyle);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectFilter(filter),
        child: AnimatedContainer(
          duration: duration,
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(horizontal: slide ? 6 : 14),
          decoration: slide
              ? null
              : BoxDecoration(
                  color:
                      isSelected ? colors.cardBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
          child: Center(
            widthFactor: slide ? null : 1,
            child: text,
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
    final isTablet = MediaQuery.of(context).size.width > 600;
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
    // 완료 칸은 시간 대신 결과 스티커를 붙인다(CLEAR / 힌트·실수 없이 푼 퍼즐은
    // PERFECT). 시간은 다시 풀기 확인창의 최고 기록에서 보여 준다.
    final isPerfect = isCompleted &&
        (_perfectGameNumbers[widget.level.name]?.contains(gameNumber) ?? false);

    if (isCompleted) {
      bgColor =
          isPerfect ? colors.perfectCellBackground : colors.clearCellBackground;
      textColor = colors.completedNumberText;
      iconColor = accentColor;
      borderColor =
          isPerfect ? colors.perfectCellBorder : colors.clearCellBorder;
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
    final numberText = gameNumber.toString().padLeft(3, '0');
    final statusText = isCompleted
        ? l10n.levelFilterDone
        : isInProgress
            ? l10n.levelStatusInProgress
            : l10n.levelFilterNew;
    final semanticsDetail = isInProgress
        ? _progressDetail(gameNumber)
        : isPerfect
            ? l10n.levelPerfectLegend
            : null;
    final semanticsLabel = l10n.levelCellSemantics(
      numberText,
      semanticsDetail == null ? statusText : '$statusText, $semanticsDetail',
    );

    final isOpening = _openingGameNumber == gameNumber;
    final isDimmedByOtherOpening = _openingGameNumber != null && !isOpening;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedOpacity(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      opacity: isDimmedByOtherOpening ? 0.75 : 1.0,
      child: Semantics(
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
                              fontSize: isTablet ? 24 : 19,
                              fontWeight: isFresh
                                  ? FontWeight.w400
                                  : isCompleted
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color: textColor,
                              height: 1.1,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(height: 1.5),
                            PuzzleResultSticker(
                              key: ValueKey(
                                'level-cell-sticker-$gameNumber-'
                                '${isPerfect ? 'perfect' : 'clear'}',
                              ),
                              perfect: isPerfect,
                              // PERFECT!는 CLEAR보다 약 2px 크게.
                              width: isTablet
                                  ? (isPerfect ? 76 : 72)
                                  : (isPerfect ? 56 : 54),
                            ),
                            const SizedBox(height: 2),
                          ],
                          if (isInProgress)
                            Text(
                              notesOnly ? l10n.gameMemoShort : '$pct%',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 11.5,
                                fontWeight: isRecent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: colors.inProgressPrimary,
                                height: 1.4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isOpening)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    ),
                  )
                else if (isInProgress)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Icon(
                      notesOnly ? Icons.edit_note_rounded : _statusIcon(kind),
                      size: 12,
                      color: iconColor,
                    ),
                  ),
              ],
            ),
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
    final l10n = AppLocalizations.of(context)!;
    if (days == 0) return l10n.levelLastPlayedToday;
    if (days == 1) return l10n.levelLastPlayedYesterday;
    return l10n.levelLastPlayedDaysAgo(days);
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

/// 완료한 퍼즐을 다시 풀기 전 확인창: 라벤더 아이콘, 전체 폭 보라 주 버튼,
/// 아래 텍스트 취소 버튼의 세로 구조(삭제 동작이 아니므로 경고색을 쓰지 않는다).
