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

@DriftDatabase(tables: [Accounts, Families, Members, Children])
class FamilyDatabase extends _$FamilyDatabase {
  FamilyDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
      );
}
