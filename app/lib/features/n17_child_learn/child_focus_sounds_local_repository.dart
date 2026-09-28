import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/prefs_misc/kv_snapshot_store.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_models.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_repository.dart';

/// Durable focus-sound prefs via kv_store (CE-B1 / CE-G023).
///
/// Sound catalog is static fixture; only selection/toggles persist.
final class LocalChildFocusSoundsRepository
    implements ChildFocusSoundsRepository {
  LocalChildFocusSoundsRepository(
    FamilyLocalDatabase db, {
    List<FocusSoundOption> catalog = focusSoundsCatalog,
  })  : _store = KvSnapshotStore(db, namespace: kvNamespace),
        _catalog = catalog;

  static const kvNamespace = 'child_focus_sounds';

  final KvSnapshotStore _store;
  final List<FocusSoundOption> _catalog;

  Future<ChildFocusSoundsSnapshot> _read() async {
    final map = await _store.readMap();
    if (map == null) {
      return ChildFocusSoundsSnapshot(
        hasSounds: _catalog.isNotEmpty,
        sounds: _catalog,
      );
    }
    return ChildFocusSoundsSnapshot.prefsFromJson(map, catalog: _catalog);
  }

  Future<void> _writePrefs(ChildFocusSoundsSnapshot snap) =>
      _store.writeMap(snap.prefsToJson());

  @override
  Future<ChildFocusSoundsSnapshot> load() => _read();

  @override
  Future<ChildFocusSoundsSnapshot> playSound(String id) async {
    final snap = (await _read()).copyWith(activeSoundId: id);
    await _writePrefs(snap);
    return snap;
  }

  @override
  Future<ChildFocusSoundsSnapshot> setAutoWithFocus(bool value) async {
    final snap = (await _read()).copyWith(autoWithFocus: value);
    await _writePrefs(snap);
    return snap;
  }

  @override
  Future<ChildFocusSoundsSnapshot> setFadeLastTwo(bool value) async {
    final snap = (await _read()).copyWith(fadeLastTwoMinutes: value);
    await _writePrefs(snap);
    return snap;
  }
}
