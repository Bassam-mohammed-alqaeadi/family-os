import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/policy_delivery.dart';

/// Tracks Web Filter policy artifact delivery (Configured→Verified).
///
/// Uses shared [policy_delivery] table. Does **not** claim native enforcement.
final class WebFilterDeliveryTracker {
  WebFilterDeliveryTracker(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const _table = 'policy_delivery';

  static String artifactIdForScope(String scopeKey) => 'wf:$scopeKey';

  Future<PolicyDeliveryState?> load(String scopeKey) async {
    final id = artifactIdForScope(scopeKey);
    final rows = await _db.query(
      _table,
      where: 'artifact_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return PolicyDeliveryState(
      artifactId: row['artifact_id']! as String,
      policyVersion: row['policy_version']! as int,
      phase: PolicyDeliveryPhaseWire.parse(row['phase']! as String),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
        isUtc: true,
      ),
      lastError: row['last_error'] as String?,
    );
  }

  /// Parent save → CONFIGURED (or reconfigure bump).
  Future<PolicyDeliveryState> onPolicySaved({
    required String scopeKey,
    required int policyVersion,
  }) async {
    final now = _clock().toUtc();
    final existing = await load(scopeKey);
    final PolicyDeliveryState next;
    if (existing == null) {
      next = PolicyDeliveryTransitions.start(
        artifactId: artifactIdForScope(scopeKey),
        policyVersion: policyVersion,
        now: now,
      );
    } else if (policyVersion > existing.policyVersion) {
      next = PolicyDeliveryTransitions.reconfigure(
        existing,
        newPolicyVersion: policyVersion,
        now: now,
      );
    } else {
      next = existing;
    }
    await _persist(next);
    return next;
  }

  /// Advance one honesty step (local sim — never implies native block success).
  Future<PolicyDeliveryState> advance(
    String scopeKey, {
    required PolicyDeliveryPhase to,
  }) async {
    final current = await load(scopeKey);
    if (current == null) {
      throw StateError('No delivery state for $scopeKey');
    }
    final next = PolicyDeliveryTransitions.advance(
      current,
      to: to,
      now: _clock().toUtc(),
    );
    await _persist(next);
    return next;
  }

  /// Local-only walk toward Verified for tests / mock remote ack simulation.
  Future<PolicyDeliveryState> simulateLocalAckToVerified(
    String scopeKey,
  ) async {
    var state = await load(scopeKey);
    if (state == null) {
      throw StateError('No delivery state for $scopeKey');
    }
    final now = _clock().toUtc();
    state = PolicyDeliveryTransitions.advanceTo(
      state,
      target: PolicyDeliveryPhase.verified,
      now: now,
    );
    await _persist(state);
    return state;
  }

  Future<void> _persist(PolicyDeliveryState state) async {
    await _db.insert(_table, {
      'artifact_id': state.artifactId,
      'policy_version': state.policyVersion,
      'phase': state.phase.wireName,
      'updated_at': state.updatedAt.millisecondsSinceEpoch,
      'last_error': state.lastError,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
  }
}
