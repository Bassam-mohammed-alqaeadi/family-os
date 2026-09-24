import 'package:family_os/features/n17_child_learn/child_smart_tilawah_models.dart';

abstract class ChildSmartTilawahRepository {
  Future<ChildSmartTilawahSnapshot> load();
  Future<ChildSmartTilawahSnapshot> startListening();
  Future<ChildSmartTilawahSnapshot> playSheikh();
}

final class InMemoryChildSmartTilawahRepository
    implements ChildSmartTilawahRepository {
  InMemoryChildSmartTilawahRepository({ChildSmartTilawahSnapshot? seed})
    : _snap = seed ?? childSmartTilawahPrototypeFixture();

  ChildSmartTilawahSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildSmartTilawahSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildSmartTilawahSnapshot> startListening() async {
    _snap = _snap.copyWith(listening: true);
    return _snap.copyWith();
  }

  @override
  Future<ChildSmartTilawahSnapshot> playSheikh() async {
    _snap = _snap.copyWith(sheikhPlayed: true);
    return _snap.copyWith();
  }

  void seed(ChildSmartTilawahSnapshot snap) => _snap = snap;

  bool get listening => _snap.listening;
  bool get sheikhPlayed => _snap.sheikhPlayed;
}

final InMemoryChildSmartTilawahRepository stage1ChildSmartTilawahRepository =
    InMemoryChildSmartTilawahRepository();

ChildSmartTilawahSnapshot childSmartTilawahEmptyFixture() =>
    const ChildSmartTilawahSnapshot();

ChildSmartTilawahSnapshot childSmartTilawahOneFixture() {
  return const ChildSmartTilawahSnapshot(hasSession: true);
}

ChildSmartTilawahSnapshot childSmartTilawahPrototypeFixture() {
  return const ChildSmartTilawahSnapshot(
    hasSession: true,
    surahKey: 'mulk',
    ayahNumber: 16,
    ayahKey: 'mulk16',
  );
}
