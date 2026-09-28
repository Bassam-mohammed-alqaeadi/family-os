import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/prefs_misc/kv_snapshot_store.dart';
import 'package:family_os/features/n02_day/child_arrival_models.dart';
import 'package:family_os/features/n02_day/child_arrival_repository.dart';

/// Durable arrival check-in journal via kv_store (CE-B1 / CE-G022).
///
/// Zones may be empty until configured; GPS remains NATIVE_CLOSED.
final class LocalChildArrivalRepository implements ChildArrivalRepository {
  LocalChildArrivalRepository(FamilyLocalDatabase db)
      : _store = KvSnapshotStore(db, namespace: kvNamespace);

  static const kvNamespace = 'child_arrival';

  final KvSnapshotStore _store;

  Future<ChildArrivalSnapshot> _read() async {
    final map = await _store.readMap();
    if (map == null) return childArrivalEmptyFixture();
    return ChildArrivalSnapshot.fromJson(map);
  }

  Future<void> _write(ChildArrivalSnapshot snap) =>
      _store.writeMap(snap.toJson());

  @override
  Future<ChildArrivalSnapshot> load() => _read();

  @override
  Future<void> checkIn(String zoneId) async {
    final snap = await _read();
    await _write(
      ChildArrivalSnapshot(
        zones: snap.zones,
        liveLocationSafe: snap.liveLocationSafe,
        liveLocationLabelKey: snap.liveLocationLabelKey,
        checkInJournal: [...snap.checkInJournal, zoneId],
      ),
    );
  }
}
