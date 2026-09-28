/// Shared alert-kind catalog for Notifications (SCR-FAT-019/020/058).
///
/// Core now: kinds that local producers already emit.
/// Wire later: kinds filled when owning systems finish (SOS polish, location,
/// AI, road, cloud push). Other campaigns **register into this list** — they
/// do not invent a second inbox.
library;

import 'package:flutter/foundation.dart';

/// Urgency lane matching prototype سلّم الأهمية / S-ADM-028.
enum FamilyAlertLane { critical, important, reassurance }

/// Stable kind ids passed as `alertKind` / projection keys.
abstract final class FamilyAlertKinds {
  // —— Core / already local ——
  static const sos = 'sos';
  static const tamper = 'tamper';
  static const timeRequest = 'timeRequest';
  static const appApproval = 'appApproval';
  static const friendRequest = 'friendRequest';

  // —— Wire when Location pack ships ——
  static const arriveSafe = 'arrive';
  static const leaveZone = 'leaveZone';
  static const batteryLow = 'battery';

  // —— Wire when Screen-time pack deepens ——
  static const gamesOverLimit = 'games';

  // —— Wire when AI pack ships ——
  static const strangerContact = 'stranger';
  static const smartSafety = 'smartSafety';

  // —— Wire when Tasks / moments deepen ——
  static const tasksDone = 'tasksDone';
}

/// One catalog row — documentation + future registry for producers.
@immutable
final class FamilyAlertKindSpec {
  const FamilyAlertKindSpec({
    required this.kind,
    required this.lane,
    required this.ownerSystem,
    required this.status,
  });

  final String kind;
  final FamilyAlertLane lane;

  /// Owning campaign that must wire this kind (e.g. `sos`, `location`, `ai`).
  final String ownerSystem;

  /// `live` = projected today · `hook` = reserved for later campaign.
  final String status;
}

/// Platform mailbox map — keep in sync when wiring new producers.
const List<FamilyAlertKindSpec> kFamilyAlertCatalog = [
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.sos,
    lane: FamilyAlertLane.critical,
    ownerSystem: 'sos',
    status: 'live',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.tamper,
    lane: FamilyAlertLane.critical,
    ownerSystem: 'lock_bypass',
    status: 'live',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.timeRequest,
    lane: FamilyAlertLane.important,
    ownerSystem: 'screen_time',
    status: 'live',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.appApproval,
    lane: FamilyAlertLane.important,
    ownerSystem: 'apps',
    status: 'live',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.friendRequest,
    lane: FamilyAlertLane.important,
    ownerSystem: 'circle',
    status: 'live',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.arriveSafe,
    lane: FamilyAlertLane.reassurance,
    ownerSystem: 'location',
    status: 'live',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.leaveZone,
    lane: FamilyAlertLane.critical,
    ownerSystem: 'location',
    status: 'live',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.batteryLow,
    lane: FamilyAlertLane.important,
    ownerSystem: 'devices',
    status: 'hook',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.gamesOverLimit,
    lane: FamilyAlertLane.important,
    ownerSystem: 'screen_time',
    status: 'hook',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.strangerContact,
    lane: FamilyAlertLane.critical,
    ownerSystem: 'ai',
    status: 'hook',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.smartSafety,
    lane: FamilyAlertLane.important,
    ownerSystem: 'ai',
    status: 'hook',
  ),
  FamilyAlertKindSpec(
    kind: FamilyAlertKinds.tasksDone,
    lane: FamilyAlertLane.reassurance,
    ownerSystem: 'tasks',
    status: 'hook',
  ),
];
