import 'package:flutter/foundation.dart';

import 'role.dart';

/// Stage-1 mother authority levels (ADR-035 / SET-006).
///
/// ① [observer] — see / notify only; cannot approve unlocks.
/// ② [partner] — can approve child requests.
/// ③ [full] — can approve + edit rules (unlock approve same as partner).
enum MotherLevel { observer, partner, full }

/// Who decides a web unlock request (SET-006).
@immutable
final class WebUnlockActor {
  const WebUnlockActor.father()
      : role = AppRole.father,
        motherLevel = null;

  const WebUnlockActor.mother(this.motherLevel) : role = AppRole.mother;

  const WebUnlockActor.child()
      : role = AppRole.child,
        motherLevel = null;

  final AppRole role;
  final MotherLevel? motherLevel;

  /// Father always; mother partner/full; observer and child cannot.
  bool get canApproveUnlock {
    if (role == AppRole.father) return true;
    if (role == AppRole.mother) {
      return motherLevel == MotherLevel.partner ||
          motherLevel == MotherLevel.full;
    }
    return false;
  }

  String get auditLabel {
    if (role == AppRole.father) return 'father';
    if (role == AppRole.mother) {
      return 'mother:${motherLevel?.name ?? 'unknown'}';
    }
    return 'child';
  }
}
