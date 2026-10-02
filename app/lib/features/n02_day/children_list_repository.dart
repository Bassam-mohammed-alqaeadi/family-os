import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Device / link health chip on SCR-FAT-012 (prototype `.tag g|a`).
enum ChildListHealth { excellent, atRisk }

/// One child row on قائمة الأبناء — values from repos, never planted in widgets.
@immutable
final class ChildrenListEntry {
  const ChildrenListEntry({
    required this.id,
    required this.displayName,
    required this.emoji,
    required this.swatch,
    required this.ageYears,
    required this.locationLabel,
    required this.lastSeenLabel,
    required this.batteryLabel,
    required this.timeLeftLabel,
    required this.health,
    this.warnRing = false,
  });

  final String id;
  final String displayName;
  final String emoji;
  final DayChildSwatch swatch;
  final int ageYears;
  final String locationLabel;
  final String lastSeenLabel;
  final String batteryLabel;
  final String timeLeftLabel;
  final ChildListHealth health;

  /// Prototype fingerprint 5 — amber status ring when connection may drop.
  final bool warnRing;
}

/// Shared family policies sheet state (FAT-012 · Family Link / Qustodio-style).
///
/// Demo Arabic bedtime lives in `children_list_mock.dart` only.
@immutable
final class SharedChildrenPolicies {
  const SharedChildrenPolicies({
    this.scopeAll = true,
    this.selectedChildIds = const [],
    this.dailyCapHours = 4,
    this.bedtimeLabel = '',
    this.webFilterOn = true,
  });

  final bool scopeAll;
  final List<String> selectedChildIds;
  final int dailyCapHours;
  final String bedtimeLabel;
  final bool webFilterOn;

  SharedChildrenPolicies copyWith({
    bool? scopeAll,
    List<String>? selectedChildIds,
    int? dailyCapHours,
    String? bedtimeLabel,
    bool? webFilterOn,
  }) {
    return SharedChildrenPolicies(
      scopeAll: scopeAll ?? this.scopeAll,
      selectedChildIds: selectedChildIds ?? this.selectedChildIds,
      dailyCapHours: dailyCapHours ?? this.dailyCapHours,
      bedtimeLabel: bedtimeLabel ?? this.bedtimeLabel,
      webFilterOn: webFilterOn ?? this.webFilterOn,
    );
  }
}

/// Rule 25 seam — children roster for SCR-FAT-012 (Drift later).
abstract class ChildrenListRepository {
  Future<List<ChildrenListEntry>> listChildren({FamilyId? familyId});

  /// Persist display fields for a child (VX-B6 / FVX-S-04). Idempotent upsert.
  Future<void> upsertChild(ChildrenListEntry entry, {FamilyId? familyId});

  Future<SharedChildrenPolicies> loadSharedPolicies({FamilyId? familyId});

  Future<void> saveSharedPolicies(
    SharedChildrenPolicies policies, {
    FamilyId? familyId,
  });

  /// Envelope provenance (`LOCAL_DEMO_SEEDED`) when roster is demo seed.
  /// Null → no honesty banner (live/unmarked).
  Future<String?> loadProvenance({FamilyId? familyId});
}

/// In-memory mock — default empty family (Rule 23 · never plants person names).
final class InMemoryChildrenListRepository implements ChildrenListRepository {
  InMemoryChildrenListRepository({
    List<ChildrenListEntry> children = const [],
    Map<String, List<ChildrenListEntry>> byFamily = const {},
    SharedChildrenPolicies policies = const SharedChildrenPolicies(),
    Map<String, SharedChildrenPolicies> policiesByFamily = const {},
    this.failLoad = false,
    this.provenance,
  }) : _children = List.of(children),
       _byFamily = {
         for (final entry in byFamily.entries) entry.key: List.of(entry.value),
       },
       _policies = policies,
       _policiesByFamily = Map.of(policiesByFamily);

  List<ChildrenListEntry> _children;
  final Map<String, List<ChildrenListEntry>> _byFamily;
  SharedChildrenPolicies _policies;
  final Map<String, SharedChildrenPolicies> _policiesByFamily;

  /// Test seam — next [listChildren] throws.
  bool failLoad;

  /// Test seam — when [kChildrenListLocalDemoProvenance], FAT-012 shows honesty.
  final String? provenance;

  void seed(List<ChildrenListEntry> children) => _children = List.of(children);
  void seedFamily(FamilyId familyId, List<ChildrenListEntry> children) {
    _byFamily[familyId.value] = List.of(children);
  }

  @override
  Future<List<ChildrenListEntry>> listChildren({FamilyId? familyId}) async {
    if (failLoad) {
      throw StateError('mock children list load failure');
    }
    if (familyId != null) {
      final scoped = _byFamily[familyId.value];
      if (scoped != null) return List.unmodifiable(scoped);
      return List.unmodifiable(
        _children
            .where((child) => child.id.startsWith('${familyId.value}::'))
            .toList(),
      );
    }
    // Stage-1 shim: unscoped seed for gallery/tests without CurrentIdentity.
    // Production callers always pass activeFamilyId.
    return List.unmodifiable(_children);
  }

  @override
  Future<void> upsertChild(ChildrenListEntry entry, {FamilyId? familyId}) async {
    if (familyId != null) {
      final key = familyId.value;
      final list = List<ChildrenListEntry>.of(_byFamily[key] ?? const []);
      final idx = list.indexWhere((c) => c.id == entry.id);
      if (idx >= 0) {
        list[idx] = entry;
      } else {
        list.add(entry);
      }
      _byFamily[key] = list;
      return;
    }
    final idx = _children.indexWhere((c) => c.id == entry.id);
    if (idx >= 0) {
      _children[idx] = entry;
    } else {
      _children.add(entry);
    }
  }

  @override
  Future<SharedChildrenPolicies> loadSharedPolicies({FamilyId? familyId}) async {
    if (familyId == null) return _policies;
    return _policiesByFamily[familyId.value] ?? _policies;
  }

  @override
  Future<void> saveSharedPolicies(
    SharedChildrenPolicies policies, {
    FamilyId? familyId,
  }) async {
    if (familyId == null) {
      _policies = policies;
    } else {
      _policiesByFamily[familyId.value] = policies;
    }
  }

  @override
  Future<String?> loadProvenance({FamilyId? familyId}) async => provenance;
}

/// LEGACY / RETAINED — InMemory empty roster. Production prefers Local KV via
/// [rebindStage1ChildrenListRepository] (DOM-IDENTITY-B).
final InMemoryChildrenListRepository _stage1ChildrenListMemory =
    InMemoryChildrenListRepository();

ChildrenListRepository? _stage1ChildrenListBound;

/// Stage-1 children list accessor — Local when bound, else InMemory.
ChildrenListRepository get stage1ChildrenListRepository =>
    _stage1ChildrenListBound ?? _stage1ChildrenListMemory;

void rebindStage1ChildrenListRepository(ChildrenListRepository repository) {
  _stage1ChildrenListBound = repository;
}

@visibleForTesting
void resetStage1ChildrenListRepositoryForTest() {
  _stage1ChildrenListBound = null;
  _stage1ChildrenListMemory.seed(const []);
  _stage1ChildrenListMemory.failLoad = false;
}
