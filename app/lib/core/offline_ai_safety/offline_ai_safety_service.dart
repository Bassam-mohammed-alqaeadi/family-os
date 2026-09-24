import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'local_safety_classifier.dart';
import 'offline_ai_safety_store.dart';
import 'safety_models.dart';
import 'safety_taxonomy.dart';

/// Result of a completed local classification pass.
final class SafetyClassifyResult {
  const SafetyClassifyResult({
    required this.signal,
    required this.notified,
    this.ticket,
  });

  final SafetySignal signal;
  final bool notified;
  final SafetyTicket? ticket;
}

/// FS-007 signal plane coordinator — classify → notify → gated ticket → suggest.
///
/// Never mutates WF/AC/Modes stores. Never fires SOS. Cloud classify out of v1.
final class OfflineAiSafetyService {
  OfflineAiSafetyService({
    required OfflineAiSafetyRepository store,
    required this.familyId,
    LocalSafetyClassifier? classifier,
    DateTime Function()? clock,
    String Function()? idFactory,
  })  : _store = store,
        _classifier = classifier ?? HeuristicSafetyClassifier(),
        _clock = clock ?? DateTime.now,
        _idFactory = idFactory ?? _defaultId;

  final OfflineAiSafetyRepository _store;
  final FamilyId familyId;
  final LocalSafetyClassifier _classifier;
  final DateTime Function() _clock;
  final String Function() _idFactory;

  static var _seq = 0;
  static String _defaultId() {
    _seq += 1;
    return 'ai_$_seq';
  }

  Future<SignedModelManifest> applyModel({
    required SignedModelManifest draft,
    required SafetyAiActor actor,
  }) async {
    if (!actor.canApplyModel) {
      throw StateError('Actor cannot apply FS-007 models');
    }
    if (!draft.mayExecute) {
      throw StateError('Unsigned/unversioned model must not execute');
    }
    SafetyAiForbiddenActions.assertNoSilentPolicyMutation();
    final active = draft.copyWith(active: true);
    await _store.saveModel(familyId, active);
    await _store.appendAudit(
      id: '${active.modelId}_apply_${_clock().millisecondsSinceEpoch}',
      familyId: familyId,
      eventType: 'model_applied',
      at: _clock().toUtc(),
      payloadJson:
          '{"modelId":"${active.modelId}","version":"${active.version}"}',
    );
    return active;
  }

  Future<SignedModelManifest?> activeModel() => _store.activeModel(familyId);

  Future<List<SafetyTicket>> listTickets() => _store.listTickets(familyId);

  Future<List<SafetySignal>> listSignals({ChildId? childId}) =>
      _store.listSignals(familyId, childId: childId);

  /// Local classify. Returns null when no hit (honest empty — not fake success).
  Future<SafetyClassifyResult?> classifyCompleted({
    required ChildId childId,
    required String text,
    SafetyToolKind tool = SafetyToolKind.searchAnalysis,
  }) async {
    SafetyAiForbiddenActions.assertNoSos();
    SafetyAiForbiddenActions.assertNoSilentPolicyMutation();
    if (SafetyAiForbiddenActions.cloudClassifyInV1) {
      throw StateError('Cloud classify forbidden in v1');
    }

    final model = await _store.activeModel(familyId);
    if (model == null || !model.mayExecute) {
      throw StateError(
        'No signed active model — refuse run (AI-OD-11 honesty)',
      );
    }

    final hit = await _classifier.classify(
      SafetyClassifyRequest(
        familyId: familyId,
        childId: childId,
        text: text,
        tool: tool,
      ),
      model: model,
    );
    if (hit == null) return null;

    final now = _clock().toUtc();
    final signalId = _idFactory();
    var signal = SafetySignal(
      id: signalId,
      familyId: familyId,
      childId: childId,
      category: hit.category,
      certainty: hit.certainty,
      severity: hit.severity,
      provenance: hit.provenance,
      modelVersion: model.version,
      policyVersion: model.policyVersion,
      createdAt: now,
      tool: tool,
      redactedPreview: hit.redactedPreview,
    );

    // Always notify on completed classification (AI-OD-03).
    final notified = SafetyTicketGate.shouldNotify(hit.certainty);
    signal = signal.copyWith(notified: notified);

    SafetyTicket? ticket;
    if (SafetyTicketGate.shouldOpenTicket(hit.certainty)) {
      final ticketId = _idFactory();
      ticket = SafetyTicket(
        id: ticketId,
        familyId: familyId,
        signalId: signalId,
        childId: childId,
        status: SafetyTicketStatus.open,
        createdAt: now,
        redactedPreview: hit.redactedPreview,
      );
      signal = signal.copyWith(ticketId: ticketId);
      await _store.saveTicket(ticket);
      await _store.appendAudit(
        id: '${ticketId}_open',
        familyId: familyId,
        eventType: 'ticket_opened',
        at: now,
        payloadJson: '{"certainty":"${hit.certainty.wireName}"}',
      );
    }

    await _store.saveSignal(signal);
    await _store.appendAudit(
      id: '${signalId}_classified',
      familyId: familyId,
      eventType: 'classified',
      at: now,
      payloadJson:
          '{"category":"${hit.category.wireName}","certainty":"${hit.certainty.wireName}","notified":$notified}',
    );

    return SafetyClassifyResult(
      signal: signal,
      notified: notified,
      ticket: ticket,
    );
  }

