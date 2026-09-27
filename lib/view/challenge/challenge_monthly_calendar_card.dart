import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/widgets/loading_skeleton.dart';

/// 오늘의 도전 월간 달력 카드. 셀 31개를 그릴 때마다 DB·원격을 호출하지
/// 않도록 달이 바뀔 때 한 번만 [ChallengeProgressService.loadMonthCalendar]를
/// 부른다. 날짜를 누르면 선택만 되고, 아래 상세 영역의 버튼을 눌렀을 때만
/// 부모의 [onOpenDate]가 실제 퍼즐을 연다.
class ChallengeMonthlyCalendarCard extends StatefulWidget {
  const ChallengeMonthlyCalendarCard({
    super.key,
    this.challengeProgressService,
    required this.onOpenDate,
    this.showTitle = true,
    this.headerImage,
    this.footerText,
  });

  final ChallengeProgressService? challengeProgressService;
  final bool showTitle;

  /// 제목 옆에 나란히 놓을 장식 이미지(예: 이번 주 카드와 같은 헤더 자리).
  final Widget? headerImage;
  final String? footerText;

  /// 상세 영역의 시작/이어하기/다시 풀기 버튼을 눌렀을 때 호출된다. 완료된
  /// 화면에서 돌아오면 이 카드가 스스로 다시 불러온다.
  final Future<void> Function(DateTime date) onOpenDate;

  @override
  State<ChallengeMonthlyCalendarCard> createState() =>
      _ChallengeMonthlyCalendarCardState();
}

