import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_break_glass.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';

/// Break-glass sheet keys (FAT-018).
abstract final class SosBreakGlassKeys {
  static const sheet = Key('sos_break_glass_sheet');
  static const reasonField = Key('sos_break_glass_reason');
  static const confirm = Key('sos_break_glass_confirm');
  static const cancel = Key('sos_break_glass_cancel');
  static const activeBanner = Key('sos_break_glass_active');
}

/// Temporary override UI — never mutates permanent SOS ladder policy.
Future<SosBreakGlassSession?> showSosBreakGlassSheet({
  required BuildContext context,
  required SosActor actor,
  required InMemorySosBreakGlassStore store,
  String capabilityKey = 'sos_response_override',
  Duration duration = const Duration(minutes: 30),
}) {
  if (!SosRoleActions.canBreakGlass(actor)) {
    return Future.value(null);
  }
  return showModalBottomSheet<SosBreakGlassSession>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SosBreakGlassSheet(
      actor: actor,
      store: store,
      capabilityKey: capabilityKey,
      duration: duration,
    ),
  );
}

class _SosBreakGlassSheet extends StatefulWidget {
  const _SosBreakGlassSheet({
    required this.actor,
    required this.store,
    required this.capabilityKey,
    required this.duration,
  });

  final SosActor actor;
  final InMemorySosBreakGlassStore store;
  final String capabilityKey;
  final Duration duration;

  @override
  State<_SosBreakGlassSheet> createState() => _SosBreakGlassSheetState();
}

class _SosBreakGlassSheetState extends State<_SosBreakGlassSheet> {
  final _reason = TextEditingController();
  var _confirming = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final text = _reason.text.trim();
    if (text.isEmpty) return;
    if (!_confirming) {
      setState(() => _confirming = true);
      return;
    }
    final session = widget.store.start(
      actor: widget.actor,
      capabilityKey: widget.capabilityKey,
      reason: text,
      duration: widget.duration,
    );
    Navigator.of(context).pop(session);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final minutes = widget.duration.inMinutes.clamp(1, 24 * 60);

    return Padding(
      key: SosBreakGlassKeys.sheet,
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sosBreakGlassTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sosBreakGlassBody(minutes),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: SosBreakGlassKeys.reasonField,
            controller: _reason,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.sosBreakGlassReasonLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: SosBreakGlassKeys.confirm,
            onPressed: () => _submit(l10n),
            child: Text(
              _confirming
                  ? l10n.sosBreakGlassConfirmCta
                  : l10n.sosBreakGlassContinueCta,
            ),
          ),
          TextButton(
            key: SosBreakGlassKeys.cancel,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.sosBreakGlassCancelCta),
          ),
        ],
      ),
    );
  }
}
