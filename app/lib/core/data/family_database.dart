import 'package:drift/drift.dart';

part 'family_database.g.dart';

/// Rule 25 — the local relational store, shaped after
/// `family-os/_CONTRACTS/schema.sql` (the Postgres contract, 20 tables).
///
/// Offline-first: the app owns these rows on the device, and the backend
/// phase swaps in a sync layer over the same contract. Table names here map
/// 1:1 to the contract's names so a later migration is mechanical.
///
/// PERS-2a covers the identity core (account · family · member · child).
/// Devices/permissions, location/emergency, communication and AI/audit land
/// in PERS-2b…2d.
enum MemberRole { owner, parent, guardian }

enum PermLevel { observer, partner, full }

/// Stores the contract's uppercase enum labels (`'OWNER'`), not Dart names.
class MemberRoleConverter extends TypeConverter<MemberRole, String> {
  const MemberRoleConverter();

  static const Map<MemberRole, String> _toDb = {
    MemberRole.owner: 'OWNER',
    MemberRole.parent: 'PARENT',
    MemberRole.guardian: 'GUARDIAN',
  };

  @override
  MemberRole fromSql(String fromDb) => _toDb.entries
      .firstWhere(
        (e) => e.value == fromDb,
        orElse: () => const MapEntry(MemberRole.parent, 'PARENT'),
      )
      .key;

  @override
  String toSql(MemberRole value) => _toDb[value]!;
}

class PermLevelConverter extends TypeConverter<PermLevel, String> {
  const PermLevelConverter();

  static const Map<PermLevel, String> _toDb = {
    PermLevel.observer: 'OBSERVER',
    PermLevel.partner: 'PARTNER',
    PermLevel.full: 'FULL',
  };

  @override
  PermLevel fromSql(String fromDb) => _toDb.entries
      .firstWhere(
        (e) => e.value == fromDb,
        orElse: () => const MapEntry(PermLevel.partner, 'PARTNER'),
      )
      .key;

  @override
  String toSql(PermLevel value) => _toDb[value]!;
}

/// Contract `device_mode` — decides who owns the device row. The contract's
/// `mode_owner_xor` CHECK (PARENT ⇒ account only · CHILD_LOCKED ⇒ child only ·
/// CHILD_PREVIEW ⇒ account present) is enforced in `DriftDeviceRepository`.
enum DeviceMode { parent, childLocked, childPreview }

class DeviceModeConverter extends TypeConverter<DeviceMode, String> {
  const DeviceModeConverter();

  static const Map<DeviceMode, String> _toDb = {
    DeviceMode.parent: 'PARENT',
    DeviceMode.childLocked: 'CHILD_LOCKED',
    DeviceMode.childPreview: 'CHILD_PREVIEW',
  };

  @override
  DeviceMode fromSql(String fromDb) => _toDb.entries
      .firstWhere(
        (e) => e.value == fromDb,
        orElse: () => const MapEntry(DeviceMode.parent, 'PARENT'),
      )
      .key;

  @override
  String toSql(DeviceMode value) => _toDb[value]!;
}

/// Contract `perm_key` — the eight permission keys the app tracks.
enum PermKey {
  locationFg,
  locationBg,
  accessibility,
  batteryUnrestricted,
  autostart,
  notifications,
  usageStats,
  screenTimeIos,
}

class PermKeyConverter extends TypeConverter<PermKey, String> {
  const PermKeyConverter();

  static const Map<PermKey, String> _toDb = {
    PermKey.locationFg: 'LOCATION_FG',
    PermKey.locationBg: 'LOCATION_BG',
    PermKey.accessibility: 'ACCESSIBILITY',
    PermKey.batteryUnrestricted: 'BATTERY_UNRESTRICTED',
    PermKey.autostart: 'AUTOSTART',
    PermKey.notifications: 'NOTIFICATIONS',
    PermKey.usageStats: 'USAGE_STATS',
    PermKey.screenTimeIos: 'SCREEN_TIME_IOS',
  };

  @override
  PermKey fromSql(String fromDb) => _toDb.entries
      .firstWhere(
        (e) => e.value == fromDb,
        orElse: () => const MapEntry(PermKey.usageStats, 'USAGE_STATS'),
      )
      .key;

