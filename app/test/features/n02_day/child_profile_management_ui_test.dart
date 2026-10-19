import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_child_deletion_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

void main() {
  tearDown(AppToast.dismiss);

  IdentityRuntime buildRuntime({required bool primary}) {
    final accountId = AccountId('acc_owner');
    return IdentityRuntime(
      account: Account(id: accountId),
      session: Session(
        id: SessionId('sess_owner'),
        accountId: accountId,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_a'),
          name: 'Family A',
          ownerMemberId: MemberId('mem_owner'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_owner'),
          accountId: accountId,
          familyId: FamilyId('fam_a'),
          role: AppRole.father,
          tier: primary ? MembershipTier.primary : MembershipTier.coParent,
          isPrimaryOwner: primary,
        ),
      ],
      activeFamilyId: FamilyId('fam_a'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
      ),
      children: [
        ChildIdentity(id: ChildId('child_a'), familyId: FamilyId('fam_a')),
      ],
      devices: [
        DeviceIdentity(
          id: DeviceId('dev_1'),
          familyId: FamilyId('fam_a'),
          childId: ChildId('child_a'),
        ),
      ],
      enrollments: [
        Enrollment(
          id: EnrollmentId('enr_1'),
          deviceId: DeviceId('dev_1'),
          familyId: FamilyId('fam_a'),
          childId: ChildId('child_a'),
          createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
          state: EnrollmentState.enrolled,
        ),
      ],
    );
  }

  ChildProfileRepository profileRepo() {
    return InMemoryChildProfileRepository(
      profiles: const [
        ChildProfile(
          id: 'child_a',
          displayName: 'Child A',
          emoji: '🧒',
          swatch: DayChildSwatch.purple,
          ageYears: 10,
          locationLabel: 'home',
          lastSeenLabel: 'now',
          batteryLabel: '80%',
          walletLabel: '10m',
          todayUsedLabel: '',
          todayCapLabel: '',
          lastHeartbeatLabel: '1m',
          health: ChildListHealth.excellent,
        ),
      ],
    );
  }

  testWidgets('device inventory and enrollment state render', (tester) async {
    final runtime = buildRuntime(primary: true);
    final management = RuntimeChildDeviceManagementRepository(runtime: runtime);
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: profileRepo(),
          managementRepository: management,
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.primaryDeviceCard), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.deviceCard('dev_1')), findsOneWidget);
    expect(find.byKey(ChildProfileKeys.enrollmentRow('enr_1')), findsOneWidget);
  });

  testWidgets('non-primary hides delete and remote controls', (tester) async {
    final runtime = buildRuntime(primary: false);
    final management = RuntimeChildDeviceManagementRepository(runtime: runtime);
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: profileRepo(),
          managementRepository: management,
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ChildProfileKeys.deleteChild), findsNothing);
    expect(find.byKey(ChildProfileKeys.remoteEnd('enr_1')), findsNothing);
  });

  testWidgets('primary can toggle logout and remote-end session', (
    tester,
  ) async {
    final runtime = buildRuntime(primary: true);
    final management = RuntimeChildDeviceManagementRepository(runtime: runtime);
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: profileRepo(),
          managementRepository: management,
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildProfileKeys.logoutToggle('enr_1')));
    await tester.pumpAndSettle();
    expect(
      runtime.childLogoutAllowedForEnrollment(EnrollmentId('enr_1')),
      isTrue,
    );

    await tester.tap(find.byKey(ChildProfileKeys.remoteEnd('enr_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildProfileKeys.remoteEndConfirmAccept));
    await tester.pumpAndSettle();
    expect(runtime.isChildSessionEnded(EnrollmentId('enr_1')), isTrue);
  });

  testWidgets('max 3 active devices shows explicit block banner', (
    tester,
  ) async {
    final runtime = buildRuntime(primary: true);
    runtime.createEnrollment(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_2'),
      enrollmentId: EnrollmentId('enr_2'),
    );
    runtime.createEnrollment(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_3'),
      enrollmentId: EnrollmentId('enr_3'),
    );
    final management = RuntimeChildDeviceManagementRepository(runtime: runtime);
    var openedPairing = false;
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: profileRepo(),
          managementRepository: management,
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
          onOpenPairing: ({required childId, deviceId, enrollmentId}) {
            openedPairing = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildProfileKeys.addDevice));
    await tester.pumpAndSettle();
    expect(openedPairing, isFalse);
    expect(find.byKey(ChildProfileKeys.maxDevicesBanner), findsOneWidget);
  });

  testWidgets('remote deletion confirmed by dialog button on success removes child', (
    tester,
  ) async {
    final runtime = buildRuntime(primary: true);
    final management = RuntimeChildDeviceManagementRepository(runtime: runtime);
    final identitySource = _FakeIdentitySource(
      IdentitySnapshot(
        authority: IdentityAuthority.remoteAuthoritative,
        accountId: AccountId('synthetic-acc'),
        familyId: FamilyId('fam_a'),
        role: AppRole.father,
        motherLevel: MotherLevel.full,
        isPrimaryOwner: true,
      ),
    );
    final fakeDeletion = _FakeChildDeletionSource(shouldSucceed: true);
    final appRuntime = AppRuntime(
      identity: identitySource,
      childDeletion: fakeDeletion,
    );

    var deletedCallbackCalled = false;
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        appRuntime: appRuntime,
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: profileRepo(),
          managementRepository: management,
          roleOverride: AppRole.father,
          onDeletedChild: () => deletedCallbackCalled = true,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(ChildProfileKeys.deleteChild),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildProfileKeys.deleteChild));
    await tester.pumpAndSettle();

    expect(find.byKey(ChildProfileKeys.deleteChildConfirm), findsOneWidget);

    final acceptBtn = tester.widget<FilledButton>(
      find.byKey(ChildProfileKeys.deleteChildConfirmAccept),
    );
    expect(acceptBtn.onPressed, isNotNull);

    await tester.tap(find.byKey(ChildProfileKeys.deleteChildConfirmAccept));
    await tester.pumpAndSettle();

    expect(fakeDeletion.deleteCalls, 1);
    expect(fakeDeletion.deletedFamilyId, FamilyId('fam_a'));
    expect(fakeDeletion.deletedChildId, ChildId('child_a'));
    expect(deletedCallbackCalled, isTrue);
    expect(find.byKey(ChildProfileKeys.deleteChildConfirm), findsNothing);

    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('remote deletion failure keeps child and shows error toast', (
    tester,
  ) async {
    final runtime = buildRuntime(primary: true);
    final management = RuntimeChildDeviceManagementRepository(runtime: runtime);
    final identitySource = _FakeIdentitySource(
      IdentitySnapshot(
        authority: IdentityAuthority.remoteAuthoritative,
        accountId: AccountId('synthetic-acc'),
        familyId: FamilyId('fam_a'),
        role: AppRole.father,
        motherLevel: MotherLevel.full,
        isPrimaryOwner: true,
      ),
    );
    final fakeDeletion = _FakeChildDeletionSource(shouldSucceed: false);
    final appRuntime = AppRuntime(
      identity: identitySource,
      childDeletion: fakeDeletion,
    );

    var deletedCallbackCalled = false;
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        appRuntime: appRuntime,
        child: ChildProfileScreen(
          childId: 'child_a',
          repository: profileRepo(),
          managementRepository: management,
          roleOverride: AppRole.father,
          onDeletedChild: () => deletedCallbackCalled = true,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(ChildProfileKeys.deleteChild),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildProfileKeys.deleteChild));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildProfileKeys.deleteChildConfirmAccept));
    await tester.pumpAndSettle();

    expect(fakeDeletion.deleteCalls, 1);
    expect(deletedCallbackCalled, isFalse);
    expect(find.byKey(ChildProfileKeys.body), findsOneWidget);

    AppToast.dismiss();
    await tester.pump();
  });
}

