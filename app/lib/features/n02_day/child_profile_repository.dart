import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Full child profile hub model for SCR-FAT-013 — values from repos, never widgets.
@immutable
final class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.displayName,
    required this.emoji,
    required this.swatch,
    required this.ageYears,
    required this.locationLabel,
    required this.lastSeenLabel,
    required this.batteryLabel,
    required this.walletLabel,
    required this.todayUsedLabel,
    required this.todayCapLabel,
    required this.lastHeartbeatLabel,
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
  final String walletLabel;
  final String todayUsedLabel;
  final String todayCapLabel;
  final String lastHeartbeatLabel;
  final ChildListHealth health;
  final bool warnRing;

  /// Map a roster row into a lean profile (metrics may be empty).
  factory ChildProfile.fromListEntry(ChildrenListEntry entry) {
    return ChildProfile(
      id: entry.id,
      displayName: entry.displayName,
      emoji: entry.emoji,
      swatch: entry.swatch,
      ageYears: entry.ageYears,
      locationLabel: entry.locationLabel,
      lastSeenLabel: entry.lastSeenLabel,
      batteryLabel: entry.batteryLabel,
      walletLabel: entry.timeLeftLabel,
      todayUsedLabel: '',
      todayCapLabel: '',
      lastHeartbeatLabel: entry.lastSeenLabel,
      health: entry.health,
      warnRing: entry.warnRing,
    );
  }
}

/// Rule 25 seam — per-child profile for SCR-FAT-013 (Drift later).
abstract class ChildProfileRepository {
  /// Returns null when [childId] is unknown / not linked.
  Future<ChildProfile?> loadById(String childId, {FamilyId? familyId});
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
///
/// Falls back to [ChildrenListRepository] so FAT-012 → FAT-013 stays coherent
/// when only the roster was seeded.
final class InMemoryChildProfileRepository implements ChildProfileRepository {
  InMemoryChildProfileRepository({
    List<ChildProfile> profiles = const [],
    ChildrenListRepository? childrenList,
    this.failLoad = false,
  })  : _profiles = List.of(profiles),
        _childrenList = childrenList;

  List<ChildProfile> _profiles;
  final ChildrenListRepository? _childrenList;

  /// Test seam — next [loadById] throws.
  bool failLoad;

  void seed(List<ChildProfile> profiles) => _profiles = List.of(profiles);

  @override
  Future<ChildProfile?> loadById(String childId, {FamilyId? familyId}) async {
    if (failLoad) {
      throw StateError('mock child profile load failure');
    }
    final trimmed = childId.trim();
    if (trimmed.isEmpty) return null;

    for (final p in _profiles) {
      if (p.id == trimmed) return p;
    }

    final listRepo = _childrenList ?? stage1ChildrenListRepository;
    final kids = await listRepo.listChildren(familyId: familyId);
    for (final k in kids) {
      if (k.id == trimmed) return ChildProfile.fromListEntry(k);
    }
    return null;
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ChildProfileRepository = InMemoryChildProfileRepository();