  @override
  String toSql(PermKey value) => _toDb[value]!;
}

/// Contract `perm_status` — extended to six states by ADR-050.
///
/// The two denials are distinct *because the behaviour differs*: only
/// [deniedSoft] may be re-asked, and only once, on a user-initiated action.
/// [restrictedByOs] is an OS-imposed block (Android 17 Advanced Protection
/// Mode) — read as a signal, never inferred from a failed check.
enum PermStatus {
  notAsked,
  granted,
  deniedSoft,
  deniedPermanent,
  restrictedByOs,
  notApplicable,
}

class PermStatusConverter extends TypeConverter<PermStatus, String> {
  const PermStatusConverter();

  static const Map<PermStatus, String> _toDb = {
    PermStatus.notAsked: 'NOT_ASKED',
    PermStatus.granted: 'GRANTED',
    PermStatus.deniedSoft: 'DENIED_SOFT',
    PermStatus.deniedPermanent: 'DENIED_PERMANENT',
    PermStatus.restrictedByOs: 'RESTRICTED_BY_OS',
    PermStatus.notApplicable: 'NOT_APPLICABLE',
  };

  @override
  PermStatus fromSql(String fromDb) => _toDb.entries
      .firstWhere(
        (e) => e.value == fromDb,
        orElse: () => const MapEntry(PermStatus.notAsked, 'NOT_ASKED'),
      )
      .key;

  @override
  String toSql(PermStatus value) => _toDb[value]!;
}

/// Contract `sos_status`. ACKNOWLEDGED and RESOLVED are different facts —
/// "I saw it" and "it is over" — and only the second closes an alarm.
enum SosStatus { active, acknowledged, resolved }

class SosStatusConverter extends TypeConverter<SosStatus, String> {
  const SosStatusConverter();

  static const Map<SosStatus, String> _toDb = {
    SosStatus.active: 'ACTIVE',
    SosStatus.acknowledged: 'ACKNOWLEDGED',
    SosStatus.resolved: 'RESOLVED',
  };

  @override
  SosStatus fromSql(String fromDb) => _toDb.entries
      .firstWhere(
        (e) => e.value == fromDb,
        orElse: () => const MapEntry(SosStatus.active, 'ACTIVE'),
      )
      .key;

  @override
  String toSql(SosStatus value) => _toDb[value]!;
}

/// Contract `geofence_shape` — ADR-051. The OS only accepts a circle, so the
/// circle case is the one it can register; the polygon is ours to evaluate.
enum GeofenceShape { circle, polygon }

class GeofenceShapeConverter extends TypeConverter<GeofenceShape, String> {
  const GeofenceShapeConverter();

  static const Map<GeofenceShape, String> _toDb = {
    GeofenceShape.circle: 'CIRCLE',
    GeofenceShape.polygon: 'POLYGON',
  };

  @override
  GeofenceShape fromSql(String fromDb) => _toDb.entries
      .firstWhere(
        (e) => e.value == fromDb,
        orElse: () => const MapEntry(GeofenceShape.circle, 'CIRCLE'),
      )
      .key;

  @override
  String toSql(GeofenceShape value) => _toDb[value]!;
}

/// Contract `geofence_event.kind` — `text` with a CHECK, not a `CREATE TYPE`,
/// so the value set lives here and is enforced by `DriftLocationRepository`.
enum GeofenceEventKind { enter, exit, noShow }

class GeofenceEventKindConverter
    extends TypeConverter<GeofenceEventKind, String> {
  const GeofenceEventKindConverter();

  static const Map<GeofenceEventKind, String> _toDb = {
    GeofenceEventKind.enter: 'ENTER',
    GeofenceEventKind.exit: 'EXIT',
    GeofenceEventKind.noShow: 'NO_SHOW',
  };

  @override
  GeofenceEventKind fromSql(String fromDb) => _toDb.entries
      .firstWhere(
        (e) => e.value == fromDb,
        orElse: () => const MapEntry(GeofenceEventKind.enter, 'ENTER'),
      )
      .key;

  @override
  String toSql(GeofenceEventKind value) => _toDb[value]!;
}

/// `prune_locations()` — "تُقلَّم تلقائيًا بعد ٩٠ يومًا".
const int kLocationRetentionDays = 90;

