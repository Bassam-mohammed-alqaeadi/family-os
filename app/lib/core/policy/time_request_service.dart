import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import '../domain/mother_level.dart';
import '../domain/role.dart';
import 'policy_sync_bus.dart';
import 'temporary_grant_query.dart';
import 'time_request.dart';
import 'time_request_repository.dart';

/// Thrown when actor lacks permission (observer / over-ceiling mother).
final class TimeRequestNotAllowedException implements Exception {
  TimeRequestNotAllowedException(this.message);
  final String message;

  @override
  String toString() => 'TimeRequestNotAllowedException: $message';
}

/// Thrown when reject has no child-visible reason.
final class TimeRequestReasonRequiredException implements Exception {
  TimeRequestReasonRequiredException(this.message);
  final String message;

  @override
  String toString() => 'TimeRequestReasonRequiredException: $message';
}

/// Same-process bus so child UI can show decision + reason (P12 / UF-05).
final class TimeRequestDecisionBus extends ChangeNotifier {
  TimeRequest? _last;

  TimeRequest? get lastDecision => _last;

  void publish(TimeRequest decided) {
    _last = decided;
    notifyListeners();
  }

  void clear() {
    _last = null;
  }
}

/// Queued parent decision while offline (UI-006).
@immutable
final class QueuedTimeDecision {
  const QueuedTimeDecision.approve({
    required this.requestId,
    required this.actor,
    required this.grantMinutes,
  })  : kind = QueuedTimeDecisionKind.approve,
        reason = null;

  const QueuedTimeDecision.reject({
    required this.requestId,
    required this.actor,
    required this.reason,
  })  : kind = QueuedTimeDecisionKind.reject,
        grantMinutes = null;

  final QueuedTimeDecisionKind kind;
  final String requestId;
  final TimeRequestActor actor;
  final int? grantMinutes;
  final String? reason;
}

enum QueuedTimeDecisionKind { approve, reject }

/// Stage-1 shared prefs store for time requests.
TimeRequestPrefsStore stage1TimeRequestPrefsStore = MemoryTimeRequestPrefsStore();

/// Stage-1 shared decision bus (same-process child notify).
final TimeRequestDecisionBus stage1TimeRequestDecisionBus =
    TimeRequestDecisionBus();

/// Child→parent extra-time loop (UI-006 / UF-05 / ADR-039 / P12).
final class TimeRequestService extends ChangeNotifier {
  TimeRequestService({
    required TimeRequestRepository repository,
    TimeRequestDecisionBus? decisionBus,
    int activeCeilingMinutes = kDefaultMotherGrantCeilingMinutes,
    bool offline = false,
    String Function()? idFactory,
    DateTime Function()? clock,
  })  : _repo = repository,
        _bus = decisionBus ?? TimeRequestDecisionBus(),
        _activeCeilingMinutes = activeCeilingMinutes,
        _offline = offline,
        _idFactory = idFactory ?? _defaultId,
        _clock = clock ?? DateTime.now;

  final TimeRequestRepository _repo;
  final TimeRequestDecisionBus _bus;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  int _activeCeilingMinutes;
  bool _offline;
  final List<QueuedTimeDecision> _queue = [];

  TimeRequestDecisionBus get decisionBus => _bus;

  /// Active ADR-039 ceiling (default 30; father may edit rule later).
  int get activeCeilingMinutes => _activeCeilingMinutes;

  set activeCeilingMinutes(int value) {
    _activeCeilingMinutes = value < 1 ? 1 : value;
    notifyListeners();
  }

  bool get offline => _offline;

  set offline(bool value) {
    _offline = value;
    notifyListeners();
  }

  List<QueuedTimeDecision> get pendingOfflineDecisions =>
      List.unmodifiable(_queue);

  static var _seq = 0;
  static String _defaultId() {
    _seq += 1;
    return 'tr-$_seq';
  }

  Future<List<TimeRequest>> listPending() async {
    await expireStaleRequests();
    final all = await _repo.loadAll();
    return all.where((r) => r.isPending).toList(growable: false);
  }

  Future<TimeRequest?> getById(String id) => _repo.getById(id);

  /// Child creates a pending extra-time request (ST-OD-006: max one pending).
  Future<TimeRequest> createRequest({
    required ChildId childId,
    required int requestedMinutes,
    String? childReason,
  }) async {
    if (requestedMinutes <= 0) {
      throw ArgumentError.value(
        requestedMinutes,
        'requestedMinutes',
        'must be > 0',
      );
    }
    await expireStaleRequests();
    final pending = await listPending();
    for (final r in pending) {
      if (r.childId == childId) {
        throw TimeRequestNotAllowedException(
          'Child ${childId.value} already has a pending time request',
        );
      }
    }
    final created = _clock().toUtc();
    final request = TimeRequest(
      id: _idFactory(),
      childId: childId,
      requestedMinutes: requestedMinutes,
      childReason: childReason,
      status: TimeRequestStatus.pending,
      createdAt: created,
    );
    await _repo.save(request);
    notifyListeners();
    return request;
  }

