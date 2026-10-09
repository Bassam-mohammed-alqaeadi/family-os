import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/prefs_misc/kv_snapshot_store.dart';
import 'package:family_os/features/n02_day/child_media_share_models.dart';
import 'package:family_os/features/n02_day/child_media_share_repository.dart';

/// Durable media-share intent journal via kv_store (CE-B1 / CE-G021).
final class LocalChildMediaShareRepository
    implements ChildMediaShareRepository {
  LocalChildMediaShareRepository(FamilyLocalDatabase db)
    : _store = KvSnapshotStore(db, namespace: kvNamespace);

  static const kvNamespace = 'child_media_share';

  final KvSnapshotStore _store;

  Future<ChildMediaShareSnapshot> _read() async {
    final map = await _store.readMap();
    if (map == null) return childMediaShareEmptyFixture();
    return ChildMediaShareSnapshot.fromJson(map);
  }

  Future<void> _write(ChildMediaShareSnapshot snap) =>
      _store.writeMap(snap.toJson());

  @override
  Future<ChildMediaShareSnapshot> load() => _read();

  @override
  Future<void> queueShareIntent(ChildMediaShareType type) async {
    final snap = await _read();
    await _write(
      ChildMediaShareSnapshot(
        recentShares: snap.recentShares,
        intentJournal: [...snap.intentJournal, type.name],
      ),
    );
  }
}
