import 'package:flutter/foundation.dart';

import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/core/runtime/family_device_revocation.dart';
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
    FamilyCreationSource? familyCreation,
    FamilyDeviceSource? devices,
    FamilyDeviceRevocationSource? deviceRevocation,
    FamilyPolicySource? policies,
  }) : roster = roster ?? UnavailableFamilyRosterSource(),
       childProfiles = childProfiles ?? UnavailableFamilyChildProfileSource(),
       familyCreation = familyCreation ?? UnavailableFamilyCreationSource(),
       devices = devices ?? UnavailableFamilyDeviceSource(),
       deviceRevocation =
           deviceRevocation ?? UnavailableFamilyDeviceRevocationSource(),
       policies = policies ?? UnavailableFamilyPolicySource() {
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

  /// The main-app family-creation source. It fails closed: a route with no
  /// configured server session says so instead of fabricating a local family.
  final FamilyCreationSource familyCreation;

  /// Explicit device-summary source. It does not grant mutation authority.
  final FamilyDeviceSource devices;

  /// The one device-write port: cutting a child device off on the server.
  /// Success exists only when the server confirms the revocation.
  final FamilyDeviceRevocationSource deviceRevocation;

  /// Explicit shared-policy source. A local source can persist a draft, but
  /// may never be presented as remote policy enforcement.
  final FamilyPolicySource policies;

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
    if (!identical(familyCreation, identity) &&
        !identical(familyCreation, roster) &&
        !identical(familyCreation, childProfiles)) {
      familyCreation.dispose();
    }
    if (!identical(devices, identity) &&
        !identical(devices, roster) &&
        !identical(devices, childProfiles) &&
        !identical(devices, familyCreation)) {
      devices.dispose();
    }
    if (!identical(deviceRevocation, identity) &&
        !identical(deviceRevocation, roster) &&
        !identical(deviceRevocation, childProfiles) &&
        !identical(deviceRevocation, familyCreation) &&
        !identical(deviceRevocation, devices)) {
      deviceRevocation.dispose();
    }
    if (!identical(policies, identity) &&
        !identical(policies, roster) &&
        !identical(policies, childProfiles) &&
        !identical(policies, familyCreation) &&
        !identical(policies, devices) &&
        !identical(policies, deviceRevocation)) {
      policies.dispose();
    }
    super.dispose();
  }
}
