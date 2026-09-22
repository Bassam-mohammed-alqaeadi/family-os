import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';

/// Local device profile for SCR-SHR-008 (dual-mode shared device).
///
/// Values come from the repo — never planted in widgets (Rule 23).
@immutable
final class DeviceUserProfile {
  const DeviceUserProfile({
    required this.id,
    required this.displayName,
    required this.role,
    required this.monogram,
    this.motherLevel,
    this.avatarColorHex,
  });

  final String id;
  final String displayName;
  final AppRole role;

  /// Single-letter avatar glyph from the repo.
  final String monogram;

  /// Mother permission level — null unless [role] is [AppRole.mother].
  final MotherLevel? motherLevel;

  /// Optional avatar fill (e.g. `#FF8FA3`) — null → role default in UI.
  final String? avatarColorHex;
}

/// Rule 25 seam — local profiles on this device (no cloud account switch).
abstract class DeviceUserSwitchRepository {
  Future<List<DeviceUserProfile>> listProfiles();
}

/// In-memory mock — default empty (Rule 23 · never plants person names).
final class InMemoryDeviceUserSwitchRepository
    implements DeviceUserSwitchRepository {
  InMemoryDeviceUserSwitchRepository({
    List<DeviceUserProfile> profiles = const [],
    this.failLoad = false,
  }) : _profiles = List.of(profiles);

  List<DeviceUserProfile> _profiles;

  /// Test seam — next [listProfiles] throws.
  bool failLoad;

  void seed(List<DeviceUserProfile> profiles) =>
      _profiles = List.of(profiles);

  @override
  Future<List<DeviceUserProfile>> listProfiles() async {
    if (failLoad) {
      throw StateError('mock device user profiles load failure');
    }
    return List.unmodifiable(_profiles);
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1DeviceUserSwitchRepository = InMemoryDeviceUserSwitchRepository();
