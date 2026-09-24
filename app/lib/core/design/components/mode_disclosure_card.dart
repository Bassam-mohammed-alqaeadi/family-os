import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/modes/modes.dart';

/// Widget keys for FS-005 child Mode disclosure (W-C01 / W-C02).
abstract final class ModeDisclosureKeys {
  static const card = Key('mode_disclosure_card');
  static const idle = Key('mode_disclosure_idle');
  static const multi = Key('mode_disclosure_multi');
  static const single = Key('mode_disclosure_single');
  static const reachability = Key('mode_disclosure_reachability');
}

/// Child-facing active Mode honesty — no admin / no cancel (MODE-OD-10).
class ModeDisclosureCard extends StatelessWidget {
  const ModeDisclosureCard({
    super.key,
    required this.evaluation,
    required this.labelsByModeId,
  });

  final ModesEvaluation evaluation;

  /// Display labels for applicable mode document ids.
  final Map<String, String> labelsByModeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    if (!evaluation.hasActiveModes) {
      return Text(
        key: ModeDisclosureKeys.idle,
        l10n.fs005ChildModeIdle,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.ink2,
        ),
      );
    }

    final names = [
      for (final id in evaluation.applicableModeIds) labelsByModeId[id] ?? id,
    ]..sort();

    final multi = names.length > 1;
    final title = multi
        ? l10n.fs005ChildModesOn(names.join(' · '))
        : l10n.fs005ChildModeOn(names.first);
    final body = multi
        ? l10n.fs005ChildModesStricter
        : l10n.fs005ChildModeLimited;

    return DecoratedBox(
      key: ModeDisclosureKeys.card,
      decoration: BoxDecoration(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              key: multi ? ModeDisclosureKeys.multi : ModeDisclosureKeys.single,
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              key: ModeDisclosureKeys.reachability,
              l10n.fs005ChildReachability,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.tealDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
