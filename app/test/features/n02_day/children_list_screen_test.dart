import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_device_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_mock.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/children_list_screen.dart';
import 'package:family_os/foundation_gate/child_device_card.dart';
import 'package:family_os/foundation_gate/device_lifecycle.dart';

void main() {
  testWidgets('SCR-FAT-012 empty → AppEmptyState + add CTA', (tester) async {
    final repo = InMemoryChildrenListRepository();

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.list), findsNothing);
  });

  testWidgets('SCR-FAT-012 roster + health tags + status ring', (tester) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.list), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.addChild), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.childRow('child_a')), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.childRow('child_b')), findsOneWidget);
    expect(find.text('ممتاز'), findsWidgets);
    expect(find.text('قد ينقطع'), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.sharedPoliciesCard), findsOneWidget);
  });

  testWidgets('SCR-FAT-012 open profile seam', (tester) async {
    String? opened;
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onOpenChildProfile: (id) => opened = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildrenListKeys.childRow('child_a')));
    await tester.pumpAndSettle();
    expect(opened, 'child_a');
  });

  testWidgets('SCR-FAT-012 shared policies sheet + father apply', (
    tester,
  ) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildrenListKeys.sharedPoliciesCard));
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.sharedPoliciesSheet), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.sharedEnforceHonesty), findsOneWidget);
    expect(find.textContaining('محرك السياسة'), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.sharedApply), findsOneWidget);

    await tester.tap(find.byKey(ChildrenListKeys.sharedApply));
    await tester.pumpAndSettle();

    final saved = await repo.loadSharedPolicies();
    expect(saved.dailyCapHours, 4);
    expect(find.byKey(ChildrenListKeys.sharedPoliciesSheet), findsNothing);
  });

  testWidgets('SCR-FAT-012 mother — shared sheet without apply', (
    tester,
  ) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.mother,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.list), findsOneWidget);
    await tester.tap(find.byKey(ChildrenListKeys.sharedPoliciesCard));
    await tester.pumpAndSettle();
    expect(find.byKey(ChildrenListKeys.sharedPoliciesSheet), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.sharedApply), findsNothing);
  });

  testWidgets('SCR-FAT-012 child lean — not parent roster', (tester) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.child,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.childLean), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.list), findsNothing);
  });

  testWidgets('SCR-FAT-012 load error → AppErrorState + Retry', (tester) async {
    final repo = InMemoryChildrenListRepository(failLoad: true);

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.error), findsOneWidget);
    expect(find.byKey(const Key('app_error_retry')), findsOneWidget);

    repo
      ..failLoad = false
      ..seed(ChildrenListMock.manyFixture);
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.list), findsOneWidget);
  });

  testWidgets('SCR-FAT-012 Rule 23 — no planted Khaled on empty default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: InMemoryChildrenListRepository(),
          roleOverride: AppRole.father,
          onAddChild: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('نورة'), findsNothing);
    expect(find.textContaining('سعد'), findsNothing);
  });

  testWidgets('SCR-FAT-012 LOCAL_DEMO provenance → honesty BannerNote', (
    tester,
  ) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
      provenance: kChildrenListLocalDemoProvenance,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.localDemoBanner), findsOneWidget);
    expect(find.textContaining('تجريبي'), findsOneWidget);
    expect(find.textContaining('GPS'), findsOneWidget);
    expect(find.byKey(ChildrenListKeys.childRow('child_a')), findsOneWidget);
  });

  testWidgets(
    'SCR-FAT-012 runtime roster renders profile repair instead of fake child facts',
    (tester) async {
      final familyId = FamilyId('fam_runtime');
      final runtime = AppRuntime(
        identity: _StaticIdentitySource(
          IdentitySnapshot(
            authority: IdentityAuthority.localOnly,
            accountId: AccountId('parent_runtime'),
            familyId: familyId,
            role: AppRole.father,
            isPrimaryOwner: true,
          ),
        ),
        roster: _StaticRosterSource(
          FamilyRosterSnapshot(
            familyId: familyId,
            origin: RuntimeDataOrigin.localOnly,
            children: [
              FamilyRosterChild(childId: ChildId('child_profile_missing')),
            ],
          ),
        ),
      );
      addTearDown(runtime.dispose);

      await tester.pumpWidget(
        _app(runtime: runtime, child: const ChildrenListScreen()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ChildrenListKeys.profileRepair('child_profile_missing')),
        findsOneWidget,
      );
      expect(
        find.byKey(ChildrenListKeys.childRow('child_profile_missing')),
        findsNothing,
      );
      expect(find.text('child_profile_missing'), findsNothing);
      expect(find.byKey(ChildrenListKeys.localOnlyBanner), findsOneWidget);
    },
  );

  testWidgets(
    'SCR-FAT-012 the device card appears only for the device the server flagged',
    (tester) async {
      const childId = '33333333-3333-4333-8333-333333333333';
      const deviceId = '44444444-4444-4444-8444-444444444444';
      // The card existed, the contract existed, and the roster showed a tag. This test is
      // the proof the association is real: the sentence the guardian reads comes from the
      // server's own reason code, and a device the server called healthy produces nothing.
      final familyId = FamilyId('fam_device_card');
      final runtime = AppRuntime(
        identity: _StaticIdentitySource(
          IdentitySnapshot(
            authority: IdentityAuthority.remoteAuthoritative,
            accountId: AccountId('parent_device_card'),
            familyId: familyId,
            role: AppRole.father,
            isPrimaryOwner: true,
          ),
        ),
        roster: _StaticRosterSource(
          FamilyRosterSnapshot(
            familyId: familyId,
            origin: RuntimeDataOrigin.remoteAuthoritative,
            children: [
              FamilyRosterChild(
                childId: ChildId('33333333-3333-4333-8333-333333333333'),
                displayName: 'أمانة',
                ageYears: 9,
              ),
            ],
          ),
        ),
        devices: _StaticDeviceSource(
          _snapshotWith(familyId, [
            _device(
              id: '44444444-4444-4444-8444-444444444444',
              childId: '33333333-3333-4333-8333-333333333333',
              state: FoundationGateDeviceHealthState.offline,
              reasonCode: 'stopped_reporting',
              needsAttention: true,
            ),
          ]),
        ),
      );
      addTearDown(runtime.dispose);

      await tester.pumpWidget(
        _app(runtime: runtime, child: const ChildrenListScreen()),
      );
      await tester.pumpAndSettle();

      // Asserted in the order the screen builds them, each with its own reason, so a
      // failure says which link of the chain broke instead of pointing at the last one.
      expect(
        find.byKey(ChildrenListKeys.childRow(childId)),
        findsOneWidget,
        reason: 'the roster row must render before its device card can',
      );
      expect(
        find.byKey(ChildrenListKeys.deviceCard(deviceId)),
        findsOneWidget,
        reason: 'the device the server flagged produced no card',
      );
      expect(find.byType(ChildDeviceCard), findsOneWidget);
      // The words are the copy layer's, and they name the cause rather than a raw code:
      // an offline device is offered the one step that could actually help it.
      expect(
        find.textContaining('غير متصل'),
        findsWidgets,
        reason: 'the card must name the condition in the guardian language',
      );
      expect(
        find.textContaining('تأكد أن الجهاز يعمل'),
        findsWidgets,
        reason: 'an offline device must offer the one step that could help',
      );
      // A raw machine code appearing on screen would mean the localization layer failed.
      expect(find.textContaining('stopped_reporting'), findsNothing);
    },
  );

  testWidgets('SCR-FAT-012 a working device is silence, not a green badge', (
    tester,
  ) async {
    final familyId = FamilyId('fam_device_quiet');
    final runtime = AppRuntime(
      identity: _StaticIdentitySource(
        IdentitySnapshot(
          authority: IdentityAuthority.remoteAuthoritative,
          accountId: AccountId('parent_device_quiet'),
          familyId: familyId,
          role: AppRole.father,
          isPrimaryOwner: true,
        ),
      ),
      roster: _StaticRosterSource(
        FamilyRosterSnapshot(
          familyId: familyId,
          origin: RuntimeDataOrigin.remoteAuthoritative,
          children: [
            FamilyRosterChild(
              childId: ChildId('55555555-5555-4555-8555-555555555555'),
              displayName: 'أمانة',
              ageYears: 9,
            ),
          ],
        ),
      ),
      devices: _StaticDeviceSource(
        _snapshotWith(familyId, [
          _device(
            id: '66666666-6666-4666-8666-666666666666',
            childId: '55555555-5555-4555-8555-555555555555',
            state: FoundationGateDeviceHealthState.active,
            reasonCode: 'reporting_now',
            needsAttention: false,
          ),
        ]),
      ),
    );
    addTearDown(runtime.dispose);

    await tester.pumpWidget(
      _app(runtime: runtime, child: const ChildrenListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChildDeviceCard), findsNothing);
  });

  testWidgets(
    'SCR-FAT-012 a device that was cut off leads to the pairing journey',
    (tester) async {
      // The card told the guardian "pair it again so it can report once more". That
      // sentence was reachable and the action was not: the screen built the card with no
      // repair callback at all, so a lost handset produced advice and no way to act on it.
      // This test walks the whole step, including where it lands and with whose child id.
      const childId = '77777777-7777-4777-8777-777777777777';
      const deviceId = '88888888-8888-4888-8888-888888888888';
      final familyId = FamilyId('fam_device_repair');
      final runtime = AppRuntime(
        identity: _StaticIdentitySource(
          IdentitySnapshot(
            authority: IdentityAuthority.remoteAuthoritative,
            accountId: AccountId('parent_device_repair'),
            familyId: familyId,
            role: AppRole.father,
            isPrimaryOwner: true,
          ),
        ),
        roster: _StaticRosterSource(
          FamilyRosterSnapshot(
            familyId: familyId,
            origin: RuntimeDataOrigin.remoteAuthoritative,
            children: [
              FamilyRosterChild(
                childId: ChildId(childId),
                displayName: 'أمانة',
                ageYears: 9,
              ),
            ],
          ),
        ),
        devices: _StaticDeviceSource(
          _snapshotWith(familyId, [
            _device(
              id: deviceId,
              childId: childId,
              state: FoundationGateDeviceHealthState.revoked,
              reasonCode: 'device_revoked',
              needsAttention: true,
            ),
          ]),
        ),
      );
      addTearDown(runtime.dispose);

      // A real router, not a callback seam: the destination under test is the route the
      // guardian's tap actually reaches, which is the only thing that proves the repair
      // journey exists rather than being described.
      final router = GoRouter(
        initialLocation: '/scr-fat-012',
        routes: [
          GoRoute(
            path: '/scr-fat-012',
            builder: (context, state) => const ChildrenListScreen(),
          ),
          GoRoute(
            path: '/scr-fat-004',
            builder: (context, state) => Scaffold(
              body: Text('PAIRING:${state.uri.queryParameters['childId']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(_routedApp(runtime: runtime, router: router));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('أعد الربط'),
        findsWidgets,
        reason: 'the card must say what would help a cut-off device',
      );
      final action = find.descendant(
        of: find.byKey(ChildrenListKeys.deviceCard(deviceId)),
        matching: find.text('إصلاح'),
      );
      expect(
        action,
        findsOneWidget,
        reason: 'the repair the card names must be offered, not just suggested',
      );

      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(
        find.text('PAIRING:$childId'),
        findsOneWidget,
        reason: 'the repair step must land on the pairing journey for that child',
      );
    },
  );

  testWidgets(
    'SCR-FAT-012 a silent device is told about, not sent somewhere useless',
    (tester) async {
      // The same card, a different state. "Check that the device is on" is a step on the
      // child's handset; a button leading to a pairing screen would create a second device
      // record and leave the silent one silent. So the sentence stands alone.
      const childId = '99999999-9999-4999-8999-999999999999';
      const deviceId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      final familyId = FamilyId('fam_device_silent');
      final runtime = AppRuntime(
        identity: _StaticIdentitySource(
          IdentitySnapshot(
            authority: IdentityAuthority.remoteAuthoritative,
            accountId: AccountId('parent_device_silent'),
            familyId: familyId,
            role: AppRole.father,
            isPrimaryOwner: true,
          ),
        ),
        roster: _StaticRosterSource(
          FamilyRosterSnapshot(
            familyId: familyId,
            origin: RuntimeDataOrigin.remoteAuthoritative,
            children: [
              FamilyRosterChild(
                childId: ChildId(childId),
                displayName: 'أمانة',
                ageYears: 9,
              ),
            ],
          ),
        ),
        devices: _StaticDeviceSource(
          _snapshotWith(familyId, [
            _device(
              id: deviceId,
              childId: childId,
              state: FoundationGateDeviceHealthState.offline,
              reasonCode: 'stopped_reporting',
              needsAttention: true,
            ),
          ]),
        ),
      );
      addTearDown(runtime.dispose);

      await tester.pumpWidget(
        _app(runtime: runtime, child: const ChildrenListScreen()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ChildrenListKeys.deviceCard(deviceId)),
        findsOneWidget,
        reason: 'a device the server flagged still has to reach the guardian',
      );
      expect(
        find.textContaining('تأكد أن الجهاز يعمل'),
        findsWidgets,
        reason: 'the cause and the step must still be named in words',
      );
      expect(
        find.text('إصلاح'),
        findsNothing,
        reason: 'no control may be offered when this handset cannot carry the step out',
      );
    },
  );

  testWidgets('SCR-FAT-012 no provenance → no demo BannerNote', (tester) async {
    final repo = InMemoryChildrenListRepository(
      children: ChildrenListMock.manyFixture,
    );

    await tester.pumpWidget(
      _app(
        child: ChildrenListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onAddChild: () {},
          onOpenChildProfile: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildrenListKeys.localDemoBanner), findsNothing);
    expect(find.byKey(ChildrenListKeys.list), findsOneWidget);
  });
}

Widget _app({required Widget child, AppRuntime? runtime}) {
  final app = MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
  if (runtime == null) return app;
  return AppScope(runtime: runtime, child: app);
}

/// The same app, driven by a router so a test can observe where a tap navigates.
Widget _routedApp({required AppRuntime runtime, required GoRouter router}) {
  return AppScope(
    runtime: runtime,
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
  );
}

final class _StaticIdentitySource extends ChangeNotifier
    implements IdentitySource {
  _StaticIdentitySource(this._value);

  final IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async => _value;
}

final class _StaticRosterSource extends ChangeNotifier
    implements FamilyRosterSource {
  _StaticRosterSource(this._value);

  final FamilyRosterSnapshot _value;

  @override
  FamilyRosterSnapshot get value => _value;

  @override
  Future<FamilyRosterSnapshot> load(FamilyId familyId) async => _value;
}

/// A device source that answers with exactly the conditions a test hands it, so the
/// widget can be checked against the server's verdict rather than against a guess.
final class _StaticDeviceSource extends ChangeNotifier
    implements FamilyDeviceSource {
  _StaticDeviceSource(this._value);

  final FamilyDeviceSnapshot _value;

  @override
  FamilyDeviceSnapshot get value => _value;

  @override
  Future<FamilyDeviceSnapshot> load(FamilyId familyId) async => _value;
}

FoundationGateGuardianDevice _device({
  required String id,
  required String childId,
  required FoundationGateDeviceHealthState state,
  required String reasonCode,
  required bool needsAttention,
}) {
  return FoundationGateGuardianDevice(
    id: id,
    childId: childId,
    deviceLabel: 'هاتف أمانة',
    credentialState: state == FoundationGateDeviceHealthState.revoked
        ? FoundationGateDeviceCredentialState.revoked
        : FoundationGateDeviceCredentialState.active,
    batteryLevel: 41,
    batteryStatus: 'unplugged',
    locationLabel: 'البيت',
    lastSeenAt: DateTime.utc(2026, 10, 6, 9),
    linkedAt: DateTime.utc(2026, 10, 1, 9),
    capabilities: const <FoundationGateDeviceCapability>[
      FoundationGateDeviceCapability(
        id: 'telemetry',
        state: FoundationGateDeviceCapabilityState.unavailable,
        reasonCode: 'stopped_reporting',
        since: null,
      ),
    ],
    health: FoundationGateDeviceHealth(
      state: state,
      reasonCode: reasonCode,
      since: null,
      needsAttention: needsAttention,
    ),
  );
}

FamilyDeviceSnapshot _snapshotWith(
  FamilyId familyId,
  List<FoundationGateGuardianDevice> devices,
) {
  final byChild = groupFoundationGateDevicesByChild(devices);
  return FamilyDeviceSnapshot(
    familyId: familyId,
    origin: RuntimeDataOrigin.remoteAuthoritative,
    children: [
      for (final entry in byChild.entries)
        FamilyChildDeviceSummary(
          childId: ChildId(entry.key),
          connectionState: ChildDeviceConnectionState.needsAttention,
          deviceCount: entry.value.length,
          devices: List<FoundationGateGuardianDevice>.unmodifiable(entry.value),
          needsAttention: attentionDeviceForChild(entry.value) != null,
        ),
    ],
    observedAt: DateTime.utc(2026, 10, 6, 15),
  );
}
