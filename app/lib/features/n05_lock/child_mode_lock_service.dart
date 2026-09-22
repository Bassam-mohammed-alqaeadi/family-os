import 'package:flutter/foundation.dart';

import 'package:family_os/core/policy/web_unlock_service.dart' show AuditAppend;

/// Stage-1 mock account password — not a device PIN / MDM credential.
const kChildModeLockMockPassword = 'parent-account';

/// Failed password attempts before 24h lockout (ADR-017).
const kChildModeLockMaxFailedAttempts = 3;

/// Lockout window after max failed attempts.
const kChildModeLockLockoutDuration = Duration(hours: 24);

/// Triple-lock attempt outcome (ADR-017 / SCR-CHD-011).
enum ChildModeUnlockOutcome {
  /// Wrong account password — father notified; attempt counted.
  failed,

  /// Password OK — awaiting second key on parent device (FAT-030).
  awaitingSecondKey,

  /// Device locked for 24h after 3 failures — mother also notified.
  lockout,
}

/// Notification fired on every failed password attempt (and lockout).
@immutable
final class ChildModeUnlockNotifyEvent {
  const ChildModeUnlockNotifyEvent({
    required this.attemptNumber,
    required this.lockout,
    required this.notifiedFather,
    required this.notifiedMother,
    required this.at,
  });

  final int attemptNumber;
  final bool lockout;
  final bool notifiedFather;
  final bool notifiedMother;
  final DateTime at;
}

/// Same-process bus — parent surfaces (FAT-030) observe failed attempts.
final class ChildModeUnlockNotifyBus extends ChangeNotifier {
  ChildModeUnlockNotifyEvent? _last;
  final List<ChildModeUnlockNotifyEvent> delivered = [];

  ChildModeUnlockNotifyEvent? get last => _last;

  void publish(ChildModeUnlockNotifyEvent event) {
    _last = event;
    delivered.add(event);
    notifyListeners();
  }

  void clear() {
    _last = null;
    delivered.clear();
  }
}

/// Pending dual-key request after correct password (key 2 = parent device).
@immutable
final class ChildModeUnlockRequest {
  const ChildModeUnlockRequest({
    required this.id,
    required this.createdAt,
    this.approvedUntil,
  });

  final String id;
  final DateTime createdAt;

  /// Set when parent grants a temporary parent-mode window.
  final DateTime? approvedUntil;

  bool get isApproved =>
      approvedUntil != null && approvedUntil!.isAfter(DateTime.now().toUtc());

  /// Still waiting for FAT-030 second-key decision.
  bool get isAwaitingSecondKey => !isApproved;

  ChildModeUnlockRequest copyWith({DateTime? approvedUntil}) {
    return ChildModeUnlockRequest(
      id: id,
      createdAt: createdAt,
      approvedUntil: approvedUntil ?? this.approvedUntil,
    );
  }
}

/// Result of [ChildModeLockService.verifyAccountPassword].
@immutable
final class ChildModeUnlockResult {
  const ChildModeUnlockResult({
    required this.outcome,
    required this.failedAttempts,
    this.request,
    this.lockoutUntil,
  });

  final ChildModeUnlockOutcome outcome;
  final int failedAttempts;
  final ChildModeUnlockRequest? request;
  final DateTime? lockoutUntil;
}

/// ADR-017 triple-lock seam for SCR-CHD-011 (mock-first · no OS MDM).
///
/// 1. Secret entry (UI hold) · 2. Account password (not PIN) ·
/// 3. Second key on parent device (FAT-030). Failures notify father;
/// 3 fails → 24h lockout + mother notify.
final class ChildModeLockService extends ChangeNotifier {
  ChildModeLockService({
    String expectedPassword = kChildModeLockMockPassword,
    AuditAppend? audit,
    ChildModeUnlockNotifyBus? notifyBus,
    DateTime Function()? clock,
    int maxFailedAttempts = kChildModeLockMaxFailedAttempts,
    Duration lockoutDuration = kChildModeLockLockoutDuration,
  })  : _expectedPassword = expectedPassword,
        _audit = audit ?? AuditAppend(),
        _notifyBus = notifyBus ?? ChildModeUnlockNotifyBus(),
        _clock = clock ?? DateTime.now,
        _maxFailedAttempts = maxFailedAttempts,
        _lockoutDuration = lockoutDuration;

  String _expectedPassword;
  final AuditAppend _audit;
  final ChildModeUnlockNotifyBus _notifyBus;
  final DateTime Function() _clock;
  final int _maxFailedAttempts;
  final Duration _lockoutDuration;

  var _secretEntryOpen = false;
  var _failedAttempts = 0;
  DateTime? _lockoutUntil;
  ChildModeUnlockRequest? _pendingRequest;
  var _requestSeq = 0;

