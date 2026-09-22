import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n05_lock/child_mode_lock_screen.dart';
import 'package:family_os/features/n05_lock/child_mode_lock_service.dart';

void main() {
  tearDown(() {
    stage1ChildModeLockService.resetForTests();
  });

  testWidgets('shows dual-key + entertainment locked + SOS (P-4)', (tester) async {
    final lock = ChildModeLockService();
    await _pump(tester, lockService: lock);
    expect(find.byKey(ChildModeLockKeys.dualKeyBanner), findsOneWidget);
    expect(find.byKey(ChildModeLockKeys.entertainmentLocked), findsOneWidget);
    expect(find.byKey(ChildModeLockKeys.sosCta), findsOneWidget);
    expect(find.byKey(ChildModeLockKeys.sosIconCta), findsOneWidget);
    expect(find.byKey(ChildModeLockKeys.passwordStep), findsNothing);
  });

  testWidgets('secret hold opens password step (mock gesture)', (tester) async {
    final lock = ChildModeLockService();
    await _pump(
      tester,
      lockService: lock,
      secretHold: const Duration(milliseconds: 80),
      secretTick: const Duration(milliseconds: 40),
    );
    final logo = find.byKey(ChildModeLockKeys.logoHold);
    expect(logo, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(logo));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(lock.secretEntryOpen, isTrue);
    expect(find.byKey(ChildModeLockKeys.secretOpened), findsOneWidget);
    expect(find.byKey(ChildModeLockKeys.passwordStep), findsOneWidget);
  });

  testWidgets('wrong password notifies father; 3rd locks 24h + mother',
      (tester) async {
    final lock = ChildModeLockService();
    await _pump(
      tester,
      lockService: lock,
      secretHold: const Duration(milliseconds: 50),
      secretTick: const Duration(milliseconds: 25),
    );
    await _openSecret(tester);

    for (var i = 1; i <= 2; i++) {
      await tester.enterText(
        find.byKey(ChildModeLockKeys.passwordField),
        'wrong-$i',
      );
      await tester.tap(find.byKey(ChildModeLockKeys.verifyCta));
      await tester.pumpAndSettle();
      expect(lock.failedAttempts, i);
      expect(lock.notifyBus.delivered.last.notifiedFather, isTrue);
      expect(lock.notifyBus.delivered.last.notifiedMother, isFalse);
      expect(lock.isLockedOut, isFalse);
    }

    await tester.enterText(
      find.byKey(ChildModeLockKeys.passwordField),
      'wrong-3',
    );
    await tester.tap(find.byKey(ChildModeLockKeys.verifyCta));
    await tester.pumpAndSettle();

    expect(lock.isLockedOut, isTrue);
    expect(lock.notifyBus.delivered.last.lockout, isTrue);
    expect(lock.notifyBus.delivered.last.notifiedMother, isTrue);
    expect(find.byKey(ChildModeLockKeys.lockoutBanner), findsOneWidget);
    expect(
      lock.audit.entries.any((e) => e.contains('lockout')),
      isTrue,
    );
  });

  testWidgets('correct password → awaiting second key (FAT-030 CTA)',
      (tester) async {
    var viewedFather = false;
    final lock = ChildModeLockService();
    await _pump(
      tester,
      lockService: lock,
      secretHold: const Duration(milliseconds: 50),
      secretTick: const Duration(milliseconds: 25),
      onViewFather: () => viewedFather = true,
    );
    await _openSecret(tester);

    await tester.enterText(
      find.byKey(ChildModeLockKeys.passwordField),
      kChildModeLockMockPassword,
    );
    await tester.tap(find.byKey(ChildModeLockKeys.verifyCta));
    await tester.pump(); // show toast
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(lock.pendingRequest, isNotNull);
    expect(find.byKey(ChildModeLockKeys.awaitingBanner), findsOneWidget);
    expect(find.byKey(ChildModeLockKeys.viewFatherCta), findsOneWidget);
    await tester.ensureVisible(find.byKey(ChildModeLockKeys.viewFatherCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildModeLockKeys.viewFatherCta));
    await tester.pumpAndSettle();
    expect(viewedFather, isTrue);
  });

  testWidgets('SOS CTA reachable while locked (P-4)', (tester) async {
    var sosOpened = false;
    final lock = ChildModeLockService();
    final fire = RecordingSosFire();
    await _pump(
      tester,
      lockService: lock,
      sosFire: fire,
      onSos: () => sosOpened = true,
    );
    await tester.tap(find.byKey(ChildModeLockKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sosOpened, isTrue);

    // Icon path also ungated.
    sosOpened = false;
    await tester.tap(find.byKey(ChildModeLockKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sosOpened, isTrue);
  });

  testWidgets('parent RoleGuard lean — no secret entry', (tester) async {
    final lock = ChildModeLockService();
    await _pump(
      tester,
      lockService: lock,
      role: AppRole.father,
      roleOverride: AppRole.father,
    );
    expect(find.byKey(ChildModeLockKeys.parentLean), findsOneWidget);
    expect(find.byKey(ChildModeLockKeys.logoHold), findsNothing);
  });

  testWidgets('SOS navigates to CHD-005 when seam null', (tester) async {
    final lock = ChildModeLockService();
    final fire = RecordingSosFire();
    final router = GoRouter(
      initialLocation: '/scr-chd-011',
      routes: [
        GoRoute(
          path: '/scr-chd-011',
          builder: (context, state) => ChildModeLockScreen(
            lockService: lock,
            sosFire: fire,
            roleOverride: AppRole.child,
          ),
        ),
        GoRoute(
          path: '/scr-chd-005',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-CHD-005',
            title: 'زر الاستغاثة',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      CurrentRole(
        notifier: RoleController(AppRole.child),
        child: MaterialApp.router(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildModeLockKeys.sosCta));
    await tester.pumpAndSettle();
    expect(find.textContaining('SCR-CHD-005'), findsWidgets);
    expect(fire.firedChildIds, ['child_local']);
  });
}

Future<void> _openSecret(WidgetTester tester) async {
  final logo = find.byKey(ChildModeLockKeys.logoHold);
  final gesture = await tester.startGesture(tester.getCenter(logo));
  await tester.pump(const Duration(milliseconds: 80));
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  required ChildModeLockService lockService,
  SosFireService? sosFire,
  AppRole role = AppRole.child,
  AppRole? roleOverride,
  Duration secretHold = kChildModeLockSecretHoldDuration,
  Duration secretTick = kChildModeLockSecretHoldTick,
  VoidCallback? onSos,
  VoidCallback? onViewFather,
  bool settle = true,
}) async {
  final roleCtrl = RoleController(role);
  addTearDown(roleCtrl.dispose);
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
        home: ChildModeLockScreen(
          lockService: lockService,
          sosFire: sosFire,
          roleOverride: roleOverride ?? role,
          secretHoldDuration: secretHold,
          secretHoldTick: secretTick,
          onSos: onSos,
          onViewFatherRequest: onViewFather,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

final class RecordingSosFire implements SosFireService {
  final List<String> firedChildIds = [];

  @override
  Future<SosFireResult> fire({
    required String childId,
    List<String> recipients = const ['father', 'mother'],
    DateTime? at,
    TimeOfDay? clock,
  }) async {
    firedChildIds.add(childId);
    return SosFireResult(
      fired: true,
      at: at ?? DateTime.now().toUtc(),
      recipientDeliveries: const [],
    );
  }
}
