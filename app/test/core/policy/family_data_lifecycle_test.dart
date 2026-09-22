import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/advisor_memory_store.dart';
import 'package:family_os/core/policy/chat_mock_store.dart';
import 'package:family_os/core/policy/family_data_lifecycle.dart';
import 'package:family_os/core/policy/web_unlock_service.dart' show AuditAppend;
import 'package:family_os/core/policy/wipe_job.dart';

void main() {
  late MemoryAdvisorMemoryStore memory;
  late MemoryChatMockStore chat;
  late AuditAppend audit;
  late DateTime now;
  late FamilyDataLifecycleService svc;

  setUp(() {
    memory = MemoryAdvisorMemoryStore([
      AdvisorMemoryNote(
        id: 'm1',
        text: 'remember homework',
        createdAt: DateTime.utc(2026, 9, 1),
      ),
    ]);
    chat = MemoryChatMockStore([
      ChatMockMessage(
        id: 'c1',
        body: 'hello dad',
        createdAt: DateTime.utc(2026, 9, 2),
      ),
    ]);
    audit = AuditAppend()..add('seed_audit_entry');
    now = DateTime.utc(2026, 9, 20, 12);
    svc = FamilyDataLifecycleService(
      memory: memory,
      chat: chat,
      audit: audit,
      clock: () => now,
      idFactory: () => 'wipe-test-1',
    );
  });

  test('forget clears memory only — chat + audit intact (R10)', () async {
    final beforeAudit = List<String>.from(audit.entries);
    final beforeChat = chat.messages.length;

    final result = await svc.forgetAdvisorMemory(actor: AppRole.father);
    expect(result, isA<ForgetOk>());
    expect(memory.notes, isEmpty);
    expect(chat.messages.length, beforeChat);
    expect(chat.messages.first.body, 'hello dad');
    expect(audit.entries, beforeAudit);
  });

  test('mother cannot forget', () async {
    final result = await svc.forgetAdvisorMemory(actor: AppRole.mother);
    expect(result, isA<ForgetDenied>());
    expect(memory.notes, isNotEmpty);
    expect(audit.entries.any((e) => e.contains('403 ADVISOR_FORGET')), isTrue);
  });

  test('child cannot forget', () async {
    final result = await svc.forgetAdvisorMemory(actor: AppRole.child);
    expect(result, isA<ForgetDenied>());
    expect(memory.notes, isNotEmpty);
  });

  test('schedule wipe — 7-day window + audit append', () async {
    final result = await svc.scheduleWipe(actor: AppRole.father);
    expect(result, isA<WipeScheduleOk>());
    final job = (result as WipeScheduleOk).job;
    expect(job.status, WipeJobStatus.pending);
    expect(
      job.pendingUntil,
      DateTime.utc(2026, 9, 27, 12),
    );
    expect(svc.pendingWipe, isNotNull);
    expect(
      audit.entries.any((e) => e.contains('FAMILY_WIPE_REQUESTED')),
      isTrue,
    );
    // Seed audit still present — wipe never clears audit.
    expect(audit.entries.first, 'seed_audit_entry');
  });

  test('mother cannot schedule wipe', () async {
    final result = await svc.scheduleWipe(actor: AppRole.mother);
    expect(result, isA<WipeScheduleDenied>());
    expect(svc.pendingWipe, isNull);
  });

  test('cancel wipe within window restores (clears pending)', () async {
    await svc.scheduleWipe(actor: AppRole.father);
    now = DateTime.utc(2026, 9, 22, 12);
    final cancel = await svc.cancelWipe(actor: AppRole.father);
    expect(cancel, isA<WipeCancelOk>());
    expect(svc.pendingWipe, isNull);
    expect(svc.wipeJob?.status, WipeJobStatus.cancelled);
    expect(
      audit.entries.any((e) => e.contains('FAMILY_WIPE_CANCELLED')),
      isTrue,
    );
  });

  test('cancel after window expired fails', () async {
    await svc.scheduleWipe(actor: AppRole.father);
    now = DateTime.utc(2026, 9, 28, 12);
    final cancel = await svc.cancelWipe(actor: AppRole.father);
    expect(cancel, isA<WipeCancelWindowExpired>());
    expect(svc.pendingWipe, isNotNull);
  });
}
