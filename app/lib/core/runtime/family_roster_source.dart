import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

/// Origin of data rendered by a family-facing screen.
///
/// A source must never report [remoteAuthoritative] unless it is backed by a
/// server-authorized read. Cached data remains distinct so stale state cannot
/// impersonate current family truth.
enum RuntimeDataOrigin { unavailable, localOnly, cached, remoteAuthoritative }

@immutable
final class FamilyRosterChild {
  const FamilyRosterChild({
    required this.childId,
    this.displayName,
    this.ageYears,
  });

  final ChildId childId;

  /// Null means the profile is not available; callers must render setup or
  /// repair truth instead of manufacturing a plausible name.
  final String? displayName;

  /// Null means age has not been supplied by an authoritative profile source.
  final int? ageYears;

  bool get hasCompleteDisplayProfile =>
      displayName != null && displayName!.trim().isNotEmpty && ageYears != null;
}

/// Family-scoped roster payload consumed by the Children Control Centre.
@immutable
final class FamilyRosterSnapshot {
  const FamilyRosterSnapshot({
    required this.familyId,
    required this.origin,
    required this.children,
    this.observedAt,
  });

  const FamilyRosterSnapshot.unavailable()
    : familyId = null,
      origin = RuntimeDataOrigin.unavailable,
      children = const [],
      observedAt = null;

  final FamilyId? familyId;
  final RuntimeDataOrigin origin;
  final List<FamilyRosterChild> children;
  final DateTime? observedAt;

  bool get isAuthoritative => origin == RuntimeDataOrigin.remoteAuthoritative;
  bool get isKnownFamily => familyId != null;
}

/// Typed source boundary for the family roster.
///
/// The current local adapter and a future Render adapter implement this same
/// contract. A caller provides the scoped family explicitly; no default child
/// or family literal is permitted by this API.
abstract interface class FamilyRosterSource
    implements ValueListenable<FamilyRosterSnapshot> {
  Future<FamilyRosterSnapshot> load(FamilyId familyId);

  void dispose();
}

/// Honest default for routes whose roster source has not been composed yet.
///
/// It returns unavailable rather than silently reading seeded/global data.
final class UnavailableFamilyRosterSource extends ChangeNotifier
    implements FamilyRosterSource {
  FamilyRosterSnapshot _value = const FamilyRosterSnapshot.unavailable();

  @override
  FamilyRosterSnapshot get value => _value;

  @override
  Future<FamilyRosterSnapshot> load(FamilyId familyId) async {
    _value = const FamilyRosterSnapshot.unavailable();
    notifyListeners();
    return _value;
  }
}
