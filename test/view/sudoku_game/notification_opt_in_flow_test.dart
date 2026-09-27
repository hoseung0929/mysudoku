import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/challenge/achievement_service.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/view/sudoku_game/game_completion_coordinator.dart';
import 'package:sudoku159/view/sudoku_game/game_end_flow.dart';
import 'package:sudoku159/view/sudoku_game/notification_opt_in_flow.dart';

import '../../helpers/fake_notifications.dart';

/// DB 없이 완료 저장이 끝난 상태를 흉내 낸다.
class FakeCoordinator extends GameCompletionCoordinator {
  FakeCoordinator(this.log, {this.nextGame});

  final List<String> log;
  final SudokuGame? nextGame;

  @override
  Future<GameCompletionData> prepare({
    required AppLocalizations l10n,
    required SudokuLevel level,
    required SudokuGame game,
    required int clearTimeSeconds,
    required int wrongCount,
    required int hintsUsed,
    bool autoNotesUsed = false,
    String? challengeDate,
    bool challengeCountsForStreak = true,
  }) async {
    log.add('saved');
    return GameCompletionData(
      isNewBestRecord: false,
      newlyUnlockedBadges: const <AchievementBadge>[],
      challengeMessage: null,
      nextGame: nextGame,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final level = SudokuLevel.levels.first;
  final game = SudokuGame(
    board: List.generate(9, (_) => List.filled(9, 1)),
    solution: List.generate(9, (_) => List.filled(9, 1)),
    emptyCells: level.emptyCells,
    levelName: level.name,
    gameNumber: 1,
  );
  const prompt = ValueKey('notification-opt-in-dialog');

  Future<void> pumpHost(
    WidgetTester tester,
    Future<void> Function(BuildContext context) onPressed, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeData? theme,
    Locale? locale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.lightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => onPressed(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> prefBool(String key) async =>
      (await SharedPreferences.getInstance()).getBool(key);

  group('NotificationOptInFlow', () {
    testWidgets('accept + granted turns reminders on and schedules them',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeGateway();
      final flow = NotificationOptInFlow(
          notificationService: notificationServiceWith(gateway));
      await pumpHost(tester, flow.maybeShow);

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.byKey(prompt), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(gateway.permissionRequests, 0);

      await tester.tap(find.text('Turn on reminders'));
      await tester.pumpAndSettle();
      expect(gateway.permissionRequests, 1);
      expect(gateway.pending, hasLength(7));
      expect(find.byType(SnackBar), findsNothing);
      expect(
          await prefBool(AppSettingsService.notificationsEnabledKey), isTrue);
      expect(
        await prefBool(AppSettingsService.notificationOptInPromptSeenKey),
        isTrue,
      );
    });

    testWidgets('accept + denied keeps reminders off and explains',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeGateway(grant: false);
      final flow = NotificationOptInFlow(
          notificationService: notificationServiceWith(gateway));
      await pumpHost(tester, flow.maybeShow);

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn on reminders'));
      await tester.pumpAndSettle();
      expect(
          await prefBool(AppSettingsService.notificationsEnabledKey), isFalse);
      expect(gateway.pending, isEmpty);
      expect(gateway.cancelled, isNotEmpty);
      expect(
          find.textContaining("Notifications aren't allowed"), findsOneWidget);
    });

    testWidgets('not now and outside tap never request permission',
        (tester) async {
      for (final dismiss in ['later', 'barrier']) {
        SharedPreferences.setMockInitialValues({});
        final gateway = FakeGateway();
        final flow = NotificationOptInFlow(
            notificationService: notificationServiceWith(gateway));
        await pumpHost(tester, flow.maybeShow);
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        if (dismiss == 'later') {
          await tester.tap(find.text('Not now'));
        } else {
          await tester.tapAt(const Offset(5, 5));
        }
        await tester.pumpAndSettle();
        expect(find.byKey(prompt), findsNothing, reason: dismiss);
        expect(gateway.permissionRequests, 0, reason: dismiss);
        expect(find.byType(SnackBar), findsNothing, reason: dismiss);
        expect(
          await prefBool(AppSettingsService.notificationsEnabledKey),
          isNull,
          reason: dismiss,
        );
        expect(
          await prefBool(AppSettingsService.notificationOptInPromptSeenKey),
          isTrue,
          reason: dismiss,
        );
      }
    });

    for (final failure in [
      (
        name: 'permission request throws',
        gateway: () => FakeGateway(throwOnPermission: true)
      ),
      (
        name: 'scheduling throws midway',
        gateway: () => FakeGateway(throwOnScheduleAt: 2)
      ),
    ]) {
      testWidgets('${failure.name}: OFF, reminders cleared, failure notice',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        final gateway = failure.gateway();
        final flow = NotificationOptInFlow(
            notificationService: notificationServiceWith(gateway));
        await pumpHost(tester, flow.maybeShow);
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Turn on reminders'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(await prefBool(AppSettingsService.notificationsEnabledKey),
            isFalse);
        expect(gateway.pending, isEmpty);
        expect(gateway.cancelled, isNotEmpty);
        expect(
            find.text(
                "We couldn't set up reminders. Please try again later in Settings."),
            findsOneWidget);
        expect(
          await prefBool(AppSettingsService.notificationOptInPromptSeenKey),
          isTrue,
        );
        // 실패 뒤에도 다시 묻지 않는다.
        expect(await flow.shouldShow(), isFalse);
      });
    }

    testWidgets('no snackbar once the calling screen is gone', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeGateway(grant: false)..holdPermission = Completer();
      final flow = NotificationOptInFlow(
          notificationService: notificationServiceWith(gateway));
      Future<void>? running;
      await pumpHost(tester, (context) => running = flow.maybeShow(context));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn on reminders'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox()); // 화면 dispose
      gateway.holdPermission!.complete();
      await tester.pump();
      await running;
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shown only once, and not when already turned on',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        AppSettingsService.notificationOptInPromptSeenKey: true,
      });
      expect(await NotificationOptInFlow().shouldShow(), isFalse);
      SharedPreferences.setMockInitialValues({
        AppSettingsService.notificationsEnabledKey: true,
      });
      expect(await NotificationOptInFlow().shouldShow(), isFalse);
      SharedPreferences.setMockInitialValues({});
      expect(await NotificationOptInFlow().shouldShow(), isTrue);
    });

    for (final variant in [
      (name: 'small light 2x', dark: false, size: const Size(320, 568)),
      (name: 'small dark 2x', dark: true, size: const Size(320, 568)),
    ]) {
      for (final locale in const [
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
        Locale('zh'),
        Locale('es'),
      ]) {
        testWidgets('fits ${variant.name} ($locale)', (tester) async {
          SharedPreferences.setMockInitialValues({});
          final flow = NotificationOptInFlow(
              notificationService: notificationServiceWith(FakeGateway()));
          await pumpHost(
            tester,
            flow.maybeShow,
            size: variant.size,
            textScale: 2.0,
            theme: variant.dark ? AppTheme.darkTheme() : null,
            locale: locale,
          );
          await tester.tap(find.text('go'));
          await tester.pumpAndSettle();
          expect(find.byKey(prompt), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('GameEndFlow ordering', () {
    testWidgets('prompt appears only after the result dialog is closed',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final log = <String>[];
      final gateway = FakeGateway();
      final endFlow = GameEndFlow(
        completionCoordinator: FakeCoordinator(log),
        notificationOptInFlow: NotificationOptInFlow(
            notificationService: notificationServiceWith(gateway)),
      );
      await pumpHost(tester, (context) async {
        await endFlow.showCompletion(
          context: context,
          level: level,
          game: game,
          clearTimeSeconds: 60,
          wrongCount: 0,
          hintsUsed: 0,
          onRestart: () async => log.add('restart'),
          onGoToLevelSelection: () async => log.add('list'),
          onNextPuzzle: (_) async => log.add('next'),
        );
      });

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(log, ['saved']);
      expect(find.text('Puzzle list'), findsOneWidget);
      expect(find.byKey(prompt), findsNothing);

      await tester.tap(find.text('Puzzle list'));
      await tester.pumpAndSettle();
      expect(find.byKey(prompt), findsOneWidget);
      expect(log, ['saved']); // 이동은 안내를 닫은 뒤에 실행된다.

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(log, ['saved', 'list']);
      expect(gateway.permissionRequests, 0);
    });

    testWidgets('second completion does not show the prompt again',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        AppSettingsService.notificationOptInPromptSeenKey: true,
      });
      final log = <String>[];
      final endFlow = GameEndFlow(
        completionCoordinator: FakeCoordinator(log),
        notificationOptInFlow: NotificationOptInFlow(
          notificationService: notificationServiceWith(FakeGateway()),
        ),
      );
      await pumpHost(tester, (context) async {
        await endFlow.showCompletion(
          context: context,
          level: level,
          game: game,
          clearTimeSeconds: 60,
          wrongCount: 0,
          hintsUsed: 0,
          onRestart: () async => log.add('restart'),
          onGoToLevelSelection: () async => log.add('list'),
          onNextPuzzle: (_) async => log.add('next'),
        );
      });
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Puzzle list'));
      await tester.pumpAndSettle();
      expect(find.byKey(prompt), findsNothing);
      expect(log, ['saved', 'list']);
    });

    Future<List<String>> completeThenPick(
      WidgetTester tester, {
      required FakeGateway gateway,
      required String button,
      bool withNext = false,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final log = <String>[];
      final endFlow = GameEndFlow(
        completionCoordinator:
            FakeCoordinator(log, nextGame: withNext ? game : null),
        notificationOptInFlow: NotificationOptInFlow(
            notificationService: notificationServiceWith(gateway)),
      );
      await pumpHost(tester, (context) async {
        await endFlow.showCompletion(
          context: context,
          level: level,
          game: game,
          clearTimeSeconds: 60,
          wrongCount: 0,
          hintsUsed: 0,
          onRestart: () async => log.add('restart'),
          onGoToLevelSelection: () async => log.add('list'),
          onNextPuzzle: (_) async => log.add('next'),
        );
      });
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.byKey(prompt), findsNothing);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(log, ['saved'], reason: 'prompt must come before navigation');
      await tester.tap(find.text('Turn on reminders'));
      await tester.pumpAndSettle();
      // 결과창 버튼을 한 번 더 눌러도 이동은 한 번만.
      expect(find.text(button), findsNothing);
      expect(tester.takeException(), isNull);
      return log;
    }

    testWidgets('permission error still opens the next puzzle once',
        (tester) async {
      final log = await completeThenPick(
        tester,
        gateway: FakeGateway(throwOnPermission: true),
        button: 'Next puzzle',
        withNext: true,
      );
      expect(log, ['saved', 'next']);
    });

    testWidgets('permission error still restarts once', (tester) async {
      final log = await completeThenPick(
        tester,
        gateway: FakeGateway(throwOnPermission: true),
        button: 'Solve this puzzle again',
      );
      expect(log, ['saved', 'restart']);
    });

    testWidgets('scheduling error still goes to the puzzle list once',
        (tester) async {
      final log = await completeThenPick(
        tester,
        gateway: FakeGateway(throwOnScheduleAt: 0),
        button: 'Puzzle list',
      );
      expect(log, ['saved', 'list']);
    });
  });
}
