import 'package:flutter/foundation.dart';

import 'package:family_os/core/runtime/family_child_deletion_source.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/core/runtime/family_device_revocation.dart';
import 'package:family_os/core/runtime/family_device_source.dart';
import 'package:family_os/core/runtime/family_invite_code_source.dart';
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
    FamilyChildDeletionSource? childDeletion,
    FamilyCreationSource? familyCreation,
    FamilyDeviceSource? devices,
    FamilyDeviceRevocationSource? deviceRevocation,
    FamilyInviteCodeSource? inviteCodes,
    FamilyPolicySource? policies,
  }) : roster = roster ?? UnavailableFamilyRosterSource(),
       childProfiles = childProfiles ?? UnavailableFamilyChildProfileSource(),
       childDeletion = childDeletion ?? UnavailableFamilyChildDeletionSource(),
       familyCreation = familyCreation ?? UnavailableFamilyCreationSource(),
       devices = devices ?? UnavailableFamilyDeviceSource(),
       deviceRevocation =
           deviceRevocation ?? UnavailableFamilyDeviceRevocationSource(),
       inviteCodes = inviteCodes ?? UnavailableFamilyInviteCodeSource(),
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

  /// Main-app child-deletion source.
  final FamilyChildDeletionSource childDeletion;

  /// The main-app family-creation source. It fails closed: a route with no
  /// configured server session says so instead of fabricating a local family.
  final FamilyCreationSource familyCreation;

  /// Explicit device-summary source. It does not grant mutation authority.
  final FamilyDeviceSource devices;

  /// The one device-write port: cutting a child device off on the server.
  /// Success exists only when the server confirms the revocation.
  final FamilyDeviceRevocationSource deviceRevocation;

  /// Invites by code: a guardian's code exists only when the server issued it, and joining
  /// a family exists only when the server created the membership. Fails closed.
  final FamilyInviteCodeSource inviteCodes;

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
    if (!identical(childDeletion, identity) &&
        !identical(childDeletion, roster) &&
        !identical(childDeletion, childProfiles)) {
      childDeletion.dispose();
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
    if (!identical(inviteCodes, identity) &&
        !identical(inviteCodes, roster) &&
        !identical(inviteCodes, childProfiles) &&
        !identical(inviteCodes, familyCreation) &&
        !identical(inviteCodes, devices) &&
        !identical(inviteCodes, deviceRevocation)) {
      inviteCodes.dispose();
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