  /// Close ticket + purge redacted preview (AI-OD-12); audit retained.
  Future<SafetyTicket> closeTicket({
    required String ticketId,
    required SafetyAiActor actor,
    required String actorId,
    required SafetyTicketStatus closeStatus,
  }) async {
    if (!actor.canReviewTicket) {
      throw StateError('Actor cannot review FS-007 tickets');
    }
    if (closeStatus != SafetyTicketStatus.resolved &&
        closeStatus != SafetyTicketStatus.dismissedFp) {
      throw StateError('Invalid close status');
    }
    final ticket = await _store.getTicket(ticketId);
    if (ticket == null || !ticket.isOpen) {
      throw StateError('Ticket not open');
    }
    final now = _clock().toUtc();
    final closed = ticket.copyWith(
      status: closeStatus,
      clearPreview: true,
      closedAt: now,
      closedBy: actorId,
    );
    await _store.saveTicket(closed);

    final signal = await _store.getSignal(ticket.signalId);
    if (signal != null) {
      await _store.saveSignal(signal.copyWith(clearPreview: true));
    }

    await _store.appendAudit(
      id: '${ticketId}_close_${now.millisecondsSinceEpoch}',
      familyId: familyId,
      eventType: 'ticket_closed',
      at: now,
      actorId: actorId,
      payloadJson: '{"status":"${closeStatus.name}","preview_purged":true}',
    );
    return closed;
  }

  /// Create suggest-only artifact — never mutates owning system stores.
  Future<SafetySuggestion> createSuggestion({
    required String ticketId,
    required SafetySuggestionTarget target,
    required String summary,
    required SafetyAiActor actor,
  }) async {
    if (!actor.canReviewTicket) {
      throw StateError('Actor cannot create FS-007 suggestions');
    }
    SafetyAiForbiddenActions.assertNoSilentPolicyMutation();
    final ticket = await _store.getTicket(ticketId);
    if (ticket == null || !ticket.isOpen) {
      throw StateError('Ticket not open');
    }
    final now = _clock().toUtc();
    final suggestion = SafetySuggestion(
      id: _idFactory(),
      familyId: familyId,
      ticketId: ticketId,
      target: target,
      summary: summary,
      status: SafetySuggestionStatus.pendingHuman,
      createdAt: now,
    );
    assert(!suggestion.mayAutoApply);
    await _store.saveSuggestion(suggestion);

    final pending = ticket.copyWith(
      status: SafetyTicketStatus.suggestionPending,
    );
    await _store.saveTicket(pending);
    await _store.appendAudit(
      id: '${suggestion.id}_suggest',
      familyId: familyId,
      eventType: 'suggestion_pending',
      at: now,
      payloadJson:
          '{"target":"${target.name}","auto_apply":false}',
    );
    return suggestion;
  }

  /// Explicit: FS-007 has no SOS fire API.
  Never fireSosFromAi() {
    SafetyAiForbiddenActions.assertNoSos();
    throw UnsupportedError('FS-007 must never fire or escalate SOS');
  }

  ChildSafetyTransparency childTransparency({
    required bool searchConfigured,
    required bool imageConfigured,
    required bool screenshotConfigured,
    required bool localPlaneAvailable,
  }) {
    String toolState(bool configured, bool available) {
      if (!configured) return 'off';
      if (!available) return 'degraded';
      return 'on_device';
    }

    return ChildSafetyTransparency(
      searchAnalysis: toolState(searchConfigured, localPlaneAvailable),
      imageClassification: toolState(imageConfigured, localPlaneAvailable),
      screenshotMonitoring: toolState(screenshotConfigured, localPlaneAvailable),
      namesOnDeviceOffline: localPlaneAvailable,
    );
  }
}
