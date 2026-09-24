import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Shared honesty badge for FS capability statuses (Rule 15).
class CapabilityHonestyBadge extends StatelessWidget {
  const CapabilityHonestyBadge({super.key, required this.status});

  final CapabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, variant) = switch (status) {
      CapabilityStatus.implemented => (
        l10n.capabilityStatusImplemented,
        TagVariant.g,
      ),
      CapabilityStatus.mockRemote => (
        l10n.capabilityStatusMockRemote,
        TagVariant.a,
      ),
      CapabilityStatus.degraded => (
        l10n.capabilityStatusDegraded,
        TagVariant.a,
      ),
      CapabilityStatus.unsupported => (
        l10n.capabilityStatusUnsupported,
        TagVariant.p,
      ),
      CapabilityStatus.notImplemented => (
        l10n.capabilityStatusNotImplemented,
        TagVariant.p,
      ),
    };
    return Tag(label: label, variant: variant);
  }
}
