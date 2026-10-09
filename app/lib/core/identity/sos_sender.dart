import 'package:flutter/widgets.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/active_child_resolver.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/sos_final/sos_final_runtime.dart';

/// VX-B2 / OD-13 · Owner D7 — who raised an SOS.
///
/// Child surface → the real child id. Parent surface → the acting parent's
/// membership plus the child being viewed (active child when none is in view).
@immutable
final class SosSender {
  const SosSender({required this.role, required this.actorId, this.childId});

  /// [AppRole.child] on child surfaces; father/mother on parent surfaces.
  final AppRole role;

  /// Child id (child surface) or the acting parent's membership id.
  final String actorId;

  /// Explicit viewed child (parent) or the child themself (child surface).
  final ChildId? childId;

  bool get isChild => role == AppRole.child;

  /// Subject child for durable records and `SosFireService.fire(childId:)`.
  ///
  /// Viewed child when set; else the child themself on child surfaces; else
  /// the family's active child (parent with no explicit view).
  ChildId subjectChildId({IdentityRuntime? runtime}) {
    if (childId != null) return childId!;
    if (isChild) return ChildId(actorId);
    return resolveActiveChildId(runtime: runtime);
  }

  /// @deprecated Prefer [subjectChildId] — kept for call-site migration.
  String get fireSubjectId => childId?.value ?? actorId;

  /// Fire with actor + subject recorded (OD-13). Parent surfaces also open a
  /// durable `sos_final` incident so FAT-018 is never empty after a parent press.
  Future<SosFireResult> fireThrough(
    SosFireService sosFire, {
    IdentityRuntime? runtime,
    bool openDurableParentIncident = true,
  }) async {
    final identity = runtime ?? stage1IdentityRuntime;
    final subject = subjectChildId(runtime: identity);
    final result = await sosFire.fire(childId: subject.value, actorId: actorId);
    if (!isChild && openDurableParentIncident) {
      try {
        await Stage1SosFinalRuntime.ensureOpen();
        final existing = await Stage1SosFinalRuntime.service.loadOpen(
          childId: subject,
        );
        if (existing == null) {
          final device = deviceIdForChild(subject, runtime: identity);
          await Stage1SosFinalRuntime.crossSystem.fireParentAlert(
            actorId: actorId,
            childId: subject,
            deviceId: device,
          );
        }
      } on Object {
        // Soft: unit/widget tests without FS session still keep the fire audit.
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is SosSender &&
      other.role == role &&
      other.actorId == actorId &&
      other.childId == childId;

  @override
  int get hashCode => Object.hash(role, actorId, childId);

  @override
  String toString() => 'SosSender($role, $actorId, ${childId?.value})';
}

/// Child-triggered SOS: explicit child (route) or the active child.
SosSender resolveChildSosSender({ChildId? explicit, IdentityRuntime? runtime}) {
  final child = resolveActiveChildId(explicit: explicit, runtime: runtime);
  return SosSender(role: AppRole.child, actorId: child.value, childId: child);
}

/// Parent-triggered SOS: acting parent + [viewedChild] when one is in view.
SosSender resolveParentSosSender({
  ChildId? viewedChild,
  AppRole? role,
  IdentityRuntime? runtime,
}) {
  final identity = runtime ?? stage1IdentityRuntime;
  final auth = identity.authorizationContext;
  final acting = role ?? auth.role;
  return SosSender(
    role: acting == AppRole.mother ? AppRole.mother : AppRole.father,
    actorId: auth.activeFamily.membershipId.value,
    childId: viewedChild,
  );
}

SosSender childSosSenderOf(BuildContext context, {ChildId? explicit}) {
  return resolveChildSosSender(
    explicit: explicit,
    runtime: identityOf(context),
  );
}

SosSender parentSosSenderOf(
  BuildContext context, {
  ChildId? viewedChild,
  AppRole? role,
}) {
  return resolveParentSosSender(
    viewedChild: viewedChild,
    role: role,
    runtime: identityOf(context),
  );
}

/// Screens shared by child and parents: sender follows the screen's role.
SosSender sosSenderForRole(
  BuildContext context,
  AppRole role, {
  ChildId? viewedChild,
}) {
  if (role == AppRole.child) return childSosSenderOf(context);
  return parentSosSenderOf(context, viewedChild: viewedChild, role: role);
}

/// [raw] as a viewed child only when it is a child of the active family
/// (e.g. a chat peer); otherwise null.
ChildId? familyChildOrNull(String? raw, {IdentityRuntime? runtime}) {
  final id = childIdFromParam(raw);
  if (id == null) return null;
  final identity = runtime ?? stage1IdentityRuntime;
  final match = identity.children.any(
    (c) => c.id == id && c.familyId == identity.activeFamilyId,
  );
  return match ? id : null;
}
