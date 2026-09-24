import 'package:flutter/foundation.dart';

@immutable
final class FocusSoundOption {
  const FocusSoundOption({
    required this.id,
    required this.labelKey,
    required this.emoji,
    required this.toastKey,
  });

  final String id;
  final String labelKey;
  final String emoji;
  final String toastKey;
}

@immutable
final class ChildFocusSoundsSnapshot {
  const ChildFocusSoundsSnapshot({
    this.hasSounds = false,
    this.sounds = const [],
    this.activeSoundId,
    this.autoWithFocus = true,
    this.fadeLastTwoMinutes = true,
  });

  final bool hasSounds;
  final List<FocusSoundOption> sounds;
  final String? activeSoundId;
  final bool autoWithFocus;
  final bool fadeLastTwoMinutes;

  bool get isEmpty => !hasSounds;

  ChildFocusSoundsSnapshot copyWith({
    String? activeSoundId,
    bool clearActive = false,
    bool? autoWithFocus,
    bool? fadeLastTwoMinutes,
  }) {
    return ChildFocusSoundsSnapshot(
      hasSounds: hasSounds,
      sounds: List<FocusSoundOption>.from(sounds),
      activeSoundId: clearActive ? null : (activeSoundId ?? this.activeSoundId),
      autoWithFocus: autoWithFocus ?? this.autoWithFocus,
      fadeLastTwoMinutes: fadeLastTwoMinutes ?? this.fadeLastTwoMinutes,
    );
  }
}
