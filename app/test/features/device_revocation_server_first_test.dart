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
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_device_revocation.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/child_profile_screen.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/sys3_identity/sys3_identity_screens.dart';

/// Slice 0, scope 2: a device cut answers to the server first.
///
/// Success is reported only after the server confirms the revocation; a
/// refusal is shown honestly and never mirrored into a local pretend-success.
const familyUuid = '11111111-1111-4111-8111-111111111111';
const childUuid = '22222222-2222-4222-8222-222222222222';
const deviceUuid = '33333333-3333-4333-8333-333333333333';

void main() {
  IdentityRuntime stage1Runtime() {
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
          id: FamilyId(familyUuid),
          name: 'Family A',
          ownerMemberId: MemberId('mem_owner'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_owner'),
          accountId: accountId,
          familyId: FamilyId(familyUuid),
          role: AppRole.father,
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
      ],
      activeFamilyId: FamilyId(familyUuid),
      activeChildScope: ChildScope(
        familyId: FamilyId(familyUuid),
        childId: ChildId(childUuid),
      ),
      children: [
        ChildIdentity(id: ChildId(childUuid), familyId: FamilyId(familyUuid)),
      ],
      devices: [
        DeviceIdentity(
          id: DeviceId(deviceUuid),
          familyId: FamilyId(familyUuid),
          childId: ChildId(childUuid),
        ),
      ],
      enrollments: [
        Enrollment(
          id: EnrollmentId('enr_1'),
          deviceId: DeviceId(deviceUuid),
          familyId: FamilyId(familyUuid),
          childId: ChildId(childUuid),
          createdAt: DateTime.utc(2026, 1, 1),
          state: EnrollmentState.enrolled,
        ),
      ],
    );
  }

  testWidgets(
    'child profile lost cut: server confirms, then the local mirror closes',
    (tester) async {
      final stage1 = stage1Runtime();
      final revocation = _RecordingRevocationSource(
        result: const DeviceRevokeResult.confirmed(),
      );
      await _pumpChildProfile(
        tester,
        stage1: stage1,
        revocation: revocation,
      );

      await tester.tap(find.byKey(ChildProfileKeys.closeLost('enr_1')));
      await tester.pumpAndSettle();

      expect(revocation.calls, 1);
      expect(revocation.lastFamilyId, familyUuid);
      expect(revocation.lastChildId, childUuid);
      expect(revocation.lastDeviceId, deviceUuid);
      expect(revocation.lastReasonCode, 'lost');
      expect(revocation.lastIdempotencyKey, isNotEmpty);
      expect(
        stage1.enrollments.singleWhere((e) => e.id.value == 'enr_1').state,
        EnrollmentState.lost,
      );
    },
  );

  testWidgets(
    'child profile lost cut: server refusal leaves the device open and says so',
    (tester) async {
      final stage1 = stage1Runtime();
      final revocation = _RecordingRevocationSource(
        result: const DeviceRevokeResult.failed(DeviceRevokeFailure.accessDenied),
      );
      await _pumpChildProfile(
        tester,
        stage1: stage1,
        revocation: revocation,
      );

      await tester.tap(find.byKey(ChildProfileKeys.closeLost('enr_1')));
      await tester.pumpAndSettle();

      expect(revocation.calls, 1);
      // The server did not confirm: the local mirror must NOT pretend the
      // device is cut.
      expect(
        stage1.enrollments.singleWhere((e) => e.id.value == 'enr_1').state,
        EnrollmentState.enrolled,
      );
      expect(find.text('Could not save — try again'), findsOneWidget);
    },
  );

  testWidgets(
    'sys3 revoke confirm: server confirms, success only after the verdict',
    (tester) async {
      final stage1 = stage1Runtime();
      final revocation = _RecordingRevocationSource(
        result: const DeviceRevokeResult.confirmed(),
      );
      await _pumpRevokeConfirm(
        tester,
        stage1: stage1,
        revocation: revocation,
        reason: 'lost',
      );

      await tester.tap(find.byKey(const Key('sys3_revoke_action')));
      await tester.pumpAndSettle();

      expect(revocation.calls, 1);
      expect(revocation.lastReasonCode, 'lost');
      expect(find.byKey(Sys3Keys.success), findsOneWidget);
      expect(
        stage1.enrollments.singleWhere((e) => e.id.value == 'enr_1').state,
        EnrollmentState.revoked,
      );
    },
  );

  testWidgets(
    'sys3 revoke confirm: server refusal shows the failure, not success',
    (tester) async {
      final stage1 = stage1Runtime();
      final revocation = _RecordingRevocationSource(
        result: const DeviceRevokeResult.failed(
          DeviceRevokeFailure.networkUnavailable,
        ),
      );
      await _pumpRevokeConfirm(
        tester,
        stage1: stage1,
        revocation: revocation,
        reason: 'no_longer_used',
      );

      await tester.tap(find.byKey(const Key('sys3_revoke_action')));
      await tester.pumpAndSettle();

      expect(revocation.calls, 1);
      expect(revocation.lastReasonCode, 'no_longer_used');
      expect(find.byKey(Sys3Keys.error), findsOneWidget);
      expect(find.byKey(Sys3Keys.success), findsNothing);
      expect(
        stage1.enrollments.singleWhere((e) => e.id.value == 'enr_1').state,
        EnrollmentState.enrolled,
      );
    },
  );
}

