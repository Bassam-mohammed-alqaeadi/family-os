import 'package:family_os/features/n02_day/child_arrival_models.dart';

abstract class ChildArrivalRepository {
  Future<ChildArrivalSnapshot> load();

  /// Stage-1 mock — records check-in; returns toast/nav payload via snapshot.
  Future<void> checkIn(String zoneId);
}

final class InMemoryChildArrivalRepository implements ChildArrivalRepository {
  InMemoryChildArrivalRepository({ChildArrivalSnapshot? seed})
    : _snap = seed ?? childArrivalPrototypeFixture();

  ChildArrivalSnapshot _snap;
  Future<void> Function()? loadGate;
  String? lastCheckInZoneId;

  @override
  Future<ChildArrivalSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildArrivalSnapshot(
      zones: List<ChildArrivalZone>.from(_snap.zones),
      liveLocationSafe: _snap.liveLocationSafe,
      liveLocationLabelKey: _snap.liveLocationLabelKey,
    );
  }

  @override
  Future<void> checkIn(String zoneId) async {
    lastCheckInZoneId = zoneId;
  }

  void seed(ChildArrivalSnapshot snap) => _snap = snap;
}

final InMemoryChildArrivalRepository stage1ChildArrivalRepository =
    InMemoryChildArrivalRepository();

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
