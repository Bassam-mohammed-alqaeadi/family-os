import 'package:flutter/widgets.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';

/// VX-B2 · D6 — one resolver for "which child / which family" on top of the
/// existing identity authority ([IdentityRuntime]). Features never fall back to
/// literal demo ids; `core/policy` defaults stay untouched.

/// `?childId=` route value → [ChildId]; blank or missing → null.
ChildId? childIdFromParam(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  return ChildId(value);
}

/// Identity in the tree, else the Stage-1 singleton (same runtime `main.dart`
/// provides).
IdentityRuntime identityOf(BuildContext? context) {
  final scoped = context == null ? null : CurrentIdentity.maybeOf(context);
  return scoped ?? stage1IdentityRuntime;
}

/// Explicit (route / profile) child wins; otherwise the active family's
/// selected child from the identity authority.
ChildId resolveActiveChildId({ChildId? explicit, IdentityRuntime? runtime}) {
  return explicit ?? (runtime ?? stage1IdentityRuntime).activeChildId;
}

ChildId resolveActiveChildIdOf(BuildContext context, {ChildId? explicit}) {
  return resolveActiveChildId(explicit: explicit, runtime: identityOf(context));
}

/// Active family from the identity authority (follows family switches).
FamilyId resolveActiveFamilyId({IdentityRuntime? runtime}) {
  return (runtime ?? stage1IdentityRuntime).activeFamilyId;
}

FamilyId resolveActiveFamilyIdOf(BuildContext context) {
  return resolveActiveFamilyId(runtime: identityOf(context));
}

/// Child chosen in the profile becomes the family context's selected child so
/// every per-child tool opened next acts on the same child.
///
/// Returns false (no change) when [childId] is not in the active family.
bool selectActiveChild(ChildId childId, {IdentityRuntime? runtime}) {
  final identity = runtime ?? stage1IdentityRuntime;
  final inFamily = identity.children.any(
    (c) => c.id == childId && c.familyId == identity.activeFamilyId,
  );
  if (!inFamily) return false;
  if (identity.activeChildId != childId) {
    identity.setActiveChild(childId);
  }
  return true;
}

/// Child linked to [deviceId] in the active family; null when unknown.
ChildId? childIdForDevice(String? deviceId, {IdentityRuntime? runtime}) {
  final raw = deviceId?.trim();
  if (raw == null || raw.isEmpty) return null;
  final identity = runtime ?? stage1IdentityRuntime;
  for (final device in identity.devices) {
    if (device.id.value == raw && device.familyId == identity.activeFamilyId) {
      return device.childId;
    }
  }
  return null;
}

/// First device linked to [childId] in the active family; null when none.
DeviceId? deviceIdForChild(ChildId childId, {IdentityRuntime? runtime}) {
  final identity = runtime ?? stage1IdentityRuntime;
  for (final device in identity.devices) {
    if (device.childId == childId &&
        device.familyId == identity.activeFamilyId) {
      return device.id;
    }
  }
  return null;
}
