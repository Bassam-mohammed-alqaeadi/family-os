import 'package:flutter/widgets.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';

/// Router / screen bind helpers for Location pack (FAT-014…017).
abstract final class LocationRouteBind {
  /// Live MotherLevel from Identity (Partner default when unbound).
  static MotherLevel motherLevelOf(
    BuildContext context, {
    AppRole? fallbackRole,
  }) {
    return resolveAuthorizationContext(
      context,
      fallbackRole: fallbackRole ?? AppRole.father,
    ).motherLevel;
  }

  /// Identity roster → AssignableChild (sync — safe for GoRouter builders).
  static List<AssignableChild> rosterAssignable() {
    final roster = activeFamilyRosterChildren();
    return [
      for (final c in roster)
        AssignableChild(id: c.id.value, label: c.id.value),
    ];
  }

  /// Active-family children for FAT-017 assignment chips (route-time).
  static List<AssignableChild> assignableChildrenOf(BuildContext context) {
    return rosterAssignable();
  }
}

/// Async enrich when ChildrenList is warm (optional screen refresh).
Future<List<AssignableChild>> loadAssignableChildren({
  required FamilyId familyId,
}) async {
  try {
    final kids = await stage1ChildrenListRepository.listChildren(
      familyId: familyId,
    );
    if (kids.isEmpty) return LocationRouteBind.rosterAssignable();
    return [
      for (final k in kids) AssignableChild(id: k.id, label: k.displayName),
    ];
  } catch (_) {
    return LocationRouteBind.rosterAssignable();
  }
}
