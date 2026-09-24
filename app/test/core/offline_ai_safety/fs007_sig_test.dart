import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/offline_ai_safety/offline_ai_safety.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalOfflineAiSafetyStore store;
  late OfflineAiSafetyService service;
  late CapabilityRegistry capabilities;
  final family = FamilyId('fam_ai');
  final child = ChildId('child_a');
  final now = DateTime.utc(2026, 9, 24, 15, 0);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
    store = LocalOfflineAiSafetyStore(db);
    var seq = 0;
    service = OfflineAiSafetyService(
      store: store,
      familyId: family,
      clock: () => now,
      idFactory: () => 'ai_${++seq}',
    );
    capabilities = CapabilityRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> activateModel() async {
    await service.applyModel(
      draft: const SignedModelManifest(
        modelId: 'safety_v1',
        version: '1.0.0',
        signature: 'sig_test_abc',
        policyVersion: 'pol_1',
      ),
      actor: const SafetyAiActor.father(),
    );
  }

  test('schema v10 exposes ai safety tables', () async {
    expect(FamilyLocalSchema.currentVersion, 10);
    await db.insert('ai_safety_signal', {
      'id': 's1',
      'family_id': family.value,
      'child_id': child.value,
      'category': 'suspicious_language',
      'certainty': 'analysis',
      'severity': 'elevated',
      'provenance': 'local_heuristic',
      'model_version': '1.0.0',
      'policy_version': 'pol_1',
      'tool': 'searchAnalysis',
      'redacted_preview': null,
      'notified': 1,
      'ticket_id': null,
      'created_at': 1,
    });
    expect((await db.query('ai_safety_signal')).length, 1);
  });

  test('unsigned model cannot apply or execute', () async {
    expect(
      () => service.applyModel(
        draft: const SignedModelManifest(
          modelId: 'x',
          version: '1',
          signature: '',
          policyVersion: 'p',
        ),
        actor: const SafetyAiActor.father(),
      ),
      throwsStateError,
    );
    expect(
      () => service.classifyCompleted(childId: child, text: 'hi'),
      throwsStateError,
    );
  });

  test('Partner cannot apply model; Observer cannot review', () async {
    expect(
      () => service.applyModel(
        draft: const SignedModelManifest(
          modelId: 'safety_v1',
          version: '1.0.0',
          signature: 'sig',
          policyVersion: 'pol_1',
        ),
        actor: const SafetyAiActor.mother(MotherLevel.partner),
      ),
      throwsStateError,
    );
    expect(
      const SafetyAiActor.mother(MotherLevel.observer).canReceiveNotify,
      isFalse,
    );
  });

  test('ticket gate B1: analysis/confirmed open; preliminary notify-only',
      () async {
    await activateModel();

    final prelim = await service.classifyCompleted(
      childId: child,
      text: 'note [preliminary:self_harm]',
    );
    expect(prelim, isNotNull);
    expect(prelim!.notified, isTrue);
    expect(prelim.ticket, isNull);
    expect(prelim.signal.certainty, SafetyCertainty.preliminary);

    final analysis = await service.classifyCompleted(
      childId: child,
      text: 'chat [analysis:suspicious]',
    );
    expect(analysis!.ticket, isNotNull);
    expect(analysis.signal.opensTicket, isTrue);
    expect(analysis.ticket!.redactedPreview, isNotNull);

    final confirmed = await service.classifyCompleted(
      childId: child,
      text: 'x [confirmed:violence]',
    );
    expect(confirmed!.ticket, isNotNull);
    expect(confirmed.signal.certainty, SafetyCertainty.confirmed);
  });

  test('suggest-only never auto-applies; close purges preview; no SOS',
      () async {
    await activateModel();
    final hit = await service.classifyCompleted(
      childId: child,
      text: '[analysis:suspicious]',
    );
    final ticketId = hit!.ticket!.id;

    final suggestion = await service.createSuggestion(
      ticketId: ticketId,
      target: SafetySuggestionTarget.webFilter,
      summary: 'Suggest keyword review',
      actor: const SafetyAiActor.mother(MotherLevel.partner),
    );
    expect(suggestion.mayAutoApply, isFalse);
    expect(suggestion.status, SafetySuggestionStatus.pendingHuman);

    final closed = await service.closeTicket(
      ticketId: ticketId,
      actor: const SafetyAiActor.father(),
      actorId: 'father',
      closeStatus: SafetyTicketStatus.dismissedFp,
    );
    expect(closed.redactedPreview, isNull);
    expect(closed.status, SafetyTicketStatus.dismissedFp);

    expect(SafetyAiForbiddenActions.mayFireSos, isFalse);
    expect(
      () => service.fireSosFromAi(),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('child transparency names on-device; cloud classify unsupported',
      () async {
    final card = service.childTransparency(
      searchConfigured: true,
      imageConfigured: false,
      screenshotConfigured: true,
      localPlaneAvailable: true,
    );
    expect(card.namesOnDeviceOffline, isTrue);
    expect(card.searchAnalysis, 'on_device');
    expect(card.imageClassification, 'off');

    await capabilities.applyFs007SigCapabilities();
    expect(
      (await capabilities.get('fs007.local_classifier'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await capabilities.get('fs007.cloud_classify'))!.status,
      CapabilityStatus.unsupported,
    );
    expect(
      (await capabilities.get('fs007.suggest_only'))!.status,
      CapabilityStatus.implemented,
    );
  });
}
