import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n05_lock/child_mode_lock_screen.dart';
import 'package:family_os/features/n05_lock/child_mode_lock_service.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/quran_progress_screen.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

/// VX-B2 · Owner D7 — who raised the SOS.
void main() {
  late IdentityRuntime runtime;

  setUp(() {
    runtime = createStage1IdentityRuntime(
      familyContextStore: MemoryFamilyContextStore(),
    );
  });

  tearDown(() {
    AppToast.dismiss();
    stage1ChildModeLockService.resetForTests();
  });

  group('resolvers', () {
    test('parent + viewed child → child is the subject, parent the actor', () {
      final sender = resolveParentSosSender(
        viewedChild: ChildId('child_b'),
        runtime: runtime,
      );
      expect(sender.role, AppRole.father);
      expect(sender.actorId, 'mem_stage1_owner');
      expect(sender.childId, ChildId('child_b'));
      expect(sender.subjectChildId(runtime: runtime), ChildId('child_b'));
      expect(sender.fireSubjectId, 'child_b');
    });

    test('parent with no child in view → active child is the subject', () {
      final sender = resolveParentSosSender(runtime: runtime);
      expect(sender.childId, isNull);
      expect(sender.actorId, 'mem_stage1_owner');
      expect(sender.subjectChildId(runtime: runtime), runtime.activeChildId);
      expect(
        resolveParentSosSender(role: AppRole.mother, runtime: runtime).role,
        AppRole.mother,
      );
    });

    test('child SOS → the real active child id', () {
      runtime.setActiveChild(ChildId('child_b'));
      final sender = resolveChildSosSender(runtime: runtime);
      expect(sender.isChild, isTrue);
      expect(sender.subjectChildId(runtime: runtime), ChildId('child_b'));
      expect(sender.fireSubjectId, 'child_b');
    });

    test('chat peer counts as viewed child only if in the active family', () {
      expect(
        familyChildOrNull('child_b', runtime: runtime),
        ChildId('child_b'),
      );
      expect(familyChildOrNull('child_c', runtime: runtime), isNull);
      expect(familyChildOrNull('family', runtime: runtime), isNull);
    });
  });

  testWidgets('child lock screen SOS fires the child using the device', (
    tester,
  ) async {
    runtime.setActiveChild(ChildId('child_b'));
    final fire = _RecordingSosFire();
    final router = GoRouter(
      initialLocation: '/scr-chd-011',
      routes: [
        GoRoute(
          path: '/scr-chd-011',
          builder: (context, state) => ChildModeLockScreen(
            lockService: ChildModeLockService(),
            sosFire: fire,
            roleOverride: AppRole.child,
          ),
        ),
        GoRoute(
          path: '/scr-chd-005',
          builder: (context, state) =>
              const PlaceholderScreen(screenId: 'SCR-CHD-005', title: 'SOS'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pumpRouter(tester, runtime, router, role: AppRole.child);

    await tester.tap(find.byKey(ChildModeLockKeys.sosCta));
    await tester.pumpAndSettle();
    expect(fire.firedChildIds, ['child_b']);
    expect(fire.firedActorIds, ['child_b']);
  });

  testWidgets(
    'father SOS on a per-child tool records parent actor + viewed child',
    (tester) async {
      final bus = InMemoryQuranWardPlanRepository();
      addTearDown(bus.dispose);
      final fire = _RecordingSosFire();
      final router = GoRouter(
        initialLocation: '/q',
        routes: [
          GoRoute(
            path: '/q',
            builder: (context, state) => QuranProgressScreen(
              childId: ChildId('child_b'),
              repository: InMemoryQuranProgressRepository(
                seed: quranProgressPrototypeFixture(),
                plans: bus,
              ),
              sosFire: fire,
              roleOverride: AppRole.father,
              motherLevel: MotherLevel.partner,
              onNavigate: (_) {},
            ),
          ),
          GoRoute(
            path: '/scr-fat-018',
            builder: (context, state) =>
                const PlaceholderScreen(screenId: 'SCR-FAT-018', title: 'SOS'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await _pumpRouter(tester, runtime, router, role: AppRole.father);

      await tester.ensureVisible(find.byKey(QuranProgressKeys.sosIconCta));
      await tester.tap(find.byKey(QuranProgressKeys.sosIconCta));
      await tester.pumpAndSettle();
      expect(fire.firedChildIds, ['child_b']);
      expect(fire.firedActorIds, ['mem_stage1_owner']);
    },
  );
}

Future<void> _pumpRouter(
  WidgetTester tester,
  IdentityRuntime runtime,
  GoRouter router, {
  required AppRole role,
}) async {
  final roleCtrl = RoleController(role);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentIdentity(
      runtime: runtime,
      child: CurrentRole(
        notifier: roleCtrl,
        child: MaterialApp.router(
          theme: buildFamilyTheme(),
          locale: const Locale('en'),
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
    ),
  );
  await tester.pumpAndSettle();
}

final class _RecordingSosFire implements SosFireService {
  final List<String> firedChildIds = [];
  final List<String> firedActorIds = [];

  @override
  Future<SosFireResult> fire({
    required String childId,
    String? actorId,
    List<String> recipients = const ['father', 'mother'],
    DateTime? at,
    TimeOfDay? clock,
  }) async {
    firedChildIds.add(childId);
    firedActorIds.add(actorId ?? childId);
    return SosFireResult(
      fired: true,
      at: at ?? DateTime.now().toUtc(),
      recipientDeliveries: const [],
      childId: childId,
      actorId: actorId ?? childId,
    );
  }
}
