import 'package:flutter/foundation.dart';

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
    FamilyDeviceSource? devices,
    FamilyPolicySource? policies,
  }) : roster = roster ?? UnavailableFamilyRosterSource(),
       devices = devices ?? UnavailableFamilyDeviceSource(),
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

  /// Explicit device-summary source. It does not grant mutation authority.
  final FamilyDeviceSource devices;

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
    roster.dispose();
    devices.dispose();
    policies.dispose();
    super.dispose();
  }
}
