/// SOS role capability matrix (OD-03 / Mother levels) — UI + policy seam.
///
/// Authorization is checked here; widgets must not invent permissions from
/// visibility alone (SOS screen-engineering contract).
library;

import 'package:flutter/foundation.dart';

import '../domain/mother_level.dart';
import '../domain/role.dart';

/// Actor context for SOS actions (father = Primary; mother uses [motherLevel]).
@immutable
final class SosActor {
  const SosActor({
    required this.role,
    this.motherLevel,
  });

  final AppRole role;
  final MotherLevel? motherLevel;

  /// Primary parent (father) or mother Full / Partner / Observer.
  factory SosActor.primary() =>
      const SosActor(role: AppRole.father);

  factory SosActor.mother(MotherLevel level) =>
      SosActor(role: AppRole.mother, motherLevel: level);

  factory SosActor.child() => const SosActor(role: AppRole.child);
}

/// Pure capability checks — no UI.
abstract final class SosRoleActions {
  /// Acknowledge — Primary + Partner + Full. Observer denied (sos_final §06).
  static bool canAcknowledge(SosActor actor) {
    if (actor.role == AppRole.father) return true;
    if (actor.role == AppRole.mother) {
      final m = actor.motherLevel;
      return m == MotherLevel.full || m == MotherLevel.partner;
    }
    return false;
  }

  /// Resolve / close incident — Primary + Partner + Full. Observer denied.
  static bool canResolve(SosActor actor) {
    if (actor.role == AppRole.father) return true;
    if (actor.role == AppRole.mother) {
      final m = actor.motherLevel;
      return m == MotherLevel.full || m == MotherLevel.partner;
    }
    return false;
  }

  /// Escalate ladder — Primary + Partner + Full. Observer denied.
  static bool canEscalate(SosActor actor) {
    return canResolve(actor);
  }

  /// SET-020 / FAT-028 configuration — Primary + Mother Full only.
  static bool canConfigure(SosActor actor) {
    if (actor.role == AppRole.father) return true;
    if (actor.role == AppRole.mother) {
      return actor.motherLevel == MotherLevel.full;
    }
    return false;
  }

  /// Break-glass RBAC — Primary + Mother Full only (OD-08).
  static bool canBreakGlass(SosActor actor) => canConfigure(actor);

  /// Child may cancel own open SOS (false-alarm path).
  static bool canCancelOwnSos(SosActor actor) => actor.role == AppRole.child;
}
