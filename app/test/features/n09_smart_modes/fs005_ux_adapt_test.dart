import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/components/mode_disclosure_card.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/modes/modes.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n09_smart_modes/modes_ux_bridge.dart';
import 'package:family_os/features/n09_smart_modes/smart_modes_screen.dart';

void main() {
  late MemoryLocalDatabase db;
  late ModesService service;
  final family = FamilyId('fam_ux');
  final child = ChildId('child_demo');
  final now = DateTime.utc(2026, 9, 24, 22);
  var idSeq = 0;

  setUp(() async {
    idSeq = 0;
    db = MemoryLocalDatabase();
    await db.open();
    service = ModesService(
      store: LocalModesStore(db, clock: () => now),
      familyId: family,
      clock: () => now,
      idFactory: () {
        idSeq += 1;
        return 'ux-$idSeq';
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'FAT-085 Modes bind: ownership + wake honesty + school activate',
    (tester) async {
      await tester.pumpWidget(
        _app(
          child: SmartModesScreen(
            childId: child.value,
            modes: service,
            roleOverride: AppRole.father,
            pickTime: (context, initial) async =>
                const TimeOfDay(hour: 8, minute: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(SmartModesKeys.ownershipBanner), findsOneWidget);
      expect(find.byKey(SmartModesKeys.wakeHonesty), findsOneWidget);
      expect(find.byType(CapabilityHonestyBadge), findsOneWidget);
      expect(find.byKey(SmartModesKeys.examsHint), findsOneWidget);

      await tester.tap(
        find.byKey(SmartModesKeys.modeSwitch(BuiltInModeId.school)),
      );
      await tester.pumpAndSettle();

      final eval = await service.evaluateChild(child, at: now);
      expect(
        eval.applicableModeIds,
        contains(ModesUxBridge.modeDocumentId(BuiltInModeId.school)),
      );

      await tester.tap(find.byKey(SmartModesKeys.schoolStart));
      await tester.pumpAndSettle();
      final modes = await service.listModes();
      final school = modes.firstWhere(
        (m) => m.id == ModesUxBridge.modeDocumentId(BuiltInModeId.school),
      );
      expect(school.clockWindow?.startMinutes, 8 * 60);
    },
  );

  testWidgets('multi-mode stack disclosure on CHD-004', (tester) async {
    await service.saveMode(
      draft: ModesUxBridge.draftFor(
        id: BuiltInModeId.school,
        familyId: family,
        start: const TimeOfDay(hour: 7, minute: 0),
        end: const TimeOfDay(hour: 14, minute: 0),
      ),
      actor: const ModesActor.father(),
    );
    await service.saveMode(
      draft: ModesUxBridge.draftFor(id: BuiltInModeId.study, familyId: family),
      actor: const ModesActor.father(),
    );
    await service.activateManual(
      modeId: ModesUxBridge.modeDocumentId(BuiltInModeId.school),
      childId: child,
      actor: const ModesActor.father(),
    );
    await service.activateManual(
      modeId: ModesUxBridge.modeDocumentId(BuiltInModeId.study),
      childId: child,
      actor: const ModesActor.father(),
    );

    await tester.pumpWidget(
      _app(
        child: ChildDayBoardScreen(
          childId: child,
          modes: service,
          activationBus: SmartModeActivationBus(),
          showModeNotices: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Async Modes evaluation after first frame.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byKey(ChildDayBoardKeys.modeDisclosure), findsOneWidget);
    expect(find.byKey(ModeDisclosureKeys.multi), findsOneWidget);
    expect(find.byKey(ModeDisclosureKeys.reachability), findsOneWidget);
  });

  test('exams maps to study catalog id', () {
    expect(
      ModesUxBridge.modeDocumentId(BuiltInModeId.exams),
      ModesUxBridge.modeDocumentId(BuiltInModeId.study),
    );
  });
}

Widget _app({required Widget child}) {
  return CurrentRole(
    notifier: RoleController(AppRole.father),
    child: MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
