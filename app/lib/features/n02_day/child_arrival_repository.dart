import 'package:family_os/features/n02_day/child_arrival_models.dart';

abstract class ChildArrivalRepository {
  Future<ChildArrivalSnapshot> load();

  /// Local check-in journal — no fake GPS / FCM delivery.
  Future<void> checkIn(String zoneId);
}

final class InMemoryChildArrivalRepository implements ChildArrivalRepository {
  InMemoryChildArrivalRepository({ChildArrivalSnapshot? seed})
      : _snap = seed ?? childArrivalEmptyFixture();

  ChildArrivalSnapshot _snap;
  Future<void> Function()? loadGate;
  Object? loadError;
  String? lastCheckInZoneId;
  final List<String> checkInJournal = [];

  @override
  Future<ChildArrivalSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
    return ChildArrivalSnapshot(
      zones: List<ChildArrivalZone>.from(_snap.zones),
      liveLocationSafe: _snap.liveLocationSafe,
      liveLocationLabelKey: _snap.liveLocationLabelKey,
      checkInJournal: List<String>.from(_snap.checkInJournal),
    );
  }

  @override
  Future<void> checkIn(String zoneId) async {
    lastCheckInZoneId = zoneId;
    checkInJournal.add(zoneId);
    _snap = ChildArrivalSnapshot(
      zones: _snap.zones,
      liveLocationSafe: _snap.liveLocationSafe,
      liveLocationLabelKey: _snap.liveLocationLabelKey,
      checkInJournal: [..._snap.checkInJournal, zoneId],
    );
  }

  void seed(ChildArrivalSnapshot snap) => _snap = snap;
}

/// Shared Stage-1 — empty until Local bind / test seed (CE-B1 / CE-G022).
ChildArrivalRepository stage1ChildArrivalRepository =
    InMemoryChildArrivalRepository(seed: childArrivalEmptyFixture());

void rebindStage1ChildArrivalRepository(ChildArrivalRepository repository) {
  stage1ChildArrivalRepository = repository;
}

ChildArrivalSnapshot childArrivalEmptyFixture() => const ChildArrivalSnapshot();

ChildArrivalSnapshot childArrivalOneFixture() {
  return const ChildArrivalSnapshot(
    zones: [
      ChildArrivalZone(
        id: 'z1',
        nameKey: 'school',
        descKey: 'schoolDesc',
        iconKey: 'school',
      ),
    ],
  );
}

/// LOCAL_DEMO / tests only — not production stage1 default.
ChildArrivalSnapshot childArrivalPrototypeFixture() {
  return const ChildArrivalSnapshot(
    zones: [
      ChildArrivalZone(
        id: 'z1',
        nameKey: 'school',
        descKey: 'schoolDesc',
        iconKey: 'school',
      ),
      ChildArrivalZone(
        id: 'z2',
        nameKey: 'home',
        descKey: 'homeDesc',
        iconKey: 'home',
      ),
    ],
  );
}
