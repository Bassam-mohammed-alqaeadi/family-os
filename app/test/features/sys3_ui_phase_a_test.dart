import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/adult_invite_repository.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/accept_mother_invite_screen.dart';
import 'package:family_os/features/n01_linking/camera_permission_seam.dart';
import 'package:family_os/features/n01_linking/child_qr_scan_screen.dart';
import 'package:family_os/features/n01_linking/invite_mother_screen.dart';
import 'package:family_os/features/n01_linking/link_qr_screen.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/device_health_list_screen.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';

void main() {
  IdentityRuntime buildRuntime({
    List<Enrollment> enrollments = const [],
    List<ChildIdentity> children = const [],
  }) {
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
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
      ],
      activeFamilyId: FamilyId('fam_a'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
      ),
      children: children.isEmpty
          ? [
              ChildIdentity(
                id: ChildId('child_a'),
                familyId: FamilyId('fam_a'),
              ),
              ChildIdentity(
                id: ChildId('child_b'),
                familyId: FamilyId('fam_a'),
              ),
            ]
          : children,
      devices: const [],
      enrollments: enrollments,
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

  testWidgets(
    'Phase A1: Add Device opens pairing journey (does not silent-enroll)',
    (tester) async {
      final runtime = buildRuntime();
      final management = RuntimeChildDeviceManagementRepository(
        runtime: runtime,
      );
      String? openedChildId;
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
              openedChildId = childId;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(runtime.enrollments, isEmpty);
      await tester.tap(find.byKey(ChildProfileKeys.addDevice));
      await tester.pumpAndSettle();

      expect(openedChildId, 'child_a');
      expect(runtime.enrollments, isEmpty);
    },
  );

  testWidgets(
    'Phase A1: FAT-004 managed pairing issues PairingTokenId + pending EnrollmentId',
    (tester) async {
      final runtime = buildRuntime();
      final management = RuntimeChildDeviceManagementRepository(
        runtime: runtime,
      );
      await tester.pumpWidget(
        _app(
          runtime: runtime,
          child: LinkQrScreen(
            childId: 'child_a',
            managementRepository: management,
            initialSeconds: 120,
            tickInterval: const Duration(days: 1),
            onContinue: () {},
            onTrial: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(LinkQrKeys.awaitingClaim), findsOneWidget);
      expect(runtime.enrollments, hasLength(1));
      final enrollment = runtime.enrollments.single;
      expect(enrollment.state, EnrollmentState.pairingPending);
      expect(enrollment.pairingTokenId, isNotNull);
      expect(
        enrollment.id.value,
        isNot(equals(enrollment.pairingTokenId!.value)),
      );
      expect(find.byKey(LinkQrKeys.enrollmentId), findsOneWidget);
    },
  );

  testWidgets(
    'Phase A1: CHD-002 invalid pairing token fails honestly (no fake enroll)',
    (tester) async {
      final runtime = buildRuntime();
      final management = RuntimeChildDeviceManagementRepository(
        runtime: runtime,
      );

      await tester.pumpWidget(
        _app(
          runtime: runtime,
          child: ChildQrScanScreen(
            permissionSeam: FakeCameraPermissionSeam(
              status: CameraPermissionStatus.permanentlyDenied,
            ),
            claimToken: 'pair_deadbeef',
            managementRepository: management,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ChildQrScanKeys.manualSubmit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byKey(ChildQrScanKeys.failure), findsOneWidget);
      expect(runtime.enrollments, isEmpty);
    },
  );

  testWidgets(
    'Phase A2: Child Profile without childId shows family-scoped picker',
    (tester) async {
      final runtime = buildRuntime();
      final management = RuntimeChildDeviceManagementRepository(
        runtime: runtime,
      );
      String? selected;
      await tester.pumpWidget(
        _app(
          runtime: runtime,
          child: ChildProfileScreen(
            repository: profileRepo(),
            managementRepository: management,
            roleOverride: AppRole.father,
            onSelectChild: (id) => selected = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildProfileKeys.selectChild), findsOneWidget);
      expect(find.byKey(ChildProfileKeys.missingId), findsOneWidget);
      expect(find.byKey(ChildProfileKeys.body), findsNothing);
      await tester.tap(find.byKey(ChildProfileKeys.selectChildRow('child_a')));
      await tester.pumpAndSettle();
      expect(selected, 'child_a');
    },
  );

  testWidgets(
    'Phase A3: Device Health links to enrollment authority on child profile',
    (tester) async {
      String? openedChildId;
      final seam = FakeDeviceHealthSeam(
        initial: [
          DeviceHealthSnapshot(
            deviceId: 'dev_a',
            familyId: 'fam_a',
            childId: 'child_a',
            displayLabel: 'Device A',
            modelLabel: 'Phone',
            level: DeviceHealthLevel.healthy,
            permissions: const [
              DevicePermissionRow(
                kind: DevicePermissionKind.locationAlways,
                status: DevicePermissionStatus.granted,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        _app(
          runtime: buildRuntime(),
          child: DeviceHealthDevicesSection(
            healthSeam: seam,
            onOpenDevice: (_) {},
            onManageEnrollment: (id) => openedChildId = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(DeviceHealthListKeys.manageEnrollment), findsOneWidget);
      await tester.tap(
        find.byKey(DeviceHealthListKeys.manageEnrollmentFor('child_a')),
      );
      await tester.pumpAndSettle();
      expect(openedChildId, 'child_a');
    },
  );

  testWidgets('Phase A4: invite lifecycle states are visible and honest', (
    tester,
  ) async {
    final runtime = buildRuntime();
    final invites = InMemoryAdultInviteRepository(runtime: runtime);
    final pending = invites.createInvite(
      familyId: FamilyId('fam_a'),
      target: 'mom@example.com',
      level: MotherLevel.partner,
      actorMemberId: MemberId('mem_owner'),
    );

    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: InviteMotherScreen(repository: invites),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('invite_mother_email')),
      'mom@example.com',
    );
    await tester.pumpAndSettle();
    final stateName = pending.stateAt(DateTime.now().toUtc()).name;
    expect(find.byKey(Key('invite_mother_state_$stateName')), findsOneWidget);

    invites.revokeInvite(
      inviteId: pending.id,
      actorMemberId: MemberId('mem_owner'),
    );
    await tester.pumpWidget(
      _app(
        runtime: runtime,
        child: AcceptMotherInviteScreen(
          inviteTokenId: pending.tokenId.value,
          repository: invites,
          onAccept: () {},
          onDecline: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('accept_mother_invite_state_revoked')),
      findsOneWidget,
    );
    expect(find.textContaining('دعوة ملغاة'), findsOneWidget);
  });

  testWidgets(
    'Phase A4: max-3 block shows on Add Device without opening pairing',
    (tester) async {
      final runtime = buildRuntime(
        enrollments: [
          Enrollment(
            id: EnrollmentId('enr_1'),
            deviceId: DeviceId('dev_1'),
            familyId: FamilyId('fam_a'),
            childId: ChildId('child_a'),
            createdAt: DateTime.utc(2026, 1, 1),
            state: EnrollmentState.enrolled,
          ),
          Enrollment(
            id: EnrollmentId('enr_2'),
            deviceId: DeviceId('dev_2'),
            familyId: FamilyId('fam_a'),
            childId: ChildId('child_a'),
            createdAt: DateTime.utc(2026, 1, 2),
            state: EnrollmentState.enrolled,
          ),
          Enrollment(
            id: EnrollmentId('enr_3'),
            deviceId: DeviceId('dev_3'),
            familyId: FamilyId('fam_a'),
            childId: ChildId('child_a'),
            createdAt: DateTime.utc(2026, 1, 3),
            state: EnrollmentState.enrolled,
          ),
        ],
      );
      final management = RuntimeChildDeviceManagementRepository(
        runtime: runtime,
      );
      var opened = false;
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
              opened = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ChildProfileKeys.addDevice));
      await tester.pumpAndSettle();
      expect(opened, isFalse);
      expect(find.byKey(ChildProfileKeys.maxDevicesBanner), findsOneWidget);
    },
  );
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
