import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import '../domain/mother_level.dart';
import '../domain/role.dart';
import 'web_filter_policy.dart';
import 'web_filter_policy_repository.dart';
import 'web_unlock_request.dart';
import 'web_unlock_request_repository.dart';

/// Thrown when mother ① (observer) or unauthorized actor tries to approve.
final class WebUnlockNotAllowedException implements Exception {
  WebUnlockNotAllowedException(this.message);
  final String message;

  @override
  String toString() => 'WebUnlockNotAllowedException: $message';
}

/// Thrown when URL is invalid / missing host.
final class WebUnlockInvalidUrlException implements Exception {
  WebUnlockInvalidUrlException(this.message);
  final String message;

  @override
  String toString() => 'WebUnlockInvalidUrlException: $message';
}

/// Simple audit append list (SET-006 Stage-1 — no Drift).
final class AuditAppend {
  final List<String> entries = [];

  void add(String entry) => entries.add(entry);

  void clear() => entries.clear();
}

/// Same-process bus so child UI can toast when a decision arrives (P12).
final class WebUnlockDecisionBus extends ChangeNotifier {
  WebUnlockRequest? _last;

  WebUnlockRequest? get lastDecision => _last;

  void publish(WebUnlockRequest decided) {
    _last = decided;
    notifyListeners();
  }

  void clear() {
    _last = null;
  }
}

/// Stage-1 shared prefs store for unlock requests.
WebUnlockPrefsStore stage1WebUnlockPrefsStore = MemoryWebUnlockPrefsStore();

/// Stage-1 shared decision bus (same-process child notify).
final WebUnlockDecisionBus stage1WebUnlockDecisionBus = WebUnlockDecisionBus();

/// Stage-1 shared audit log.
final AuditAppend stage1WebUnlockAudit = AuditAppend();

/// Result of [WebUnlockService.requestUnlock].
@immutable
final class WebUnlockRequestResult {
  const WebUnlockRequestResult({
    required this.request,
    required this.throttled,
  });

  final WebUnlockRequest request;
  final bool throttled;
}

/// Child→parent web unlock loop (SET-006 / P12).
///
/// Competitive lens: Family Link app-approval — approve/deny produces allow-list
/// effect + audit, not decorative buttons.
final class WebUnlockService extends ChangeNotifier {
  WebUnlockService({
    required WebUnlockRequestRepository requestRepository,
    required WebFilterPolicyRepository policyRepository,
    AuditAppend? audit,
    WebUnlockDecisionBus? decisionBus,
    String Function()? idFactory,
    DateTime Function()? clock,
  })  : _requests = requestRepository,
        _policies = policyRepository,
        _audit = audit ?? AuditAppend(),
        _bus = decisionBus ?? WebUnlockDecisionBus(),
        _idFactory = idFactory ?? _defaultId,
        _clock = clock ?? DateTime.now;

  final WebUnlockRequestRepository _requests;
  final WebFilterPolicyRepository _policies;
  final AuditAppend _audit;
  final WebUnlockDecisionBus _bus;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  AuditAppend get audit => _audit;
  WebUnlockDecisionBus get decisionBus => _bus;

  static var _seq = 0;
  static String _defaultId() {
    _seq += 1;
    return 'wfr-$_seq';
  }

  /// Creates a pending unlock request. Throttles duplicate pending same host.
  ///
  /// When throttled, returns the existing pending request with [throttled] true.
  Future<WebUnlockRequestResult> requestUnlock(
    ChildId childId,
    String url,
  ) async {
    final host = WebFilterPolicy.normalizeHost(_hostOf(url));
    if (host.isEmpty) {
      throw WebUnlockInvalidUrlException('URL must include a host');
    }

    final all = await _requests.loadAll();
    for (final existing in all) {
      if (existing.childId == childId &&
          existing.host == host &&
          existing.isPending) {
        _audit.add(
          'throttle duplicate pending host=$host child=${childId.value}',
        );
        return WebUnlockRequestResult(request: existing, throttled: true);
      }
    }

    final request = WebUnlockRequest(
      id: _idFactory(),
      childId: childId,
      url: url.trim(),
      status: WebUnlockRequestStatus.pending,
      createdAt: _clock().toUtc(),
    );
    await _requests.save(request);
    _audit.add(
      'request created id=${request.id} host=${request.host} '
      'child=${childId.value}',
    );
    notifyListeners();
    return WebUnlockRequestResult(request: request, throttled: false);
  }

