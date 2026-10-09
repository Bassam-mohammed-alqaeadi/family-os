import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';
import 'package:family_os/core/policy/sos_settings.dart';
import 'package:family_os/features/n06_notifications/notification_prefs_screen.dart';
import 'package:family_os/features/n10_emergency/emergency_setup_screen.dart';

void main() {
  tearDown(AppToast.dismiss);
  testWidgets(
    'rung 1 shows father+mother locked — no remove; switch off disabled',
    (tester) async {
      final repo = InMemorySosLadderRepository({
        SosLadder.defaultFamilyId: SosLadder.defaults().copyWith(
          backups: const [
            SosBackupContact(id: 'uncle', name: 'عم فيصل', delaySeconds: 60),
          ],
        ),
      });

      await _pump(tester, repository: repo);

      expect(
        find.byKey(EmergencySetupKeys.parentRow('father')),
        findsOneWidget,
      );
      expect(
        find.byKey(EmergencySetupKeys.parentRow('mother')),
        findsOneWidget,
      );
      expect(
        find.byKey(EmergencySetupKeys.parentRemove('father')),
        findsNothing,
      );
      expect(
        find.byKey(EmergencySetupKeys.parentRemove('mother')),
        findsNothing,
      );

      final motherSwitch = tester.widget<Switch>(
        find.byKey(EmergencySetupKeys.parentSwitch('mother')),
      );
      expect(motherSwitch.value, isTrue);
      expect(motherSwitch.onChanged, isNull);

      final fatherSwitch = tester.widget<Switch>(
        find.byKey(EmergencySetupKeys.parentSwitch('father')),
      );
      expect(fatherSwitch.value, isTrue);
      expect(fatherSwitch.onChanged, isNull);

      expect(find.text('إلزامي'), findsWidgets);
    },
  );

  testWidgets('cannot remove mother from rung 1 — inline ARB error', (
    tester,
  ) async {
    final repo = InMemorySosLadderRepository();
    await _pump(tester, repository: repo);

    final state = tester.state<EmergencySetupScreenState>(
      find.byType(EmergencySetupScreen),
    );
    await state.attemptRemove('mother');
    await tester.pumpAndSettle();

    expect(find.byKey(EmergencySetupKeys.inlineError), findsOneWidget);
    expect(
      find.text('لا يمكن إزالة الوالدين من الدرجة الأولى في سلّم الطوارئ'),
      findsOneWidget,
    );
    final ladder = await repo.load();
    expect(ladder.rung1MemberIds, contains('mother'));
  });

  testWidgets('backups editable on lower rung — toggle + remove', (
    tester,
  ) async {
    final repo = InMemorySosLadderRepository({
      SosLadder.defaultFamilyId: SosLadder.defaults().copyWith(
        backups: const [
          SosBackupContact(id: 'uncle', name: 'عم فيصل', enabled: true),
        ],
      ),
    });

    await _pump(tester, repository: repo);

    expect(find.byKey(EmergencySetupKeys.backupRow('uncle')), findsOneWidget);
    expect(
      find.byKey(EmergencySetupKeys.backupRemove('uncle')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(EmergencySetupKeys.backupSwitch('uncle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EmergencySetupKeys.backupSwitch('uncle')));
    await tester.pumpAndSettle();

    var ladder = await repo.load();
    expect(ladder.backups.single.enabled, isFalse);

    await tester.ensureVisible(
      find.byKey(EmergencySetupKeys.backupRemove('uncle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EmergencySetupKeys.backupRemove('uncle')));
    await tester.pumpAndSettle();

    ladder = await repo.load();
    expect(ladder.backups, isEmpty);
    expect(find.byKey(EmergencySetupKeys.backupRow('uncle')), findsNothing);
  });

  testWidgets('add backup CTA opens sheet and saves editable rung 2+', (
    tester,
  ) async {
    final repo = InMemorySosLadderRepository();
    await _pump(tester, repository: repo);

    await tester.ensureVisible(find.byKey(EmergencySetupKeys.addBackup));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EmergencySetupKeys.addBackup));
    await tester.pumpAndSettle();

    expect(find.byKey(EmergencySetupKeys.backupSheet), findsOneWidget);
    await tester.tap(find.byKey(EmergencySetupKeys.backupSave));
    await tester.pumpAndSettle();

    final ladder = await repo.load();
    expect(ladder.backups, hasLength(1));
    expect(
      find.byKey(EmergencySetupKeys.backupSwitch(ladder.backups.single.id)),
      findsOneWidget,
    );
  });

  testWidgets('live readiness rows render on FAT-028', (tester) async {
    final repo = InMemorySosLadderRepository();
    await _pump(tester, repository: repo);

    expect(find.byKey(EmergencySetupKeys.readinessCard), findsOneWidget);
    expect(
      find.byKey(const Key('sos_readiness_dot_trusted_ladder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('sos_readiness_dot_push_alerts')),
      findsOneWidget,
    );
  });

  testWidgets('Mother Partner cannot configure — read-only summary', (
    tester,
  ) async {
    final repo = InMemorySosLadderRepository({
      SosLadder.defaultFamilyId: SosLadder.defaults().copyWith(
        backups: const [
          SosBackupContact(
            id: 'uncle',
            name: 'عم',
            enabled: true,
            verification: SosVerificationStatus.verified,
          ),
        ],
      ),
    });
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );

    expect(find.byKey(EmergencySetupKeys.readOnlyLean), findsOneWidget);
    expect(find.byKey(EmergencySetupKeys.partnerSummary), findsOneWidget);
    expect(find.byKey(EmergencySetupKeys.addBackup), findsNothing);
    expect(find.textContaining('جهة خارجية موثّقة'), findsOneWidget);
  });

  testWidgets('priority up/down reorders backups on FAT-028', (tester) async {
    final repo = InMemorySosLadderRepository({
      SosLadder.defaultFamilyId: SosLadder.defaults().copyWith(
        backups: const [
          SosBackupContact(id: 'a', name: 'أول', priority: 1),
          SosBackupContact(id: 'b', name: 'ثانٍ', priority: 2),
        ],
      ),
    });
    await _pump(tester, repository: repo);

    await tester.ensureVisible(
      find.byKey(EmergencySetupKeys.backupPriorityUp('b')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EmergencySetupKeys.backupPriorityUp('b')));
    await tester.pumpAndSettle();

    final ladder = await repo.load();
    expect(ladder.backupsByPriority.map((c) => c.id), ['b', 'a']);
  });

  testWidgets('verify advances unverified → pending → verified (local)', (
    tester,
  ) async {
    final repo = InMemorySosLadderRepository({
      SosLadder.defaultFamilyId: SosLadder.defaults().copyWith(
        backups: const [
          SosBackupContact(
            id: 'uncle',
            name: 'عم فيصل',
            enabled: true,
            phoneE164: '+966555000111',
          ),
        ],
      ),
    });
    await _pump(tester, repository: repo);

    expect(find.byKey(EmergencySetupKeys.unverifiedNote), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(EmergencySetupKeys.backupVerify('uncle')),
    );
    await tester.tap(find.byKey(EmergencySetupKeys.backupVerify('uncle')));
    await tester.pumpAndSettle();
    var ladder = await repo.load();
    expect(ladder.backups.single.verification, SosVerificationStatus.pending);

    await tester.tap(find.byKey(EmergencySetupKeys.backupVerify('uncle')));
    await tester.pumpAndSettle();
    ladder = await repo.load();
    expect(ladder.backups.single.verification, SosVerificationStatus.verified);
    expect(find.byKey(EmergencySetupKeys.unverifiedNote), findsNothing);
  });

  group('SET-021 no SOS mute for guardians', () {
    testWidgets('FAT-028 tree has zero SOS-off / mute-SOS controls', (
      tester,
    ) async {
      final repo = InMemorySosLadderRepository();
      await _pump(tester, repository: repo);

      expect(find.byKey(EmergencySetupKeys.muteSosToggle), findsNothing);
      expect(find.byKey(NotificationPrefsKeys.muteSosToggle), findsNothing);
      expect(find.textContaining('كتم SOS'), findsNothing);
      expect(find.textContaining('Mute SOS'), findsNothing);
      expect(find.textContaining('sosMuted'), findsNothing);
      expect(find.textContaining('إيقاف الاستغاثة'), findsNothing);
      expect(find.textContaining('إيقاف SOS'), findsNothing);
    });

    testWidgets('SOS receipt cannot-disable banner visible (ARB)', (
      tester,
    ) async {
      final repo = InMemorySosLadderRepository();
      await _pump(tester, repository: repo);

      expect(find.byKey(EmergencySetupKeys.sosReceiptBanner), findsOneWidget);
      expect(
        find.text(
          'استلام تنبيهات الاستغاثة (SOS) لا يمكن إيقافه للأولياء — يصل للأم في كل المستويات بما فيها المطّلعة',
        ),
        findsOneWidget,
      );
    });
  });

  group('per-child outside escalation desk', () {
    testWidgets('empty roster shows empty copy — no child cards', (
      tester,
    ) async {
      final repo = InMemorySosLadderRepository();
      final settings = InMemorySosSettingsStore();
      await _pump(
        tester,
        repository: repo,
        settings: settings,
        children: const [],
      );

      expect(
        find.byKey(EmergencySetupKeys.childEscalationSection),
        findsOneWidget,
      );
      expect(
        find.byKey(EmergencySetupKeys.childEscalationEmpty),
        findsOneWidget,
      );
      expect(
        find.byKey(EmergencySetupKeys.childEscalationSmsHonesty),
        findsOneWidget,
      );
    });

    testWidgets('enable persists per child and reveals delay + SMS intent', (
      tester,
    ) async {
      final repo = InMemorySosLadderRepository();
      final settings = InMemorySosSettingsStore();
      const childId = 'kid_alpha';
      await _pump(
        tester,
        repository: repo,
        settings: settings,
        children: [RosterChildRef(id: ChildId(childId), nameKey: 'one')],
      );

      expect(
        find.byKey(EmergencySetupKeys.childEscalationCard(childId)),
        findsOneWidget,
      );
      expect(
        find.byKey(EmergencySetupKeys.childEscalationDelay(childId)),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(EmergencySetupKeys.childEscalationEnable(childId)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(EmergencySetupKeys.childEscalationEnable(childId)),
      );
      await tester.pumpAndSettle();

      expect(settings.settings.escalationFor(childId).enabled, isTrue);
      expect(
        find.byKey(EmergencySetupKeys.childEscalationDelay(childId)),
        findsOneWidget,
      );
      expect(
        find.byKey(EmergencySetupKeys.childEscalationPrepareSms(childId)),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(EmergencySetupKeys.childEscalationPrepareSms(childId)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(EmergencySetupKeys.childEscalationPrepareSms(childId)),
      );
      await tester.pumpAndSettle();
      AppToast.dismiss();
      await tester.pump();
      expect(
        settings.settings.escalationFor(childId).prepareSmsFallback,
        isFalse,
      );
    });

    test(
      'ChildSosEscalationPrefs round-trips through SosLocalSettings JSON',
      () {
        const prefs = ChildSosEscalationPrefs(
          enabled: true,
          delaySeconds: 120,
          notifyTrustedBackups: true,
          prepareSmsFallback: false,
        );
        final settings = SosLocalSettings(
          panicQuietPreferred: true,
          childEscalation: const {'kid_x': prefs},
        );
        final restored = SosLocalSettings.fromJson(settings.toJson());
        expect(restored.panicQuietPreferred, isTrue);
        final kid = restored.escalationFor('kid_x');
        expect(kid.enabled, isTrue);
        expect(kid.delaySeconds, 120);
        expect(kid.prepareSmsFallback, isFalse);
        expect(restored.escalationFor('unknown').enabled, isFalse);
      },
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required SosLadderRepository repository,
  AppRole role = AppRole.father,
  MotherLevel? motherLevel,
  SosSettingsStore? settings,
  List<RosterChildRef>? children,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: EmergencySetupScreen(
        repository: repository,
        roleOverride: role,
        motherLevel: motherLevel,
        settings: settings,
        childrenOverride: children,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
