import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/database/database_manager.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/level_progress_service.dart';
import 'package:mysudoku/view/sudoku_game_screen.dart';
import 'package:mysudoku/widgets/custom_app_bar.dart';

/// 난이도 선택 화면
/// 사용자가 스도쿠 게임의 난이도를 선택할 수 있는 화면입니다.
class LevelSelectionScreen extends StatefulWidget {
  final SudokuLevel level;

  const LevelSelectionScreen({super.key, required this.level});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  static const int _perfLogThresholdMs = 120;
  static const int _maxReasonableClearSeconds = 24 * 60 * 60;
  final DatabaseManager _databaseManager = DatabaseManager();
  final LevelProgressService _levelProgressService = LevelProgressService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  // 게임 데이터 캐시
  final Map<String, List<int>> _gameCache = {};
  final Map<String, Future<List<int>>> _gameFutureCache = {};
  final Map<String, Map<int, SudokuGame>> _playGameCache = {};
  final Map<String, Stopwatch> _levelLoadStopwatch = {};
  final Map<String, Set<int>> _clearedGameNumbers = {};
  final Map<String, _LevelHeroStats> _heroStatsCache = {};
  final Map<String, Future<_LevelHeroStats>> _heroStatsFutureCache = {};
  final Map<String, int> _heroQuoteIndexByLevel = {};
  final Random _random = Random();
  List<SudokuLevel> _levels = List<SudokuLevel>.from(SudokuLevel.levels);
  bool _isGameTransitioning = false;
  bool _didInitHeroQuote = false;

  @override
  void initState() {
    super.initState();
    // 단일 진입 흐름: 홈 -> 특정 레벨 게임 목록
    _gamesFutureForLevel(widget.level.name);
    _heroStatsFutureForLevel(widget.level.name);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitHeroQuote) return;
    _didInitHeroQuote = true;
    _rotateHeroQuote(widget.level.name);
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

  Future<_LevelHeroStats> _loadHeroStats(String levelName) async {
    final records = await _dbHelper.getClearRecordsForLevel(levelName);
    final validRecords = records.where((record) {
      final clearTime = (record['clear_time'] as num?)?.toInt();
      return clearTime != null &&
          clearTime >= 0 &&
          clearTime <= _maxReasonableClearSeconds;
    }).toList();
    if (validRecords.isEmpty) {
      const empty = _LevelHeroStats(bestClearSeconds: null, avgClearSeconds: null);
      _heroStatsCache[levelName] = empty;
      return empty;
    }

    int? best;
    var total = 0;
    for (final record in validRecords) {
      final clearTime = (record['clear_time'] as num?)?.toInt();
      if (clearTime == null) continue;
      total += clearTime;
      if (best == null || clearTime < best) {
        best = clearTime;
      }
    }

    final validCount = validRecords
        .where((record) => (record['clear_time'] as num?) != null)
        .length;
    final avg = validCount == 0 ? null : (total / validCount).round();
    final stats = _LevelHeroStats(
      bestClearSeconds: best,
      avgClearSeconds: avg,
    );
    _heroStatsCache[levelName] = stats;
    return stats;
  }

  Future<_LevelHeroStats> _heroStatsFutureForLevel(String levelName) {
    return _heroStatsFutureCache.putIfAbsent(
      levelName,
      () => _loadHeroStats(levelName),
    );
  }

