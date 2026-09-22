import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/anti_tamper_alert_bus.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/features/n05_lock/instant_lock_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('widget-at-child');

  testWidgets('mother FULL: zero anti-tamper switch nodes', (tester) async {
    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.mother,
      motherLevel: MotherLevel.full,
    );

    expect(find.byKey(AntiTamperKeys.section), findsNothing);
    for (final key in AntiTamperKeys.allSwitches) {
      expect(find.byKey(key), findsNothing);
    }
    expect(find.byKey(AntiTamperKeys.denyPanel), findsNothing);
    expect(find.byKey(InstantLockKeys.legacySwitch), findsOneWidget);
    expect(find.byKey(InstantLockKeys.lockButton), findsOneWidget);
  });

  testWidgets('mother FULL lock then father unlock → supersession banner',
      (tester) async {
    final sharedService = DeviceLockService.inMemory();

    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: sharedService,
      childId: child,
      role: AppRole.mother,
      motherLevel: MotherLevel.full,
    );
    await tester.tap(find.byKey(InstantLockKeys.lockButton));
    await tester.pumpAndSettle();
    expect(find.text('الجهاز مقفل'), findsOneWidget);

    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: sharedService,
      childId: child,
      role: AppRole.father,
    );
    await tester.tap(find.byKey(InstantLockKeys.unlockButton));
    await tester.pumpAndSettle();
    expect(find.text('الجهاز غير مقفل'), findsOneWidget);

    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: sharedService,
      childId: child,
      role: AppRole.mother,
      motherLevel: MotherLevel.full,
    );
    // Bus already holds supersession from father unlock; re-notify mother UI.
    sharedService.notifyBus.publish(
      DeviceLockSupersessionEvent(
        childId: child,
        at: DateTime.now().toUtc(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(InstantLockKeys.supersessionBanner), findsOneWidget);
    expect(find.text('الأب فتح القفل (تم تجاوز قفلك)'), findsOneWidget);
  });

  testWidgets('mother observer: lock button disabled, stays unlocked',
      (tester) async {
    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    final btn = tester.widget<PrimaryBtn>(find.byKey(InstantLockKeys.lockButton));
    expect(btn.onPressed, isNull);
    await tester.tap(find.byKey(InstantLockKeys.lockButton));
    await tester.pumpAndSettle();
    expect(find.text('الجهاز غير مقفل'), findsOneWidget);
  });

  testWidgets('father: six anti-tamper switches visible', (tester) async {
    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.father,
    );

    expect(find.byKey(AntiTamperKeys.section), findsOneWidget);
    for (final key in AntiTamperKeys.allSwitches) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(AntiTamperKeys.allSwitches, hasLength(6));
  });

  testWidgets('father: all six whenEnabled strings visible (SET-008)',
      (tester) async {
    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.father,
    );

    expect(AntiTamperKeys.allWhenEnabled, hasLength(6));
    for (final key in AntiTamperKeys.allWhenEnabled) {
      expect(find.byKey(key), findsOneWidget);
    }

    expect(
      find.text('لا يمكن إلغاء تثبيت عائلتي من جهاز الابن'),
      findsOneWidget,
    );
    expect(
      find.text('أي تلاعب بالساعة يُعاد تلقائيًا ويُسجل'),
      findsOneWidget,
    );
    expect(find.text('تُعطل فور تثبيتها ويصلك تنبيه'), findsOneWidget);
    expect(
      find.text('إشعار فوري إن أُخرجت شريحة الاتصال'),
      findsOneWidget,
    );
    expect(
      find.text('إعدادات الجهاز الحساسة تطلب رمز الأب'),
      findsOneWidget,
    );
    expect(
      find.text('أي محاولة التفاف تصلك لحظيًا كمعلومة تربوية'),
      findsOneWidget,
    );
  });

  testWidgets('father bypassAlert ON + simulate → father alert event',
      (tester) async {
    final bus = AntiTamperAlertBus();
    final screenKey = GlobalKey<InstantLockScreenState>();
    final repo = InMemoryAntiTamperRepository(
      seed: {
        child.value: const AntiTamperPolicy(bypassAlert: true),
      },
    );

    await _pump(
      tester,
      repository: repo,
      alertBus: bus,
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.father,
      screenKey: screenKey,
    );

    expect(screenKey.currentState!.simulateBypassAttempt(), isTrue);
    expect(bus.delivered, hasLength(1));
    expect(bus.delivered.single.kind, AntiTamperAlertKind.bypassAttempt);
    expect(bus.delivered.single.childId, child);
    bus.dispose();
  });

  testWidgets('child: zero anti-tamper nodes', (tester) async {
    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.child,
    );

    for (final key in AntiTamperKeys.allSwitches) {
      expect(find.byKey(key), findsNothing);
    }
    expect(find.byKey(AntiTamperKeys.section), findsNothing);
  });

  testWidgets('mother deep-link force → deny panel, still no switches',
      (tester) async {
    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.mother,
      forceAntiTamperSurface: true,
    );

    expect(find.byKey(AntiTamperKeys.denyPanel), findsOneWidget);
    expect(find.text('غير متاح'), findsOneWidget);
    for (final key in AntiTamperKeys.allSwitches) {
      expect(find.byKey(key), findsNothing);
    }
  });

  testWidgets('father toggle + save persists across repo reopen',
      (tester) async {
    final shared = <String, String>{};
    final repo = PrefsAntiTamperRepository(
      MemoryAntiTamperPrefsStore(shared),
    );

    await _pump(
      tester,
      repository: repo,
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.father,
    );

    await tester.tap(
      find.byKey(AntiTamperKeys.switchFor(AntiTamperFlags.noDelete)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(AntiTamperKeys.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AntiTamperKeys.save));
    await tester.pump();
    expect(find.text('تم حفظ حماية التلاعب'), findsOneWidget);
    await _settleToast(tester);

    final loaded = await PrefsAntiTamperRepository(
      MemoryAntiTamperPrefsStore(shared),
    ).load(child);
    expect(loaded.noDelete, isTrue);
  });

  testWidgets('enabling noDelete without device admin → permission banner',
      (tester) async {
    await _pump(
      tester,
      repository: InMemoryAntiTamperRepository(),
      lockService: DeviceLockService.inMemory(),
      childId: child,
      role: AppRole.father,
      deviceAdminGranted: false,
    );

    expect(find.byKey(AntiTamperKeys.permissionBanner), findsNothing);

    await tester.tap(
      find.byKey(AntiTamperKeys.switchFor(AntiTamperFlags.noDelete)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AntiTamperKeys.permissionBanner), findsOneWidget);
    expect(find.text('يحتاج صلاحية الجهاز'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required AntiTamperRepository repository,
  required ChildId childId,
  required AppRole role,
  DeviceLockService? lockService,
  AntiTamperAlertBus? alertBus,
  GlobalKey<InstantLockScreenState>? screenKey,
  MotherLevel motherLevel = MotherLevel.full,
  bool forceAntiTamperSurface = false,
  bool deviceAdminGranted = true,
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
        home: InstantLockScreen(
          key: screenKey,
          childId: childId,
          repository: repository,
          alertBus: alertBus,
          lockService: lockService,
          motherLevel: motherLevel,
          forceAntiTamperSurface: forceAntiTamperSurface,
          deviceAdminGranted: deviceAdminGranted,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _settleToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}
