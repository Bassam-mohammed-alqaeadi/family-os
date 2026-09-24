import 'package:flutter/foundation.dart';

@immutable
final class ChildStickerItem {
  const ChildStickerItem({
    required this.id,
    required this.emoji,
    this.locked = false,
  });

  final String id;
  final String emoji;
  final bool locked;
}

@immutable
final class ChildChatBackground {
  const ChildChatBackground({
    required this.id,
    required this.colorA,
    required this.colorB,
  });

  final String id;
  final int colorA;
  final int colorB;
}

@immutable
final class ChildStickersBackgroundsSnapshot {
  const ChildStickersBackgroundsSnapshot({
    this.hasPack = false,
    this.stickers = const [],
    this.backgrounds = const [],
    this.selectedBackgroundId,
    this.wardsRemaining = 1,
  });

  final bool hasPack;
  final List<ChildStickerItem> stickers;
  final List<ChildChatBackground> backgrounds;
  final String? selectedBackgroundId;
  final int wardsRemaining;

  bool get isEmpty => !hasPack;

  ChildStickersBackgroundsSnapshot copyWith({String? selectedBackgroundId}) {
    return ChildStickersBackgroundsSnapshot(
      hasPack: hasPack,
      stickers: List<ChildStickerItem>.from(stickers),
      backgrounds: List<ChildChatBackground>.from(backgrounds),
      selectedBackgroundId: selectedBackgroundId ?? this.selectedBackgroundId,
      wardsRemaining: wardsRemaining,
    );
  }
}
