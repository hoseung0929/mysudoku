import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/profile/profile_image_service.dart';
import 'package:sudoku159/services/profile/profile_state_controller.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/widgets/profile_editor_sheet.dart';

typedef _Saved = ({String? name, bool removeImage, String? bio});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openSheet(
    WidgetTester tester, {
    required ProfileSaveCallback onSave,
    String? name = 'Traveler One',
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showProfileEditorSheet(
                  context: context,
                  profileImageService: ProfileImageService(),
                  initialProfileName: name,
                  initialProfileImagePath: null,
                  onSave: onSave,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bio input and its notice are gone; name and photo remain',
      (tester) async {
    await openSheet(tester,
        onSave: ({
          required name,
          required removeImage,
          pickedImagePath,
          bio,
        }) async {});
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Bio'), findsNothing);
    expect(
        find.text('Write a short introduction about yourself'), findsNothing);
    expect(find.textContaining('displayed on your profile'), findsNothing);
    // 남은 입력란은 이름 하나뿐.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Default profile'), findsOneWidget);
    expect(find.text('Choose from album'), findsOneWidget);
  });

  testWidgets('saving sends the new name and never sends a bio',
      (tester) async {
    _Saved? saved;
    await openSheet(tester, onSave: ({
      required name,
      required removeImage,
      pickedImagePath,
      bio,
    }) async {
      saved = (name: name, removeImage: removeImage, bio: bio);
    });
    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(saved, isNotNull);
    expect(saved!.name, 'Renamed');
    expect(saved!.bio, isNull); // null = 저장된 소개를 건드리지 않음
    expect(find.byType(TextField), findsNothing); // 시트가 닫힘
  });

  testWidgets('end to end: rename through the real controller keeps the bio',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'profile_name': 'Before',
      'profile_bio': 'Existing intro',
    });
    await tester.runAsync(() => ProfileStateController.instance.refresh());
    await openSheet(
      tester,
      name: 'Before',
      onSave: ({
        required name,
        required removeImage,
        pickedImagePath,
        bio,
      }) =>
          ProfileStateController.instance.save(
        name: name,
        removeImage: removeImage,
        pickedImagePath: pickedImagePath,
        bio: bio,
      ),
    );
    await tester.enterText(find.byType(TextField), 'After');
    await tester.tap(find.text('Save'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final controller = ProfileStateController.instance;
    expect(controller.name, 'After');
    expect(controller.bio, 'Existing intro');
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getString('profile_bio'), 'Existing intro');
  });

  testWidgets('dismissing without saving changes nothing', (tester) async {
    var called = 0;
    await openSheet(tester, onSave: ({
      required name,
      required removeImage,
      pickedImagePath,
      bio,
    }) async {
      called++;
    });
    await tester.enterText(find.byType(TextField), 'Edited but not saved');
    // 아래로 끌어내려 저장 없이 닫는다.
    await tester.drag(find.text('Edit profile'), const Offset(0, 700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(called, 0);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('resetting to the default photo sends removeImage, no bio',
      (tester) async {
    _Saved? saved;
    await openSheet(tester, onSave: ({
      required name,
      required removeImage,
      pickedImagePath,
      bio,
    }) async {
      saved = (name: name, removeImage: removeImage, bio: bio);
    });
    await tester.tap(find.text('Default profile'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(saved!.removeImage, isTrue);
    expect(saved!.bio, isNull);
  });

  for (final entry in {
    'phone 1x': (const Size(390, 844), 1.0, false),
    'small phone 2x dark': (const Size(320, 568), 2.0, true),
    'tablet': (const Size(768, 1024), 1.0, false),
  }.entries) {
    testWidgets('no overflow and save reachable: ${entry.key}', (tester) async {
      final (size, scale, dark) = entry.value;
      await openSheet(
        tester,
        size: size,
        textScale: scale,
        theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
        onSave: ({
          required name,
          required removeImage,
          pickedImagePath,
          bio,
        }) async {},
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Save'));
      await tester.pump();
      expect(find.text('Save'), findsOneWidget);
    });
  }
}
