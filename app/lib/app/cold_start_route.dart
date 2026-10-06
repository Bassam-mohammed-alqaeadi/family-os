import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// The only launch decision used after native child-mode and guardian identity
/// restoration have completed.
///
/// This resolver is intentionally pure: cold-start behavior can be covered by
/// deterministic unit tests without building the router or touching storage.
@immutable
final class ColdStartDestination {
  const ColdStartDestination({required this.location, required this.role});

  final String location;
  final AppRole role;
}

/// Routes a restored session directly to its active flow.
///
/// A paired child always wins. Guardians with an authenticated provider
/// principal never see launch marketing or a login screen. Signed-out users
/// alone enter the short, bounded launch experience.
ColdStartDestination resolveColdStartDestination({
  required String? pairedChildHomeLocation,
  required IdentitySnapshot identity,
  required FoundationGatePhase guardianPhase,
  required bool hasAuthenticatedGuardian,
}) {
  if (pairedChildHomeLocation case final childHome?) {
    return ColdStartDestination(location: childHome, role: AppRole.child);
  }

  final restoredRole = switch (identity.role) {
    AppRole.mother => AppRole.mother,
    _ => AppRole.father,
  };

  if (!hasAuthenticatedGuardian) {
    return ColdStartDestination(location: '/launch', role: restoredRole);
  }

  final location = switch (guardianPhase) {
    FoundationGatePhase.noActiveFamily => '/scr-fat-001',
    FoundationGatePhase.noChildren => '/scr-fat-003',
    FoundationGatePhase.familiesAvailable ||
    FoundationGatePhase.loadingRoster ||
    FoundationGatePhase.childrenAvailable ||
    FoundationGatePhase.rosterAccessDenied ||
    FoundationGatePhase.serviceUnavailable ||
    FoundationGatePhase.networkUnavailable => '/scr-fat-012',
    // An authenticated principal should not ordinarily remain in another
    // phase after refresh. Fail safely into family setup rather than exposing
    // onboarding or asking for credentials that are already restored.
    _ => '/scr-fat-001',
  };

  return ColdStartDestination(location: location, role: restoredRole);
}
