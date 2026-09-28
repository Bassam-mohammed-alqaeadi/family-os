import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/events/local_event_journal.dart';
import 'package:family_os/core/events/local_event_policy_bridge.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/sos_break_glass.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';
import 'package:family_os/core/policy/web_unlock_service.dart';
import 'package:family_os/core/sos_final/sos_final_runtime.dart';
import 'package:family_os/features/n07_privacy/audit_log_local_persistence.dart';
import 'package:family_os/features/n07_privacy/audit_log_models.dart';
import 'package:family_os/features/n07_privacy/audit_log_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    LocalEventPolicyBridge.resetForTest();
    // Drain soft journal futures before closing DB.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    Stage1SosFinalRuntime.resetForTest();
    rebindStage1AuditLogRepository(InMemoryAuditLogRepository());
    await FsSessionKernel.resetForTest();
  });

  test('AUTH-FS006-BG break-glass survives restart via Domain table', () async {
    final dir = await Directory.systemTemp.createTemp('bg_');
    final path = p.join(dir.path, 'bg.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    await Stage1SosFinalRuntime.ensureOpen();
    expect(stage1SosBreakGlassStore, isA<LocalSosBreakGlassStore>());

    final session = await stage1SosBreakGlassStore.start(
      actor: SosActor.primary(),
      capabilityKey: 'sos_response_override',
      reason: 'device offline',
      duration: const Duration(minutes: 30),
      incidentId: 'inc_test_1',
    );
    expect(session.phase, SosBreakGlassPhase.overrideActive);

    Stage1SosFinalRuntime.resetForTest();
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    await Stage1SosFinalRuntime.ensureOpen();
    final active = stage1SosBreakGlassStore.active;
    expect(active, isNotNull);
    expect(active!.id, session.id);
    expect(active.reason, 'device offline');
    expect(active.incidentId, 'inc_test_1');

    Stage1SosFinalRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('DOM-AUDIT-LOCAL append→close→reopen→read; append-only', () async {
    final dir = await Directory.systemTemp.createTemp('audit_');
    final path = p.join(dir.path, 'audit.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await AuditLogLocalPersistence.openRepository();
    await repo1.appendDurable(
      AuditLogEntry(
        id: 'audit-1',
        kind: AuditLogEntryKind.sosAlert,
        actor: AuditLogActor.system,
        at: DateTime.utc(2026, 9, 22, 12, 0),
        subjectKey: 'childOne',
        detailKey: 'closedAfter6m',
      ),
    );
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final repo2 = await AuditLogLocalPersistence.openRepository();
    final loaded = await repo2.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'audit-1');

    // Duplicate id must not replace (append-only / abort).
    await expectLater(
      repo2.appendDurable(
        AuditLogEntry(
          id: 'audit-1',
          kind: AuditLogEntryKind.forgetUsed,
          actor: AuditLogActor.father,
          at: DateTime.utc(2026, 9, 23),
        ),
      ),
      throwsA(anything),
    );
    final still = await repo2.load();
    expect(still.single.kind, AuditLogEntryKind.sosAlert);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('EVT-01-B PolicySync + AuditAppend journal bridge', () async {
    final dir = await Directory.systemTemp.createTemp('evt01b_');
    final path = p.join(dir.path, 'evt.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);

    await LocalEventPolicyBridge.tryBind();
    expect(LocalEventPolicyBridge.isBound, isTrue);

    final child = ChildId('demo-child');
    stage1PolicySyncBus.publish(
      PolicySyncEvent(
        childId: child,
        updatedAt: DateTime.utc(2026, 9, 25, 10),
        kind: PolicySyncKind.policy,
        policy: ScreenTimePolicy.defaults(),
      ),
    );
    stage1WebUnlockAudit.add('test unlock audit line');

    // Allow soft async emits to flush.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final journal = LocalEventJournal(FsSessionKernel.db);
    final recent = await journal.listRecent(limit: 20);
    expect(
      recent.any((e) => e.channel == 'policy.sync'),
      isTrue,
      reason: 'PolicySyncBus publish must journal locally',
    );
    expect(
      recent.any((e) => e.channel == 'audit.append'),
      isTrue,
      reason: 'AuditAppend must journal locally',
    );
    expect(
      recent.every((e) => e.toJson()['deliveryClaim'] == 'queued_locally'),
      isTrue,
    );

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
