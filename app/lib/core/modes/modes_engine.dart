import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/location/modes_location_fact_feed.dart';

import 'mode_activation.dart';
import 'mode_definition.dart';
import 'mode_exception.dart';
import 'mode_overlay.dart';

/// Result of evaluating Modes for one child at one instant.
@immutable
final class ModesEvaluation {
  const ModesEvaluation({
    required this.applicableModeIds,
    required this.effectiveOverlay,
    required this.channelsByModeId,
    required this.sosReachable,
    required this.requiredChatReachable,
    required this.quranReachable,
    required this.activeExceptionIds,
  });

  final Set<String> applicableModeIds;
  final ModeOverlay effectiveOverlay;
  final Map<String, ModeActivationChannel> channelsByModeId;
  final bool sosReachable;
  final bool requiredChatReachable;
  final bool quranReachable;
  final Set<String> activeExceptionIds;

  bool get hasActiveModes => applicableModeIds.isNotEmpty;
}

/// Canonical lifestyle schedule / Mode activation evaluator (MODE-OD-08).
///
/// Sole Mode `modeActive` path — ScheduleWindow is not a second Mode authority.
abstract final class ModesEngine {
  /// Minutes from midnight in local wall clock of [at].
  static int minutesOfDay(DateTime at) => at.hour * 60 + at.minute;

  /// Whether [mode] applies to [childId] given time, location facts, manuals.
  static bool isApplicable({
    required ModeDefinition mode,
    required ChildId childId,
    required DateTime at,
    required List<ModeActivation> manualActivations,
    required List<LocationModeFact> locationFacts,
  }) {
    if (!mode.enabled) return false;
    if (!mode.targetsChild(childId)) return false;

    final manualOn = manualActivations.any(
      (a) =>
          a.active &&
          a.modeId == mode.id &&
          a.childId == childId &&
          a.channel == ModeActivationChannel.manual &&
          (a.endsAt == null || at.toUtc().isBefore(a.endsAt!.toUtc())),
    );
    if (manualOn) return true;

    if (mode.clockWindow != null &&
        mode.clockWindow!.containsMinutes(minutesOfDay(at))) {
      return true;
    }

    if (mode.season != null && mode.season!.contains(at)) {
      return true;
    }

    final zoneId = mode.locationZoneId;
    if (zoneId != null && zoneId.isNotEmpty) {
      LocationModeFact? latest;
      for (final f in locationFacts) {
        if (f.zoneId != zoneId) continue;
        if (latest == null || f.occurredAt.isAfter(latest.occurredAt)) {
          latest = f;
        }
      }
      if (latest != null) {
        if (latest.kind == LocationModeFactKind.zoneEnter) return true;
        if (latest.kind == LocationModeFactKind.presence &&
            latest.inside == true) {
          return true;
        }
      }
    }

    return false;
  }

  static ModeActivationChannel? resolveChannel({
    required ModeDefinition mode,
    required ChildId childId,
    required DateTime at,
    required List<ModeActivation> manualActivations,
    required List<LocationModeFact> locationFacts,
  }) {
    if (!isApplicable(
      mode: mode,
      childId: childId,
      at: at,
      manualActivations: manualActivations,
      locationFacts: locationFacts,
    )) {
      return null;
    }
    final manualOn = manualActivations.any(
      (a) =>
          a.active &&
          a.modeId == mode.id &&
          a.childId == childId &&
          a.channel == ModeActivationChannel.manual,
    );
    if (manualOn) return ModeActivationChannel.manual;
    if (mode.clockWindow != null &&
        mode.clockWindow!.containsMinutes(minutesOfDay(at))) {
      return ModeActivationChannel.clock;
    }
    if (mode.season != null && mode.season!.contains(at)) {
      return ModeActivationChannel.seasonal;
    }
    if (mode.locationZoneId != null) return ModeActivationChannel.location;
    return ModeActivationChannel.manual;
  }

  /// Multi-mode stack: stricter intersection of overlays (MODE-OD-05/07).
  static ModesEvaluation evaluate({
    required List<ModeDefinition> modes,
    required ChildId childId,
    required DateTime at,
    List<ModeActivation> manualActivations = const [],
    List<LocationModeFact> locationFacts = const [],
    List<ModeException> exceptions = const [],
  }) {
    final applicable = <String>{};
    final channels = <String, ModeActivationChannel>{};
    var overlay = const ModeOverlay();

    for (final mode in modes) {
      if (!isApplicable(
        mode: mode,
        childId: childId,
        at: at,
        manualActivations: manualActivations,
        locationFacts: locationFacts,
      )) {
        continue;
      }
      applicable.add(mode.id);
      final ch = resolveChannel(
        mode: mode,
        childId: childId,
        at: at,
        manualActivations: manualActivations,
        locationFacts: locationFacts,
      );
      if (ch != null) channels[mode.id] = ch;
      overlay = ModeOverlay.intersect(overlay, mode.overlay.asTightenOnly());
    }

    final activeEx = <String>{
      for (final e in exceptions)
        if (e.childId == childId && e.isActiveAt(at)) e.id,
    };

    return ModesEvaluation(
      applicableModeIds: Set<String>.unmodifiable(applicable),
      effectiveOverlay: overlay,
      channelsByModeId: Map<String, ModeActivationChannel>.unmodifiable(
        channels,
      ),
      sosReachable: ModeProtectedReachability.sosReachable,
      requiredChatReachable:
          ModeProtectedReachability.requiredFamilyChatReachable,
      quranReachable: ModeProtectedReachability.quranReachable,
      activeExceptionIds: Set<String>.unmodifiable(activeEx),
    );
  }

  static int effectiveGraceMinutes({
    required int configured,
    required bool manualActivation,
  }) {
    if (manualActivation) return 0;
    return ModeOverlay.clampGrace(configured);
  }

  static void assertNoWiden(ModeOverlay overlay) {
    if (overlay.widenAllowedPackages) {
      throw StateError('Modes are tighten-only — Vacation widen rejected');
    }
  }
}
