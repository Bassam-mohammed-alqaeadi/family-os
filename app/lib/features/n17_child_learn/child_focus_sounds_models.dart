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

  Map<String, Object?> toJson() => {
        'id': id,
        'labelKey': labelKey,
        'emoji': emoji,
        'toastKey': toastKey,
      };

  static FocusSoundOption fromJson(Map<String, Object?> json) {
    return FocusSoundOption(
      id: json['id']?.toString() ?? '',
      labelKey: json['labelKey']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
      toastKey: json['toastKey']?.toString() ?? '',
    );
  }
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
    bool? hasSounds,
    List<FocusSoundOption>? sounds,
  }) {
    return ChildFocusSoundsSnapshot(
      hasSounds: hasSounds ?? this.hasSounds,
      sounds: List<FocusSoundOption>.from(sounds ?? this.sounds),
      activeSoundId: clearActive ? null : (activeSoundId ?? this.activeSoundId),
      autoWithFocus: autoWithFocus ?? this.autoWithFocus,
      fadeLastTwoMinutes: fadeLastTwoMinutes ?? this.fadeLastTwoMinutes,
    );
  }

  /// Prefs-only payload (catalog is static fixture).
  Map<String, Object?> prefsToJson() => {
        'activeSoundId': activeSoundId,
        'autoWithFocus': autoWithFocus,
        'fadeLastTwoMinutes': fadeLastTwoMinutes,
      };

  static ChildFocusSoundsSnapshot prefsFromJson(
    Map<String, Object?> json, {
    required List<FocusSoundOption> catalog,
  }) {
    return ChildFocusSoundsSnapshot(
      hasSounds: catalog.isNotEmpty,
      sounds: catalog,
      activeSoundId: json['activeSoundId']?.toString(),
      autoWithFocus: json['autoWithFocus'] != false,
      fadeLastTwoMinutes: json['fadeLastTwoMinutes'] != false,
    );
  }
}
