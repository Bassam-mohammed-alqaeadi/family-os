import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

/// Declares where a visible identity/family context comes from.
///
/// The application must not present a local context as remote authority. The
/// legacy adapter deliberately reports [localOnly] until a Render-backed
/// identity source replaces it.
enum IdentityAuthority { unavailable, localOnly, remoteAuthoritative }

/// Immutable, UI-safe projection of the current identity context.
///
/// This is the boundary screens use during the migration away from direct
/// `stage1IdentityRuntime` access. It deliberately holds no credentials,
/// tokens, or raw provider data.
@immutable
final class IdentitySnapshot {
  const IdentitySnapshot({
    required this.authority,
    this.accountId,
    this.familyId,
    this.activeChildId,
    this.role,
    this.motherLevel,
    this.isPrimaryOwner = false,
  });

  const IdentitySnapshot.unavailable()
    : authority = IdentityAuthority.unavailable,
      accountId = null,
      familyId = null,
      activeChildId = null,
      role = null,
      motherLevel = null,
      isPrimaryOwner = false;

  final IdentityAuthority authority;
  final AccountId? accountId;
  final FamilyId? familyId;
  final ChildId? activeChildId;
  final AppRole? role;
  final MotherLevel? motherLevel;
  final bool isPrimaryOwner;

  bool get hasFamilyContext => accountId != null && familyId != null;
  bool get isRemoteAuthoritative =>
      authority == IdentityAuthority.remoteAuthoritative;

  @override
  bool operator ==(Object other) {
    return other is IdentitySnapshot &&
        other.authority == authority &&
        other.accountId == accountId &&
        other.familyId == familyId &&
        other.activeChildId == activeChildId &&
        other.role == role &&
        other.motherLevel == motherLevel &&
        other.isPrimaryOwner == isPrimaryOwner;
  }

  @override
  int get hashCode => Object.hash(
    authority,
    accountId,
    familyId,
    activeChildId,
    role,
    motherLevel,
    isPrimaryOwner,
  );
}

/// The application-facing identity seam.
///
/// Implementations may be local during the migration or Render-authoritative
/// later. Screens consume [value], not a process-global identity singleton.
abstract interface class IdentitySource
    implements ValueListenable<IdentitySnapshot> {
  Future<IdentitySnapshot> refresh();

  void dispose();
}

/// Transitional adapter around the existing in-process identity runtime.
///
/// Its authority label prevents a screen from mistaking local state for a
/// remotely authorized family context. This adapter belongs only in the app
/// composition root and is the migration bridge, not the target source.
final class RuntimeIdentitySource extends ChangeNotifier
    implements IdentitySource {
  RuntimeIdentitySource(
    this._runtime, {
    this.authority = IdentityAuthority.localOnly,
  }) : _value = _snapshotOf(_runtime, authority: authority) {
    _runtime.addListener(_sync);
  }

  final IdentityRuntime _runtime;
  final IdentityAuthority authority;
  IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async {
    _sync();
    return _value;
  }

  void _sync() {
    final next = _snapshotOf(_runtime, authority: authority);
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _runtime.removeListener(_sync);
    super.dispose();
  }

  static IdentitySnapshot _snapshotOf(
    IdentityRuntime runtime, {
    required IdentityAuthority authority,
  }) {
    final authorization = runtime.authorizationContext;
    return IdentitySnapshot(
      authority: authority,
      accountId: runtime.account.id,
      familyId: runtime.activeFamilyId,
      activeChildId: runtime.activeChildId,
      role: authorization.role,
      motherLevel: authorization.motherLevel,
      isPrimaryOwner: authorization.isPrimaryOwner,
    );
  }
}
