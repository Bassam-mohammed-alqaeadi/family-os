import 'package:drift/drift.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// DEV-2 — the roster seam closed over real rows.
///
/// Owner / mother / guardian come from `member` joined to `account` (the
/// account is what owns a name — the app still plants none), and children from
/// `child`. Same contract as [InMemoryFamilyMembersRepository], including the
/// fail-closed rule for an unscoped family.
final class DriftFamilyMembersRepository implements FamilyMembersRepository {
  DriftFamilyMembersRepository(this._db, {this.selfAccountId});

  final FamilyDatabase _db;

  /// Marks the signed-in member's own row (the UI appends «(أنت)»).
  final String? selfAccountId;

  @override
  Future<List<FamilyMemberEntry>> listMembers({String? familyId}) async {
    final fid = (familyId ?? '').trim();
    if (fid.isEmpty) {
      // Fail closed — an unscoped roster would mix families.
      return const <FamilyMemberEntry>[];
    }

    final memberRows =
        await (_db.select(_db.members)
              ..where((t) => t.familyId.equals(fid))
              ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
            .get();
    final childRows =
        await (_db.select(_db.children)
              ..where((t) => t.familyId.equals(fid))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    final out = <FamilyMemberEntry>[];
    for (final m in memberRows) {
      final account =
          await (_db.select(_db.accounts)
                ..where((t) => t.id.equals(m.accountId)))
              .getSingleOrNull();
      final kind = _kindOf(m.role);
      final name = (account?.displayName ?? '').trim();
      out.add(
        FamilyMemberEntry(
          id: m.id,
          familyId: m.familyId,
          displayName: name.isEmpty ? (account?.email ?? m.id) : name,
          kind: kind,
          monogram: _monogram(name, account?.email ?? m.id),
          swatch: _swatchOf(m.id),
          isSelf: selfAccountId != null && m.accountId == selfAccountId,
          motherLevel: kind == FamilyMemberKind.mother
              ? _levelOf(m.permissionLevel)
              : null,
          levelLocked: kind == FamilyMemberKind.guardian,
        ),
      );
    }

    for (final c in childRows) {
      out.add(
        FamilyMemberEntry(
          id: c.id,
          familyId: c.familyId,
          displayName: c.displayName,
          kind: FamilyMemberKind.child,
          monogram: _monogram(c.displayName, c.alias),
          swatch: _swatchOf(c.id),
        ),
      );
    }

    return List.unmodifiable(out);
  }

  static FamilyMemberKind _kindOf(MemberRole role) => switch (role) {
    MemberRole.owner => FamilyMemberKind.owner,
    MemberRole.parent => FamilyMemberKind.mother,
    MemberRole.guardian => FamilyMemberKind.guardian,
  };

  static MotherLevel _levelOf(PermLevel level) => switch (level) {
    PermLevel.observer => MotherLevel.observer,
    PermLevel.partner => MotherLevel.partner,
    PermLevel.full => MotherLevel.full,
  };

  /// Deterministic from the row id — presentation only, never a planted fact.
  static DayChildSwatch _swatchOf(String id) {
    var sum = 0;
    for (final unit in id.codeUnits) {
      sum += unit;
    }
    return switch (sum % DayChildSwatch.values.length) {
      0 => DayChildSwatch.purple,
      1 => DayChildSwatch.sky,
      _ => DayChildSwatch.amber,
    };
  }

  static String _monogram(String name, String fallback) {
    final source = name.trim().isNotEmpty ? name.trim() : fallback.trim();
    if (source.isEmpty) return '';
    return String.fromCharCode(source.runes.first).toUpperCase();
  }
}
