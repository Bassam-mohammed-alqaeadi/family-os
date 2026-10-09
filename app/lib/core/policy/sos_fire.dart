import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'notification_delivery.dart';

/// Result of an SOS fire attempt (UI-007 / P-4 · OD-13).
///
/// [fired] is the honest answer to "did this press reach something that will raise the
/// alarm". It is `true` only when an authority accepted the press and can be asked about it
/// afterwards; a device with no authority bound answers `false` and says so through
/// [reachedServer], rather than succeeding locally where nobody would ever be told.
@immutable
final class SosFireResult {
  const SosFireResult({
    required this.fired,
    required this.at,
    required this.recipientDeliveries,
    required this.childId,
    required this.actorId,
    this.alertId,
    this.reachedServer = false,
    this.duplicate = false,
  });

  /// True when an authority accepted this press. A local-only press is `false`.
  final bool fired;
  final DateTime at;
  final List<NotificationDeliveryResult> recipientDeliveries;

  /// Subject child the alert is about (viewed child, active child, or self).
  final String childId;

  /// Who pressed SOS (child id or parent membership id).
  final String actorId;

  /// The incident this press belongs to on the server, when there is one.
  ///
  /// A screen hands this id to the board rather than an id it invented, so the child and
  /// the parent are looking at the same incident.
  final String? alertId;

  /// True when the press was answered by a server rather than recorded locally.
  final bool reachedServer;

  /// True when the server answered that this child already had an open incident, which
  /// makes this press part of that incident instead of a second one.
  final bool duplicate;
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

/// Raised by a surface that needs an authority which was never bound.
///
/// The screens do not throw this on a press — they answer with
/// [SosFireResult.fired] `false` — but a caller that must know the difference between
/// "recorded here" and "told someone" can ask [activeSosFireService] whether it is wired.
final class SosFireUnavailable implements Exception {
  const SosFireUnavailable();

  @override
  String toString() => 'SosFireUnavailable: no SOS authority is bound in this build';
}

/// The service the family's buttons actually reach.
///
/// Bound once at boot, next to the location authority, from the server session the device
/// already holds. When nothing is bound the answer is [UnwiredSosFireService]: a press is
/// recorded as NOT fired and no recipient is reported as told, because there is nothing in
/// this build that could tell anyone. That is deliberately worse-looking than the mock it
/// replaced and deliberately true: a parent who believes an alarm left a handset stops
/// checking, and the day it mattered nobody was coming.
SosFireService get activeSosFireService =>
    _activeSosFireService ?? const UnwiredSosFireService();

/// True when this build can actually raise an alarm somewhere.
bool get sosFireIsWired => _activeSosFireService != null;

/// Rebinds the authority. Passing null puts the build back to honest refusal, which is what
/// sign-out does.
void bindSosFireService(SosFireService? service) {
  _activeSosFireService = service;
}

SosFireService? _activeSosFireService;

/// The answer when this build has no way to raise an alarm.
///
/// It does not throw on a press: a child holding the button must get a screen, not a
/// crash. It answers [SosFireResult.fired] `false` with no deliveries, which is the shape a
/// surface can render honestly - and no surface in this codebase may describe that press as
/// having reached anyone.
final class UnwiredSosFireService implements SosFireService {
  const UnwiredSosFireService();

  @override
  Future<SosFireResult> fire({
    required String childId,
    String? actorId,
    List<String> recipients = const ['father', 'mother'],
    DateTime? at,
    TimeOfDay? clock,
  }) async {
    return SosFireResult(
      fired: false,
      at: (at ?? DateTime.now()).toUtc(),
      recipientDeliveries: const <NotificationDeliveryResult>[],
      childId: childId,
      actorId: (actorId == null || actorId.isEmpty) ? childId : actorId,
    );
  }
}
