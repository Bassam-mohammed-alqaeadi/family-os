import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:family_os/core/events/local_event_emitter.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart';

/// EVT-01-B — bridge PolicySyncBus + AuditAppend → Local Event Journal.
///
/// Local journal/enqueue ≠ remote transport ≠ remote delivery.
abstract final class LocalEventPolicyBridge {
  LocalEventPolicyBridge._();

  static var _bound = false;

  static bool get isBound => _bound;

  /// Soft bind from [main] — never throws.
  static Future<void> tryBind() async {
    if (_bound) return;
    try {
      await FsSessionKernel.ensureOpen();
      if (FsSessionKernel.sqliteFallbackToMemory) {
        debugPrint(
          'EVT-01-B: SQLite→Memory — policy journal bridge skipped '
          '(not restart-safe)',
        );
        _bound = true;
        return;
      }
      final emitter = LocalEventPersistence.emitter(FsSessionKernel.db);
      _attachHooks(emitter);
      _bound = true;
    } catch (e, st) {
      debugPrint('EVT-01-B LocalEventPolicyBridge.tryBind soft-fail: $e\n$st');
      _bound = true;
    }
  }

  static void _attachHooks(LocalEventEmitter emitter) {
    void auditHook(String entry) {
      unawaited(
        emitter.emit(channel: 'audit.append', payload: {'entry': entry}),
      );
    }

    stage1WebUnlockAudit.journalHook = auditHook;
    stage1DeviceLockAudit.journalHook = auditHook;
    stage1AntiTamperAudit.journalHook = auditHook;
    stage1PrivacyCollectionAudit.journalHook = auditHook;

    stage1PolicySyncBus.journalHook = (event, status) {
      unawaited(
        emitter.emit(
          channel: 'policy.sync',
          payload: {
            'childId': event.childId.value,
            'kind': event.kind.name,
            'updatedAt': event.updatedAt.toUtc().toIso8601String(),
            'status': status.name,
          },
        ),
      );
    };
  }

  static void resetForTest() {
    _bound = false;
    stage1WebUnlockAudit.journalHook = null;
    stage1DeviceLockAudit.journalHook = null;
    stage1AntiTamperAudit.journalHook = null;
    stage1PrivacyCollectionAudit.journalHook = null;
    stage1PolicySyncBus.journalHook = null;
  }
}