Future<void> _pumpChildProfile(
  WidgetTester tester, {
  required IdentityRuntime stage1,
  required FamilyDeviceRevocationSource revocation,
}) async {
  final management = RuntimeChildDeviceManagementRepository(runtime: stage1);
  await tester.pumpWidget(
    AppScope(
      runtime: AppRuntime(
        identity: _StaticRemoteIdentity(IdentitySnapshot(
          authority: IdentityAuthority.remoteAuthoritative,
          accountId: AccountId('acc_owner'),
          familyId: FamilyId(familyUuid),
          isPrimaryOwner: true,
          role: AppRole.father,
        )),
        deviceRevocation: revocation,
      ),
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => CurrentIdentity(
          runtime: stage1,
          child: child ?? const SizedBox.shrink(),
        ),
        home: ChildProfileScreen(
          childId: childUuid,
          repository: InMemoryChildProfileRepository(
            profiles: const [
              ChildProfile(
                id: childUuid,
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
          ),
          managementRepository: management,
          roleOverride: AppRole.father,
          onNavigateTool: (_) {},
          onOpenLocation: () {},
          onOpenDeviceHealth: () {},
          onOpenPairing: ({required childId, deviceId, enrollmentId}) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRevokeConfirm(
  WidgetTester tester, {
  required IdentityRuntime stage1,
  required FamilyDeviceRevocationSource revocation,
  required String reason,
}) async {
  await tester.pumpWidget(
    AppScope(
      runtime: AppRuntime(
        identity: _StaticRemoteIdentity(IdentitySnapshot(
          authority: IdentityAuthority.remoteAuthoritative,
          accountId: AccountId('acc_owner'),
          familyId: FamilyId(familyUuid),
          isPrimaryOwner: true,
          role: AppRole.father,
        )),
        deviceRevocation: revocation,
      ),
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => CurrentIdentity(
          runtime: stage1,
          child: child ?? const SizedBox.shrink(),
        ),
        home: RevokeConfirmScreen(
          kind: 'enrollment',
          id: 'enr_1',
          childId: childUuid,
          deviceId: deviceUuid,
          reason: reason,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A remote-authoritative identity source that answers with the exact snapshot
/// a test hands it.
final class _StaticRemoteIdentity extends ChangeNotifier
    implements IdentitySource {
  _StaticRemoteIdentity(this._value);

  final IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async => _value;
}

/// Records every revocation call and answers with exactly the verdict a test
/// hands it — so the widget can be checked against the server's answer rather
/// than against a guess.
final class _RecordingRevocationSource
    implements FamilyDeviceRevocationSource {
  _RecordingRevocationSource({required this.result});

  final DeviceRevokeResult result;
  final List<String> idempotencyKeys = [];
  int calls = 0;
  String? lastFamilyId;
  String? lastChildId;
  String? lastDeviceId;
  String? lastReasonCode;

  String get lastIdempotencyKey => idempotencyKeys.last;

  @override
  Future<DeviceRevokeResult> revokeDevice({
    required FamilyId familyId,
    required ChildId childId,
    required String deviceId,
    required String? reasonCode,
    required String idempotencyKey,
  }) async {
    calls++;
    lastFamilyId = familyId.value;
    lastChildId = childId.value;
    lastDeviceId = deviceId;
    lastReasonCode = reasonCode;
    idempotencyKeys.add(idempotencyKey);
    return result;
  }

  @override
  void dispose() {}
}
