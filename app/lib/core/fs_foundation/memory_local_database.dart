import 'local_database.dart';

/// In-process [FamilyLocalDatabase] for unit tests and DI proofs (Rule 25).
final class MemoryLocalDatabase implements FamilyLocalDatabase {
  MemoryLocalDatabase();

  final Map<String, List<Map<String, Object?>>> _tables = {
    'schema_meta': <Map<String, Object?>>[],
    'kv_store': <Map<String, Object?>>[],
    'capability_entry': <Map<String, Object?>>[],
    'sync_outbox': <Map<String, Object?>>[],
    'policy_delivery': <Map<String, Object?>>[],
    'loc_zone': <Map<String, Object?>>[],
    'loc_zone_geometry': <Map<String, Object?>>[],
    'loc_zone_assignment': <Map<String, Object?>>[],
    'loc_trail_sample': <Map<String, Object?>>[],
    'loc_geofence_event': <Map<String, Object?>>[],
    'loc_zone_presence': <Map<String, Object?>>[],
    'loc_sos_evidence': <Map<String, Object?>>[],
    'loc_mode_fact': <Map<String, Object?>>[],
    'wf_document': <Map<String, Object?>>[],
    'wf_temp_allow': <Map<String, Object?>>[],
    'ac_document': <Map<String, Object?>>[],
    'ac_exception': <Map<String, Object?>>[],
    'ac_lock_now': <Map<String, Object?>>[],
    'ac_install': <Map<String, Object?>>[],
    'sc_document': <Map<String, Object?>>[],
    'mode_document': <Map<String, Object?>>[],
    'mode_activation': <Map<String, Object?>>[],
    'mode_exception': <Map<String, Object?>>[],
    'sos_incident': <Map<String, Object?>>[],
    'sos_lifecycle_audit': <Map<String, Object?>>[],
    'sos_ops_sample': <Map<String, Object?>>[],
    'sos_break_glass': <Map<String, Object?>>[],
    'ai_model_manifest': <Map<String, Object?>>[],
    'ai_safety_signal': <Map<String, Object?>>[],
    'ai_safety_ticket': <Map<String, Object?>>[],
    'ai_safety_suggestion': <Map<String, Object?>>[],
    'ai_safety_audit': <Map<String, Object?>>[],
  };

  bool _open = false;
  int _version = 0;

  @override
  Future<void> open() async {
    _open = true;
    if (_version < FamilyLocalSchema.currentVersion) {
      _version = FamilyLocalSchema.currentVersion;
      await _upsertMeta('schema_version', '$_version');
    }
  }

  @override
  Future<void> close() async {
    _open = false;
  }

  void _ensureOpen() {
    if (!_open) {
      throw StateError('MemoryLocalDatabase is not open');
    }
  }

  List<Map<String, Object?>> _table(String name) {
    final t = _tables[name];
    if (t == null) {
      throw ArgumentError('Unknown table: $name');
    }
    return t;
  }

  Future<void> _upsertMeta(String key, String value) async {
    final rows = _table('schema_meta');
    final i = rows.indexWhere((r) => r['key'] == key);
    final row = {'key': key, 'value': value};
    if (i >= 0) {
      rows[i] = row;
    } else {
      rows.add(row);
    }
  }

