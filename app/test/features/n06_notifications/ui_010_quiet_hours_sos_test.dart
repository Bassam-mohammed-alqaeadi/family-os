import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/notification_tier.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n06_notifications/notification_prefs_screen.dart';
import 'package:family_os/features/n10_emergency/emergency_setup_screen.dart';

/// UI-010 — SCR-FAT-058 quiet hours: SOS/critical never muted (P-4 / SET-010).
void main() {
  group('UI-010 quiet hours SOS exclusion', () {
    testWidgets('AC1: SOS-never-muted banner + subtitle copy visible (AR)',
        (tester) async {
      await _pump(
        tester,
        repository: InMemoryNotificationPrefsRepository(),
        role: AppRole.father,
        memberId: 'father',
        locale: const Locale('ar'),
      );

      expect(find.byKey(NotificationPrefsKeys.sosPierceBanner), findsOneWidget);
      expect(
        find.text(
          'تنبيهات الطوارئ (SOS) والتنبيهات الحرجة تصل دائماً — حتى أثناء ساعات الهدوء',
        ),
        findsOneWidget,
      );
      expect(
        find.text('ساعات الهدوء لكتم التنبيهات غير الحرجة فقط'),
        findsOneWidget,
      );
    });

    testWidgets('AC1: SOS-never-muted banner + subtitle copy visible (EN)',
        (tester) async {
      await _pump(
        tester,
        repository: InMemoryNotificationPrefsRepository(),
        role: AppRole.father,
        memberId: 'father',
        locale: const Locale('en'),
      );

      expect(find.byKey(NotificationPrefsKeys.sosPierceBanner), findsOneWidget);
      expect(
        find.text(
          'SOS and critical alerts always get through — even during quiet hours',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Quiet hours mute non-critical alerts only'),
        findsOneWidget,
      );
    });

    testWidgets('AC2: no SOS mute Switch in FAT-058 widget tree', (tester) async {
      await _pump(
        tester,
        repository: InMemoryNotificationPrefsRepository(),
        role: AppRole.father,
        memberId: 'father',
      );

      expect(find.byKey(NotificationPrefsKeys.muteSosToggle), findsNothing);
      expect(find.byKey(EmergencySetupKeys.muteSosToggle), findsNothing);
      expect(canShowSosMuteControl(AppRole.father), isFalse);
      expect(canShowSosMuteControl(AppRole.mother), isFalse);

      // Only quiet-hours Switch — never an SOS mute control.
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byKey(NotificationPrefsKeys.quietHoursSwitch), findsOneWidget);

      expect(find.textContaining('Mute SOS'), findsNothing);
      expect(find.textContaining('كتم SOS'), findsNothing);
      expect(find.textContaining('sosMuted'), findsNothing);
      expect(find.textContaining('إيقاف الطوارئ'), findsNothing);
    });

    test('AC2 schema: forbidden SOS mute keys rejected', () {
      for (final key in kForbiddenSosMuteKeys) {
        expect(
          () => NotificationPrefs.fromJson({
            'memberId': 'father',
            key: true,
          }),
          throwsA(isA<ForbiddenSosMuteFieldException>()),
          reason: 'schema must forbid $key',
        );
      }
      expect(NotificationPrefs.sosReceiptAlwaysOn, isTrue);
    });

    testWidgets(
      'AC3: quiet hours ON + MockSosFireService still delivers SOS',
      (tester) async {
        final quiet = const NotificationPrefs(
          memberId: 'father',
          quietHoursEnabled: true,
          quietStart: TimeOfDay(hour: 22, minute: 0),
          quietEnd: TimeOfDay(hour: 7, minute: 0),
        );
        final motherQuiet = const NotificationPrefs(
          memberId: 'mother',
          quietHoursEnabled: true,
          quietStart: TimeOfDay(hour: 22, minute: 0),
          quietEnd: TimeOfDay(hour: 7, minute: 0),
        );
        final repo = InMemoryNotificationPrefsRepository({
          'father': quiet,
          'mother': motherQuiet,
        });

        await _pump(
          tester,
          repository: repo,
          role: AppRole.father,
          memberId: 'father',
        );

        expect(find.byKey(NotificationPrefsKeys.sosPierceBanner), findsOneWidget);
        final sw = tester.widget<Switch>(
          find.byKey(NotificationPrefsKeys.quietHoursSwitch),
        );
        expect(sw.value, isTrue);

        final sos = MockSosFireService(
          prefsByMember: {
            'father': await repo.load('father'),
            'mother': await repo.load('mother'),
          },
        );
        final result = await sos.fire(
          childId: 'ui010-child',
          recipients: const ['father', 'mother'],
          clock: const TimeOfDay(hour: 23, minute: 30),
        );

        expect(result.fired, isTrue);
        expect(sos.fireCount, 1);
        expect(result.recipientDeliveries, hasLength(2));
        expect(
          result.recipientDeliveries.every((d) => d.delivered),
          isTrue,
        );
        expect(
          result.recipientDeliveries.every(
            (d) => d.tier == NotificationTier.critical,
          ),
          isTrue,
        );
      },
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required NotificationPrefsRepository repository,
  required AppRole role,
  String? memberId,
  Locale locale = const Locale('ar'),
}) async {
  final roleCtrl = RoleController(role);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: locale,
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