  /// Marks pending requests past ST-OD-007 timeout as [TimeRequestStatus.expired].
  Future<void> expireStaleRequests() async {
    final now = _clock().toUtc();
    final all = await _repo.loadAll();
    var changed = false;
    for (final r in all) {
      if (!r.isPending) continue;
      final expires = TemporaryGrantQuery.requestOrGrantExpiresAt(r.createdAt);
      if (!now.isBefore(expires)) {
        await _repo.save(
          r.copyWith(status: TimeRequestStatus.expired),
        );
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Active Temporary Grant remaining for [childId] (G-A sum).
  Future<int> activeGrantRemaining(ChildId childId) async {
    final now = _clock();
    final grants = TemporaryGrantQuery.sweepExpired(
      await _repo.loadGrants(),
      now: now,
    );
    return TemporaryGrantQuery.activeRemaining(
      childId: childId,
      grants: grants,
      now: now,
    ).inMinutes;
  }

  /// Approve + activate Temporary Grant (G-A). Does **not** call WalletLedger.
  Future<TimeRequest> approve(
    String requestId,
    TimeRequestActor actor, {
    required int grantMinutes,
  }) async {
    if (!actor.canDecide) {
      throw TimeRequestNotAllowedException(
        'Actor ${actor.auditLabel} cannot approve time requests',
      );
    }
    if (!actor.canGrantMinutes(grantMinutes, _activeCeilingMinutes)) {
      throw TimeRequestNotAllowedException(
        'Grant $grantMinutes exceeds ADR-039 ceiling '
        '$_activeCeilingMinutes for ${actor.auditLabel}',
      );
    }

    if (_offline) {
      _queue.add(
        QueuedTimeDecision.approve(
          requestId: requestId,
          actor: actor,
          grantMinutes: grantMinutes,
        ),
      );
      notifyListeners();
      final pending = await _require(requestId);
      return pending;
    }

    return _applyApprove(requestId, actor, grantMinutes);
  }

  /// Reject with child-visible [reason] (UF-05 / UI-006 AC3).
  Future<TimeRequest> reject(
    String requestId,
    TimeRequestActor actor, {
    required String reason,
  }) async {
    if (!actor.canDecide) {
      throw TimeRequestNotAllowedException(
        'Actor ${actor.auditLabel} cannot reject time requests',
      );
    }
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw TimeRequestReasonRequiredException(
        'Reject reason is required for child visibility',
      );
    }

    if (_offline) {
      _queue.add(
        QueuedTimeDecision.reject(
          requestId: requestId,
          actor: actor,
          reason: trimmed,
        ),
      );
      notifyListeners();
      return _require(requestId);
    }

    return _applyReject(requestId, actor, trimmed);
  }

  /// Flush offline queue when reconnecting.
  Future<void> flushOfflineQueue() async {
    if (_queue.isEmpty) return;
    final copy = List<QueuedTimeDecision>.from(_queue);
    _queue.clear();
    for (final item in copy) {
      switch (item.kind) {
        case QueuedTimeDecisionKind.approve:
          await _applyApprove(
            item.requestId,
            item.actor,
            item.grantMinutes!,
          );
        case QueuedTimeDecisionKind.reject:
          await _applyReject(item.requestId, item.actor, item.reason!);
      }
    }
    notifyListeners();
  }

  Future<TimeRequest> _applyApprove(
    String requestId,
    TimeRequestActor actor,
    int grantMinutes,
  ) async {
    final request = await _require(requestId);
    if (!request.isPending) {
      throw TimeRequestNotAllowedException(
        'Request $requestId is ${request.status.name}',
      );
    }

    final stamp = _clock().toUtc();
    final expires = TemporaryGrantQuery.requestOrGrantExpiresAt(stamp);
    final decided = request.copyWith(
      status: TimeRequestStatus.approved,
      decidedBy: actor.auditLabel,
      grantedMinutes: grantMinutes,
      clearDecisionReason: true,
    );
    await _repo.save(decided);
    await _repo.saveGrant(
      TimeGrant(
        id: 'tg-${decided.id}',
        requestId: decided.id,
        childId: decided.childId,
        minutes: grantMinutes,
        remainingMinutes: grantMinutes,
        grantedBy: actor.auditLabel,
        createdAt: stamp,
        expiresAt: expires,
        status: TimeGrantStatus.active,
      ),
    );
    final remaining = await activeGrantRemaining(decided.childId);
    stage1PolicySyncBus.hydrate(
      decided.childId,
      temporaryGrantRemaining: remaining,
    );
    _bus.publish(decided);
    notifyListeners();
    return decided;
  }

  Future<TimeRequest> _applyReject(
    String requestId,
    TimeRequestActor actor,
    String reason,
  ) async {
    final request = await _require(requestId);
    if (!request.isPending) {
      throw TimeRequestNotAllowedException(
        'Request $requestId is ${request.status.name}',
      );
    }

    final decided = request.copyWith(
      status: TimeRequestStatus.rejected,
      decidedBy: actor.auditLabel,
      decisionReason: reason,
      clearGrantedMinutes: true,
    );
    await _repo.save(decided);
    final remaining = await activeGrantRemaining(decided.childId);
    stage1PolicySyncBus.hydrate(
      decided.childId,
      temporaryGrantRemaining: remaining,
    );
    _bus.publish(decided);
    notifyListeners();
    return decided;
  }

  Future<TimeRequest> _require(String id) async {
    final request = await _repo.getById(id);
    if (request == null) {
      throw TimeRequestNotAllowedException('Unknown request $id');
    }
    return request;
  }

  /// Derive actor from role + mother level (FAT-033 host).
  static TimeRequestActor actorFor({
    required AppRole role,
    MotherLevel? motherLevel,
  }) {
    return switch (role) {
      AppRole.father => const TimeRequestActor.father(),
      AppRole.mother => TimeRequestActor.mother(
          motherLevel ?? MotherLevel.partner,
        ),
      AppRole.child => const TimeRequestActor.child(),
    };
  }
}
