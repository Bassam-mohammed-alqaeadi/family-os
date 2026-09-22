import 'package:flutter/foundation.dart';

/// Built-in smart mode identities + custom (Register §3 M-A).
enum BuiltInModeId { sleep, school, study, ramadan, exams, vacation, custom }

/// Fate of a manual grant when it intersects a scheduled mode (Ruling C).
///
/// UI dialog is out of scope for F2-POLICY; the domain requires an explicit
/// non-null choice before accepting an intersecting grant.
enum GrantOnModeStart {
  /// Grant runs to its end even after the mode starts.
  complete,

  /// Freeze grant when the mode starts; remainder returns after.
  freeze,
}

/// Error when an intersecting grant lacks [GrantOnModeStart] (Ruling C).
final class MissingGrantOnModeStartException implements Exception {
  const MissingGrantOnModeStartException();

  @override
  String toString() =>
      'GrantOnModeStart must be chosen before accepting a grant '
      'that intersects a scheduled mode (Ruling C).';
}

/// Domain gate for intersecting grants — no silent default (Ruling C).
abstract final class GrantConflictPolicy {
  /// Accepts an intersecting grant only when [onModeStart] is non-null.
  ///
  /// Throws [MissingGrantOnModeStartException] if the choice is missing.
  static GrantOnModeStart requireOnModeStart(GrantOnModeStart? onModeStart) {
    if (onModeStart == null) {
      throw const MissingGrantOnModeStartException();
    }
    return onModeStart;
  }
}

/// Intersect allowed-app sets — narrowest wins (M-B).
abstract final class ModeConflictResolver {
  /// Returns the intersection of [a] and [b] (stricter / narrowest).
  static Set<String> stricter(Set<String> a, Set<String> b) =>
      a.intersection(b);
}

/// Gentle-finish grace before mode activation (M-D).
@immutable
final class ModeGrace {
  /// Default grace: 2 minutes.
  static const int defaultMinutes = 2;

  /// Father-set floor.
  static const int minMinutes = 0;

  /// Father-set ceiling.
  static const int maxMinutes = 5;

  /// Standing owner directive: manual activation is always instant.
  static const bool manualActivationSkipsGrace = true;

  /// Clamps father-set grace into 0…5.
  static int clamp(int minutes) {
    if (minutes < minMinutes) {
      return minMinutes;
    }
    if (minutes > maxMinutes) {
      return maxMinutes;
    }
    return minutes;
  }

  /// Effective grace before activation.
  ///
  /// Manual activation skips grace when [manualActivationSkipsGrace] is true.
  static int effectiveMinutes({
    required int configured,
    required bool manualActivation,
  }) {
    if (manualActivation && manualActivationSkipsGrace) {
      return 0;
    }
    return clamp(configured);
  }
}
