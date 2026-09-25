import 'package:drift/drift.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart'
    show toEasternDigits;
import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/day_followup_bridge.dart';

/// WIR-03b — the father's day surfaces on the ADR-054 v6 rows:
/// SCR-FAT-010 (لوحة اليوم) · SCR-FAT-019 (مركز التنبيهات) · SCR-FAT-020
/// (تفصيل التنبيه).
///
/// Every value comes from a row the app already wrote: the roster from `child`
/// with `device` / `device_health`, the wallet line from the positive
/// `wallet_ledger` entries, the Quran line from `quran_memorization`, the
/// morning inbox from `task_submission` rows still waiting for review, the
/// alerts from `sos_alert` · `device_health` · `geofence_event`. What the
/// contract has no column for (an allowance countdown, a sync age, a category
/// phrase, a "primary action done" stamp on non-SOS alerts) stays empty and is
/// declared — never planted.
/// Below this the battery row is worth a look (the prototype's 🔋 tier).
const _lowBatteryPercent = 20;

abstract base class _DayBoardScope extends DayFollowupScope {
  _DayBoardScope({
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  /// The child's paired device, newest pairing first.
  Future<Device?> deviceOf(String childId) {
    return (db.select(db.devices)
          ..where((d) => d.childId.equals(childId))
          ..orderBy([(d) => OrderingTerm.desc(d.pairedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<DeviceHealth?> healthOf(String deviceId) {
    return (db.select(db.deviceHealths)
          ..where((h) => h.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  /// The geofence the child most recently entered — its own stored name.
  Future<GeofenceEvent?> lastEnterOf(String childId) {
    return (db.select(db.geofenceEvents)
          ..where(
            (e) =>
                e.childId.equals(childId) &
                e.kind.equalsValue(GeofenceEventKind.enter),
          )
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<String> fenceNameOf(String geofenceId) async {
    final fence =
        await (db.select(db.geofences)
              ..where((g) => g.id.equals(geofenceId))
              ..limit(1))
            .getSingleOrNull();
    return fence?.name.trim() ?? '';
  }

  ChildrenData? childOrNull(List<ChildrenData> children, String id) {
    for (final child in children) {
      if (child.id == id) return child;
    }
    return null;
  }

  int ordinalOfChild(List<ChildrenData> children, String id) {
    for (var i = 0; i < children.length; i++) {
      if (children[i].id == id) return i;
    }
    return 0;
  }

  /// The stored avatar token, mapped to the glyph the day screens show.
  String emojiFor(String avatar) => switch (avatar.trim()) {
    'lion' => '🦁',
    'cat' => '🐱',
    'panda' => '🐼',
    _ => '🙂',
  };

  DayChildSwatch swatchFor(int ordinal) =>
      DayChildSwatch.values[ordinal % DayChildSwatch.values.length];

  /// A row's own timestamp as a plain clock label — no invented copy.
  String clockLabel(DateTime at) {
    final hour = toEasternDigits(at.hour);
    final minute = toEasternDigits(at.minute);
    // rule12-allow — a zero glyph, numeral shaping only.
    return '$hour:${at.minute < 10 ? '٠' : ''}$minute';
  }

  /// A measured percent, shaped with Eastern digits (glyph, no words).
  String percentLabel(int percent) =>
      '${toEasternDigits(percent)}٪'; // rule12-allow

  FamilyDatabase get db;
}

/// SCR-FAT-010 — the morning board over the family's own rows.
final class DriftDayBoardProjectionRepository extends _DayBoardScope
    implements DayBoardProjectionRepository {
  DriftDayBoardProjectionRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  FamilyDatabase get db => _db;

  @override
  Future<DayBoardProjection> load() async {
    if (!await familyExists(_db)) return DayBoardProjection.empty;
    final children = await childrenInOrder(_db);
    final now = clock();
    final cards = <DayChildMock>[];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final device = await deviceOf(child.id);
      final health = device == null ? null : await healthOf(device.id);
      final enter = await lastEnterOf(child.id);
      final battery = health?.batteryLevel;
      final memorization =
          await (_db.select(_db.quranMemorizations)
                ..where((m) => m.childId.equals(child.id))
                ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)])
                ..limit(1))
              .getSingleOrNull();
      final earned =
          await (_db.select(_db.walletLedgerEntries)
                ..where(
                  (e) =>
                      e.childId.equals(child.id) &
                      e.deltaMinutes.isBiggerThanValue(0),
                ))
              .get();
      var earnedMinutes = 0;
      for (final entry in earned) {
        earnedMinutes += entry.deltaMinutes;
      }
      cards.add(
        DayChildMock(
          id: child.id,
          // The child's own stored name — the board is the parent's.
          displayName: child.displayName,
          emoji: emojiFor(child.avatar),
          // No avatar→colour column: the swatch cycles by roster order.
          swatch: swatchFor(i),
          // A missing birth year is unknown, never a guess.
          ageYears: child.birthYear == null ? 0 : now.year - child.birthYear!,
          locationLabel: enter == null
              ? ''
              : await fenceNameOf(enter.geofenceId),
          batteryLabel: battery == null ? '' : percentLabel(battery),
          // No allowance column in v6 — declared gap, never a countdown.
          timeLeftLabel: '',
          quranLabel: memorization == null
              ? ''
              : percentLabel(memorization.progress.clamp(0, 100)),
          walletLabel: toEasternDigits(earnedMinutes),
        ),
      );
    }
    return DayBoardProjection(
      children: cards,
      pendingRequests: await _pendingRequests(children),
      // No sync-metadata column in v6 — the board shows no sync age.
      offline: false,
    );
  }

  /// The morning inbox: the family's own submissions still waiting for review.
  Future<List<DayBoardPendingRequest>> _pendingRequests(
    List<ChildrenData> children,
  ) async {
    if (children.isEmpty) return const [];
    final ids = children.map((c) => c.id).toList(growable: false);
    final rows =
        await (_db.select(_db.taskSubmissions)
              ..where(
                (s) => s.childId.isIn(ids) & s.reviewedAt.isNull(),
              )
              ..orderBy([(s) => OrderingTerm.desc(s.submittedAt)]))
            .get();
    final out = <DayBoardPendingRequest>[];
    for (final row in rows) {
      final task =
          await (_db.select(_db.tasks)
                ..where((t) => t.id.equals(row.taskId))
                ..limit(1))
              .getSingleOrNull();
      out.add(
        DayBoardPendingRequest(
          id: row.id,
          // The wording is the screen's own copy (no column carries it here);
          // what the row proves is that a real submission is waiting.
          minutes: task?.rewardMinutes,
          inboxPath: '/scr-fat-033',
        ),
      );
    }
    return out;
  }
}

/// SCR-FAT-019 — the alerts hub over the rows the app already keeps.
///
/// Critical: still-active `sos_alert` rows (never muted — P-4). Attention: a
/// `device_health` battery at or under the low tier, and a fence `NO_SHOW`.
/// Reassurance: an `ENTER` at a named fence. Each row's text is the row's own
/// value (the child's stored name, the fence's stored name, a measured
/// percent/clock) because the contract keeps no category copy; the prototype's
/// per-alert phrases stay a declared gap instead of being planted here.
final class DriftAlertsHubRepository extends _DayBoardScope
    implements AlertsHubRepository {
  DriftAlertsHubRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  FamilyDatabase get db => _db;

  @override
  Future<AlertsHubSnapshot> load() async {
    if (!await familyExists(_db)) return const AlertsHubSnapshot();
    final children = await childrenInOrder(_db);
    final now = clock();
    final dayStart = DateTime(now.year, now.month, now.day);
    final critical = <HubAlert>[];
    final attention = <HubAlert>[];
    final reassurance = <HubAlert>[];

    final sos =
        await (_db.select(_db.sosAlerts)
              ..where(
                (a) =>
                    a.familyId.equals(familyId) &
                    a.status.equalsValue(SosStatus.active),
              )
              ..orderBy([(a) => OrderingTerm.desc(a.triggeredAt)]))
            .get();
    for (final alert in sos) {
      final child = childOrNull(children, alert.childId);
      final ordinal = ordinalOfChild(children, alert.childId);
      critical.add(
        HubAlert(
          id: 'sos_${alert.id}',
          urgency: AlertUrgency.critical,
          title: child?.displayName ?? '',
          subtitle: clockLabel(alert.triggeredAt),
          emoji: emojiFor(child?.avatar ?? ''),
          swatch: swatchFor(ordinal),
          // The SOS flow is its own screen: the row states the fact and the
          // hub's SOS CTA is the way in (the detail's four kinds have no SOS
          // variant, so this row never pretends to be one of them).
          target: HubAlertTarget.none,
        ),
      );
    }

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final device = await deviceOf(child.id);
      final health = device == null ? null : await healthOf(device.id);
      final battery = health?.batteryLevel;
      if (battery != null && battery <= _lowBatteryPercent) {
        attention.add(
          HubAlert(
            id: 'battery_${child.id}',
            urgency: AlertUrgency.attention,
            title: child.displayName,
            subtitle: percentLabel(battery),
            emoji: emojiFor(child.avatar),
            swatch: swatchFor(i),
            alertKind: 'battery',
          ),
        );
      }
      final events =
          await (_db.select(_db.geofenceEvents)
                ..where(
                  (e) =>
                      e.childId.equals(child.id) &
                      e.occurredAt.isBiggerOrEqualValue(dayStart),
                )
                ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)]))
              .get();
      for (final event in events) {
        final fence = await fenceNameOf(event.geofenceId);
        final id = event.id;
        if (event.kind == GeofenceEventKind.noShow) {
          attention.add(
            HubAlert(
              id: 'noshow_$id',
              urgency: AlertUrgency.attention,
              title: fence,
              subtitle: child.displayName,
              emoji: emojiFor(child.avatar),
              swatch: swatchFor(i),
              alertKind: 'arrive',
            ),
          );
        } else if (event.kind == GeofenceEventKind.enter) {
          reassurance.add(
            HubAlert(
              id: 'geo_$id',
              urgency: AlertUrgency.reassurance,
              title: fence,
              subtitle: child.displayName,
              emoji: emojiFor(child.avatar),
              swatch: swatchFor(i),
              alertKind: 'arrive',
            ),
          );
        }
      }
    }
    return AlertsHubSnapshot(
      critical: critical,
      attention: attention,
      reassurance: reassurance,
    );
  }
}

/// SCR-FAT-020 — one alert's detail, resolved from the same rows the hub read.
///
/// The lookup is by the hub row's own id (`battery_<child>` · `geo_<event>` ·
/// `noshow_<event>`), else by the wire kind. `stranger` and `games` have no v6
/// row, so they resolve to nothing (declared gap) instead of a planted alert.
/// The primary action has no stamp column on a battery or fence alert, so it
/// writes nothing and returns the row's own state — declared, never faked.
final class DriftAlertDetailRepository extends _DayBoardScope
    implements AlertDetailRepository {
  DriftAlertDetailRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  @override
  FamilyDatabase get db => _db;

  @override
  Future<AlertDetail?> load({String? alertId, String? alertKind}) async {
    if (!await familyExists(_db)) return null;
    final children = await childrenInOrder(_db);
    final raw = alertId?.trim() ?? '';
    if (raw.isNotEmpty) {
      if (raw.startsWith(_batteryPrefix)) {
        return _batteryDetail(raw.substring(_batteryPrefix.length), children);
      }
      if (raw.startsWith(_noShowPrefix)) {
        return _fenceDetail(
          _eventId(raw, _noShowPrefix),
          children,
          AlertUrgency.attention,
        );
      }
      if (raw.startsWith(_enterPrefix)) {
        return _fenceDetail(
          _eventId(raw, _enterPrefix),
          children,
          AlertUrgency.reassurance,
        );
      }
      // A bare id is not one of the projected rows: no row backs it.
      return null;
    }
    switch (AlertDetailKind.tryParse(alertKind)) {
      case AlertDetailKind.battery:
        for (final child in children) {
          final detail = await _batteryDetail(child.id, children);
          if (detail != null) return detail;
        }
        return null;
      case AlertDetailKind.arrive:
        for (final child in children) {
          final event = await lastEnterOf(child.id);
          if (event == null) continue;
          final detail = await _fenceDetail(
            event.id,
            children,
            AlertUrgency.reassurance,
          );
          if (detail != null) return detail;
        }
        return null;
      case AlertDetailKind.stranger:
      case AlertDetailKind.games:
      case null:
        // No v6 row carries these categories — declared gap.
        return null;
    }
  }

  @override
  Future<AlertDetail> markPrimaryDone(String alertId) async {
    final detail = await load(alertId: alertId);
    if (detail == null) {
      throw StateError('alert not found: $alertId');
    }
    // A battery or fence alert has no "done" column in v6: the row's own state
    // is returned unchanged and nothing is written (declared gap).
    return detail;
  }

  Future<AlertDetail?> _batteryDetail(
    String childId,
    List<ChildrenData> children,
  ) async {
    final child = childOrNull(children, childId);
    if (child == null) return null;
    final device = await deviceOf(child.id);
    final health = device == null ? null : await healthOf(device.id);
    final battery = health?.batteryLevel;
    if (battery == null) return null;
    return AlertDetail(
      id: '$_batteryPrefix${child.id}',
      kind: AlertDetailKind.battery,
      childId: child.id,
      urgency: battery <= _lowBatteryPercent
          ? AlertUrgency.attention
          : AlertUrgency.reassurance,
      // The child's own stored name is the alert's subject.
      title: child.displayName,
      body: percentLabel(battery),
      // No advice / reply / done columns on a device row — declared gaps.
    );
  }

  Future<AlertDetail?> _fenceDetail(
    int eventId,
    List<ChildrenData> children,
    AlertUrgency urgency,
  ) async {
    final event =
        await (_db.select(_db.geofenceEvents)
              ..where((e) => e.id.equals(eventId))
              ..limit(1))
            .getSingleOrNull();
    if (event == null) return null;
    final child = childOrNull(children, event.childId);
    if (child == null) return null;
    final fence = await fenceNameOf(event.geofenceId);
    final prefix = event.kind == GeofenceEventKind.noShow
        ? _noShowPrefix
        : _enterPrefix;
    return AlertDetail(
      id: '$prefix${event.id}',
      kind: AlertDetailKind.arrive,
      childId: child.id,
      urgency: urgency,
      title: fence,
      body: '${child.displayName} · ${clockLabel(event.occurredAt)}',
    );
  }

  static const _batteryPrefix = 'battery_';
  static const _enterPrefix = 'geo_';
  static const _noShowPrefix = 'noshow_';

  static int _eventId(String raw, String prefix) =>
      int.tryParse(raw.substring(prefix.length)) ?? -1;
}
