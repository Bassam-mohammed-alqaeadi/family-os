import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

void main() {
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
}

Widget _app({required IdentityRuntime runtime, required Widget child}) {
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
    home: CurrentIdentity(runtime: runtime, child: child),
  );
}
