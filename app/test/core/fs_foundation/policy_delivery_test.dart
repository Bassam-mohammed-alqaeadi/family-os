import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/fs_foundation/policy_delivery.dart';

void main() {
  final now = DateTime.utc(2026, 9, 24, 12);

  test('start begins at CONFIGURED', () {
    final s = PolicyDeliveryTransitions.start(
      artifactId: 'wf.family',
      policyVersion: 1,
      now: now,
    );
    expect(s.phase, PolicyDeliveryPhase.configured);
    expect(s.policyVersion, 1);
  });

  test('advance walks Configured→…→Verified', () {
    var s = PolicyDeliveryTransitions.start(
      artifactId: 'wf.family',
      policyVersion: 1,
      now: now,
    );
    s = PolicyDeliveryTransitions.advanceTo(
      s,
      target: PolicyDeliveryPhase.verified,
      now: now,
    );
    expect(s.phase, PolicyDeliveryPhase.verified);
    expect(s.isVerified, isTrue);
  });

  test('illegal skip throws', () {
    final s = PolicyDeliveryTransitions.start(
      artifactId: 'ac.child',
      policyVersion: 1,
      now: now,
    );
    expect(
      () => PolicyDeliveryTransitions.advance(
        s,
        to: PolicyDeliveryPhase.applied,
        now: now,
      ),
      throwsStateError,
    );
  });

  test('reconfigure bumps version and resets phase', () {
    var s = PolicyDeliveryTransitions.start(
      artifactId: 'modes.stack',
      policyVersion: 1,
      now: now,
    );
    s = PolicyDeliveryTransitions.advanceTo(
      s,
      target: PolicyDeliveryPhase.delivered,
      now: now,
    );
    s = PolicyDeliveryTransitions.reconfigure(s, newPolicyVersion: 2, now: now);
    expect(s.policyVersion, 2);
    expect(s.phase, PolicyDeliveryPhase.configured);
  });
}
