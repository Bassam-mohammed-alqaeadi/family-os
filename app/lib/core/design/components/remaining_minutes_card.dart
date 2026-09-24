import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Labeled daily / temporary-grant / wallet remaining minutes (G-A vs earned).
class RemainingMinutesCard extends StatelessWidget {
  const RemainingMinutesCard({
    super.key,
    this.dailyMinutes,
    this.grantMinutes,
    this.walletMinutes,
    this.title,
  });

  final int? dailyMinutes;
  final int? grantMinutes;
  final int? walletMinutes;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return AppCard(
      title: title ?? l10n.remainingMinutesCardTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dailyMinutes != null)
            _row(
              colors,
              l10n.remainingMinutesDailyLabel,
              l10n.remainingMinutesValue(dailyMinutes!),
            ),
          if (grantMinutes != null) ...[
            if (dailyMinutes != null) const SizedBox(height: 8),
            _row(
              colors,
              l10n.remainingMinutesGrantLabel,
              l10n.remainingMinutesValue(grantMinutes!),
            ),
          ],
          if (walletMinutes != null) ...[
            if (dailyMinutes != null || grantMinutes != null)
              const SizedBox(height: 8),
            _row(
              colors,
              l10n.remainingMinutesWalletLabel,
              l10n.remainingMinutesValue(walletMinutes!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(FamilyColors colors, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ],
    );
  }
}
