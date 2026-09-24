import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import '../domain/mother_level.dart';
import '../domain/role.dart';
import 'device_lock_state.dart';
import 'web_unlock_service.dart' show AuditAppend;

/// Surfaces always reachable while the device is locked (Rule 11 / SET-009).
const List<String> kDeviceLockExemptSurfaces = ['chat', 'quran', 'sos'];

/// Who issues a lock/unlock command (SET-009 / ADR-035).
@immutable
final class DeviceLockActor {
  const DeviceLockActor.father()
      : role = AppRole.father,
        motherLevel = null;

  const DeviceLockActor.mother(this.motherLevel) : role = AppRole.mother;

  final AppRole role;
  final MotherLevel? motherLevel;

  /// Father always; mother only at FULL (observer/partner denied).
  bool get canLock {
    if (role == AppRole.father) return true;
    if (role == AppRole.mother) return motherLevel == MotherLevel.full;
    return false;
  }

  /// Father always; mother FULL may unlock only a mother-owned lock.
  bool canUnlock(DeviceLockState state) {
    if (role == AppRole.father) return true;
    if (role == AppRole.mother && motherLevel == MotherLevel.full) {
      return state.locked && state.lockedBy == DeviceLockedBy.mother;
    }
    return false;
  }

  String get auditLabel {
    if (role == AppRole.father) return 'father';
    if (role == AppRole.mother) {
      return 'mother:${motherLevel?.name ?? 'unknown'}';
    }
    return role.name;
  }

  DeviceLockedBy get asLockedBy =>
      role == AppRole.father ? DeviceLockedBy.father : DeviceLockedBy.mother;
}

/// Result of [DeviceLockService.lock] / [DeviceLockService.unlock].
@immutable
sealed class DeviceLockCommandResult {
  const DeviceLockCommandResult();
}

final class DeviceLockCommandOk extends DeviceLockCommandResult {
  const DeviceLockCommandOk(
    this.state, {
    this.superseded = false,
  });

  final DeviceLockState state;
  final bool superseded;
}

final class DeviceLockCommandDenied extends DeviceLockCommandResult {
  const DeviceLockCommandDenied(this.reason);

  final String reason;
}

/// Mother-facing supersession notice (father unlocked after mother lock).
@immutable
final class DeviceLockSupersessionEvent {
  const DeviceLockSupersessionEvent({
    required this.childId,
    required this.at,
  });

  final ChildId childId;
  final DateTime at;
}

/// Same-process bus so mother UI can show a supersession banner (P12).
final class DeviceLockNotifyBus extends ChangeNotifier {
  DeviceLockSupersessionEvent? _last;

  DeviceLockSupersessionEvent? get lastSupersession => _last;

  final List<DeviceLockSupersessionEvent> delivered = [];

  void publish(DeviceLockSupersessionEvent event) {
    _last = event;
    delivered.add(event);
    notifyListeners();
  }

  void clear() {
    _last = null;
  }
}

/// String KV used by [PrefsDeviceLockStore].
abstract class DeviceLockPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across instances to simulate restart.
final class MemoryDeviceLockPrefsStore implements DeviceLockPrefsStore {
  MemoryDeviceLockPrefsStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Stage-1 shared prefs / audit / notify (Rule 25 seam).
DeviceLockPrefsStore stage1DeviceLockPrefsStore = MemoryDeviceLockPrefsStore();
final AuditAppend stage1DeviceLockAudit = AuditAppend();
final DeviceLockNotifyBus stage1DeviceLockNotifyBus = DeviceLockNotifyBus();

/// Instant lock service (SET-009 / ADR-035) — Prefs mock, no Device Admin API.
///
/// Father always supersedes mother lock/unlock. Mother FULL may lock; observer
/// and partner are denied.
final class DeviceLockService extends ChangeNotifier {
  DeviceLockService({
    DeviceLockPrefsStore? store,
    AuditAppend? audit,
    DeviceLockNotifyBus? notifyBus,
    DateTime Function()? clock,
    Map<String, DeviceLockState>? memorySeed,
  })  : _store = store ?? MemoryDeviceLockPrefsStore(),
        _audit = audit ?? AuditAppend(),
        _bus = notifyBus ?? DeviceLockNotifyBus(),
        _clock = clock ?? DateTime.now,
        _memoryOnly = memorySeed != null,
        _memory = memorySeed ?? {};

