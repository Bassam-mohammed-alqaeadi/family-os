import 'package:flutter/widgets.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

class CurrentIdentity extends InheritedNotifier<IdentityRuntime> {
  const CurrentIdentity({
    required IdentityRuntime runtime,
    required super.child,
    super.key,
  }) : super(notifier: runtime);

  static IdentityRuntime? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<CurrentIdentity>()?.notifier;
  }

  static IdentityRuntime of(BuildContext context) {
    final runtime = maybeOf(context);
    assert(runtime != null, 'CurrentIdentity not found in tree');
    return runtime!;
  }
}

AuthorizationContext resolveAuthorizationContext(
  BuildContext context, {
  AppRole? fallbackRole,
  MotherLevel fallbackMotherLevel = MotherLevel.partner,
}) {
  final runtime = CurrentIdentity.maybeOf(context);
  if (runtime != null) return runtime.authorizationContext;
  return AuthorizationContext(
    activeFamily: ActiveFamilyContext(
      sessionId: runtime?.session.id ?? SessionId('sess_fallback'),
      accountId: runtime?.account.id ?? AccountId('acc_fallback'),
      membershipId: runtime?.activeMembership.id ?? MemberId('mem_fallback'),
      familyId: runtime?.activeFamilyId ?? FamilyId('fam_fallback'),
    ),
    role: fallbackRole ?? AppRole.father,
    motherLevel: fallbackMotherLevel,
    membershipTier: MembershipTier.primary,
    isPrimaryOwner: fallbackRole == null || fallbackRole == AppRole.father,
  );
}

ChildScope resolveChildScope(
  BuildContext context, {
  ChildId? explicitChildId,
  ChildScope? explicitScope,
}) {
  if (explicitScope != null) return explicitScope;
  final runtime = CurrentIdentity.maybeOf(context);
  final familyId = runtime?.activeFamilyId ?? FamilyId('fam_stage1');
  final childId =
      explicitChildId ?? runtime?.activeChildId ?? ChildId('demo-child');
  return ChildScope(familyId: familyId, childId: childId);
}