  AuditAppend get audit => _audit;
  ChildModeUnlockNotifyBus get notifyBus => _notifyBus;

  bool get secretEntryOpen => _secretEntryOpen;
  int get failedAttempts => _failedAttempts;
  DateTime? get lockoutUntil => _lockoutUntil;
  ChildModeUnlockRequest? get pendingRequest => _pendingRequest;

  /// FAT-030 inbox — pending requests still awaiting second-key decision.
  List<ChildModeUnlockRequest> get awaitingSecondKeyRequests {
    final pending = _pendingRequest;
    if (pending == null || !pending.isAwaitingSecondKey) return const [];
    return [pending];
  }

  bool get isLockedOut {
    final until = _lockoutUntil;
    if (until == null) return false;
    return _clock().toUtc().isBefore(until);
  }

  /// Test / Stage-1 seam — rotate expected mock password.
  void setExpectedPassword(String password) {
    _expectedPassword = password;
  }

  /// Opens step 2 after the secret-entry hold succeeds.
  void openSecretEntry() {
    if (isLockedOut) return;
    _secretEntryOpen = true;
    _audit.add('mode_unlock_secret_opened');
    notifyListeners();
  }

  /// Verifies account password (never a device PIN). Requires secret entry.
  ChildModeUnlockResult verifyAccountPassword(String password) {
    if (isLockedOut) {
      return ChildModeUnlockResult(
        outcome: ChildModeUnlockOutcome.lockout,
        failedAttempts: _failedAttempts,
        lockoutUntil: _lockoutUntil,
      );
    }
    if (!_secretEntryOpen) {
      return ChildModeUnlockResult(
        outcome: ChildModeUnlockOutcome.failed,
        failedAttempts: _failedAttempts,
      );
    }

    final trimmed = password.trim();
    if (trimmed == _expectedPassword) {
      _requestSeq += 1;
      final request = ChildModeUnlockRequest(
        id: 'mode_unlock_$_requestSeq',
        createdAt: _clock().toUtc(),
      );
      _pendingRequest = request;
      _failedAttempts = 0;
      _audit.add('mode_unlock_attempt:ok:${request.id}');
      notifyListeners();
      return ChildModeUnlockResult(
        outcome: ChildModeUnlockOutcome.awaitingSecondKey,
        failedAttempts: 0,
        request: request,
      );
    }

    _failedAttempts += 1;
    final attempt = _failedAttempts;
    final lockout = attempt >= _maxFailedAttempts;
    if (lockout) {
      _lockoutUntil = _clock().toUtc().add(_lockoutDuration);
      _secretEntryOpen = false;
      _pendingRequest = null;
    }
    _audit.add(
      lockout
          ? 'mode_unlock_attempt:fail:$attempt:lockout'
          : 'mode_unlock_attempt:fail:$attempt',
    );
    final event = ChildModeUnlockNotifyEvent(
      attemptNumber: attempt,
      lockout: lockout,
      notifiedFather: true,
      notifiedMother: lockout,
      at: _clock().toUtc(),
    );
    _notifyBus.publish(event);
    notifyListeners();
    return ChildModeUnlockResult(
      outcome: lockout
          ? ChildModeUnlockOutcome.lockout
          : ChildModeUnlockOutcome.failed,
      failedAttempts: attempt,
      lockoutUntil: _lockoutUntil,
    );
  }

  /// Mock second-key grant (FAT-030 seam) — temporary parent-mode window.
  void approveSecondKey({Duration window = const Duration(minutes: 10)}) {
    final pending = _pendingRequest;
    if (pending == null) return;
    _pendingRequest = pending.copyWith(
      approvedUntil: _clock().toUtc().add(window),
    );
    _audit.add('mode_unlock_second_key:approved:${_pendingRequest!.id}');
    notifyListeners();
  }

  void rejectSecondKey() {
    final pending = _pendingRequest;
    if (pending == null) return;
    _audit.add('mode_unlock_second_key:rejected:${pending.id}');
    _pendingRequest = null;
    notifyListeners();
  }

  void resetForTests() {
    _secretEntryOpen = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    _pendingRequest = null;
    _audit.clear();
    _notifyBus.clear();
    notifyListeners();
  }
}

/// Stage-1 singleton — empty audit until UI/tests drive attempts.
final ChildModeUnlockNotifyBus stage1ChildModeUnlockNotifyBus =
    ChildModeUnlockNotifyBus();

final AuditAppend stage1ChildModeLockAudit = AuditAppend();

final ChildModeLockService stage1ChildModeLockService = ChildModeLockService(
  audit: stage1ChildModeLockAudit,
  notifyBus: stage1ChildModeUnlockNotifyBus,
);
