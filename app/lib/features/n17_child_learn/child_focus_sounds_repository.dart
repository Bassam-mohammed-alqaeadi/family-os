import 'package:family_os/features/n17_child_learn/child_focus_sounds_models.dart';

abstract class ChildFocusSoundsRepository {
  Future<ChildFocusSoundsSnapshot> load();
  Future<ChildFocusSoundsSnapshot> playSound(String id);
  Future<ChildFocusSoundsSnapshot> setAutoWithFocus(bool value);
  Future<ChildFocusSoundsSnapshot> setFadeLastTwo(bool value);
}

final class InMemoryChildFocusSoundsRepository
    implements ChildFocusSoundsRepository {
  InMemoryChildFocusSoundsRepository({ChildFocusSoundsSnapshot? seed})
      : _snap = seed ?? childFocusSoundsEmptyFixture();

  ChildFocusSoundsSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildFocusSoundsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildFocusSoundsSnapshot> playSound(String id) async {
    _snap = _snap.copyWith(activeSoundId: id);
    return _snap.copyWith();
  }

  @override
  Future<ChildFocusSoundsSnapshot> setAutoWithFocus(bool value) async {
    _snap = _snap.copyWith(autoWithFocus: value);
    return _snap.copyWith();
  }

  @override
  Future<ChildFocusSoundsSnapshot> setFadeLastTwo(bool value) async {
    _snap = _snap.copyWith(fadeLastTwoMinutes: value);
    return _snap.copyWith();
  }

  void seed(ChildFocusSoundsSnapshot snap) => _snap = snap;

  String? get activeSoundId => _snap.activeSoundId;
  bool get autoWithFocus => _snap.autoWithFocus;
  bool get fadeLastTwoMinutes => _snap.fadeLastTwoMinutes;
}

/// Shared Stage-1 — empty until Local bind / test seed (CE-B1 / CE-G023).
ChildFocusSoundsRepository stage1ChildFocusSoundsRepository =
    InMemoryChildFocusSoundsRepository(seed: childFocusSoundsEmptyFixture());

void rebindStage1ChildFocusSoundsRepository(
  ChildFocusSoundsRepository repository,
) {
  stage1ChildFocusSoundsRepository = repository;
}

const focusSoundsCatalog = [
  FocusSoundOption(
    id: 'rain',
    labelKey: 'rain',
    emoji: '🌧',
    toastKey: 'toastRain',
  ),
  FocusSoundOption(
    id: 'waves',
    labelKey: 'waves',
    emoji: '🌊',
    toastKey: 'toastWaves',
  ),
  FocusSoundOption(
    id: 'forest',
    labelKey: 'forest',
    emoji: '🍃',
    toastKey: 'toastForest',
  ),
  FocusSoundOption(
    id: 'fire',
    labelKey: 'fire',
    emoji: '🔥',
    toastKey: 'toastFire',
  ),
];

ChildFocusSoundsSnapshot childFocusSoundsEmptyFixture() =>
    const ChildFocusSoundsSnapshot();

ChildFocusSoundsSnapshot childFocusSoundsOneFixture() {
  return const ChildFocusSoundsSnapshot(
    hasSounds: true,
    sounds: [
      FocusSoundOption(
        id: 'rain',
        labelKey: 'rain',
        emoji: '🌧',
        toastKey: 'toastRain',
      ),
    ],
  );
}

/// LOCAL_DEMO / tests — catalog present; prefs default unset.
ChildFocusSoundsSnapshot childFocusSoundsPrototypeFixture() {
  return const ChildFocusSoundsSnapshot(
    hasSounds: true,
    sounds: focusSoundsCatalog,
  );
}
