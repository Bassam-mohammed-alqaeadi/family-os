import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';
import 'package:family_os/features/n06_notifications/notification_prefs_screen.dart';
import 'package:family_os/features/n10_emergency/emergency_setup_screen.dart';

void main() {
  testWidgets('rung 1 shows father+mother locked — no remove; switch off disabled',
      (tester) async {
    final repo = InMemorySosLadderRepository({
      SosLadder.defaultFamilyId: SosLadder.defaults().copyWith(
        backups: const [
          SosBackupContact(id: 'uncle', name: 'عم فيصل', delaySeconds: 60),
        ],
      ),
    });

    await _pump(tester, repository: repo);

    expect(find.byKey(EmergencySetupKeys.parentRow('father')), findsOneWidget);
    expect(find.byKey(EmergencySetupKeys.parentRow('mother')), findsOneWidget);
    expect(find.byKey(EmergencySetupKeys.parentRemove('father')), findsNothing);
    expect(find.byKey(EmergencySetupKeys.parentRemove('mother')), findsNothing);

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
  });

  testWidgets('cannot remove mother from rung 1 — inline ARB error',
      (tester) async {
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

  testWidgets('backups editable on lower rung — toggle + remove', (tester) async {
    final repo = InMemorySosLadderRepository({
      SosLadder.defaultFamilyId: SosLadder.defaults().copyWith(
        backups: const [
          SosBackupContact(id: 'uncle', name: 'عم فيصل', enabled: true),
        ],
      ),
    });

    await _pump(tester, repository: repo);

    expect(find.byKey(EmergencySetupKeys.backupRow('uncle')), findsOneWidget);
    expect(find.byKey(EmergencySetupKeys.backupRemove('uncle')), findsOneWidget);

    await tester.tap(find.byKey(EmergencySetupKeys.backupSwitch('uncle')));
    await tester.pumpAndSettle();

    var ladder = await repo.load();
    expect(ladder.backups.single.enabled, isFalse);

    await tester.tap(find.byKey(EmergencySetupKeys.backupRemove('uncle')));
    await tester.pumpAndSettle();

    ladder = await repo.load();
    expect(ladder.backups, isEmpty);
    expect(find.byKey(EmergencySetupKeys.backupRow('uncle')), findsNothing);
  });

  testWidgets('add backup CTA appends editable rung 2+', (tester) async {
    final repo = InMemorySosLadderRepository();
    await _pump(tester, repository: repo);

    await tester.tap(find.byKey(EmergencySetupKeys.addBackup));
    await tester.pumpAndSettle();

    final ladder = await repo.load();
    expect(ladder.backups, hasLength(1));
    expect(find.byKey(EmergencySetupKeys.backupSwitch(ladder.backups.single.id)),
        findsOneWidget);
  });

  group('SET-021 no SOS mute for guardians', () {
    testWidgets('FAT-028 tree has zero SOS-off / mute-SOS controls',
        (tester) async {
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

    testWidgets('SOS receipt cannot-disable banner visible (ARB)',
        (tester) async {
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
}

Future<void> _pump(
  WidgetTester tester, {
  required SosLadderRepository repository,
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
      home: EmergencySetupScreen(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}
