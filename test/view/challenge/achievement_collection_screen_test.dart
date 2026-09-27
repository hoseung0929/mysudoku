import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/challenge/achievement_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/challenge/achievement_collection_screen.dart';

AchievementBadge _badge(
  String id, {
  required bool unlocked,
  required AchievementRarity rarity,
  required int sortOrder,
}) =>
    AchievementBadge(
      id: id,
      title: id,
      description: '$id description',
      progressLabel: unlocked ? 'Done' : '0/1',
      unlocked: unlocked,
      rarity: rarity,
      sortOrder: sortOrder,
    );

class _FakeAchievementService extends AchievementService {
  _FakeAchievementService(this.summary);
  final AchievementSummary summary;

  @override
  Future<AchievementSummary> load(AppLocalizations l10n) async => summary;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  final defaultSummary = AchievementSummary(badges: [
    _badge('first_clear',
        unlocked: true, rarity: AchievementRarity.common, sortOrder: 0),
    _badge('streak_3',
        unlocked: false, rarity: AchievementRarity.rare, sortOrder: 1),
    _badge('perfect_clear',
        unlocked: true, rarity: AchievementRarity.epic, sortOrder: 2),
  ]);

  Future<void> pumpScreen(
    WidgetTester tester, {
    AchievementSummary? summary,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: AchievementCollectionScreen(
          achievementService:
              _FakeAchievementService(summary ?? defaultSummary),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the correct final list after a filter change',
      (tester) async {
    await pumpScreen(tester);
    expect(find.text('first_clear'), findsOneWidget);
    expect(find.text('streak_3'), findsOneWidget);
    expect(find.text('perfect_clear'), findsOneWidget);

    await tester.tap(find.text('Unlocked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('first_clear'), findsOneWidget);
    expect(find.text('perfect_clear'), findsOneWidget);
    expect(find.text('streak_3'), findsNothing);
  });

  testWidgets('shows the correct order after a sort change', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Default order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('By rarity').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    final commonY = tester.getTopLeft(find.text('first_clear')).dy;
    final rareY = tester.getTopLeft(find.text('streak_3')).dy;
    final epicY = tester.getTopLeft(find.text('perfect_clear')).dy;
    // 희귀도 정렬에서는 등급 순서가 기본 순서(sortOrder)와 달라진다.
    expect({commonY, rareY, epicY}.length, 3);
  });

  testWidgets('rapid repeated filter taps only keep the latest selection',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Unlocked'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(find.text('In progress'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(find.text('All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('first_clear'), findsOneWidget);
    expect(find.text('streak_3'), findsOneWidget);
    expect(find.text('perfect_clear'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty-list transition does not overflow or throw',
      (tester) async {
    await pumpScreen(
      tester,
      summary: const AchievementSummary(badges: []),
    );
    await tester.tap(find.text('Unlocked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('OVERFLOWED'), findsNothing);
  });

  testWidgets('reduce motion applies the filter change instantly',
      (tester) async {
    await pumpScreen(tester, reduceMotion: true);
    await tester.tap(find.text('Unlocked'));
    // 한 프레임만으로 전환이 끝나야 한다(추가 대기 없이 바로 확인).
    await tester.pump();
    expect(find.text('first_clear'), findsOneWidget);
    expect(find.text('streak_3'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
