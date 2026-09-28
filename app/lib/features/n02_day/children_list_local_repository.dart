import 'dart:convert';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/identity/identity_local_persistence.dart';
import 'package:family_os/features/n02_day/children_list_local_seed_mock.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Legacy provenance string (pre-LDR). Still recognized by honesty banners.
const String kChildrenListLocalDemoProvenance = 'LOCAL_DEMO_SEEDED';

/// LDR-B1 — REAL_LOCAL roster seed (identity fields; no fake GPS/battery).
const String kChildrenListRealLocalProvenance = 'REAL_LOCAL_SEEDED';

/// True when roster envelope is a Local seed (legacy demo or REAL_LOCAL).
bool isChildrenListSeededProvenance(String? provenance) =>
    provenance == kChildrenListLocalDemoProvenance ||
    provenance == kChildrenListRealLocalProvenance;

/// Re-export of [ChildrenListLocalSeedMock] — demo labels live in `*mock*.dart`
/// (Rule 12 / D8). IDs align with Stage-1 [IdentityRuntime] for FAT-012 merge.
typedef ChildrenListLocalSeed = ChildrenListLocalSeedMock;

/// Local KV [ChildrenListRepository] (`id_roster`) — DOM-IDENTITY-B.
final class LocalChildrenListRepository implements ChildrenListRepository {
  LocalChildrenListRepository(
    this._db, {
    this.namespace = IdentityKvNamespaces.roster,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final String namespace;
  final DateTime Function() _clock;

  static const _table = 'kv_store';
  static const _policiesKey = 'shared_policies';

  static String _childrenKey(FamilyId familyId) =>
      'children:${familyId.value}';

  /// Ensures deterministic LOCAL DEMO seed when family roster key is missing.
  Future<void> ensureSeeded(FamilyId familyId) async {
    final existing = await _readRaw(_childrenKey(familyId));
    if (existing != null && existing.isNotEmpty) return;
    final seed = ChildrenListLocalSeed.forFamily(familyId);
    if (seed.isEmpty) return;
    await _writeChildren(familyId, seed);
  }

  Future<void> ensurePoliciesSeeded() async {
    final existing = await _readRaw(_policiesKey);
    if (existing != null && existing.isNotEmpty) return;
    await saveSharedPolicies(ChildrenListLocalSeed.defaultPolicies);
  }

  /// Envelope provenance after load (empty if not seeded / missing).
  @override
  Future<String?> loadProvenance({FamilyId? familyId}) async {
    final id = familyId ?? ChildrenListLocalSeed.famStage1;
    final raw = await _readRaw(_childrenKey(id));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return decoded['provenance'] as String?;
  }

  @override
  Future<List<ChildrenListEntry>> listChildren({FamilyId? familyId}) async {
    final id = familyId ?? ChildrenListLocalSeed.famStage1;
    await ensureSeeded(id);
    await _migrateLegacyDemoTelemetry(id);
    final raw = await _readRaw(_childrenKey(id));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final list = decoded['children'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map)
          _entryFromJson(item.map((k, v) => MapEntry(k.toString(), v))),
    ];
  }

  /// LDR-B1 — one-shot: strip fabricated GPS/battery from legacy LOCAL_DEMO seed.
  Future<void> _migrateLegacyDemoTelemetry(FamilyId familyId) async {
    final raw = await _readRaw(_childrenKey(familyId));
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    final provenance = decoded['provenance'] as String?;
    if (provenance != kChildrenListLocalDemoProvenance) return;
    final list = decoded['children'];
    if (list is! List) return;
    final kids = [
      for (final item in list)
        if (item is Map)
          _entryFromJson(item.map((k, v) => MapEntry(k.toString(), v))),
    ];
    final scrubbed = [
      for (final k in kids)
        ChildrenListEntry(
          id: k.id,
          displayName: k.displayName,
          emoji: k.emoji,
          swatch: k.swatch,
          ageYears: k.ageYears,
          locationLabel: '',
          lastSeenLabel: '',
          batteryLabel: '',
          timeLeftLabel: '',
          health: ChildListHealth.excellent,
          warnRing: false,
        ),
    ];
    await _writeChildren(familyId, scrubbed);
  }

  @override
  Future<void> upsertChild(ChildrenListEntry entry, {FamilyId? familyId}) async {
    final id = familyId ?? ChildrenListLocalSeed.famStage1;
    final existing = await listChildren(familyId: id);
    final next = List<ChildrenListEntry>.of(existing);
    final idx = next.indexWhere((c) => c.id == entry.id);
    if (idx >= 0) {
      next[idx] = entry;
    } else {
      next.add(entry);
    }
    await _writeChildren(id, next);
  }

  @override
  Future<SharedChildrenPolicies> loadSharedPolicies() async {
    await ensurePoliciesSeeded();
    final raw = await _readRaw(_policiesKey);
    if (raw == null || raw.isEmpty) {
      return ChildrenListLocalSeed.defaultPolicies;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return ChildrenListLocalSeed.defaultPolicies;
    return _policiesFromJson(decoded.map((k, v) => MapEntry(k.toString(), v)));
  }

  @override
  Future<void> saveSharedPolicies(SharedChildrenPolicies policies) async {
    await _write(
      _policiesKey,
      jsonEncode({
        'provenance': kChildrenListRealLocalProvenance,
        ..._policiesToJson(policies),
      }),
    );
  }

  Future<void> _writeChildren(
    FamilyId familyId,
    List<ChildrenListEntry> children,
  ) async {
    await _write(
      _childrenKey(familyId),
      jsonEncode({
        'provenance': kChildrenListRealLocalProvenance,
        'children': [for (final c in children) _entryToJson(c)],
      }),
    );
  }

  Future<String?> _readRaw(String key) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _write(String key, String value) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': key,
        'value': value,
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  static Map<String, Object?> _entryToJson(ChildrenListEntry e) => {
        'id': e.id,
        'displayName': e.displayName,
        'emoji': e.emoji,
        'swatch': e.swatch.name,
        'ageYears': e.ageYears,
        'locationLabel': e.locationLabel,
        'lastSeenLabel': e.lastSeenLabel,
        'batteryLabel': e.batteryLabel,
        'timeLeftLabel': e.timeLeftLabel,
        'health': e.health.name,
        'warnRing': e.warnRing,
      };

  static ChildrenListEntry _entryFromJson(Map<String, Object?> json) {
    final swatchName = json['swatch'] as String? ?? DayChildSwatch.purple.name;
    final healthName =
        json['health'] as String? ?? ChildListHealth.excellent.name;
    return ChildrenListEntry(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🧒',
      swatch: DayChildSwatch.values.firstWhere(
        (s) => s.name == swatchName,
        orElse: () => DayChildSwatch.purple,
      ),
      ageYears: json['ageYears'] as int? ?? 0,
      locationLabel: json['locationLabel'] as String? ?? '',
      lastSeenLabel: json['lastSeenLabel'] as String? ?? '',
      batteryLabel: json['batteryLabel'] as String? ?? '',
      timeLeftLabel: json['timeLeftLabel'] as String? ?? '',
      health: ChildListHealth.values.firstWhere(
        (h) => h.name == healthName,
        orElse: () => ChildListHealth.excellent,
      ),
      warnRing: json['warnRing'] as bool? ?? false,
    );
  }

  static Map<String, Object?> _policiesToJson(SharedChildrenPolicies p) => {
        'scopeAll': p.scopeAll,
        'selectedChildIds': p.selectedChildIds,
        'dailyCapHours': p.dailyCapHours,
        'bedtimeLabel': p.bedtimeLabel,
        'webFilterOn': p.webFilterOn,
      };

  static SharedChildrenPolicies _policiesFromJson(Map<String, Object?> json) {
    final ids = json['selectedChildIds'];
    return SharedChildrenPolicies(
      scopeAll: json['scopeAll'] as bool? ?? true,
      selectedChildIds: ids is List
          ? [for (final i in ids) i.toString()]
          : const [],
      dailyCapHours: json['dailyCapHours'] as int? ?? 4,
      bedtimeLabel: json['bedtimeLabel'] as String? ?? '',
      webFilterOn: json['webFilterOn'] as bool? ?? true,
    );
  }
}