  /// Pure in-memory alternate (no prefs) for unit tests.
  factory DeviceLockService.inMemory({
    Map<String, DeviceLockState>? seed,
    AuditAppend? audit,
    DeviceLockNotifyBus? notifyBus,
    DateTime Function()? clock,
  }) {
    return DeviceLockService(
      audit: audit,
      notifyBus: notifyBus,
      clock: clock,
      memorySeed: seed ?? {},
    );
  }

  final DeviceLockPrefsStore _store;
  final AuditAppend _audit;
  final DeviceLockNotifyBus _bus;
  final DateTime Function() _clock;
  final bool _memoryOnly;
  final Map<String, DeviceLockState> _memory;

  AuditAppend get audit => _audit;
  DeviceLockNotifyBus get notifyBus => _bus;

  static String _key(ChildId childId) => 'device_lock_state:${childId.value}';

  /// True when [surface] is chat / quran / sos (always reachable while locked).
  bool isExempt(String surface) {
    final normalized = surface.trim().toLowerCase();
    return kDeviceLockExemptSurfaces.contains(normalized);
  }

  /// Reachable when unlocked, or when locked but [surface] is exempt.
  bool isSurfaceReachable(String surface, {required bool locked}) {
    if (!locked) return true;
    return isExempt(surface);
  }

  Future<DeviceLockState> load(ChildId childId) async {
    if (_memoryOnly) {
      return _memory[childId.value] ??
          DeviceLockState.unlocked(childId, at: _clock().toUtc());
    }
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      final unlocked = DeviceLockState.unlocked(childId, at: _clock().toUtc());
      _memory[childId.value] = unlocked;
      return unlocked;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      final unlocked = DeviceLockState.unlocked(childId, at: _clock().toUtc());
      _memory[childId.value] = unlocked;
      return unlocked;
    }
    final state = DeviceLockState.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
    _memory[childId.value] = state;
    return state;
  }

  Future<DeviceLockCommandResult> lock(
    ChildId childId,
    DeviceLockActor actor,
  ) async {
    if (!actor.canLock) {
      _audit.add(
        'DENIED device_lock lock actor=${actor.auditLabel} '
        'child=${childId.value}',
      );
      return DeviceLockCommandDenied(
        'lock denied for ${actor.auditLabel}',
      );
    }

    final previous = await load(childId);
    final now = _clock().toUtc();

    // Concurrent / sequential: father command always wins ownership.
    final next = DeviceLockState(
      childId: childId,
      locked: true,
      lockedBy: actor.asLockedBy,
      updatedAt: now,
    );
    await _persist(next);

    _audit.add(
      'LOCK actor=${actor.auditLabel} child=${childId.value} '
      'lockedBy=${next.lockedBy!.name}',
    );

    if (actor.role == AppRole.father &&
        previous.locked &&
        previous.lockedBy == DeviceLockedBy.mother) {
      _audit.add(
        'SUPERSESSION father lock overrides mother lock '
        'child=${childId.value}',
      );
    }

    notifyListeners();
    return DeviceLockCommandOk(next);
  }

  Future<DeviceLockCommandResult> unlock(
    ChildId childId,
    DeviceLockActor actor,
  ) async {
    final previous = await load(childId);
    if (!previous.locked) {
      return DeviceLockCommandOk(previous);
    }

    if (!actor.canUnlock(previous)) {
      _audit.add(
        'DENIED device_lock unlock actor=${actor.auditLabel} '
        'child=${childId.value} lockedBy=${previous.lockedBy?.name}',
      );
      return DeviceLockCommandDenied(
        'unlock denied for ${actor.auditLabel}',
      );
    }

    final now = _clock().toUtc();
    final next = DeviceLockState.unlocked(childId, at: now);
    await _persist(next);

    final motherLocked =
        previous.lockedBy == DeviceLockedBy.mother && actor.role == AppRole.father;

    _audit.add(
      'UNLOCK actor=${actor.auditLabel} child=${childId.value}',
    );

    if (motherLocked) {
      _audit.add(
        'SUPERSESSION father unlock supersedes mother lock '
        'child=${childId.value}',
      );
      _bus.publish(
        DeviceLockSupersessionEvent(childId: childId, at: now),
      );
    }

    notifyListeners();
    return DeviceLockCommandOk(next, superseded: motherLocked);
  }

  Future<void> _persist(DeviceLockState state) async {
    _memory[state.childId.value] = state;
    if (_memoryOnly) return;
    await _store.write(_key(state.childId), jsonEncode(state.toJson()));
  }
}
