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

  Future<SharedChildrenPolicies> loadSharedPolicies();

  Future<void> saveSharedPolicies(SharedChildrenPolicies policies);
}

/// In-memory mock — default empty family (Rule 23 · never plants person names).
final class InMemoryChildrenListRepository implements ChildrenListRepository {
  InMemoryChildrenListRepository({
    List<ChildrenListEntry> children = const [],
    Map<String, List<ChildrenListEntry>> byFamily = const {},
    SharedChildrenPolicies policies = const SharedChildrenPolicies(),
    this.failLoad = false,
  }) : _children = List.of(children),
       _byFamily = {
         for (final entry in byFamily.entries) entry.key: List.of(entry.value),
       },
       _policies = policies;

  List<ChildrenListEntry> _children;
  final Map<String, List<ChildrenListEntry>> _byFamily;
  SharedChildrenPolicies _policies;

  /// Test seam — next [listChildren] throws.
  bool failLoad;

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
  Future<SharedChildrenPolicies> loadSharedPolicies() async => _policies;

  @override
  Future<void> saveSharedPolicies(SharedChildrenPolicies policies) async {
    _policies = policies;
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ChildrenListRepository = InMemoryChildrenListRepository();
