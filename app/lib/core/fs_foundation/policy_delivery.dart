import 'package:flutter/foundation.dart';

/// Offline honesty pipeline for parent→child policy planes.
///
/// Configured → Published → Delivered → Applied → Verified.
/// Advances only forward for a given [policyVersion]; a new version resets
/// to [configured].
enum PolicyDeliveryPhase { configured, published, delivered, applied, verified }

extension PolicyDeliveryPhaseWire on PolicyDeliveryPhase {
  String get wireName => name.toUpperCase();

  static PolicyDeliveryPhase parse(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'CONFIGURED':
        return PolicyDeliveryPhase.configured;
      case 'PUBLISHED':
        return PolicyDeliveryPhase.published;
      case 'DELIVERED':
        return PolicyDeliveryPhase.delivered;
      case 'APPLIED':
        return PolicyDeliveryPhase.applied;
      case 'VERIFIED':
        return PolicyDeliveryPhase.verified;
      default:
        throw FormatException('Unknown PolicyDeliveryPhase: $raw');
    }
  }

  int get rank => index;
}

/// Immutable delivery record for one policy artifact on one device/child.
@immutable
final class PolicyDeliveryState {
  const PolicyDeliveryState({
    required this.artifactId,
    required this.policyVersion,
    required this.phase,
    required this.updatedAt,
    this.lastError,
  });

  final String artifactId;
  final int policyVersion;
  final PolicyDeliveryPhase phase;
  final DateTime updatedAt;
  final String? lastError;

  bool get isVerified => phase == PolicyDeliveryPhase.verified;

  PolicyDeliveryState copyWith({
    PolicyDeliveryPhase? phase,
    int? policyVersion,
    DateTime? updatedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return PolicyDeliveryState(
      artifactId: artifactId,
      policyVersion: policyVersion ?? this.policyVersion,
      phase: phase ?? this.phase,
      updatedAt: updatedAt ?? this.updatedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, Object?> toJson() => {
    'artifactId': artifactId,
    'policyVersion': policyVersion,
    'phase': phase.wireName,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'lastError': lastError,
  };

  factory PolicyDeliveryState.fromJson(Map<String, Object?> json) {
    return PolicyDeliveryState(
      artifactId: json['artifactId']! as String,
      policyVersion: json['policyVersion']! as int,
      phase: PolicyDeliveryPhaseWire.parse(json['phase']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String).toUtc(),
      lastError: json['lastError'] as String?,
    );
  }
}

/// Pure domain transitions — no I/O.
abstract final class PolicyDeliveryTransitions {
  static const _order = PolicyDeliveryPhase.values;

  /// Creates a fresh configured state for [policyVersion].
  static PolicyDeliveryState start({
    required String artifactId,
    required int policyVersion,
    required DateTime now,
  }) {
    return PolicyDeliveryState(
      artifactId: artifactId,
      policyVersion: policyVersion,
      phase: PolicyDeliveryPhase.configured,
      updatedAt: now.toUtc(),
    );
  }

  /// New parent edit bumps version and resets to configured.
  static PolicyDeliveryState reconfigure(
    PolicyDeliveryState current, {
    required int newPolicyVersion,
    required DateTime now,
  }) {
    if (newPolicyVersion <= current.policyVersion) {
      throw ArgumentError(
        'newPolicyVersion ($newPolicyVersion) must exceed '
        'current (${current.policyVersion})',
      );
    }
    return PolicyDeliveryState(
      artifactId: current.artifactId,
      policyVersion: newPolicyVersion,
      phase: PolicyDeliveryPhase.configured,
      updatedAt: now.toUtc(),
    );
  }

  /// Advances exactly one step forward. Throws if already verified or jump.
  static PolicyDeliveryState advance(
    PolicyDeliveryState current, {
    required PolicyDeliveryPhase to,
    required DateTime now,
    String? error,
  }) {
    final expected = _next(current.phase);
    if (expected == null) {
      throw StateError('Already verified — cannot advance');
    }
    if (to != expected) {
      throw StateError(
        'Illegal advance ${current.phase.wireName} → ${to.wireName}; '
        'expected ${expected.wireName}',
      );
    }
    return current.copyWith(
      phase: to,
      updatedAt: now.toUtc(),
      lastError: error,
      clearError: error == null,
    );
  }

  static PolicyDeliveryPhase? _next(PolicyDeliveryPhase phase) {
    final i = phase.index;
    if (i >= _order.length - 1) return null;
    return _order[i + 1];
  }

  /// Convenience: walk to [target] one step at a time (same version).
  static PolicyDeliveryState advanceTo(
    PolicyDeliveryState current, {
    required PolicyDeliveryPhase target,
    required DateTime now,
  }) {
    var state = current;
    while (state.phase.rank < target.rank) {
      final next = _next(state.phase)!;
      state = advance(state, to: next, now: now);
    }
    return state;
  }
}
