import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/settings_persist_toggle.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/notification_delivery.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/notification_tier.dart';
import 'package:family_os/features/n06_notifications/notification_prefs_screen.dart';
import 'package:family_os/features/n10_emergency/emergency_setup_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('quiet ON + SOS simulate → father and mother delivered',
      (tester) async {
    final repo = InMemoryNotificationPrefsRepository();
    await repo.save(
      const NotificationPrefs(
        memberId: 'father',
        quietHoursEnabled: true,
        quietStart: TimeOfDay(hour: 22, minute: 0),
        quietEnd: TimeOfDay(hour: 7, minute: 0),
      ),
    );
    await repo.save(
      const NotificationPrefs(
        memberId: 'mother',
        quietHoursEnabled: true,
        quietStart: TimeOfDay(hour: 22, minute: 0),
        quietEnd: TimeOfDay(hour: 7, minute: 0),
      ),
    );

    await _pump(
      tester,
      repository: repo,
      role: AppRole.father,
      memberId: 'father',
    );

    expect(find.byKey(NotificationPrefsKeys.quietHoursSwitch), findsOneWidget);
    final father = await repo.load('father');
    final mother = await repo.load('mother');
    expect(father.quietHoursEnabled, isTrue);
    expect(mother.quietHoursEnabled, isTrue);

    final results = NotificationDelivery.simulateSosAlert(
      const ['father', 'mother'],
      prefsByMember: {
        'father': father,
        'mother': mother,
      },
      now: const TimeOfDay(hour: 23, minute: 15),
    );
    expect(results.every((r) => r.delivered), isTrue);
    expect(results.every((r) => r.tier == NotificationTier.critical), isTrue);
  });

  testWidgets('no mute-SOS control in widget tree', (tester) async {
    await _pump(
      tester,
      repository: InMemoryNotificationPrefsRepository(),
      role: AppRole.father,
      memberId: 'father',
    );

    expect(find.byKey(NotificationPrefsKeys.muteSosToggle), findsNothing);
    expect(find.textContaining('كتم SOS'), findsNothing);
    expect(find.textContaining('Mute SOS'), findsNothing);
    expect(find.textContaining('sosMuted'), findsNothing);
    expect(find.textContaining('إيقاف الطوارئ'), findsNothing);
  });

  testWidgets('SOS pierce banner visible; quiet hours editable for father',
      (tester) async {
    final repo = InMemoryNotificationPrefsRepository();
    await _pump(
      tester,
      repository: repo,
      role: AppRole.father,
      memberId: 'father',
    );

    expect(find.byKey(NotificationPrefsKeys.sosPierceBanner), findsOneWidget);
    expect(
      find.text(
        'تنبيهات الطوارئ (SOS) والتنبيهات الحرجة تصل دائماً — حتى أثناء ساعات الهدوء',
      ),
      findsOneWidget,
    );
    expect(find.byKey(NotificationPrefsKeys.memberLabel), findsOneWidget);
    expect(find.textContaining('الأب'), findsWidgets);

    await tester.tap(find.byKey(NotificationPrefsKeys.quietHoursSwitch));
    await tester.pumpAndSettle();
    expect(find.byKey(NotificationPrefsKeys.quietStart), findsOneWidget);
    expect(find.byKey(NotificationPrefsKeys.quietEnd), findsOneWidget);

    await tester.tap(find.byKey(NotificationPrefsKeys.save));
    await tester.pump();
    expect(find.text('تم حفظ إعدادات الإشعارات'), findsOneWidget);
    await _settleToast(tester);

    final loaded = await repo.load('father');
    expect(loaded.quietHoursEnabled, isTrue);
    expect(loaded.quietStart, NotificationPrefs.defaultQuietStart);
    expect(loaded.quietEnd, NotificationPrefs.defaultQuietEnd);
  });

  group('SET-011 mother identity', () {
    testWidgets('two members → independent quietHoursEnabled', (tester) async {
      final repo = InMemoryNotificationPrefsRepository();
      await repo.save(
        const NotificationPrefs(
          memberId: 'father',
          quietHoursEnabled: false,
        ),
      );
      await repo.save(
        const NotificationPrefs(
          memberId: 'mother',
          quietHoursEnabled: true,
          quietStart: TimeOfDay(hour: 22, minute: 0),
          quietEnd: TimeOfDay(hour: 7, minute: 0),
        ),
      );

      final father = await repo.load('father');
      final mother = await repo.load('mother');
      expect(father.quietHoursEnabled, isFalse);
      expect(mother.quietHoursEnabled, isTrue);
      expect(father.memberId, 'father');
      expect(mother.memberId, 'mother');
    });

    testWidgets('father prefs unchanged when mother toggles quiet hours',
        (tester) async {
      final repo = InMemoryNotificationPrefsRepository();
      await repo.save(
        const NotificationPrefs(
          memberId: 'father',
          quietHoursEnabled: false,
          analysisNoticesEnabled: true,
        ),
      );
      await repo.save(
        const NotificationPrefs(
          memberId: 'mother',
          quietHoursEnabled: false,
          analysisNoticesEnabled: true,
        ),
      );

      await _pump(
        tester,
        repository: repo,
        role: AppRole.mother,
        memberId: 'mother',
      );

      expect(find.byKey(NotificationPrefsKeys.memberLabel), findsOneWidget);
      expect(find.textContaining('الأم'), findsWidgets);
      expect(find.byKey(NotificationPrefsKeys.sosPierceBanner), findsOneWidget);
      expect(
        find.byKey(NotificationPrefsKeys.analysisNoticesSwitch),
        findsOneWidget,
      );

      await tester.tap(find.byKey(NotificationPrefsKeys.quietHoursSwitch));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(NotificationPrefsKeys.save));
      await tester.pump();
      await _settleToast(tester);

      final mother = await repo.load('mother');
      final father = await repo.load('father');
      expect(mother.quietHoursEnabled, isTrue);
      expect(father.quietHoursEnabled, isFalse);
      expect(father.analysisNoticesEnabled, isTrue);
    });

    testWidgets('mother cannot mute SOS — UI findsNothing + API reject',
        (tester) async {
      final repo = InMemoryNotificationPrefsRepository();
      await _pump(
        tester,
        repository: repo,
        role: AppRole.mother,
        memberId: 'mother',
      );

      expect(find.byKey(NotificationPrefsKeys.muteSosToggle), findsNothing);
      expect(find.textContaining('Mute SOS'), findsNothing);
      expect(find.textContaining('كتم SOS'), findsNothing);
      expect(find.textContaining('sosMuted'), findsNothing);
      expect(find.textContaining('إيقاف الطوارئ'), findsNothing);
      expect(NotificationPrefs.sosReceiptAlwaysOn, isTrue);
      expect(canShowSosMuteControl(AppRole.mother), isFalse);

      expect(
        () => repo.setSosMuted('mother', true),
        throwsA(isA<ForbiddenSosMuteFieldException>()),
      );
      expect(
        () => repo.setSosMuted('guardian', true),
        throwsA(isA<ForbiddenSosMuteFieldException>()),
      );
    });

    testWidgets('mother role settings tree — zero SOS-off controls',
        (tester) async {
      await _pump(
        tester,
        repository: InMemoryNotificationPrefsRepository(),
        role: AppRole.mother,
        memberId: 'mother',
      );

      expect(find.byKey(NotificationPrefsKeys.muteSosToggle), findsNothing);
      expect(find.byKey(EmergencySetupKeys.muteSosToggle), findsNothing);
      expect(find.textContaining('Mute SOS'), findsNothing);
      expect(find.textContaining('كتم SOS'), findsNothing);
      expect(find.byKey(NotificationPrefsKeys.sosPierceBanner), findsOneWidget);
    });

    testWidgets('CurrentRole mother resolves memberId without constructor',
        (tester) async {
      final repo = InMemoryNotificationPrefsRepository();
      await repo.save(
        const NotificationPrefs(
          memberId: 'mother',
          quietHoursEnabled: true,
          quietStart: TimeOfDay(hour: 21, minute: 0),
          quietEnd: TimeOfDay(hour: 6, minute: 0),
        ),
      );

      await _pump(
        tester,
        repository: repo,
        role: AppRole.mother,
        // null → CurrentRole mother → 'mother'
      );

      expect(find.textContaining('الأم'), findsWidgets);
      final switchWidget = tester.widget<Switch>(
        find.byKey(NotificationPrefsKeys.quietHoursSwitch),
      );
      expect(switchWidget.value, isTrue);
    });
  });

  group('UI-008 quiet hours persist feedback', () {
    testWidgets('toggle success toast without bare Switch flip', (tester) async {
      final repo = InMemoryNotificationPrefsRepository();
      await _pump(
        tester,
        repository: repo,
        role: AppRole.father,
        memberId: 'father',
      );

      expect(find.byType(SettingsPersistToggle), findsWidgets);
      await tester.tap(find.byKey(NotificationPrefsKeys.quietHoursSwitch));
      await tester.pumpAndSettle();

      expect(find.text('تم حفظ إعدادات الإشعارات'), findsOneWidget);
      expect((await repo.load('father')).quietHoursEnabled, isTrue);
      // AC3 host: Material Switch still present after persist (not CSS-only).
      expect(
        find.byKey(NotificationPrefsKeys.quietHoursSwitch),
        findsOneWidget,
      );
      await _settleToast(tester);
    });

    testWidgets('toggle failure shows error and reverts', (tester) async {
      final repo = _FailingNotificationPrefsRepository();
      await _pump(
        tester,
        repository: repo,
        role: AppRole.father,
        memberId: 'father',
      );

      await tester.tap(find.byKey(NotificationPrefsKeys.quietHoursSwitch));
      await tester.pumpAndSettle();

      expect(find.byKey(SettingsPersistToggleKeys.error), findsOneWidget);
      expect(find.text('تعذر الحفظ — حاول مرة أخرى'), findsOneWidget);
      final sw = tester.widget<Switch>(
        find.byKey(NotificationPrefsKeys.quietHoursSwitch),
      );
      expect(sw.value, isFalse);
      expect((await repo.load('father')).quietHoursEnabled, isFalse);
    });
  });
}

/// Stage-1 seam — save always fails (UI-008 AC1 host proof).
final class _FailingNotificationPrefsRepository
    implements NotificationPrefsRepository {
  @override
  Future<NotificationPrefs> load(String memberId) async =>
      NotificationPrefs.defaults(memberId: memberId);

  @override
  Future<void> save(NotificationPrefs prefs) async {
    throw StateError('mock save failure');
  }

  @override
  Future<void> setSosMuted(String memberId, bool muted) async {
    rejectSosMutedWrite(memberId, muted);
  }
}

Future<void> _settleToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  required NotificationPrefsRepository repository,
  required AppRole role,
  String? memberId,
}) async {
  final roleCtrl = RoleController(role);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: NotificationPrefsScreen(
          memberId: memberId,
          repository: repository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
