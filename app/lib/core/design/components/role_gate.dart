import 'package:flutter/widgets.dart';

import 'package:family_os/core/runtime/permission_matrix.dart';

/// Renders a control according to the shared [PermissionMatrix].
///
/// The caller supplies all wording, so this primitive never embeds user-facing
/// copy. A gate is presentation only; the matching server/native mutation must
/// enforce the same authority independently.
final class RoleGate extends StatelessWidget {
  const RoleGate({
    super.key,
    required this.profile,
    required this.capability,
    required this.builder,
  });

  final PanelProfile profile;
  final PanelCapability capability;
  final Widget Function(BuildContext context, PermissionDisposition disposition)
  builder;

  @override
  Widget build(BuildContext context) {
    final disposition = PermissionMatrix.dispositionFor(profile, capability);
    return builder(context, disposition);
  }
}
