import 'device_lifecycle.dart';

/// Where a device's suggested next step leads, when it is the guardian's to take.
///
/// The card's copy layer already says what would help. This decides whether that step can
/// be taken from the parent's own handset, and where it goes, so the two answers cannot
/// drift apart: a button that leads nowhere and a sentence with no way to act are the same
/// lie told in two directions.
///
/// **One state offers a step a parent can take today: a device cut off after a loss.** It
/// is replaced by pairing the child's device again - and deliberately by walking the whole
/// pairing journey a first device walks: a fresh code, claimed once, expiring on its own
/// clock. There is no "known device" shortcut, because a shortcut would be a second way
/// into the family for whoever is holding the handset that was reported lost.
///
/// **Every other attention state belongs to the child's handset**, not to this screen: a
/// device that never reported needs the app opened on it, and a device that is late or
/// offline needs to be switched on or reconnected. Sending the guardian to a pairing screen
/// for those would produce a brand-new device record and leave the real one untouched - an
/// action that cannot change the outcome, dressed as help.
///
/// Returns null when there is nothing this handset can usefully do.
String? deviceRepairPath(FoundationGateGuardianDevice device) {
  return switch (device.health.state) {
    FoundationGateDeviceHealthState.revoked =>
      '/scr-fat-004?childId=${Uri.encodeComponent(device.childId)}',
    // The remaining states have no destination here, and listing them one by one is the
    // point: a future state added to the lifecycle forces a decision in this switch
    // instead of silently inheriting "no action".
    FoundationGateDeviceHealthState.awaitingPairing ||
    FoundationGateDeviceHealthState.neverReported ||
    FoundationGateDeviceHealthState.active ||
    FoundationGateDeviceHealthState.stale ||
    FoundationGateDeviceHealthState.offline =>
      null,
  };
}