  @override
  Future<int> schemaVersion() async {
    final rows = _table(
      'schema_meta',
    ).where((r) => r['key'] == 'schema_version').toList();
    if (rows.isEmpty) return 0;
    return int.parse(rows.first['value']! as String);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    LocalConflictAlgorithm conflictAlgorithm = LocalConflictAlgorithm.abort,
  }) async {
    _ensureOpen();
    final rows = _table(table);
    final pk = _primaryKey(table);
    if (pk != null) {
      final existing = rows.indexWhere((r) => r[pk] == values[pk]);
      if (existing >= 0) {
        switch (conflictAlgorithm) {
          case LocalConflictAlgorithm.abort:
            throw StateError('UNIQUE constraint failed on $table.$pk');
          case LocalConflictAlgorithm.ignore:
            return 0;
          case LocalConflictAlgorithm.replace:
            rows[existing] = Map<String, Object?>.from(values);
            return 1;
        }
      }
    }
    // Composite primary keys (kv_store, loc_zone_assignment, loc_zone_presence).
    if (table == 'kv_store' ||
        table == 'loc_zone_assignment' ||
        table == 'loc_zone_presence') {
      final existing = rows.indexWhere(
        (r) => _isCompositeConflict(table, r, values),
      );
      if (existing >= 0) {
        switch (conflictAlgorithm) {
          case LocalConflictAlgorithm.abort:
            throw StateError('UNIQUE constraint failed on $table');
          case LocalConflictAlgorithm.ignore:
            return 0;
          case LocalConflictAlgorithm.replace:
            rows[existing] = Map<String, Object?>.from(values);
            return 1;
        }
      }
    }
    rows.add(Map<String, Object?>.from(values));
    return 1;
  }

  String? _primaryKey(String table) {
    return switch (table) {
      'schema_meta' => 'key',
      'capability_entry' => 'id',
      'sync_outbox' => 'id',
      'policy_delivery' => 'artifact_id',
      'loc_zone' => 'id',
      'loc_zone_geometry' => 'zone_id',
      'loc_trail_sample' => 'id',
      'loc_geofence_event' => 'event_id',
      'loc_sos_evidence' => 'id',
      'loc_mode_fact' => 'id',
      'wf_document' => 'scope_key',
      'wf_temp_allow' => 'id',
      'ac_document' => 'scope_key',
      'ac_exception' => 'id',
      'ac_lock_now' => 'id',
      'ac_install' => 'id',
      'sc_document' => 'scope_key',
      'mode_document' => 'id',
      'mode_activation' => 'id',
      'mode_exception' => 'id',
      'sos_incident' => 'id',
      'sos_lifecycle_audit' => 'id',
      'sos_ops_sample' => 'id',
      'sos_break_glass' => 'id',
      'ai_model_manifest' => 'model_id',
      'ai_safety_signal' => 'id',
      'ai_safety_ticket' => 'id',
      'ai_safety_suggestion' => 'id',
      'ai_safety_audit' => 'id',
      _ => null,
    };
  }

  bool _isCompositeConflict(
    String table,
    Map<String, Object?> existing,
    Map<String, Object?> values,
  ) {
    if (table == 'kv_store') {
      return existing['namespace'] == values['namespace'] &&
          existing['key'] == values['key'];
    }
    if (table == 'loc_zone_assignment' || table == 'loc_zone_presence') {
      return existing['zone_id'] == values['zone_id'] &&
          existing['child_id'] == values['child_id'];
    }
    return false;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    _ensureOpen();
    final rows = _table(table);
    var count = 0;
    for (var i = 0; i < rows.length; i++) {
      if (_matches(rows[i], where, whereArgs)) {
        rows[i] = {...rows[i], ...values};
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    _ensureOpen();
    final rows = _table(table);
    final before = rows.length;
    rows.removeWhere((r) => _matches(r, where, whereArgs));
    return before - rows.length;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    _ensureOpen();
    var rows = _table(table)
        .where((r) => _matches(r, where, whereArgs))
        .map((r) => Map<String, Object?>.from(r))
        .toList();
    if (orderBy != null) {
      rows = _sort(rows, orderBy);
    }
    if (limit != null && rows.length > limit) {
      rows = rows.sublist(0, limit);
    }
    return rows;
  }

  @override
  Future<void> execute(String sql, [List<Object?>? args]) async {
    _ensureOpen();
    // Memory DB no-ops raw DDL after open(); tests use structured APIs.
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    _ensureOpen();
    throw UnsupportedError(
      'MemoryLocalDatabase.rawQuery is not supported — use query()',
    );
  }

  bool _matches(
    Map<String, Object?> row,
    String? where,
    List<Object?>? whereArgs,
  ) {
    if (where == null || where.isEmpty) return true;
    final args = whereArgs ?? const <Object?>[];
    // Supports simple "col = ?" and "col = ? AND col2 = ?" only.
    final parts = where.split(RegExp(r'\s+AND\s+', caseSensitive: false));
    var argIndex = 0;
    for (final part in parts) {
      final m = RegExp(r'^(\w+)\s*=\s*\?$').firstMatch(part.trim());
      if (m == null) {
        throw UnsupportedError('Unsupported where clause: $where');
      }
      final col = m.group(1)!;
      if (argIndex >= args.length) return false;
      if (row[col] != args[argIndex]) return false;
      argIndex++;
    }
    return true;
  }

  List<Map<String, Object?>> _sort(
    List<Map<String, Object?>> rows,
    String orderBy,
  ) {
    final specs = orderBy.split(',').map((s) => s.trim()).toList();
    rows.sort((a, b) {
      for (final spec in specs) {
        final bits = spec.split(RegExp(r'\s+'));
        final col = bits.first;
        final desc = bits.length > 1 && bits[1].toUpperCase() == 'DESC';
        final av = a[col];
        final bv = b[col];
        final cmp = _cmp(av, bv);
        if (cmp != 0) return desc ? -cmp : cmp;
      }
      return 0;
    });
    return rows;
  }

  int _cmp(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is Comparable && b is Comparable) {
      return a.compareTo(b);
    }
    return a.toString().compareTo(b.toString());
  }
}
