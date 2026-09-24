import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Child cancel / false-alarm confirmation sheet (CHD-006).
abstract final class SosCancelConfirmationKeys {
  static const sheet = Key('sos_cancel_confirmation_sheet');
  static const confirm = Key('sos_cancel_confirmation_confirm');
  static const back = Key('sos_cancel_confirmation_back');
}

Future<bool> showSosCancelConfirmation(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final colors = Theme.of(ctx).extension<FamilyColors>()!;
      return Padding(
        key: SosCancelConfirmationKeys.sheet,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.childSosInProgressCancelSheetTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.coral,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.childSosInProgressCancelSheetBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: l10n.childSosInProgressConfirmSafeSemantics,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: FilledButton(
                  key: SosCancelConfirmationKeys.confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.mint,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.childSosInProgressConfirmSafeCta),
                ),
              ),
            ),
            TextButton(
              key: SosCancelConfirmationKeys.back,
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.childSosInProgressCancelBackCta),
            ),
          ],
        ),
      );
    },
  );
  return result == true;
}
