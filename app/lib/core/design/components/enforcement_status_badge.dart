import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Honesty badge — Stage-1 enforcement is simulated (not device MDM).
class EnforcementStatusBadge extends StatelessWidget {
  const EnforcementStatusBadge({
    super.key,
    this.label,
    this.variant = TagVariant.a,
  });

  /// When null, uses [AppLocalizations.enforcementSimulatedLabel].
  final String? label;
  final TagVariant variant;

  @override
  Widget build(BuildContext context) {
    final text =
        label ?? AppLocalizations.of(context).enforcementSimulatedLabel;
    return Tag(label: text, variant: variant);
  }
}
