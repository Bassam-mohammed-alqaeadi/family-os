import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/identity/active_child_resolver.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

/// OD-14 — roster child for father pickers (assignments / tasks / events / …).
///
/// [nameKey] is an ARB discriminator (`one` / `two` / `three` …) — never a
/// planted person name (Rule 23). Ids come only from [IdentityRuntime].
@immutable
final class RosterChildRef {
  const RosterChildRef({required this.id, required this.nameKey});

  final ChildId id;
  final String nameKey;
}

/// Children of the active family, in identity order.
///
/// Empty when the family has no children (Rule 23 empty-first).
List<RosterChildRef> activeFamilyRosterChildren({IdentityRuntime? runtime}) {
  final identity = runtime ?? stage1IdentityRuntime;
  final familyId = identity.activeFamilyId;
  final kids = identity.children
      .where((c) => c.familyId == familyId)
      .toList(growable: false);
  return [
    for (var i = 0; i < kids.length; i++)
      RosterChildRef(id: kids[i].id, nameKey: _ordinalNameKey(i)),
  ];
}

/// Active child as a roster ref; null when the family has no children.
RosterChildRef? activeRosterChild({IdentityRuntime? runtime}) {
  final roster = activeFamilyRosterChildren(runtime: runtime);
  if (roster.isEmpty) return null;
  final active = resolveActiveChildId(runtime: runtime);
  for (final c in roster) {
    if (c.id == active) return c;
  }
  return roster.first;
}

String _ordinalNameKey(int index) {
  return switch (index) {
    0 => 'one',
    1 => 'two',
    2 => 'three',
    3 => 'four',
    4 => 'five',
    _ => 'child${index + 1}',
  };
}
