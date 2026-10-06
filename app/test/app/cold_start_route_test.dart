import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/cold_start_route.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

void main() {
  group('resolveColdStartDestination', () {
    test('paired child bypasses every guardian and signed-out route', () {
      final result = resolveColdStartDestination(
        pairedChildHomeLocation:
            '/scr-chd-004?childId=11111111-1111-4111-8111-111111111111',
        identity: const IdentitySnapshot.unavailable(),
        guardianPhase: FoundationGatePhase.signedOut,
        hasAuthenticatedGuardian: false,
      );

      expect(result.role, AppRole.child);
      expect(result.location, startsWith('/scr-chd-004'));
    });

    test('signed-out user alone receives the bounded launch screen', () {
      final result = resolveColdStartDestination(
        pairedChildHomeLocation: null,
        identity: const IdentitySnapshot.unavailable(),
        guardianPhase: FoundationGatePhase.signedOut,
        hasAuthenticatedGuardian: false,
      );

      expect(result.location, '/launch');
      expect(result.role, AppRole.father);
    });

    test('restored owner with children bypasses launch, onboarding and login', () {
      final result = resolveColdStartDestination(
        pairedChildHomeLocation: null,
        identity: IdentitySnapshot(
          authority: IdentityAuthority.remoteAuthoritative,
          accountId: AccountId('11111111-1111-4111-8111-111111111111'),
          familyId: FamilyId('22222222-2222-4222-8222-222222222222'),
          role: AppRole.father,
          isPrimaryOwner: true,
        ),
        guardianPhase: FoundationGatePhase.childrenAvailable,
        hasAuthenticatedGuardian: true,
      );

      expect(result.location, '/scr-fat-012');
      expect(result.role, AppRole.father);
    });

    test('restored mother keeps her role and enters the active roster', () {
      final result = resolveColdStartDestination(
        pairedChildHomeLocation: null,
        identity: IdentitySnapshot(
          authority: IdentityAuthority.remoteAuthoritative,
          accountId: AccountId('11111111-1111-4111-8111-111111111111'),
          familyId: FamilyId('22222222-2222-4222-8222-222222222222'),
          role: AppRole.mother,
        ),
        guardianPhase: FoundationGatePhase.loadingRoster,
        hasAuthenticatedGuardian: true,
      );

      expect(result.location, '/scr-fat-012');
      expect(result.role, AppRole.mother);
    });

    test('restored account with no family enters family creation directly', () {
      final result = resolveColdStartDestination(
        pairedChildHomeLocation: null,
        identity: const IdentitySnapshot.unavailable(),
        guardianPhase: FoundationGatePhase.noActiveFamily,
        hasAuthenticatedGuardian: true,
      );

      expect(result.location, '/scr-fat-001');
    });

    test('restored family with no child enters first-child creation directly', () {
      final result = resolveColdStartDestination(
        pairedChildHomeLocation: null,
        identity: const IdentitySnapshot.unavailable(),
        guardianPhase: FoundationGatePhase.noChildren,
        hasAuthenticatedGuardian: true,
      );

      expect(result.location, '/scr-fat-003');
    });
  });
}
