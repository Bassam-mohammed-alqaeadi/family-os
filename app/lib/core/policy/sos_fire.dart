import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'notification_delivery.dart';
import 'notification_prefs.dart';

/// Result of an SOS fire attempt (UI-007 / P-4 · OD-13).
@immutable
final class SosFireResult {
  const SosFireResult({
    required this.fired,
    required this.at,
    required this.recipientDeliveries,
    required this.childId,
    required this.actorId,
  });

  /// Always `true` on the Stage-1 mock — entitlement cannot suppress fire.
  final bool fired;
  final DateTime at;
  final List<NotificationDeliveryResult> recipientDeliveries;

  /// Subject child the alert is about (viewed child, active child, or self).
  final String childId;

  /// Who pressed SOS (child id or parent membership id).
  final String actorId;
}

/// SOS fire path — entitlement-free by construction (UI-007 / SET-PAYWALL-RISK).
///
/// This library must never import billing entitlement modules.
/// Plan cancel / expired / trial UI cannot reach this API.
abstract class SosFireService {
  /// Fires SOS to guardians. Ignores plan state — there is no billing parameter.
  ///
  /// [childId] = subject (the child concerned). [actorId] = who pressed;
  /// when omitted, defaults to [childId] (child self-fire).
  Future<SosFireResult> fire({
    required String childId,
    String? actorId,
    List<String> recipients = const ['father', 'mother'],
    DateTime? at,
    TimeOfDay? clock,
  });
}

/// Stage-1 mock SOS fire — always succeeds; uses [NotificationDelivery.simulateSosAlert].
final class MockSosFireService implements SosFireService {
  MockSosFireService({
    Map<String, NotificationPrefs>? prefsByMember,
    DateTime Function()? clock,
  })  : _prefsByMember = prefsByMember,
        _clock = clock ?? DateTime.now;

  final Map<String, NotificationPrefs>? _prefsByMember;
  final DateTime Function() _clock;

  int fireCount = 0;
  final List<SosFireResult> fireLog = [];

  @override
  Future<SosFireResult> fire({
    required String childId,
    String? actorId,
    List<String> recipients = const ['father', 'mother'],
    DateTime? at,
    TimeOfDay? clock,
  }) async {
    assert(childId.isNotEmpty, 'childId required');
    fireCount++;
    final when = at ?? _clock().toUtc();
    final actor = (actorId == null || actorId.isEmpty) ? childId : actorId;
    final deliveries = NotificationDelivery.simulateSosAlert(
      recipients,
      prefsByMember: _prefsByMember,
      now: clock ?? const TimeOfDay(hour: 23, minute: 0),
    );
    final result = SosFireResult(
      fired: true,
      at: when,
      recipientDeliveries: deliveries,
      childId: childId,
      actorId: actor,
    );
    fireLog.add(result);
    return result;
  }
}

/// Stage-1 shared SOS fire seam.
final MockSosFireService stage1SosFireService = MockSosFireService();
