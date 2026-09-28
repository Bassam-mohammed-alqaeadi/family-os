import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/identity/active_child_resolver.dart';
import 'package:family_os/features/n03_screen_time/stage1_child_scope.dart';

/// Per-child routes (VX-B2 · FVX-G-04): `?childId=` from the profile wins,
/// else the family context's selected child. Never a literal demo id.
ChildId routeChildId(BuildContext context, GoRouterState state) {
  return resolveActiveChildIdOf(
    context,
    explicit: childIdFromParam(state.uri.queryParameters['childId']),
  );
}

/// Same child in the family-scoped key the Screen Time domain stores under
/// (`family::child`, see [familyScopedChildId]).
ChildId routeScopedChildId(BuildContext context, GoRouterState state) {
  final raw = state.uri.queryParameters['childId']?.trim() ?? '';
  if (raw.contains('::')) return ChildId(raw);
  return familyScopedChildId(
    familyId: resolveActiveFamilyIdOf(context),
    childId: routeChildId(context, state),
  );
}
