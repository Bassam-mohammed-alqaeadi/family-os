import 'package:family_os/features/n17_child_learn/child_coming_gifts_models.dart';

abstract class ChildComingGiftsRepository {
  Future<ChildComingGiftsSnapshot> load();
}

final class InMemoryChildComingGiftsRepository
    implements ChildComingGiftsRepository {
  InMemoryChildComingGiftsRepository({ChildComingGiftsSnapshot? seed})
    : _snap = seed ?? childComingGiftsPrototypeFixture();

  ChildComingGiftsSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildComingGiftsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildComingGiftsSnapshot(
      ready: _snap.ready,
      links: List<ChildComingLink>.from(_snap.links),
    );
  }

  void seed(ChildComingGiftsSnapshot snap) => _snap = snap;
}

final InMemoryChildComingGiftsRepository stage1ChildComingGiftsRepository =
    InMemoryChildComingGiftsRepository();

ChildComingGiftsSnapshot childComingGiftsEmptyFixture() =>
    const ChildComingGiftsSnapshot();

ChildComingGiftsSnapshot childComingGiftsOneFixture() {
  return const ChildComingGiftsSnapshot(
    ready: true,
    links: [
      ChildComingLink(
        id: 'stories',
        titleKey: 'stories',
        subKey: 'storiesSub',
        navigateTo: 'SCR-CHD-033',
      ),
    ],
  );
}

ChildComingGiftsSnapshot childComingGiftsPrototypeFixture() {
  return const ChildComingGiftsSnapshot(
    ready: true,
    links: [
      ChildComingLink(
        id: 'callPlay',
        titleKey: 'callPlay',
        subKey: 'callPlaySub',
        navigateTo: 'SCR-CHD-036',
      ),
      ChildComingLink(
        id: 'challenges',
        titleKey: 'challenges',
        subKey: 'challengesSub',
        navigateTo: 'SCR-CHD-034',
      ),
      ChildComingLink(
        id: 'stories',
        titleKey: 'stories',
        subKey: 'storiesSub',
        navigateTo: 'SCR-CHD-033',
      ),
      ChildComingLink(
        id: 'sounds',
        titleKey: 'sounds',
        subKey: 'soundsSub',
        navigateTo: 'SCR-CHD-035',
      ),
      ChildComingLink(
        id: 'stickers',
        titleKey: 'stickers',
        subKey: 'stickersSub',
        navigateTo: 'SCR-CHD-037',
      ),
      ChildComingLink(
        id: 'smartTilawa',
        titleKey: 'smartTilawa',
        subKey: 'smartTilawaSub',
        navigateTo: 'SCR-CHD-032',
      ),
    ],
  );
}
