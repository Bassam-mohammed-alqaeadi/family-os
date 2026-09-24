import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Warning when remaining entertainment minutes are ≤ 5.
class TimeWarningBanner extends StatelessWidget {
  const TimeWarningBanner({
    super.key,
    required this.remainingMinutes,
    this.message,
  });

  final int remainingMinutes;

  /// When null, uses [AppLocalizations.timeWarningBannerMessage].
  final String? message;

  /// True when the banner should render (≤ 5 min remaining, non-negative).
  static bool shouldShow(int remainingMinutes) =>
      remainingMinutes >= 0 && remainingMinutes <= 5;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(remainingMinutes)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return BannerNote(
      variant: BannerVariant.a,
      leading: Icon(Icons.timer_outlined, size: 18, color: colors.amberDeep),
      message: message ?? l10n.timeWarningBannerMessage(remainingMinutes),
    );
  }
}
