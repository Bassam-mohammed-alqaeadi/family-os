import 'package:flutter/foundation.dart';

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
  }) : roster = roster ?? UnavailableFamilyRosterSource() {
    identity.addListener(notifyListeners);
    this.roster.addListener(notifyListeners);
  }

  final IdentitySource identity;

  /// Explicit family roster source. Its default is intentionally unavailable,
  /// never a seeded/global fallback; a normal product route must compose the
  /// local or remote adapter it is allowed to use.
  final FamilyRosterSource roster;

  /// Refreshes only the identity projection. Future runtime ports expose their
  /// own explicit refresh/sync commands; there is intentionally no generic
  /// "pretend everything synchronized" operation.
  Future<IdentitySnapshot> refreshIdentity() => identity.refresh();

  @override
  void dispose() {
    identity.removeListener(notifyListeners);
    roster.removeListener(notifyListeners);
    identity.dispose();
    roster.dispose();
    super.dispose();
  }
}
