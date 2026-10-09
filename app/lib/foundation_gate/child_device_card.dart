import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';

import 'device_lifecycle.dart';
import 'device_lifecycle_copy.dart';

/// One child's device condition, as a guardian sees it in the roster.
///
/// The card obeys one rule above all: it earns its place on screen. When a child
/// has a device that is working, this renders nothing at all - the family day
/// should be quiet, and a green badge that never changes is decoration, not
/// information. Something appears only when the server has decided a human should
/// look: a device cut off, never started, quiet, or late.
///
/// Every visible element has a function. The dot and the state name carry the
/// condition, the second line names the cause in words, and the action appears
/// only when there is a step that would actually help. Nothing is tappable that
/// has nowhere to go.
class ChildDeviceCard extends StatelessWidget {
  const ChildDeviceCard({
    super.key,
    required this.device,
    required this.copy,
    this.onRepair,
    this.isWide = false,
  });

  final FoundationGateGuardianDevice device;
  final DeviceLifecycleCopy copy;

  /// Runs when the guardian accepts the suggested next step. Null means the
  /// server suggested nothing to do, and then the control is absent rather than
  /// present and inert.
  final VoidCallback? onRepair;

  /// Tablet layout: the action sits beside the text instead of under it.
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final nextStep = copy.nextStep(device);
    final canRepair = nextStep != null && onRepair != null;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _StateDot(state: device.health.state, colors: colors),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${device.deviceLabel} · ${copy.stateName(device.health.state)}',
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          nextStep ?? copy.reason(device.health.reasonCode),
          style: TextStyle(color: colors.ink2, fontSize: 12, height: 1.4),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: isWide
          ? Row(
              children: <Widget>[
                Expanded(child: details),
                if (canRepair) ...<Widget>[
                  const SizedBox(width: 12),
                  _RepairAction(copy: copy, onRepair: onRepair),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                details,
                if (canRepair) ...<Widget>[
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _RepairAction(copy: copy, onRepair: onRepair),
                  ),
                ],
              ],
            ),
    );
  }
}

/// The colour of a state comes from the theme, never from a literal, so a device
/// that was cut off reads as a fault in both brightness modes and both languages.
///
/// A fault is coral: the device will not report again until someone acts. A late
/// or quiet device is amber: it may be a flat battery rather than a broken
/// promise, and colouring it as damage would train a guardian to ignore coral.
class _StateDot extends StatelessWidget {
  const _StateDot({required this.state, required this.colors});

  final FoundationGateDeviceHealthState state;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final isFault = state == FoundationGateDeviceHealthState.revoked ||
        state == FoundationGateDeviceHealthState.neverReported;
    return Semantics(
      // The dot is the only purely visual element here, so it is labelled rather
      // than left as a shape a screen reader would skip in silence.
      label: state.wireName,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFault ? colors.coral : colors.amber,
        ),
      ),
    );
  }
}

class _RepairAction extends StatelessWidget {
  const _RepairAction({required this.copy, required this.onRepair});

  final DeviceLifecycleCopy copy;
  final VoidCallback? onRepair;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return TextButton(
      onPressed: onRepair,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: colors.p600,
      ),
      child: Text(
        copy.repairAction,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
