import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/records/recent_completions_service.dart';
import 'package:sudoku159/view/records/recent_completion_tile.dart';

/// 기록 화면의 "최근 완료 · 전체 보기"에서 여는 전체 완료 목록(최신 순).
class RecentCompletionsScreen extends StatefulWidget {
  const RecentCompletionsScreen({super.key, this.service});

  /// 테스트에서 저장소를 대체하기 위한 선택적 주입.
  final RecentCompletionsService? service;

  @override
  State<RecentCompletionsScreen> createState() =>
      _RecentCompletionsScreenState();
}

class _RecentCompletionsScreenState extends State<RecentCompletionsScreen> {
  late final RecentCompletionsService _service =
      widget.service ?? RecentCompletionsService();
  List<RecentCompletion>? _entries;
  bool _loadFailed = false;
  bool _opening = false;
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // 이 화면에서 다시 풀어 완료하면 목록에 새 판이 생긴다.
    GameRecordNotifier.instance.version.addListener(_load);
  }

  @override
  void dispose() {
    GameRecordNotifier.instance.version.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_loadRequestId;
    try {
      final entries = await _service.load();
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _entries = entries;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() => _loadFailed = true);
    }
  }

  Future<void> _open(RecentCompletion entry) async {
    // 연타로 확인창·게임 화면이 두 번 열리지 않게 한다.
    if (_opening) return;
    _opening = true;
    try {
      await openRecentCompletion(context, entry);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final entries = _entries;

    Widget body;
    if (entries == null && _loadFailed) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.recordsStatsLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              TextButton(onPressed: _load, child: Text(l10n.recordsRetry)),
            ],
          ),
        ),
      );
    } else if (entries == null) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: cs.outlineVariant),
        itemBuilder: (context, i) => RecentCompletionTile(
          entry: entries[i],
          onTap: () => _open(entries[i]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordsRecentTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: body,
          ),
        ),
      ),
    );
  }
}
