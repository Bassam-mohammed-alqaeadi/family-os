import 'package:flutter/foundation.dart';

/// Tighten-only overlay facts emitted by Modes (MODE-OD-07 / MODE-OD-12).
///
/// Never mutates FS-002/003/004 permanent stores — Kernel / peers consume.
@immutable
final class ModeOverlay {
  const ModeOverlay({
    this.tightenAppAccess = false,
    this.tightenWebFilter = false,
    this.tightenCameraOs = false,
    this.tightenCapturePrevent = false,
    this.tightenProtectSurfaces = false,

    /// Forbidden: vacation/widen allow packages (rejected by MODE-OD-07).
    this.widenAllowedPackages = false,
  });

  final bool tightenAppAccess;
  final bool tightenWebFilter;
  final bool tightenCameraOs;
  final bool tightenCapturePrevent;
  final bool tightenProtectSurfaces;

  /// Always forced false — Vacation widen rejected.
  final bool widenAllowedPackages;

  /// Intersection / stricter composition across stacked Modes (MODE-OD-05).
  static ModeOverlay intersect(ModeOverlay a, ModeOverlay b) {
    return ModeOverlay(
      tightenAppAccess: a.tightenAppAccess || b.tightenAppAccess,
      tightenWebFilter: a.tightenWebFilter || b.tightenWebFilter,
      tightenCameraOs: a.tightenCameraOs || b.tightenCameraOs,
      tightenCapturePrevent: a.tightenCapturePrevent || b.tightenCapturePrevent,
      tightenProtectSurfaces:
          a.tightenProtectSurfaces || b.tightenProtectSurfaces,
      widenAllowedPackages: false,
    );
  }

  ModeOverlay asTightenOnly() {
    return ModeOverlay(
      tightenAppAccess: tightenAppAccess,
      tightenWebFilter: tightenWebFilter,
      tightenCameraOs: tightenCameraOs,
      tightenCapturePrevent: tightenCapturePrevent,
      tightenProtectSurfaces: tightenProtectSurfaces,
      widenAllowedPackages: false,
    );
  }

  static int clampGrace(int minutes) {
    if (minutes < 0) return 0;
    if (minutes > 5) return 5;
    return minutes;
  }

  Map<String, Object?> toJson() => {
    'tightenAppAccess': tightenAppAccess,
    'tightenWebFilter': tightenWebFilter,
    'tightenCameraOs': tightenCameraOs,
    'tightenCapturePrevent': tightenCapturePrevent,
    'tightenProtectSurfaces': tightenProtectSurfaces,
    'widenAllowedPackages': false,
  };

  factory ModeOverlay.fromJson(Map<String, Object?> json) {
    return ModeOverlay(
      tightenAppAccess: json['tightenAppAccess'] == true,
      tightenWebFilter: json['tightenWebFilter'] == true,
      tightenCameraOs: json['tightenCameraOs'] == true,
      tightenCapturePrevent: json['tightenCapturePrevent'] == true,
      tightenProtectSurfaces: json['tightenProtectSurfaces'] == true,
      widenAllowedPackages: false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModeOverlay &&
          other.tightenAppAccess == tightenAppAccess &&
          other.tightenWebFilter == tightenWebFilter &&
          other.tightenCameraOs == tightenCameraOs &&
          other.tightenCapturePrevent == tightenCapturePrevent &&
          other.tightenProtectSurfaces == tightenProtectSurfaces;

  @override
  int get hashCode => Object.hash(
    tightenAppAccess,
    tightenWebFilter,
    tightenCameraOs,
    tightenCapturePrevent,
    tightenProtectSurfaces,
  );
}

/// Protected reachability — Modes never gate these (MODE-OD-14).
abstract final class ModeProtectedReachability {
  static const bool sosReachable = true;
  static const bool requiredFamilyChatReachable = true;
  static const bool quranReachable = true;
}
