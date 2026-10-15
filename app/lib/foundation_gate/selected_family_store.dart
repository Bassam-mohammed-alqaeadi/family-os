import 'dart:convert';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

/// The family this device last selected, kept across a cold start.
///
/// Without it, a guardian who restarts the app offline has no family to match the kept minutes
/// reading against, and the reading is hidden. It holds only the family id, which the server
/// already told this device. It is cleared at sign-in and sign-out, so a different account never
/// inherits it.
abstract interface class SelectedFamilyStore {
  Future<String?> read();

  Future<void> write(String familyId);

  Future<void> clear();
}

/// The durable store, in the device's SQLite `kv_store` (the same table as the minutes cache).
final class SqliteSelectedFamilyStore implements SelectedFamilyStore {
  SqliteSelectedFamilyStore(this._db);

  static const namespace = 'foundation_gate_session';
  static const _key = 'selected_family';
  static const _table = 'kv_store';

  final FamilyLocalDatabase _db;

  @override
  Future<String?> read() async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: const [namespace, _key],
    );
    if (rows.isEmpty) return null;
    final value = rows.single['value'];
    if (value is! String) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map) return null;
    final familyId = decoded['familyId'];
    return familyId is String && familyId.isNotEmpty ? familyId : null;
  }

  @override
  Future<void> write(String familyId) => _put(jsonEncode({'familyId': familyId}));

  @override
  Future<void> clear() => _put('{}');

  Future<void> _put(String value) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': _key,
        'value': value,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }
}

/// The device's durable store, or null when this device has no honest SQLite store.
/// There is no silent memory fallback: a selection that does not survive a restart must not
/// look like it does.
Future<SelectedFamilyStore?> openDurableSelectedFamilyStore() async {
  await FsSessionKernel.ensureOpen();
  if (FsSessionKernel.sqliteFallbackToMemory) return null;
  return SqliteSelectedFamilyStore(FsSessionKernel.db);
}

/// Opens the durable store on first use. Every read and write fails soft: a broken store means
/// "no remembered family", never an exception in the sign-in flow.
final class DeferredSelectedFamilyStore implements SelectedFamilyStore {
  DeferredSelectedFamilyStore(this._open);

  final Future<SelectedFamilyStore?> Function() _open;
  Future<SelectedFamilyStore?>? _opened;

  Future<SelectedFamilyStore?> get _store => _opened ??= _open();

  @override
  Future<String?> read() async {
    try {
      return await (await _store)?.read();
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String familyId) async {
    try {
      await (await _store)?.write(familyId);
    } on Object {
      return;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await (await _store)?.clear();
    } on Object {
      return;
    }
  }
}

/// The one selected-family store for the app process.
final DeferredSelectedFamilyStore sharedSelectedFamilyStore = DeferredSelectedFamilyStore(
  openDurableSelectedFamilyStore,
);
