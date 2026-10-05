import 'package:flutter/foundation.dart';

import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/core/runtime/family_device_source.dart';
import 'package:family_os/core/runtime/family_policy_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';

/// Application composition boundary for runtime services.
///
/// New ports are added here as typed fields, rather than screens importing
/// concrete adapters or reaching into mutable process-wide singletons.
final class AppRuntime extends ChangeNotifier {
  AppRuntime({
    required this.identity,
    FamilyRosterSource? roster,
    FamilyChildProfileSource? childProfiles,
    FamilyDeviceSource? devices,
    FamilyPolicySource? policies,
    FamilyCreationSource? familyCreation,
  }) : roster = roster ?? UnavailableFamilyRosterSource(),
       childProfiles = childProfiles ?? UnavailableFamilyChildProfileSource(),
       devices = devices ?? UnavailableFamilyDeviceSource(),
       policies = policies ?? UnavailableFamilyPolicySource(),
       familyCreation =
           familyCreation ?? const UnavailableFamilyCreationSource() {
    identity.addListener(notifyListeners);
    this.roster.addListener(notifyListeners);
    this.devices.addListener(notifyListeners);
    this.policies.addListener(notifyListeners);
  }

  final IdentitySource identity;

  /// Explicit family roster source. Its default is intentionally unavailable,
  /// never a seeded/global fallback; a normal product route must compose the
  /// local or remote adapter it is allowed to use.
  final FamilyRosterSource roster;

  /// The only main-app child-profile creation source. An unavailable source
  /// fails closed rather than delegating to the legacy local roster.
  final FamilyChildProfileSource childProfiles;

  /// Explicit device-summary source. It does not grant mutation authority.
  final FamilyDeviceSource devices;

  /// Explicit shared-policy source. A local source can persist a draft, but
  /// may never be presented as remote policy enforcement.
  final FamilyPolicySource policies;

  /// The only main-app family-creation source. Its default is intentionally
  /// unavailable: an unconfigured composition reports that honestly instead of
  /// creating a mock family.
  final FamilyCreationSource familyCreation;

  /// Refreshes only the identity projection. Future runtime ports expose their
  /// own explicit refresh/sync commands; there is intentionally no generic
  /// "pretend everything synchronized" operation.
  Future<IdentitySnapshot> refreshIdentity() => identity.refresh();

  @override
  void dispose() {
    identity.removeListener(notifyListeners);
    roster.removeListener(notifyListeners);
    devices.removeListener(notifyListeners);
    policies.removeListener(notifyListeners);
    identity.dispose();
    if (!identical(roster, identity)) roster.dispose();
    if (!identical(childProfiles, identity) &&
        !identical(childProfiles, roster)) {
      childProfiles.dispose();
    }
    if (!identical(devices, identity) &&
        !identical(devices, roster) &&
        !identical(devices, childProfiles)) {
      devices.dispose();
    }
    if (!identical(policies, identity) &&
        !identical(policies, roster) &&
        !identical(policies, childProfiles) &&
        !identical(policies, devices)) {
      policies.dispose();
    }
    super.dispose();
  }
}