Widget _app({
  required IdentityRuntime runtime,
  required Widget child,
  AppRuntime? appRuntime,
}) {
  Widget content = CurrentIdentity(runtime: runtime, child: child);
  if (appRuntime != null) {
    content = AppScope(runtime: appRuntime, child: content);
  }
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
    home: content,
  );
}

class _FakeChildDeletionSource implements FamilyChildDeletionSource {
  _FakeChildDeletionSource({this.shouldSucceed = true});

  final bool shouldSucceed;
  int deleteCalls = 0;
  FamilyId? deletedFamilyId;
  ChildId? deletedChildId;

  @override
  Future<FamilyChildDeleteResult> deleteChild({
    required FamilyId familyId,
    required ChildId childId,
    String? idempotencyKey,
  }) async {
    deleteCalls += 1;
    deletedFamilyId = familyId;
    deletedChildId = childId;
    if (shouldSucceed) {
      return const FamilyChildDeleteResult.success();
    }
    return const FamilyChildDeleteResult.failed(
      FamilyChildDeleteFailure.serviceUnavailable,
    );
  }

  @override
  void dispose() {}
}

class _FakeIdentitySource extends ChangeNotifier implements IdentitySource {
  _FakeIdentitySource(this._snapshot);

  IdentitySnapshot _snapshot;

  @override
  IdentitySnapshot get value => _snapshot;

  @override
  Future<IdentitySnapshot> refresh() async => _snapshot;
}
