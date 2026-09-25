import 'package:drift/drift.dart';

import 'family_database.dart';

/// Rule 25 seam — children as real persisted rows (they were mock-only).
///
/// Hosts: SCR-FAT-003 add child · SCR-FAT-012 child list · SCR-FAT-013 child
/// profile. Rule 13 stays intact: every screen stays `f(ChildId)`, only the
/// source of the rows changes from a mock list to the device database.
abstract class ChildRepository {
  Future<List<ChildrenData>> allInFamily(String familyId);

  Future<ChildrenData?> byId(String childId);

  Future<ChildrenData?> byAlias(String alias);

  Future<void> upsert(ChildrenCompanion child);

  Future<int> deleteById(String childId);
}

final class DriftChildRepository implements ChildRepository {
  DriftChildRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<List<ChildrenData>> allInFamily(String familyId) {
    return (_db.select(_db.children)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  @override
  Future<ChildrenData?> byId(String childId) {
    return (_db.select(_db.children)..where((t) => t.id.equals(childId)))
        .getSingleOrNull();
  }

  @override
  Future<ChildrenData?> byAlias(String alias) {
    return (_db.select(_db.children)..where((t) => t.alias.equals(alias)))
        .getSingleOrNull();
  }

  @override
  Future<void> upsert(ChildrenCompanion child) {
    return _db.into(_db.children).insertOnConflictUpdate(child);
  }

  @override
  Future<int> deleteById(String childId) {
    return (_db.delete(_db.children)..where((t) => t.id.equals(childId))).go();
  }
}
