import 'dart:async';
import 'dart:convert';

import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/education/learning_result_repository.dart';

/// Durable LearningResult store via `kv_store` (DOM-EDU-LOCAL-B).
///
/// Namespace [kvNamespace]. Metadata only — no licensed content.
final class LocalLearningResultRepository implements LearningResultRepository {
  LocalLearningResultRepository(
    this._db, {
    this.namespace = kvNamespace,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _defaultId;

  static const kvNamespace = 'edu_results';
  static const _indexKey = '_index';
  static const _table = 'kv_store';

  final FamilyLocalDatabase _db;
  final String namespace;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  final _controller = StreamController<LearningResultSubmission>.broadcast();
  static var _seq = 0;

  static String _defaultId() {
    _seq += 1;
    return 'result_${_seq}_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Stream<LearningResultSubmission> get submissions => _controller.stream;

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
    await _db.insert(_table, {
      'namespace': namespace,
      'key': _indexKey,
      'value': jsonEncode(ids),
      'updated_at': _clock().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
  }

  Future<LearningResultSubmission?> _loadById(String id) async {
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
    return LearningResultSubmission.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  @override
  Future<List<LearningResultSubmission>> listRecent({int limit = 20}) async {
    final ids = await _loadIndex();
    final out = <LearningResultSubmission>[];
    for (final id in ids) {
      final row = await _loadById(id);
      if (row != null) out.add(row);
    }
    out.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    if (out.length <= limit) return List.unmodifiable(out);
    return List.unmodifiable(out.sublist(0, limit));
  }

  @override
  Future<LearningResultSubmission> submit(
    LearningResultSubmitRequest request,
  ) async {
    final row = LearningResultSubmission(
      id: _idFactory(),
      childId: request.childId,
      kind: request.kind,
      titleKey: request.titleKey,
      submittedAt: _clock().toUtc(),
      rewardMinutes: request.rewardMinutes,
      scoreCorrect: request.scoreCorrect,
      scoreTotal: request.scoreTotal,
    );
    await _db.insert(_table, {
      'namespace': namespace,
      'key': row.id,
      'value': jsonEncode(row.toJson()),
      'updated_at': _clock().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.abort);
    final ids = await _loadIndex();
    ids.add(row.id);
    await _saveIndex(ids);
    _controller.add(row);
    return row;
  }

  void dispose() {
    _controller.close();
  }
}