/// `device_health.score` — the contract keeps these as `text` with a documented
/// value set (they are not `CREATE TYPE`s, so they are not typed here either).
const String kHealthGood = 'GOOD';
const String kHealthAtRisk = 'AT_RISK';
const String kHealthOffline = 'OFFLINE';
const Set<String> kHealthScores = {kHealthGood, kHealthAtRisk, kHealthOffline};

/// `device_health.reason`
const String kReasonBatteryOptimizer = 'BATTERY_OPTIMIZER';
const String kReasonNoNetwork = 'NO_NETWORK';
const String kReasonUninstalled = 'UNINSTALLED';
const Set<String> kHealthReasons = {
  kReasonBatteryOptimizer,
  kReasonNoNetwork,
  kReasonUninstalled,
};

/// Contract `account` — email + password only (ADR-003: no phone, no OTP).
/// Email is stored lower-cased here; the contract's `citext` does the same.
class Accounts extends Table {
  @override
  String get tableName => 'account';

  TextColumn get id => text()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get displayName => text()();
  TextColumn get locale => text().withDefault(const Constant('ar'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contract `family`.
class Families extends Table {
  @override
  String get tableName => 'family';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerAccountId => text()();
  TextColumn get plan => text().withDefault(const Constant('TRIAL'))();
  DateTimeColumn get trialEndsAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contract `member` — owner is always FULL, guardian is pinned OBSERVER
/// (20_MOTHER_PERMISSIONS). Enforced in [FamilyDatabase] at write time.
class Members extends Table {
  @override
  String get tableName => 'member';

  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get accountId => text()();
  TextColumn get role => text().map(const MemberRoleConverter())();
  TextColumn get permissionLevel => text().map(const PermLevelConverter())();
  TextColumn get invitedBy => text().nullable()();
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contract `child` — `displayName` never leaves the family; analytics and
/// the AI layer use `alias` exclusively (Rule 13/23, G8 parametric ChildId).
class Children extends Table {
  @override
  String get tableName => 'child';

  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get displayName => text()();
  TextColumn get alias => text().unique()();
  IntColumn get birthYear => integer().nullable()();
  TextColumn get avatar => text().withDefault(const Constant('lion'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contract `device` — one row per paired device.
/// ⛔ No IMEI · no MAC · no SSID · no AAID: the contract forbids them by design.
class Devices extends Table {
  @override
  String get tableName => 'device';

  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get childId => text().nullable()();
  TextColumn get mode => text().map(const DeviceModeConverter())();
  TextColumn get platform => text()();
  TextColumn get osVersion => text().nullable()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get appVersion => text().nullable()();
  DateTimeColumn get pairedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contract `device_permission` — "observed state, not assumed" (ADR-050).
/// The Dart getter is `permKey`; the SQL column is the contract's `key`.
class DevicePermissions extends Table {
  @override
  String get tableName => 'device_permission';

  TextColumn get deviceId => text()();
  TextColumn get permKey => text().named('key').map(const PermKeyConverter())();
  TextColumn get status => text().map(const PermStatusConverter())();
  DateTimeColumn get checkedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {deviceId, permKey};
}

/// Contract `device_health` — the surface behind ADR-050 rule 4: whatever is
/// missing is reported here, in one place, instead of nagging the parent.
class DeviceHealths extends Table {
  @override
  String get tableName => 'device_health';

  TextColumn get deviceId => text()();
  DateTimeColumn get lastHeartbeat => dateTime().nullable()();
  // The contract's CHECK (0..100) guards the server copy; on device the range is
  // validated in `DriftDeviceRepository.saveHealth`, which also keeps
  // `score`/`reason` inside their documented value sets.
  IntColumn get batteryLevel => integer().nullable()();
  TextColumn get score => text().withDefault(const Constant(kHealthGood))();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

/// Contract `mode_unlock_attempt` — the triple lock. The contract notes
/// "٣ محاولات ⇒ ٢٤ ساعة"; `DriftDeviceRepository` is what applies that rule.
class ModeUnlockAttempts extends Table {
  @override
  String get tableName => 'mode_unlock_attempt';

  TextColumn get id => text()();
  TextColumn get deviceId => text()();
  DateTimeColumn get attemptedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get passwordOk => boolean()();
  BoolColumn get approved => boolean().nullable()();
  DateTimeColumn get lockedUntil => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contract `location_ping` — the raw trail every decision is built on.
/// Pruned after [kLocationRetentionDays]; the device copy calls the prune
/// explicitly, the server has `prune_locations()` on a schedule.
class LocationPings extends Table {
  @override
  String get tableName => 'location_ping';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get childId => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real().nullable()();
  IntColumn get battery => integer().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Contract `geofence` — ADR-051: a shape, not a radius.
///
/// `lat`/`lon` is the circle's centre, or a polygon's bounding-box centre —
/// which is also what gets registered with the OS as its coarse circle.
/// `altitudeM`/`floorLabel` are **display only**: the contract forbids using
/// altitude in containment, because GPS vertical accuracy cannot carry it.
class Geofences extends Table {
  @override
  String get tableName => 'geofence';

  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get childId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get shape => text().map(const GeofenceShapeConverter())();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  IntColumn get radiusM => integer().nullable()();
  TextColumn get icon => text().withDefault(const Constant('home'))();
  RealColumn get altitudeM => real().nullable()();
  TextColumn get floorLabel => text().nullable()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contract `geofence_vertex` — the drawn boundary. The polygon is closed
/// implicitly (the first vertex is never repeated) and ordered by `seq`.
class GeofenceVertices extends Table {
  @override
  String get tableName => 'geofence_vertex';

  TextColumn get geofenceId => text()();
  IntColumn get seq => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();

  @override
  Set<Column<Object>> get primaryKey => {geofenceId, seq};
}

/// Contract `geofence_schedule` — what makes a fence dynamic in time, and the
/// only source of a NO_SHOW. No rows = always active (٢٤/٧).
class GeofenceSchedules extends Table {
  @override
  String get tableName => 'geofence_schedule';

  TextColumn get id => text()();
  TextColumn get geofenceId => text()();
  IntColumn get weekday => integer()();
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();
  IntColumn get expectBy => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Contract `geofence_event` — the decision log. `accuracyM` keeps the evidence
/// next to the verdict, so a bad GPS fix is never blamed on the family.
class GeofenceEvents extends Table {
  @override
  String get tableName => 'geofence_event';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get geofenceId => text()();
  TextColumn get childId => text()();
  TextColumn get kind => text().map(const GeofenceEventKindConverter())();
  DateTimeColumn get occurredAt => dateTime()();
  RealColumn get accuracyM => real().nullable()();
}

/// Contract `sos_alert` — "🚨 لا يُحذف أبدًا · لا يعتمد على اشتراك ولا صلاحية".
/// `requestId` is UNIQUE in the contract: a re-sent alert is the same alert.
class SosAlerts extends Table {
  @override
  String get tableName => 'sos_alert';

  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get childId => text()();
  DateTimeColumn get triggeredAt => dateTime()();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();
  TextColumn get status => text().map(const SosStatusConverter())();
  TextColumn get acknowledgedBy => text().nullable()();
  DateTimeColumn get acknowledgedAt => dateTime().nullable()();
  TextColumn get resolvedBy => text().nullable()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get requestId => text().unique()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Accounts,
    Families,
    Members,
    Children,
    Devices,
    DevicePermissions,
    DeviceHealths,
    ModeUnlockAttempts,
    LocationPings,
    Geofences,
    GeofenceVertices,
    GeofenceSchedules,
    GeofenceEvents,
    SosAlerts,
  ],
)
class FamilyDatabase extends _$FamilyDatabase {
  FamilyDatabase(super.e);

  /// v1 = identity core (PERS-2a) · v2 = devices + permissions (PERS-2b)
  /// · v3 = location + geofence + emergency (PERS-2c, ADR-051).
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(devices);
            await m.createTable(devicePermissions);
            await m.createTable(deviceHealths);
            await m.createTable(modeUnlockAttempts);
          }
          if (from < 3) {
            await m.createTable(locationPings);
            await m.createTable(geofences);
            await m.createTable(geofenceVertices);
            await m.createTable(geofenceSchedules);
            await m.createTable(geofenceEvents);
            await m.createTable(sosAlerts);
          }
        },
      );
}