  Future<void> _refreshHeroStats(String levelName) async {
    _heroStatsFutureCache.remove(levelName);
    final stats = await _loadHeroStats(levelName);
    if (!mounted) return;
    setState(() {
      _heroStatsCache[levelName] = stats;
    });
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
    setState(() {
      _isGameTransitioning = true;
    });
    final game = await _loadGameForPlay(level.name, gameNumber);
    if (!mounted) return;
    if (game == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.recordsGameLoadError)),
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
          pageBuilder: (context, animation, secondaryAnimation) => SudokuGameScreen(
            game: game,
            level: level,
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
      final currentLevel = _levels.firstWhere(
        (item) => item.name == level.name,
        orElse: () => level,
      );
      final refreshedLevel = await _levelProgressService.refreshLevel(currentLevel);
      if (mounted) {
        setState(() {
          _levels = _levels
              .map((item) => item.name == refreshedLevel.name ? refreshedLevel : item)
              .toList();
        });
      }

      if (mounted) {
        setState(() {});
      }
      await _refreshHeroStats(level.name);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
    return CustomAppBar(
      title: '',
      showNotificationIcon: false,
      showLogoutIcon: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// 게임 선택 화면용 태블릿 레이아웃
  Widget _buildGameSelectionTabletLayout(AppLocalizations l10n) {
    return Column(
      children: [
        // 상단 설명 영역
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _levelHeaderTitle(l10n),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              _buildLevelProgressSummary(l10n, compact: false),
            ],
          ),
        ),
        // 게임 카드 영역
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: FutureBuilder<List<int>>(
              future: _gamesFutureForLevel(widget.level.name),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildGameListStateMessage(
                    l10n.levelLoadingGames,
                    showSpinner: true,
                  );
                }
                if (snapshot.hasError) {
                  return _buildGameListStateMessage(l10n.recordsGameLoadError);
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildGameListStateMessage(_emptyGamesMessage(l10n));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final gameNumber = snapshot.data![index];
                    return _buildGameSelectionCard(gameNumber, l10n);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 게임 선택 화면용 모바일 레이아웃
  Widget _buildGameSelectionMobileLayout(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 설명 영역
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _levelHeaderTitle(l10n),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),
              _buildLevelProgressSummary(l10n, compact: true),
            ],
          ),
        ),
        // 게임 카드 영역
        Expanded(
          child: FutureBuilder<List<int>>(
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
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return _buildGameSelectionMobileCard(games[index], l10n);
                },
              );
            },
          ),
        ),
      ],
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
    );
  }

  Widget _buildLevelProgressSummary(
    AppLocalizations l10n, {
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = _currentLevelInfo();
    final total = level.gameCount;
    final cleared = _clearedGameNumbers[level.name]?.length ?? 0;
    final progress = total == 0 ? 0.0 : cleared / total;
    final progressPercent = (progress * 100).round();

    return FutureBuilder<_LevelHeroStats>(
      future: _heroStatsFutureForLevel(level.name),
      initialData: _heroStatsCache[level.name],
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const _LevelHeroStats(bestClearSeconds: null, avgClearSeconds: null);
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE3F4EC),
                Color(0xFFF2E6D5),
              ],
            ),
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 38 : 46,
                    height: compact ? 38 : 46,
                    decoration: BoxDecoration(
                      color: _getLevelColor(level),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getLevelIcon(level),
                      color: Colors.white,
                      size: compact ? 18 : 22,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.localizedName(l10n),
                          style: TextStyle(
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _completedSummaryLabel(cleared, total),
                          style: TextStyle(
                            fontSize: compact ? 12 : 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: compact ? 44 : 52,
                    height: compact ? 44 : 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: compact ? 4 : 4.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.75),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getLevelColor(level).withValues(alpha: 0.95),
                          ),
                        ),
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              SizedBox(height: compact ? 9 : 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _bestRecordLabel(stats.bestClearSeconds),
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _avgFocusLabel(stats.avgClearSeconds),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 9),
              Text(
                _heroQuoteForLevel(level.name),
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SudokuLevel _currentLevelInfo() {
    return _levels.firstWhere(
      (item) => item.name == widget.level.name,
      orElse: () => widget.level,
    );
  }

  String _completedSummaryLabel(int cleared, int total) {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '완료 $cleared / 전체 $total'
        : 'Completed $cleared / $total';
  }

  String _levelHeaderTitle(AppLocalizations l10n) {
    final levelName = widget.level.localizedName(l10n);
    final levelNameEn = _levelEnglishName(widget.level);
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '$levelName 레벨 ($levelNameEn)'
        : '$levelName ($levelNameEn)';
  }

  String _levelEnglishName(SudokuLevel level) {
    switch (level.difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Medium';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Beginner';
    }
  }

  String _bestRecordLabel(int? seconds) {
    final value = seconds == null ? '--:--' : _formatDuration(seconds);
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '🏆 최고 기록: $value'
        : '🏆 Best: $value';
  }

  String _avgFocusLabel(int? seconds) {
    final value = seconds == null ? '--:--:--' : _formatDuration(seconds);
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '🧘 평균 몰입: $value'
        : '🧘 Avg focus: $value';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final minutePart = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutePart.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _rotateHeroQuote(String levelName) {
    final quotes = _heroQuoteCandidates();
    if (quotes.isEmpty) return;
    final previousIndex = _heroQuoteIndexByLevel[levelName];
    if (quotes.length == 1) {
      _heroQuoteIndexByLevel[levelName] = 0;
      return;
    }
    var nextIndex = _random.nextInt(quotes.length);
    if (previousIndex != null && nextIndex == previousIndex) {
      nextIndex = (nextIndex + 1 + _random.nextInt(quotes.length - 1)) % quotes.length;
    }
    _heroQuoteIndexByLevel[levelName] = nextIndex;
  }

  String _heroQuoteForLevel(String levelName) {
    final quotes = _heroQuoteCandidates();
    if (quotes.isEmpty) return '';
    final idx = _heroQuoteIndexByLevel[levelName] ?? 0;
    return quotes[idx % quotes.length];
  }

  List<String> _heroQuoteCandidates() {
    if (Localizations.localeOf(context).languageCode == 'ko') {
      return const [
        '"숫자의 흐름에 차분히 몰입해보세요."',
        '"한 칸씩 확실하게, 리듬을 잃지 말아요."',
        '"지금 페이스 좋아요. 정확도를 먼저 챙겨보세요."',
        '"작은 단서가 큰 해답으로 이어집니다."',
      ];
    }
    return const [
      '"Stay calm and follow the rhythm of numbers."',
      '"One cell at a time, keep your steady pace."',
      '"Great pace so far. Prioritize precision first."',
      '"Small clues often unlock the biggest answers."',
    ];
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
    _gameCache.remove(levelName);
    _playGameCache.remove(levelName);
    _clearedGameNumbers.remove(levelName);
    _levelLoadStopwatch.remove(levelName);
    if (mounted) {
      setState(() {});
    }
  }

  /// 게임 선택용 카드 위젯
  Widget _buildGameSelectionCard(int gameNumber, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCleared = _isCleared(widget.level.name, gameNumber);
    return _GameCardFrame(
      colorScheme: colorScheme,
      deemphasized: isCleared,
      isEnabled: !_isGameTransitioning,
      onTap: () async {
        await _onGameSelected(gameNumber, widget.level);
      },
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _getLevelColor(widget.level),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isCleared ? Icons.check : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.gameNumberLabel(gameNumber),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (isCleared)
            Positioned(
              top: 6,
              right: 6,
              child: _ClearedBadge(
                text: l10n.levelClearedBadge,
                color: _getLevelColor(widget.level),
                colorScheme: colorScheme,
              ),
            ),
        ],
      ),
    );
  }

  /// 게임 선택용 모바일 카드 위젯
  Widget _buildGameSelectionMobileCard(
    int gameNumber,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCleared = _isCleared(widget.level.name, gameNumber);
    return _GameCardFrame(
      colorScheme: colorScheme,
      deemphasized: isCleared,
      isEnabled: !_isGameTransitioning,
      onTap: () async {
        await _onGameSelected(gameNumber, widget.level);
      },
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _getLevelColor(widget.level),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isCleared ? Icons.check : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.gameNumberLabel(gameNumber),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.levelTapToStart,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          if (isCleared)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ClearedBadge(
                text: l10n.levelClearedBadge,
                color: _getLevelColor(widget.level),
                colorScheme: colorScheme,
              ),
            ),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ],
      ),
    );
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

  IconData _getLevelIcon(SudokuLevel level) {
    switch (level.difficulty) {
      case 1:
        return Icons.grid_view;
      case 2:
        return Icons.diamond;
      case 3:
        return Icons.star;
      case 4:
        return Icons.flash_on;
      case 5:
        return Icons.workspace_premium;
      default:
        return Icons.grid_view;
    }
  }

}

class _LevelHeroStats {
  const _LevelHeroStats({
    required this.bestClearSeconds,
    required this.avgClearSeconds,
  });

  final int? bestClearSeconds;
  final int? avgClearSeconds;
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
    required this.colorScheme,
    required this.onTap,
    required this.child,
    required this.isEnabled,
    this.deemphasized = false,
  });

  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final Widget child;
  final bool isEnabled;
  final bool deemphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: deemphasized ? 0.04 : 0.08),
            blurRadius: deemphasized ? 8 : 12,
            offset: Offset(0, deemphasized ? 2 : 4),
          ),
        ],
      ),
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: isEnabled ? 1 : 0.72,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ClearedBadge extends StatelessWidget {
  const _ClearedBadge({
    required this.text,
    required this.color,
    required this.colorScheme,
  });

  final String text;
  final Color color;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
