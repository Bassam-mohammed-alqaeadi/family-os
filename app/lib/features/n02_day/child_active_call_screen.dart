import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/active_call_repository.dart';

/// Widget keys for SCR-CHD-009 acceptance.
abstract final class ChildActiveCallKeys {
  static const screen = Key('child_active_call_screen');
  static const loading = Key('child_active_call_loading');
  static const missingId = Key('child_active_call_missing_id');
  static const notFound = Key('child_active_call_not_found');
  static const error = Key('child_active_call_error');
  static const body = Key('child_active_call_body');
  static const avatar = Key('child_active_call_avatar');
  static const peerLabel = Key('child_active_call_peer');
  static const statusLine = Key('child_active_call_status');
  static const mute = Key('child_active_call_mute');
  static const speaker = Key('child_active_call_speaker');
  static const end = Key('child_active_call_end');
  static const sosCta = Key('child_active_call_sos');
  static const parentLean = Key('child_active_call_parent_lean');
  static const title = Key('child_active_call_title');
}

/// SCR-CHD-009 — مكالمة (child active call — slim vs FAT-023).
///
/// Mute / speaker / end mock seams. End → CHD-007. P-4 SOS → CHD-005.
/// No video / play-together. Parent lean. Rule 23 empty default.
class ChildActiveCallScreen extends StatefulWidget {
  const ChildActiveCallScreen({
    super.key,
    this.callId,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.onSos,
    this.onMute,
    this.onSpeaker,
    this.onEnd,
  });

  final String? callId;
  final ActiveCallRepository? repository;
  final AppRole? roleOverride;
  final SosFireService? sosFire;
  final VoidCallback? onSos;
  final void Function(bool muted)? onMute;
  final void Function(bool speakerOn)? onSpeaker;
  final VoidCallback? onEnd;

  @override
  State<ChildActiveCallScreen> createState() => _ChildActiveCallScreenState();
}

class _ChildActiveCallScreenState extends State<ChildActiveCallScreen>
    with SingleTickerProviderStateMixin {
  late final ActiveCallRepository _repo;
  late final AnimationController _pulse;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  var _muted = false;
  var _speakerOn = false;
  var _actionBusy = false;
  ActiveCallDetail? _detail;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  String? get _id {
    final raw = widget.callId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ActiveCallRepository;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _id;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _detail = null;
    });
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final detail = await _repo.load(id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      if (detail != null && !MediaQuery.disableAnimationsOf(context)) {
        _pulse.repeat(reverse: true);
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    await fire.fire(childId: 'child_local');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.go('/scr-chd-005');
  }

  Future<void> _toggleMute() async {
    final id = _id;
    if (id == null || _detail == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final next = !_muted;
      await _repo.setMuted(id, muted: next);
      if (!mounted) return;
      setState(() {
        _muted = next;
        _actionBusy = false;
      });
      widget.onMute?.call(next);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? l10n.childActiveCallMuteOnToast
                : l10n.childActiveCallMuteOffToast,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _actionBusy = false);
    }
  }

  Future<void> _toggleSpeaker() async {
    final id = _id;
    if (id == null || _detail == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final next = !_speakerOn;
      await _repo.setSpeaker(id, speakerOn: next);
      if (!mounted) return;
      setState(() {
        _speakerOn = next;
        _actionBusy = false;
      });
      widget.onSpeaker?.call(next);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? l10n.childActiveCallSpeakerOnToast
                : l10n.childActiveCallSpeakerOffToast,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _actionBusy = false);
    }
  }

  Future<void> _endCall() async {
    final id = _id;
    if (id == null || _detail == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await _repo.end(id);
      if (!mounted) return;
      setState(() => _actionBusy = false);
      _pulse.stop();
      widget.onEnd?.call();
      if (widget.onEnd != null) return;
      context.go('/scr-chd-007');
    } on Object {
      if (!mounted) return;
      setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return FamilyUiModeScope(
      mode: FamilyUiMode.child,
      child: Scaffold(
        key: ChildActiveCallKeys.screen,
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          title: Text(
            l10n.childActiveCallTitle,
            key: ChildActiveCallKeys.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          actions: [
            IconButton(
              key: ChildActiveCallKeys.sosCta,
              tooltip: l10n.spineCtaSosSemantics,
              onPressed: _sosBusy ? null : _openSos,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.padded,
                minimumSize: WidgetStatePropertyAll(Size(48, 48)),
              ),
              icon: Icon(Icons.sos, color: colors.coral),
            ),
          ],
        ),
        body: SafeArea(child: _buildBody(l10n, colors)),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, FamilyColors colors) {
    if (_role != AppRole.child) {
      return AppEmptyState(
        key: ChildActiveCallKeys.parentLean,
        title: l10n.childActiveCallParentLeanTitle,
        message: l10n.childActiveCallParentLeanMessage,
      );
    }
    if (_loading) {
      return Semantics(
        key: ChildActiveCallKeys.loading,
        label: l10n.childActiveCallLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadFailed) {
      return AppErrorState(
        key: ChildActiveCallKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }
    if (_id == null) {
      return AppEmptyState(
        key: ChildActiveCallKeys.missingId,
        title: l10n.childActiveCallMissingIdTitle,
        message: l10n.childActiveCallMissingIdMessage,
      );
    }
    if (_detail == null) {
      return AppEmptyState(
        key: ChildActiveCallKeys.notFound,
        title: l10n.childActiveCallNotFoundTitle,
        message: l10n.childActiveCallNotFoundMessage,
      );
    }

    final detail = _detail!;
    return Column(
      key: ChildActiveCallKeys.body,
      children: [
        const Spacer(),
        ScaleTransition(
          scale: Tween<double>(begin: 1, end: 1.06).animate(_pulse),
          child: CircleAvatar(
            key: ChildActiveCallKeys.avatar,
            radius: 56,
            backgroundColor: Color(detail.avatarColor),
            child: Text(detail.emoji, style: const TextStyle(fontSize: 42)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          detail.peerLabel,
          key: ChildActiveCallKeys.peerLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.childActiveCallStatus(detail.elapsedLabel),
          key: ChildActiveCallKeys.statusLine,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundAction(
                key: ChildActiveCallKeys.mute,
                label: l10n.childActiveCallMuteSemantics,
                icon: _muted ? Icons.mic_off : Icons.mic,
                color: _muted ? colors.coral : colors.teal,
                onPressed: _actionBusy ? null : _toggleMute,
              ),
              _RoundAction(
                key: ChildActiveCallKeys.speaker,
                label: l10n.childActiveCallSpeakerSemantics,
                icon: _speakerOn ? Icons.volume_up : Icons.volume_down,
                color: _speakerOn ? colors.teal : colors.ink2,
                onPressed: _actionBusy ? null : _toggleSpeaker,
              ),
              _RoundAction(
                key: ChildActiveCallKeys.end,
                label: l10n.childActiveCallEndSemantics,
                icon: Icons.call_end,
                color: colors.coral,
                onPressed: _actionBusy ? null : _endCall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: color.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}
