import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/device_lock_state.dart';
import 'package:family_os/core/policy/web_unlock_service.dart' show AuditAppend;

void main() {
  final child = ChildId('lock-child-1');

  group('DeviceLockService SET-009', () {
    late AuditAppend audit;
    late DeviceLockNotifyBus bus;
    late DeviceLockService service;

    setUp(() {
      audit = AuditAppend();
      bus = DeviceLockNotifyBus();
      service = DeviceLockService.inMemory(
        audit: audit,
        notifyBus: bus,
      );
    });

    tearDown(() {
      bus.dispose();
    });

    test('mother FULL lock then father unlock → unlocked + supersession audit',
        () async {
      final motherLock = await service.lock(
        child,
        const DeviceLockActor.mother(MotherLevel.full),
      );
      expect(motherLock, isA<DeviceLockCommandOk>());
      final locked = (motherLock as DeviceLockCommandOk).state;
      expect(locked.locked, isTrue);
      expect(locked.lockedBy, DeviceLockedBy.mother);

      final fatherUnlock = await service.unlock(
        child,
        const DeviceLockActor.father(),
      );
      expect(fatherUnlock, isA<DeviceLockCommandOk>());
      final ok = fatherUnlock as DeviceLockCommandOk;
      expect(ok.state.locked, isFalse);
      expect(ok.state.lockedBy, isNull);
      expect(ok.superseded, isTrue);

      expect(audit.entries.length, greaterThanOrEqualTo(2));
      expect(
        audit.entries.any((e) => e.startsWith('LOCK actor=mother:full')),
        isTrue,
      );
      expect(
        audit.entries.any((e) => e.contains('SUPERSESSION')),
        isTrue,
      );
      expect(bus.delivered, hasLength(1));
      expect(bus.delivered.single.childId, child);
    });

    test('mother observer cannot lock', () async {
      final result = await service.lock(
        child,
        const DeviceLockActor.mother(MotherLevel.observer),
      );
      expect(result, isA<DeviceLockCommandDenied>());
      final state = await service.load(child);
      expect(state.locked, isFalse);
      expect(audit.entries.any((e) => e.startsWith('DENIED')), isTrue);
    });

    test('mother partner cannot lock', () async {
      final result = await service.lock(
        child,
        const DeviceLockActor.mother(MotherLevel.partner),
      );
      expect(result, isA<DeviceLockCommandDenied>());
      final state = await service.load(child);
      expect(state.locked, isFalse);
    });

    test('exempt chat/quran/sos reachable while locked', () async {
      await service.lock(child, const DeviceLockActor.father());
      expect(service.isExempt('chat'), isTrue);
      expect(service.isExempt('quran'), isTrue);
      expect(service.isExempt('sos'), isTrue);
      expect(service.isExempt('CHATS'), isFalse);
      expect(service.isSurfaceReachable('chat', locked: true), isTrue);
      expect(service.isSurfaceReachable('quran', locked: true), isTrue);
      expect(service.isSurfaceReachable('sos', locked: true), isTrue);
      expect(service.isSurfaceReachable('youtube', locked: true), isFalse);
      expect(service.isSurfaceReachable('youtube', locked: false), isTrue);
      expect(kDeviceLockExemptSurfaces, containsAll(['chat', 'quran', 'sos']));
    });

    test('father lock after mother lock wins ownership', () async {
      await service.lock(
        child,
        const DeviceLockActor.mother(MotherLevel.full),
      );
      final result = await service.lock(child, const DeviceLockActor.father());
      expect(result, isA<DeviceLockCommandOk>());
      final state = (result as DeviceLockCommandOk).state;
      expect(state.locked, isTrue);
      expect(state.lockedBy, DeviceLockedBy.father);
      expect(
        audit.entries.any((e) => e.contains('SUPERSESSION')),
        isTrue,
      );
    });

    test('mother cannot unlock father lock', () async {
      await service.lock(child, const DeviceLockActor.father());
      final result = await service.unlock(
        child,
        const DeviceLockActor.mother(MotherLevel.full),
      );
      expect(result, isA<DeviceLockCommandDenied>());
      final state = await service.load(child);
      expect(state.locked, isTrue);
      expect(state.lockedBy, DeviceLockedBy.father);
    });

    test('prefs persist lock state across service reopen', () async {
      final shared = <String, String>{};
      final first = DeviceLockService(
        store: MemoryDeviceLockPrefsStore(shared),
        audit: AuditAppend(),
        notifyBus: DeviceLockNotifyBus(),
      );
      await first.lock(child, const DeviceLockActor.father());

      final second = DeviceLockService(
        store: MemoryDeviceLockPrefsStore(shared),
        audit: AuditAppend(),
        notifyBus: DeviceLockNotifyBus(),
      );
      final loaded = await second.load(child);
      expect(loaded.locked, isTrue);
      expect(loaded.lockedBy, DeviceLockedBy.father);
    });
  });
}
