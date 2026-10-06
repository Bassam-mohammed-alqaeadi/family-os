import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Where a membership stands, in the server's own vocabulary.
///
/// `invited` is an offer and not access: the server refuses the family to an invited
/// account until it accepts. The distinction is kept in the model because the screen must
/// offer a different step for a pending invitation than for an active member.
enum FamilyMembershipStatus {
  invited,
  active,
  revoked,
  removed;

  /// The wire value, so the client never invents its own spelling of a server enum.
  String get wireName => switch (this) {
    FamilyMembershipStatus.invited => 'invited',
    FamilyMembershipStatus.active => 'active',
    FamilyMembershipStatus.revoked => 'revoked',
    FamilyMembershipStatus.removed => 'removed',
  };

  bool get isPending => this == FamilyMembershipStatus.invited;
  bool get isActive => this == FamilyMembershipStatus.active;

  /// A status this client does not know returns null rather than a guessed meaning: a
  /// membership rendered under the wrong status is a screen telling a guardian something
  /// the server did not say.
  static FamilyMembershipStatus? parse(Object? value) {
    for (final status in FamilyMembershipStatus.values) {
      if (status.wireName == value) return status;
    }
    return null;
  }
}

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
    required this.familyId,
    required this.displayName,
    required this.kind,
    required this.monogram,
    required this.swatch,
    this.isSelf = false,
    this.motherLevel,
    this.levelLocked = false,
    this.membershipStatus,
  });

  final String id;
  final String familyId;
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

  /// The membership's standing on the server, when this row came from the server. Null for
  /// a child listed from the children roster, which is not a membership row.
  final FamilyMembershipStatus? membershipStatus;
}

/// Rule 25 seam — family roster for SCR-FAT-027 (Drift later).
abstract class FamilyMembersRepository {
  Future<List<FamilyMemberEntry>> listMembers({String? familyId});
}

/// A members repository that can also say where its children rows came from.
///
/// The screen used to ask that question by testing for one concrete repository type, which
/// made every new implementation an edit to the screen. Asking through an interface keeps
/// the screen closed and the answer open.
abstract class FamilyMembersProvenanceSource {
  Future<String?> loadProvenance({FamilyId? familyId});
}

/// In-memory mock — default empty (Rule 23 · never plants person names).
final class InMemoryFamilyMembersRepository implements FamilyMembersRepository {
  InMemoryFamilyMembersRepository({
    List<FamilyMemberEntry> members = const [],
    Map<String, List<FamilyMemberEntry>> byFamily = const {},
    this.failLoad = false,
  }) : _members = List.of(members),
       _byFamily = {
         for (final entry in byFamily.entries) entry.key: List.of(entry.value),
       };

  List<FamilyMemberEntry> _members;
  final Map<String, List<FamilyMemberEntry>> _byFamily;

  /// Test seam — next [listMembers] throws.
  bool failLoad;

  void seed(List<FamilyMemberEntry> members) => _members = List.of(members);
  void seedFamily(String familyId, List<FamilyMemberEntry> members) {
    _byFamily[familyId] = List.of(members);
  }

  @override
  Future<List<FamilyMemberEntry>> listMembers({String? familyId}) async {
    if (failLoad) {
      throw StateError('mock family members load failure');
    }
    final id = familyId?.trim();
    if (id != null && id.isNotEmpty) {
      if (_byFamily.containsKey(id)) {
        return List.unmodifiable(_byFamily[id]!);
      }
      return List.unmodifiable(
        _members.where((m) => m.familyId == id).toList(growable: false),
      );
    }
    // Fail closed — unscoped list must not leak across families.
    return const [];
  }
}

/// Stage-1 accessor — Identity projection when bound, else empty InMemory.
FamilyMembersRepository? _stage1FamilyMembersBound;

final InMemoryFamilyMembersRepository _stage1FamilyMembersMemory =
    InMemoryFamilyMembersRepository();

FamilyMembersRepository get stage1FamilyMembersRepository =>
    _stage1FamilyMembersBound ?? _stage1FamilyMembersMemory;

void rebindStage1FamilyMembersRepository(FamilyMembersRepository repository) {
  _stage1FamilyMembersBound = repository;
}

@visibleForTesting
void resetStage1FamilyMembersRepositoryForTest() {
  _stage1FamilyMembersBound = null;
  _stage1FamilyMembersMemory.seed(const []);
  _stage1FamilyMembersMemory.failLoad = false;
}

/// The live membership commands, bound once at startup when a server is configured.
///
/// Null is a real state, not a defect: a build with no API origin has no server to change
/// a membership on, and the screen then offers no membership actions at all rather than
/// buttons that could only fail.
final _stage1MembershipCommands = <FamilyMembershipCommands>[];

FamilyMembershipCommands? get stage1MembershipCommands =>
    _stage1MembershipCommands.isEmpty ? null : _stage1MembershipCommands.first;

void rebindStage1MembershipCommands(FamilyMembershipCommands commands) {
  _stage1MembershipCommands
    ..clear()
    ..add(commands);
}

@visibleForTesting
void resetStage1MembershipCommandsForTest() => _stage1MembershipCommands.clear();
