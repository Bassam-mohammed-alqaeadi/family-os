import 'dart:async';
import 'dart:convert';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';

/// Durable LearningAssignment store via `kv_store` (DOM-EDU-LOCAL-A).
///
/// Namespace [kvNamespace]. Keys are assignment ids. Index key `_index`
/// holds ordered id list. Metadata only — no licensed Quran content.
final class LocalLearningAssignmentRepository
    implements LearningAssignmentRepository {
  LocalLearningAssignmentRepository(
    this._db, {
    this.namespace = kvNamespace,
    DateTime Function()? clock,
    String Function()? idFactory,
  })  : _clock = clock ?? DateTime.now,
        _idFactory = idFactory ?? _defaultId;

  static const kvNamespace = 'edu_assignments';
  static const _indexKey = '_index';
  static const _table = 'kv_store';

  final FamilyLocalDatabase _db;
  final String namespace;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  final _controller = StreamController<LearningAssignment>.broadcast();
  static var _seq = 0;

  static String _defaultId() {
    _seq += 1;
    return 'assign_${_seq}_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Stream<LearningAssignment> get assignments => _controller.stream;

  Future<List<String>> _loadIndex() async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, _indexKey],
      limit: 1,
    );
    if (rows.isEmpty) return [];
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.map((e) => e.toString()).toList();
  }

  Future<void> _saveIndex(List<String> ids) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': _indexKey,
        'value': jsonEncode(ids),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  Future<LearningAssignment?> _loadById(String id) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return LearningAssignment.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  @override
  Future<List<LearningAssignment>> listForChild(ChildId childId) async {
    final ids = await _loadIndex();
    final out = <LearningAssignment>[];
    for (final id in ids) {
      final a = await _loadById(id);
      if (a != null && a.childId == childId) out.add(a);
    }
    return List.unmodifiable(out);
  }

  @override
  Future<LearningAssignment?> latestForChild(ChildId childId) async {
    final forChild = await listForChild(childId);
    if (forChild.isEmpty) return null;
    return forChild.last;
  }

  @override
  Future<LearningAssignment> publish(
    LearningAssignmentPublishRequest request,
  ) async {
    final assignment = LearningAssignment(
      id: _idFactory(),
      childId: request.childId,
      titleKey: request.titleKey,
      rewardMinutes: request.rewardMinutes,
      source: request.source,
      assignedAt: _clock().toUtc(),
      ctaScreenId: request.ctaScreenId,
      materialKindKey: request.materialKindKey,
    );
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': assignment.id,
        'value': jsonEncode(assignment.toJson()),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.abort,
    );
    final ids = await _loadIndex();
    ids.add(assignment.id);
    await _saveIndex(ids);
    _controller.add(assignment);
    return assignment;
  }

  void dispose() {
    _controller.close();
  }

  /// LDR-B5 — one homework assignment for demo-child when store empty.
  Future<void> ensureRealLocalSeeded() async {
    final ids = await _loadIndex();
    if (ids.isNotEmpty) return;
    await publish(
      LearningAssignmentPublishRequest(
        childId: ChildId('demo-child'),
        titleKey: 'mathPractice',
        rewardMinutes: Minutes(10),
        source: LearningAssignmentSource.homework,
        ctaScreenId: 'SCR-CHD-015',
        materialKindKey: 'math',
      ),
    );
  }
}
