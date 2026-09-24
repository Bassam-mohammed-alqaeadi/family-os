import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';

/// Keys for Silent Location Request sheet (LOC-P-SLR).
abstract final class SilentLocateKeys {
  static const sheet = Key('silent_locate_sheet');
  static const confirm = Key('silent_locate_confirm');
  static const dismiss = Key('silent_locate_dismiss');
  static const result = Key('silent_locate_result');
  static const gpsBadge = Key('silent_locate_gps_badge');
}

/// Parent Silent Location Request — honest result; no child interactive UX.
class SilentLocateSheet extends StatefulWidget {
  const SilentLocateSheet({
    super.key,
    required this.childId,
    required this.childLabel,
    required this.onRequest,
    this.gpsStatus = CapabilityStatus.notImplemented,
  });

  final String childId;
  final String childLabel;
  final Future<SilentLocateResult> Function() onRequest;
  final CapabilityStatus gpsStatus;

  static Future<SilentLocateResult?> show(
    BuildContext context, {
    required String childId,
    required String childLabel,
    required Future<SilentLocateResult> Function() onRequest,
    CapabilityStatus gpsStatus = CapabilityStatus.notImplemented,
  }) {
    return showModalBottomSheet<SilentLocateResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SilentLocateSheet(
        childId: childId,
        childLabel: childLabel,
        onRequest: onRequest,
        gpsStatus: gpsStatus,
      ),
    );
  }

  @override
  State<SilentLocateSheet> createState() => _SilentLocateSheetState();
}

class _SilentLocateSheetState extends State<SilentLocateSheet> {
  var _busy = false;
  SilentLocateResult? _result;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await widget.onRequest();
    if (!mounted) return;
    setState(() {
      _result = result;
      _busy = false;
    });
  }

  String _resultLabel(AppLocalizations l10n, SilentLocateResult r) {
    return switch (r.status) {
      SilentLocateResultStatus.pending => l10n.silentLocateResultPending,
      SilentLocateResultStatus.located => l10n.silentLocateResultLocated,
      SilentLocateResultStatus.staleLastKnown => l10n.silentLocateResultStale,
      SilentLocateResultStatus.unavailable =>
        l10n.silentLocateResultUnavailable,
      SilentLocateResultStatus.notImplementedGps =>
        l10n.silentLocateResultGpsNotImplemented,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SafeArea(
      key: SilentLocateKeys.sheet,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.silentLocateTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.silentLocateBody(widget.childLabel),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                key: SilentLocateKeys.gpsBadge,
                child: CapabilityHonestyBadge(status: widget.gpsStatus),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 14),
              Container(
                key: SilentLocateKeys.result,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.p50,
                  borderRadius: BorderRadius.circular(radii.card),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  _resultLabel(l10n, _result!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_result == null)
              PrimaryBtn(
                key: SilentLocateKeys.confirm,
                label: l10n.silentLocateConfirmCta,
                onPressed: _busy ? null : _confirm,
              )
            else
              PrimaryBtn(
                key: SilentLocateKeys.dismiss,
                label: l10n.silentLocateDismissCta,
                onPressed: () => Navigator.of(context).pop(_result),
              ),
          ],
        ),
      ),
    );
  }
}
