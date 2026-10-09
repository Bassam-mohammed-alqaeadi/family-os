import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/prefs_misc/kv_snapshot_store.dart';
import 'package:family_os/features/n15_calendar/family_calendar_models.dart';
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';

/// Durable Family Calendar via kv_store (CE-B1 / CE-G016–017).
final class LocalFamilyCalendarRepository implements FamilyCalendarRepository {
  LocalFamilyCalendarRepository(FamilyLocalDatabase db)
    : _store = KvSnapshotStore(db, namespace: kvNamespace);

  static const kvNamespace = 'family_calendar';

  final KvSnapshotStore _store;

  Future<FamilyCalendarSnapshot> _read() async {
    final map = await _store.readMap();
    if (map == null) return familyCalendarEmptyFixture();
    return FamilyCalendarSnapshot.fromJson(map);
  }

  Future<void> _write(FamilyCalendarSnapshot snap) =>
      _store.writeMap(snap.toJson());

  @override
  Future<FamilyCalendarSnapshot> load() => _read();

  @override
  Future<void> addEvent(FamilyCalendarEvent event) async {
    final snap = await _read();
    await _write(snap.withEvents([...snap.events, event]));
  }

  /// LDR-B3 — one school + one family event when empty.
  Future<void> ensureRealLocalSeeded() async {
    final snap = await _read();
    if (!snap.isEmpty) return;
    final today = snap.month.todayDay;
    await _write(
      snap.withEvents([
        FamilyCalendarEvent(
          id: 'cal_quran_real_local',
          titleKey: 'quranTest',
          whenKey: 'today',
          day: today,
          category: FamilyCalendarEventCategory.sch,
          whoNameKey: 'one',
          colorKey: 'sky',
        ),
        FamilyCalendarEvent(
          id: 'cal_dinner_real_local',
          titleKey: 'grandpaDinner',
          whenKey: 'evening',
          day: today < snap.month.daysInMonth ? today + 1 : today,
          category: FamilyCalendarEventCategory.occ,
          whoNameKey: 'everyone',
          colorKey: 'amber',
        ),
      ]),
    );
  }
}
