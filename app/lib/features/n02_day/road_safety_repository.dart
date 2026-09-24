import 'package:family_os/features/n02_day/road_safety_models.dart';

abstract class RoadSafetyRepository {
  Future<RoadSafetySnapshot> load();
  Future<RoadSafetySnapshot> setCrashDetection(bool value);
  Future<RoadSafetySnapshot> setPhoneWhileDriving(bool value);
}

final class InMemoryRoadSafetyRepository implements RoadSafetyRepository {
  InMemoryRoadSafetyRepository({RoadSafetySnapshot? seed})
    : _snap = seed ?? roadSafetyPrototypeFixture();

  RoadSafetySnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<RoadSafetySnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<RoadSafetySnapshot> setCrashDetection(bool value) async {
    _snap = _snap.copyWith(crashDetection: value);
    return _snap.copyWith();
  }

  @override
  Future<RoadSafetySnapshot> setPhoneWhileDriving(bool value) async {
    _snap = _snap.copyWith(phoneWhileDriving: value);
    return _snap.copyWith();
  }

  void seed(RoadSafetySnapshot snap) => _snap = snap;
}

final InMemoryRoadSafetyRepository stage1RoadSafetyRepository =
    InMemoryRoadSafetyRepository();

RoadSafetySnapshot roadSafetyEmptyFixture() => const RoadSafetySnapshot();

RoadSafetySnapshot roadSafetyOneFixture() {
  return const RoadSafetySnapshot(hasFamily: true, hardBrakes: 0);
}

RoadSafetySnapshot roadSafetyPrototypeFixture() {
  return const RoadSafetySnapshot(hasFamily: true);
}
