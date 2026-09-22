import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/core/policy/smart_mode_prefs_repository.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n09_smart_modes/smart_modes_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets(
    'SET-019 P12: activate school on parent → CHD-004 shows school same session',
    (tester) async {
      final bus = SmartModeActivationBus();
      final repo = InMemorySmartModePrefsRepository();
      final childId = ChildId(SmartModePrefs.defaultChildId);

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: childId,
            activationBus: bus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.idleStatus), findsOneWidget);
      expect(find.byKey(ChildDayBoardKeys.activeModeLabel), findsNothing);
      final childState = tester.state(find.byType(ChildDayBoardScreen));

      // Parent FAT-085 same isolate: save + publish (no child cold restart).
      await repo.save(
        SmartModePrefs.defaults(childId: childId.value).withRow(
          const SmartModeRow(
            modeId: BuiltInModeId.school,
            active: true,
            scheduleStart: SmartModeRow.defaultSchoolStart,
            scheduleEnd: SmartModeRow.defaultSchoolEnd,
          ),
        ),
      );
      bus.publish(
        SmartModeActivation(
          childId: childId.value,
          modeId: BuiltInModeId.school,
          active: true,
          updatedAt: DateTime.utc(2026, 9, 21, 8),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.activeModeLabel), findsOneWidget);
      expect(find.textContaining('المدرسة'), findsOneWidget);
      expect(
        identical(childState, tester.state(find.byType(ChildDayBoardScreen))),
        isTrue,
      );

      bus.publish(
        SmartModeActivation(
          childId: childId.value,
          modeId: null,
          active: false,
          updatedAt: DateTime.utc(2026, 9, 21, 9),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildDayBoardKeys.idleStatus), findsOneWidget);
      expect(find.byKey(ChildDayBoardKeys.activeModeLabel), findsNothing);
    },
  );

  testWidgets(
    'SET-019 FAT-085 toggle school publishes activation for demo child',
    (tester) async {
      final bus = SmartModeActivationBus();
      final repo = InMemorySmartModePrefsRepository();

      await tester.pumpWidget(
        _wrap(
          SmartModesScreen(
            repository: repo,
            activationBus: bus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(bus.activationOf(SmartModePrefs.defaultChildId).active, isFalse);

      final schoolSwitch =
          find.byKey(SmartModesKeys.modeSwitch(BuiltInModeId.school));
      await tester.ensureVisible(schoolSwitch);
      await tester.pumpAndSettle();
      await tester.tap(schoolSwitch);
      await tester.pumpAndSettle();

      final act = bus.activationOf(SmartModePrefs.defaultChildId);
      expect(act.active, isTrue);
      expect(act.modeId, BuiltInModeId.school);
      expect(act.expiresAt, isNotNull);

      await tester.ensureVisible(schoolSwitch);
      await tester.pumpAndSettle();
      await tester.tap(schoolSwitch);
      await tester.pumpAndSettle();

      final cleared = bus.activationOf(SmartModePrefs.defaultChildId);
      expect(cleared.active, isFalse);
      expect(cleared.modeId, isNull);
    },
  );

  testWidgets(
    'SET-019 offline: child keeps last activation until reconnect',
    (tester) async {
      final bus = SmartModeActivationBus();
      const childKey = SmartModePrefs.defaultChildId;
      final childId = ChildId(childKey);
      bus.hydrate(
        SmartModeActivation(
          childId: childKey,
          modeId: BuiltInModeId.school,
          active: true,
          updatedAt: DateTime.utc(2026, 9, 21, 8),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          ChildDayBoardScreen(
            childId: childId,
            activationBus: bus,
            showModeNotices: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ChildDayBoardKeys.activeModeLabel), findsOneWidget);

      bus.markChildOffline(childKey);
      bus.publish(
        SmartModeActivation(
          childId: childKey,
          modeId: null,
          active: false,
          updatedAt: DateTime.utc(2026, 9, 21, 9),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ChildDayBoardKeys.activeModeLabel), findsOneWidget);

      bus.markChildOnline(childKey);
      await tester.pumpAndSettle();
      expect(find.byKey(ChildDayBoardKeys.idleStatus), findsOneWidget);
    },
  );

  test('SmartModeActivation json round-trip', () {
    final a = SmartModeActivation(
      childId: 'c1',
      modeId: BuiltInModeId.school,
      active: true,
      updatedAt: DateTime.utc(2026, 9, 21, 10, 30),
      expiresAt: DateTime.utc(2026, 9, 21, 13, 45),
    );
    final b = SmartModeActivation.fromJson(a.toJson());
    expect(b, a);
  });
}

Widget _wrap(Widget home) {
  return MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}