class _ChallengeMonthlyCalendarCardState
    extends State<ChallengeMonthlyCalendarCard> {
  late final ChallengeProgressService _service =
      widget.challengeProgressService ?? ChallengeProgressService();
  late DateTime _visibleMonth;
  ChallengeMonthCalendar? _calendar;
  bool _isLoading = true;
  bool _hasError = false;
  int _requestId = 0;
  DateTime? _selectedDate;
  bool _isStartingSelectedChallenge = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _load();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _visibleMonth.year == now.year && _visibleMonth.month == now.month;
  }

  Future<void> _load() async {
    // 월 이동 요청 도중 오래된 응답이 최신 월을 덮어쓰지 않도록 요청 id를 쓴다.
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await _service.loadMonthCalendar(
        year: _visibleMonth.year,
        month: _visibleMonth.month,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _calendar = result;
        _isLoading = false;
      });
    } catch (_) {
      // 이 카드는 기록 화면의 다른 통계와 나란히 쓰이므로, 조회 실패가
      // 처리되지 않은 예외로 새어나가 다른 통계까지 막지 않게 한다.
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _calendar = null;
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      _calendar = null;
      _selectedDate = null;
    });
    _load();
  }

  void _goToNextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      _calendar = null;
      _selectedDate = null;
    });
    _load();
  }

  void _goToCurrentMonth() {
    if (_isCurrentMonth) return;
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _calendar = null;
      _selectedDate = null;
    });
    _load();
  }

  /// 날짜를 누르면 선택 상태만 바꾼다. 같은 날짜를 다시 누르면 선택을 푼다.
  void _handleDayTap(DateTime date, ChallengeDayStatus status) {
    if (status == ChallengeDayStatus.future) return;
    setState(() {
      _selectedDate = _isSameDate(_selectedDate, date) ? null : date;
    });
  }

  bool _isSameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _startSelectedChallenge() async {
    final date = _selectedDate;
    if (date == null || _isStartingSelectedChallenge) return;
    setState(() => _isStartingSelectedChallenge = true);
    try {
      await widget.onOpenDate(date);
      if (!mounted) return;
      await _load();
    } finally {
      if (mounted) setState(() => _isStartingSelectedChallenge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final calendar = _calendar;
    final selectedDate = _selectedDate;
    final selectedStatus = selectedDate == null || calendar == null
        ? null
        : calendar.statusByDate[
                ChallengeProgressService.formatLocalDate(selectedDate)] ??
            ChallengeDayStatus.notCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.challengeMonthlyTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (calendar?.isMonthFullyCompleted == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Semantics(
                            label: l10n.challengeMonthComplete,
                            excludeSemantics: true,
                            child: Icon(
                              Icons.emoji_events,
                              size: 18,
                              color:
                                  LevelStatusPalette.of(context).primaryPurple,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.headerImage != null) ...[
                  const SizedBox(width: 12),
                  widget.headerImage!,
                ],
              ],
            ),
            const SizedBox(height: 4),
          ],
          Text(
            l10n.challengeMonthlyDescription,
            style:
                TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Row(
              children: [
                IconButton(
                  onPressed: _goToPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: l10n.challengePreviousMonth,
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            DateFormat.yMMMM(locale).format(_visibleMonth),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!widget.showTitle &&
                            calendar?.isMonthFullyCompleted == true) ...[
                          const SizedBox(width: 6),
                          Semantics(
                            label: l10n.challengeMonthComplete,
                            excludeSemantics: true,
                            child: Icon(
                              Icons.emoji_events,
                              size: 18,
                              color:
                                  LevelStatusPalette.of(context).primaryPurple,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isCurrentMonth ? null : _goToNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
                if (!_isCurrentMonth)
                  TextButton(
                    onPressed: _goToCurrentMonth,
                    child: Text(l10n.challengeBackToCurrentMonth),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _WeekdayHeaderRow(locale: locale),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              child: KeyedSubtree(
                key: ValueKey(
                  'month-${_visibleMonth.year}-${_visibleMonth.month}-'
                  '$_isLoading-$_hasError',
                ),
                child: _hasError
                    ? _CalendarLoadError(onRetry: _load)
                    : (_isLoading || calendar == null)
                        ? const _MonthGridSkeleton()
                        : _MonthGrid(
                            month: _visibleMonth,
                            calendar: calendar,
                            l10n: l10n,
                            selectedDate: selectedDate,
                            reduceMotion: reduceMotion,
                            onDayTap: _handleDayTap,
                          ),
              ),
            ),
          ),
          if (selectedDate != null && selectedStatus != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            _maybeAnimatedSize(
              reduceMotion: reduceMotion,
              duration: const Duration(milliseconds: 150),
              child: _ChallengeDayDetail(
                key: ValueKey(
                  'detail-${ChallengeProgressService.formatLocalDate(selectedDate)}',
                ),
                l10n: l10n,
                date: selectedDate,
                status: selectedStatus,
                isBusy: _isStartingSelectedChallenge,
                onStart: _startSelectedChallenge,
              ),
            ),
          ],
          if (widget.footerText != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              widget.footerText!,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _maybeAnimatedSize({
    required bool reduceMotion,
    required Duration duration,
    required Widget child,
  }) {
    if (reduceMotion) return child;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// 달력 조회 실패 시 스켈레톤 대신 보여줄 오류 문구 + 재시도.
class _CalendarLoadError extends StatelessWidget {
  const _CalendarLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            l10n.challengeCalendarLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.recordsRetry),
          ),
        ],
      ),
    );
  }
}

/// 선택한 날짜의 상태와 시작/이어하기/다시 풀기 버튼. 과거 도전은 연속
/// 기록에서 제외된다는 안내를 함께 보여준다. 긴 번역에서도 잘리지 않게
/// 최소 높이만 두고 필요한 만큼 늘어난다.
class _ChallengeDayDetail extends StatelessWidget {
  const _ChallengeDayDetail({
    super.key,
    required this.l10n,
    required this.date,
    required this.status,
    required this.isBusy,
    required this.onStart,
  });

  final AppLocalizations l10n;
  final DateTime date;
  final ChallengeDayStatus status;
  final bool isBusy;
  final VoidCallback onStart;

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _statusLabel() {
    switch (status) {
      case ChallengeDayStatus.future:
        return l10n.challengeStatusFuture;
      case ChallengeDayStatus.notCompleted:
        return l10n.challengeStatusNotCompleted;
      case ChallengeDayStatus.inProgress:
        return l10n.challengeStatusInProgress;
      case ChallengeDayStatus.completed:
        return l10n.challengeStatusCompleted;
      case ChallengeDayStatus.perfectCompleted:
        return l10n.challengeStatusPerfect;
    }
  }

  String _buttonLabel() {
    switch (status) {
      case ChallengeDayStatus.future:
      case ChallengeDayStatus.notCompleted:
        return _isToday
            ? l10n.homeTodayChallengeStartButton
            : l10n.challengeStartPastChallenge;
      case ChallengeDayStatus.inProgress:
        return _isToday
            ? l10n.homeTodayChallengeResumeButton
            : l10n.challengeResumePastChallenge;
      case ChallengeDayStatus.completed:
      case ChallengeDayStatus.perfectCompleted:
        return _isToday
            ? l10n.homeTodayChallengeReviewButton
            : l10n.challengeRetryPastChallenge;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateLabel =
        DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(date);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$dateLabel · ${_statusLabel()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          if (!_isToday) ...[
            const SizedBox(height: 4),
            Text(
              l10n.challengeStreakExcludedNote,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isBusy ? null : onStart,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(_buttonLabel(), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGridSkeleton extends StatelessWidget {
  const _MonthGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LoadingSkeletonPulse(
      key: const Key('challenge_calendar_skeleton'),
      builder: (context, color) => Column(
        children: [
          for (var row = 0; row < 6; row++) ...[
            if (row > 0) const SizedBox(height: 6),
            Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: Center(
                      child: SkeletonBox(
                        color: color,
                        width: 24,
                        height: 24,
                        borderRadius: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstDayOfWeekIndex =
        MaterialLocalizations.of(context).firstDayOfWeekIndex;
    // DateTime.weekday: 1=월 ... 7=일. firstDayOfWeekIndex: 0=일 ... 6=토.
    final orderedWeekdays = List.generate(7, (i) {
      final sundayBased = (firstDayOfWeekIndex + i) % 7;
      return sundayBased == 0 ? 7 : sundayBased;
    });
    return Row(
      children: [
        for (final weekday in orderedWeekdays)
          Expanded(
            child: Center(
              child: Text(
                DateFormat.E(locale).format(
                  DateTime(2024, 1, weekday), // 2024-01-01은 월요일(weekday=1)
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.calendar,
    required this.l10n,
    required this.selectedDate,
    required this.reduceMotion,
    required this.onDayTap,
  });

  final DateTime month;
  final ChallengeMonthCalendar calendar;
  final AppLocalizations l10n;
  final DateTime? selectedDate;
  final bool reduceMotion;
  final void Function(DateTime date, ChallengeDayStatus status) onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDayOfWeekIndex =
        MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDay = DateTime(month.year, month.month, 1);
    // firstDay.weekday: 1=월..7=일 → 일요일 기준(0..6)으로 변환.
    final firstDaySundayBased = firstDay.weekday % 7;
    final leadingBlanks = (firstDaySundayBased - firstDayOfWeekIndex + 7) % 7;

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          date: DateTime(month.year, month.month, day),
          status:
              calendar.statusByDate[ChallengeProgressService.formatLocalDate(
                    DateTime(month.year, month.month, day),
                  )] ??
                  ChallengeDayStatus.notCompleted,
          isSelected: selectedDate != null &&
              selectedDate!.year == month.year &&
              selectedDate!.month == month.month &&
              selectedDate!.day == day,
          reduceMotion: reduceMotion,
          l10n: l10n,
          onTap: onDayTap,
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.status,
    required this.isSelected,
    required this.reduceMotion,
    required this.l10n,
    required this.onTap,
  });

  final DateTime date;
  final ChallengeDayStatus status;
  final bool isSelected;
  final bool reduceMotion;
  final AppLocalizations l10n;
  final void Function(DateTime date, ChallengeDayStatus status) onTap;

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _statusLabel() {
    switch (status) {
      case ChallengeDayStatus.future:
        return l10n.challengeStatusFuture;
      case ChallengeDayStatus.notCompleted:
        return l10n.challengeStatusNotCompleted;
      case ChallengeDayStatus.inProgress:
        return l10n.challengeStatusInProgress;
      case ChallengeDayStatus.completed:
        return l10n.challengeStatusCompleted;
      case ChallengeDayStatus.perfectCompleted:
        return l10n.challengeStatusPerfect;
    }
  }

  Widget? _statusIcon(Color onFillColor, Color onSurfaceVariant) {
    switch (status) {
      case ChallengeDayStatus.future:
        return null;
      case ChallengeDayStatus.notCompleted:
        return null;
      case ChallengeDayStatus.inProgress:
        return Icon(Icons.edit_note, size: 12, color: onSurfaceVariant);
      case ChallengeDayStatus.completed:
        return Icon(Icons.check_circle, size: 12, color: onFillColor);
      case ChallengeDayStatus.perfectCompleted:
        return Icon(Icons.star, size: 12, color: onFillColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = LevelStatusPalette.of(context);
    final isFuture = status == ChallengeDayStatus.future;
    final isFilled = status == ChallengeDayStatus.completed ||
        status == ChallengeDayStatus.perfectCompleted;
    // 완료·완벽 완료: 보라색 채움(흰 글자). 진행 중: 연한 라벤더. 미완료:
    // 기본 surface. 미래: Opacity로 흐리게(아래에서 처리).
    final fillColor = isFilled
        ? palette.primaryPurple
        : status == ChallengeDayStatus.inProgress
            ? palette.completedBackground
            : Colors.transparent;
    final dayTextColor = isFilled ? Colors.white : colorScheme.onSurface;
    final icon = _statusIcon(Colors.white, colorScheme.onSurfaceVariant);
    final label = l10n.challengeDayCellSemantics(
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date),
      _statusLabel(),
    );

    return Semantics(
      button: !isFuture,
      enabled: !isFuture,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: isFuture ? 0.35 : 1.0,
        child: Material(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: isFuture ? null : () => onTap(date, status),
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 130),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: palette.primaryPurple, width: 2)
                    : _isToday
                        ? Border.all(color: colorScheme.onSurface, width: 2)
                        : null,
              ),
              // 날짜 칸은 31개를 한 화면에 고정 크기 격자로 보여줘야 해서,
              // 시스템 글자 크기를 키워도 칸 자체는 커지지 않는다(다른
              // 달력 앱과 같은 관례) — 그렇지 않으면 칸 높이를 넘쳐 오버플로가 난다.
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _isToday ? FontWeight.bold : FontWeight.w500,
                        color: dayTextColor,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(height: 2),
                      icon,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
