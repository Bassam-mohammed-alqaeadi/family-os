import 'package:flutter/material.dart' show TimeOfDay;

import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/policy/notification_delivery.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_tier.dart';
import 'package:family_os/core/policy/sos_fire.dart';

/// A recording stand-in for the SOS authority, for tests only.
///
/// It lives under `test/` on purpose. The service it replaced (`MockSosFireService`) sat in
/// `lib/` and was reachable from production code, which made "the alarm succeeded" a thing
/// the *product* could say without anything having happened. Tests still need to know a
/// press happened and how it was answered, and that is a question about a test double, not
/// about a build: production reaches the server through `ServerSosFireService`.
///
/// It reports `reachedServer: false` rather than pretending to be one, so a test that cares
/// about the difference can assert it.
final class RecordingSosFireService implements SosFireService {
  RecordingSosFireService({
    Map<String, NotificationPrefs>? prefsByMember,
    Map<String, MotherLevel?>? motherLevelByMember,
    DateTime Function()? clock,
  }) : _prefsByMember = prefsByMember,
       _motherLevelByMember = motherLevelByMember,
       _clock = clock ?? DateTime.now;

  final Map<String, NotificationPrefs>? _prefsByMember;
  final Map<String, MotherLevel?>? _motherLevelByMember;
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
    fireCount++;
    final when = (at ?? _clock()).toUtc();
    final actor = (actorId == null || actorId.isEmpty) ? childId : actorId;
    final result = SosFireResult(
      fired: true,
      at: when,
      recipientDeliveries: simulate(
        recipients,
        prefsByMember: _prefsByMember,
        now: clock,
      ),
      childId: childId,
      actorId: actor,
    );
    fireLog.add(result);
    return result;
  }

  /// What a critical alert does to [recipients]: every one of them receives it, whatever
  /// their quiet hours say (SET-010 / P-4).
  ///
  /// This used to be a product function (`NotificationDelivery.simulateSosAlert`), which
  /// made a *simulation* part of the shipping library. The policy it asserted - quiet hours
  /// cannot mute SOS, and no mother level is excluded - stays in the library as
  /// `NotificationDelivery.shouldDeliver` and `guardianReceivesSos`, tested directly.
  static List<NotificationDeliveryResult> simulate(
    List<String> recipients, {
    Map<String, NotificationPrefs>? prefsByMember,
    Map<String, MotherLevel?>? motherLevelByMember,
    TimeOfDay? now,
  }) {
    final clock = now ?? const TimeOfDay(hour: 23, minute: 0);
    return [
      for (final id in recipients)
        NotificationDeliveryResult(
          recipientId: id,
          tier: NotificationTier.critical,
          delivered:
              NotificationDelivery.guardianReceivesSos(
                memberId: id,
                motherLevel: motherLevelByMember?[id],
              ) &&
              NotificationDelivery.shouldDeliver(
                NotificationTier.critical,
                prefsByMember?[id] ??
                    NotificationPrefs.defaults(memberId: id).copyWith(
                      quietHoursEnabled: true,
                      quietStart: NotificationPrefs.defaultQuietStart,
                      quietEnd: NotificationPrefs.defaultQuietEnd,
                    ),
                clock,
              ),
        ),
    ];
  }
}
