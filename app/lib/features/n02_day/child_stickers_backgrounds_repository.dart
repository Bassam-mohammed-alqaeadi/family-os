import 'package:family_os/features/n02_day/child_stickers_backgrounds_models.dart';

abstract class ChildStickersBackgroundsRepository {
  Future<ChildStickersBackgroundsSnapshot> load();
  Future<ChildStickersBackgroundsSnapshot> selectBackground(String id);
  Future<void> remindSpaceUnlock();
}

final class InMemoryChildStickersBackgroundsRepository
    implements ChildStickersBackgroundsRepository {
  InMemoryChildStickersBackgroundsRepository({
    ChildStickersBackgroundsSnapshot? seed,
  }) : _snap = seed ?? childStickersBackgroundsPrototypeFixture();

  ChildStickersBackgroundsSnapshot _snap;
  Future<void> Function()? loadGate;
  var remindTapped = false;

  @override
  Future<ChildStickersBackgroundsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildStickersBackgroundsSnapshot> selectBackground(String id) async {
    _snap = _snap.copyWith(selectedBackgroundId: id);
    return _snap.copyWith();
  }

  @override
  Future<void> remindSpaceUnlock() async {
    remindTapped = true;
  }

  void seed(ChildStickersBackgroundsSnapshot snap) => _snap = snap;

  String? get selectedBackgroundId => _snap.selectedBackgroundId;
}

final InMemoryChildStickersBackgroundsRepository
stage1ChildStickersBackgroundsRepository =
    InMemoryChildStickersBackgroundsRepository();

ChildStickersBackgroundsSnapshot childStickersBackgroundsEmptyFixture() =>
    const ChildStickersBackgroundsSnapshot();

ChildStickersBackgroundsSnapshot childStickersBackgroundsOneFixture() {
  return const ChildStickersBackgroundsSnapshot(
    hasPack: true,
    stickers: [ChildStickerItem(id: 'lion', emoji: '🦁')],
    backgrounds: [
      ChildChatBackground(id: 'teal', colorA: 0xFF00BFA5, colorB: 0xFF00796B),
    ],
    selectedBackgroundId: 'teal',
  );
}

ChildStickersBackgroundsSnapshot childStickersBackgroundsPrototypeFixture() {
  return const ChildStickersBackgroundsSnapshot(
    hasPack: true,
    stickers: [
      ChildStickerItem(id: 'lion', emoji: '🦁'),
      ChildStickerItem(id: 'laugh', emoji: '😂'),
      ChildStickerItem(id: 'star', emoji: '🌟'),
      ChildStickerItem(id: 'flex', emoji: '💪'),
      ChildStickerItem(id: 'trophy', emoji: '🏆'),
      ChildStickerItem(id: 'mosque', emoji: '🕌'),
      ChildStickerItem(id: 'ball', emoji: '⚽'),
      ChildStickerItem(id: 'pizza', emoji: '🍕'),
      ChildStickerItem(id: 'lock1', emoji: '🔒', locked: true),
      ChildStickerItem(id: 'lock2', emoji: '🔒', locked: true),
    ],
    backgrounds: [
      ChildChatBackground(id: 'teal', colorA: 0xFF00BFA5, colorB: 0xFF00796B),
      ChildChatBackground(id: 'indigo', colorA: 0xFF5C6BC0, colorB: 0xFF3949AB),
      ChildChatBackground(id: 'amber', colorA: 0xFFFFB74D, colorB: 0xFFF57C00),
    ],
    selectedBackgroundId: 'teal',
    wardsRemaining: 1,
  );
}
