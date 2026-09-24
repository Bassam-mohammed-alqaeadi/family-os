import 'package:flutter/foundation.dart';

@immutable
final class ChildFocusSnapshot {
  const ChildFocusSnapshot({
    this.sessionMinutes = 25,
    this.praiseMessageKey,
    this.sessionActive = false,
    this.soundsScreenId = 'SCR-CHD-035',
  });

  /// Focus session length — gift time, never deducted from play (S-EDU-044).
  final int sessionMinutes;

  /// ARB discriminator for parent praise quote. Banner when non-null.
  final String? praiseMessageKey;

  final bool sessionActive;

  /// Secondary CTA destination (calm sounds).
  final String soundsScreenId;

  bool get isEmpty => sessionMinutes <= 0;

  ChildFocusSnapshot copyWith({
    int? sessionMinutes,
    String? praiseMessageKey,
    bool clearPraise = false,
    bool? sessionActive,
    String? soundsScreenId,
  }) {
    return ChildFocusSnapshot(
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      praiseMessageKey: clearPraise
          ? null
          : (praiseMessageKey ?? this.praiseMessageKey),
      sessionActive: sessionActive ?? this.sessionActive,
      soundsScreenId: soundsScreenId ?? this.soundsScreenId,
    );
  }
}
