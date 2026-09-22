import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Roster kind on SCR-FAT-027 (prototype FAT-027 · one_owner_per_family).
enum FamilyMemberKind {
  /// Sole family owner (father) — invite authority.
  owner,

  /// Mother / co-parent with [MotherLevel].
  mother,

  /// Extra guardian — fixed observer; never promoted (DB constraint).
  guardian,

  /// Linked child — triple-lock posture.
  child,
}

/// One roster row — values from repos, never planted in widgets (Rule 23).
@immutable
final class FamilyMemberEntry {
  const FamilyMemberEntry({
    required this.id,
    required this.displayName,
    required this.kind,
    required this.monogram,
    required this.swatch,
    this.isSelf = false,
    this.motherLevel,
    this.levelLocked = false,
  });

  final String id;
  final String displayName;
  final FamilyMemberKind kind;

  /// Single-letter / emoji avatar glyph from the repo.
  final String monogram;
  final DayChildSwatch swatch;

  /// When true, UI appends the ARB «(أنت)» self marker.
  final bool isSelf;

  /// Mother permission level — null unless [kind] is [FamilyMemberKind.mother].
  final MotherLevel? motherLevel;

  /// Guardians stay مطّلع — cannot open FAT-031.
  final bool levelLocked;
}

/// Rule 25 seam — family roster for SCR-FAT-027 (Drift later).
abstract class FamilyMembersRepository {
  Future<List<FamilyMemberEntry>> listMembers();
}

/// In-memory mock — default empty (Rule 23 · never plants person names).
final class InMemoryFamilyMembersRepository implements FamilyMembersRepository {
  InMemoryFamilyMembersRepository({
    List<FamilyMemberEntry> members = const [],
    this.failLoad = false,
  }) : _members = List.of(members);

  List<FamilyMemberEntry> _members;

  /// Test seam — next [listMembers] throws.
  bool failLoad;

  void seed(List<FamilyMemberEntry> members) => _members = List.of(members);

  @override
  Future<List<FamilyMemberEntry>> listMembers() async {
    if (failLoad) {
      throw StateError('mock family members load failure');
    }
    return List.unmodifiable(_members);
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1FamilyMembersRepository = InMemoryFamilyMembersRepository();
