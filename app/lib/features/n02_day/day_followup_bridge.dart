import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart'
    show toEasternDigits;
import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_board_bridge.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// DEV-9 — the day domain's father-facing roster on the ADR-054 v6 rows:
/// `child` (the roster itself) · `device` + `device_health` (link health,
/// battery, last heartbeat) · `geofence` + `geofence_event` (where the child
/// is). Every value comes from a row; anything the contract has no column for
/// stays empty and is declared, never planted (Rule 23).
abstract base class DayFollowupScope {
  DayFollowupScope({
    String? familyId,
    String? childId,
    String? accountId,
    DateTime Function()? clock,
  }) : _familyIdArg = familyId?.trim(),
       _childIdArg = childId?.trim(),
       _accountIdArg = accountId?.trim(),
       clock = clock ?? DateTime.now;

  final String? _familyIdArg;
  final String? _childIdArg;
  final String? _accountIdArg;
  final DateTime Function() clock;

  /// The family scope: the explicit argument first, else the identity runtime.
  String get familyId =>
      (_familyIdArg ?? stage1IdentityRuntime.activeFamilyId.value).trim();

  String get childId =>
      (_childIdArg ?? stage1IdentityRuntime.activeChildId.value).trim();

  String get accountId {
    final arg = _accountIdArg;
    if (arg != null && arg.isNotEmpty) return arg;
    final live = stage1IdentityRuntime.account.id.value.trim();
    return live.isEmpty ? Stage1RowVocabulary.unattributedAccount : live;
  }

  /// The `family` row that gates every day surface; an empty or unowned scope
  /// owns no family and reads (and writes) nothing.
  Future<bool> familyExists(FamilyDatabase db) async {
    if (familyId.isEmpty) return false;
    final row =
        await (db.select(db.families)
              ..where((f) => f.id.equals(familyId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// The family's children, oldest first (Rule 23 — labelled by order).
  Future<List<ChildrenData>> childrenInOrder(FamilyDatabase db) {
    if (familyId.isEmpty) return Future.value(const []);
    return (db.select(db.children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  /// The acting child's index in the roster, else 0 (the roster's first).
  Future<int> ordinalOf(FamilyDatabase db, String childId) async {
    final children = await childrenInOrder(db);
    for (var i = 0; i < children.length; i++) {
      if (children[i].id == childId) return i;
    }
    return 0;
  }
}

/// Stage-2 composition root for the day domain's father surfaces (ADR-054 §3 ·
/// §11.2). Repos resolve the family at call time, so a screen binds one line.
final class Stage1DayRuntime {
  Stage1DayRuntime._();

  static FamilyDatabase? _db;

  /// Opens once, synchronously — the getters below are screen defaults and
  /// cannot await. Pass [override] to inject a database (tests own it).
  static FamilyDatabase ensureOpenSync({FamilyDatabase? override}) {
    final existing = _db;
    if (override != null) {
      _db = override;
      return override;
    }
    if (existing != null) return existing;
    final opened = FamilyDatabase(NativeDatabase.memory());
    _db = opened;
    return opened;
  }

  /// SCR-FAT-012 — the father's roster over `child` + `device_health`.
  static ChildrenListRepository get childrenList =>
      DriftChildrenListRepository(ensureOpenSync());

  /// WIR-03b — SCR-FAT-010: the morning board over the family's own rows.
  static DayBoardProjectionRepository get dayBoard =>
      DriftDayBoardProjectionRepository(ensureOpenSync());

  /// WIR-03b — SCR-FAT-019: the alerts hub over `sos_alert` · `device_health`
  /// · `geofence_event`.
  static AlertsHubRepository get alertsHub =>
      DriftAlertsHubRepository(ensureOpenSync());

  /// WIR-03b — SCR-FAT-020: one alert's detail from those same rows.
  static AlertDetailRepository get alertDetail =>
      DriftAlertDetailRepository(ensureOpenSync());

  /// Clears this runtime only. An injected database is closed by its owner.
  static void resetForTest() => _db = null;
}

/// SCR-FAT-012 — قائمة الأبناء over the family's own `child` rows.
///
/// Each row is one real child: the name is the child's stored `display_name`,
/// the age is the stored `birth_year`, and the health/battery/last-seen trio
/// comes from that child's paired `device` and its `device_health` heartbeat,
/// while the place line is the last `geofence_event` enter for that child and
/// the geofence's own stored name. The shared-policies sheet has no row in the
/// contract, so its load returns an honest empty policy and its save is a
/// declared gap (nothing is written where nothing exists).
final class DriftChildrenListRepository extends DayFollowupScope
    implements ChildrenListRepository {
  DriftChildrenListRepository(
    this._db, {
    super.familyId,
    super.childId,
    super.accountId,
    super.clock,
  });

  final FamilyDatabase _db;

  /// A heartbeat older than this is a link at risk, not a live one.
  static const Duration _staleAfter = Duration(hours: 24);

  @override
  Future<List<ChildrenListEntry>> listChildren({FamilyId? familyId}) async {
    final scope = (familyId?.value ?? this.familyId).trim();
    if (scope.isEmpty) return const [];
    final children =
        await (_db.select(_db.children)
              ..where((c) => c.familyId.equals(scope))
              ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
            .get();
    final rows = <ChildrenListEntry>[];
    for (var ordinal = 0; ordinal < children.length; ordinal++) {
      final child = children[ordinal];
      final device = await _deviceOf(child.id);
      final health = device == null ? null : await _healthOf(device.id);
      final heartbeat = health?.lastHeartbeat;
      final now = clock();
      final stale =
          heartbeat == null ||
          now.difference(heartbeat) > _staleAfter ||
          (health?.score ?? kHealthOffline) != kHealthGood;
      final battery = health?.batteryLevel;
      rows.add(
        ChildrenListEntry(
          id: child.id,
          // The child's own stored name — the roster is the parent's.
          displayName: child.displayName,
          emoji: _emojiFor(child.avatar),
          // No avatar→colour column: the swatch cycles by roster order.
          swatch: _swatchFor(ordinal),
          // A missing birth year is unknown, never a guess.
          ageYears: child.birthYear == null ? 0 : now.year - child.birthYear!,
          locationLabel: await _placeOf(child.id),
          lastSeenLabel: heartbeat == null
              ? ''
              : Stage1RowVocabulary.timeKeyFor(heartbeat, now),
          batteryLabel: battery == null
              ? ''
              : '${toEasternDigits(battery)}٪', // rule12-allow
          // No allowance column in v6 — the screen shows its own label only.
          timeLeftLabel: '',
          health: stale ? ChildListHealth.atRisk : ChildListHealth.excellent,
          warnRing: stale,
        ),
      );
    }
    return rows;
  }

  /// The contract keeps no shared-children-policy row: an honest empty policy.
  @override
  Future<SharedChildrenPolicies> loadSharedPolicies() async =>
      const SharedChildrenPolicies(bedtimeLabel: '');

  /// Declared gap (no row to write): the sheet's values are not persisted yet,
  /// and this seam never pretends they are.
  @override
  Future<void> saveSharedPolicies(SharedChildrenPolicies policies) async {}

  Future<Device?> _deviceOf(String childId) {
    return (_db.select(_db.devices)
          ..where((d) => d.childId.equals(childId))
          ..orderBy([(d) => OrderingTerm.desc(d.pairedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<DeviceHealth?> _healthOf(String deviceId) {
    return (_db.select(_db.deviceHealths)
          ..where((h) => h.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  /// The geofence the child most recently entered — its own stored name.
  Future<String> _placeOf(String childId) async {
    final event =
        await (_db.select(_db.geofenceEvents)
              ..where(
                (e) =>
                    e.childId.equals(childId) &
                    e.kind.equalsValue(GeofenceEventKind.enter),
              )
              ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)])
              ..limit(1))
            .getSingleOrNull();
    if (event == null) return '';
    final fence =
        await (_db.select(_db.geofences)
              ..where((g) => g.id.equals(event.geofenceId)))
            .getSingleOrNull();
    return fence?.name.trim() ?? '';
  }

  /// The stored avatar token, mapped to the glyph the roster shows.
  static String _emojiFor(String avatar) => switch (avatar.trim()) {
    'lion' => '🦁',
    'cat' => '🐱',
    'panda' => '🐼',
    _ => '🙂',
  };

  static DayChildSwatch _swatchFor(int ordinal) =>
      DayChildSwatch.values[ordinal % DayChildSwatch.values.length];
}