  /// Approves a pending (or supersedes path handled in [deny]).
  ///
  /// Mother observer → [WebUnlockNotAllowedException].
  /// On success: host added to policy allowList + status approved + audit.
  Future<WebUnlockRequest> approve(
    String requestId,
    WebUnlockActor actor,
  ) async {
    if (!actor.canApproveUnlock) {
      _audit.add(
        'approve rejected actor=${actor.auditLabel} id=$requestId',
      );
      throw WebUnlockNotAllowedException(
        'Actor ${actor.auditLabel} cannot approve web unlocks',
      );
    }

    final request = await _require(requestId);
    if (request.status == WebUnlockRequestStatus.denied &&
        request.decidedBy?.startsWith('father') == true) {
      // Father already denied — mother approve cannot override (father wins).
      _audit.add(
        'approve blocked father-wins id=$requestId actor=${actor.auditLabel}',
      );
      throw WebUnlockNotAllowedException(
        'Father already denied; father wins conflict',
      );
    }

    if (!request.isPending &&
        request.status != WebUnlockRequestStatus.approved) {
      throw WebUnlockNotAllowedException(
        'Request $requestId is ${request.status.name}',
      );
    }

    if (request.status == WebUnlockRequestStatus.approved) {
      return request;
    }

    final policy = await _policies.load(request.childId);
    final nextAllow = {...policy.allowList, request.host};
    final stamp = _clock().toUtc();
    await _policies.save(
      request.childId,
      policy.copyWith(
        allowList: nextAllow,
        policyVersion: policy.policyVersion + 1,
        updatedAt: stamp,
      ),
    );

    final decided = request.copyWith(
      status: WebUnlockRequestStatus.approved,
      decidedBy: actor.auditLabel,
      clearReason: true,
    );
    await _requests.save(decided);
    _audit.add(
      'approved id=${decided.id} host=${decided.host} '
      'actor=${actor.auditLabel}',
    );
    _bus.publish(decided);
    notifyListeners();
    return decided;
  }

  /// Denies a request. Father deny after mother approve → father wins:
  /// host removed from allowList + status denied + supersession audit.
  Future<WebUnlockRequest> deny(
    String requestId,
    WebUnlockActor actor, {
    String? reason,
  }) async {
    // Deny is allowed for father always; mother partner/full may deny pending;
    // mother observer cannot decide.
    if (actor.role == AppRole.mother &&
        actor.motherLevel == MotherLevel.observer) {
      _audit.add('deny rejected observer id=$requestId');
      throw WebUnlockNotAllowedException(
        'Mother observer cannot decide web unlocks',
      );
    }
    if (actor.role == AppRole.child) {
      throw WebUnlockNotAllowedException('Child cannot decide web unlocks');
    }

    final request = await _require(requestId);

    // Father wins: reverse a prior mother approval.
    if (request.status == WebUnlockRequestStatus.approved &&
        actor.role == AppRole.father) {
      final policy = await _policies.load(request.childId);
      final nextAllow = {...policy.allowList}..remove(request.host);
      final stamp = _clock().toUtc();
      await _policies.save(
        request.childId,
        policy.copyWith(
          allowList: nextAllow,
          policyVersion: policy.policyVersion + 1,
          updatedAt: stamp,
        ),
      );
      final decided = request.copyWith(
        status: WebUnlockRequestStatus.denied,
        decidedBy: actor.auditLabel,
        reason: reason ?? 'father_supersede',
      );
      await _requests.save(decided);
      _audit.add(
        'father_wins supersede id=${decided.id} host=${decided.host} '
        'prior=${request.decidedBy}',
      );
      _bus.publish(decided);
      notifyListeners();
      return decided;
    }

    if (!request.isPending) {
      throw WebUnlockNotAllowedException(
        'Request $requestId is ${request.status.name}',
      );
    }

    final decided = request.copyWith(
      status: WebUnlockRequestStatus.denied,
      decidedBy: actor.auditLabel,
      reason: reason ?? 'denied',
    );
    await _requests.save(decided);
    _audit.add(
      'denied id=${decided.id} host=${decided.host} '
      'actor=${actor.auditLabel} reason=${decided.reason}',
    );
    _bus.publish(decided);
    notifyListeners();
    return decided;
  }

  Future<List<WebUnlockRequest>> listPending({ChildId? childId}) async {
    final all = await _requests.loadAll();
    return [
      for (final r in all)
        if (r.isPending && (childId == null || r.childId == childId)) r,
    ];
  }

  Future<List<WebUnlockRequest>> listAll({ChildId? childId}) async {
    final all = await _requests.loadAll();
    if (childId == null) return all;
    return [for (final r in all) if (r.childId == childId) r];
  }

  Future<WebUnlockRequest> _require(String id) async {
    final found = await _requests.getById(id);
    if (found == null) {
      throw WebUnlockNotAllowedException('Unknown request $id');
    }
    return found;
  }

  static String _hostOf(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final withScheme =
        trimmed.contains('://') ? trimmed : 'https://$trimmed';
    return Uri.tryParse(withScheme)?.host ?? '';
  }
}
