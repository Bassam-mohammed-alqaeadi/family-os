import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_toast.dart';

/// Widget keys for UI-008 / Rule 24 acceptance.
abstract final class SettingsPersistToggleKeys {
  static const loading = Key('settings_persist_toggle_loading');
  static const error = Key('settings_persist_toggle_error');
}

/// UI-008 / Rule 24 — settings spine toggle with persist feedback.
///
/// **Law for future SET toggles:** do not ship bare [Switch] / [SwitchListTile]
/// that only flip local CSS/state. Wire every former VISUAL toggle through this
/// control (or an equivalent that shows loading → success toast / error+revert).
///
/// Competitive pattern: Family Link / Qustodio — settings flips ack or fail
/// honestly; never silent.
class SettingsPersistToggle extends StatefulWidget {
  const SettingsPersistToggle({
    super.key,
    required this.value,
    required this.title,
    required this.onPersist,
    required this.successMessage,
    this.subtitle,
    this.errorMessage,
    this.enabled = true,
    this.switchKey,
    this.debounce = const Duration(milliseconds: 400),
  });

  /// Source-of-truth value from the host (repository-backed).
  final bool value;

  final String title;
  final String? subtitle;

  /// Injectable async save. Complete normally on success; throw on failure.
  final Future<void> Function(bool next) onPersist;

  /// Shown via [AppToast] after a successful persist.
  final String successMessage;

  /// Inline error copy on failure; host may pass l10n [settingsPersistError].
  final String? errorMessage;

  final bool enabled;

  /// Optional key on the inner [Switch] (host acceptance keys).
  final Key? switchKey;

  /// Rapid-tap window — taps inside this window are ignored (Rule 24).
  final Duration debounce;

  @override
  State<SettingsPersistToggle> createState() => _SettingsPersistToggleState();
}

class _SettingsPersistToggleState extends State<SettingsPersistToggle> {
  bool? _optimistic;
  var _saving = false;
  var _error = false;
  DateTime? _lastAcceptedTap;

  bool get _shown => _optimistic ?? widget.value;

  @override
  void didUpdateWidget(covariant SettingsPersistToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving && widget.value != oldWidget.value) {
      _optimistic = null;
    }
  }

  Future<void> _handleChanged(bool next) async {
    if (!widget.enabled || _saving) return;

    final now = DateTime.now();
    if (_lastAcceptedTap != null &&
        now.difference(_lastAcceptedTap!) < widget.debounce) {
      return;
    }
    _lastAcceptedTap = now;

    final previous = widget.value;
    setState(() {
      _optimistic = next;
      _saving = true;
      _error = false;
    });

    try {
      await widget.onPersist(next);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _optimistic = null;
      });
      AppToast.show(context, message: widget.successMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _optimistic = previous;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final canInteract = widget.enabled && !_saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: colors.ink2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_saving)
              SizedBox(
                key: SettingsPersistToggleKeys.loading,
                width: 48,
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.p700,
                    ),
                  ),
                ),
              )
            else
              Semantics(
                label: widget.title,
                toggled: _shown,
                enabled: canInteract,
                excludeSemantics: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Switch(
                      key: widget.switchKey,
                      value: _shown,
                      onChanged: canInteract ? _handleChanged : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_error && widget.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            key: SettingsPersistToggleKeys.error,
            widget.errorMessage!,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.amberDeep,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
