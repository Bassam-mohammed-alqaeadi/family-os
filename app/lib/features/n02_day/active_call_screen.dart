import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/active_call_repository.dart';

/// Widget keys for SCR-FAT-023 acceptance.
abstract final class ActiveCallKeys {
  static const screen = Key('active_call_screen');
  static const loading = Key('active_call_loading');
  static const missingId = Key('active_call_missing_id');
  static const notFound = Key('active_call_not_found');
  static const error = Key('active_call_error');
  static const body = Key('active_call_body');
  static const avatar = Key('active_call_avatar');
  static const peerLabel = Key('active_call_peer');
  static const statusLine = Key('active_call_status');
  static const mute = Key('active_call_mute');
  static const speaker = Key('active_call_speaker');
  static const video = Key('active_call_video');
  static const end = Key('active_call_end');
  static const honesty = Key('active_call_honesty');
  static const playTogether = Key('active_call_play_together');
  static const drawOpen = Key('active_call_draw_open');
  static const xoPlay = Key('active_call_xo_play');
  static const sosCta = Key('active_call_sos');
  static const childLean = Key('active_call_child_lean');
  static const title = Key('active_call_title');
}

/// SCR-FAT-023 — مكالمة جارية (parent active call).
///
/// Opened with `?callId=`. Mute / speaker / video / end are Stage-1 mock seams
/// (LiveKit later). P-4 SOS ungated. Mother OK; child lean. Mock-first —
/// Rule 23 empty default. Empty when [callId] missing.
class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({
    super.key,
    this.callId,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.onSos,
    this.onMute,
    this.onSpeaker,
    this.onVideo,
    this.onEnd,
    this.onDrawOpen,
    this.onXoPlay,
  });

  /// From route `?callId=`.
  final String? callId;

  /// Null → [stage1ActiveCallRepository].
  final ActiveCallRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  final VoidCallback? onSos;

  /// Fired after mute toggle with new muted state.
  final void Function(bool muted)? onMute;

  /// Fired after speaker toggle with new speaker-on state.
  final void Function(bool speakerOn)? onSpeaker;

  /// Fired after camera toggle with new camera-on state.
  final void Function(bool cameraOn)? onVideo;

  /// Fired after end succeeds (before navigate).
  final VoidCallback? onEnd;

  final VoidCallback? onDrawOpen;
  final VoidCallback? onXoPlay;

  @override
  ActiveCallScreenState createState() => ActiveCallScreenState();
}

class ActiveCallScreenState extends State<ActiveCallScreen> {
  late final ActiveCallRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  var _muted = false;
  var _speakerOn = false;
  var _cameraOn = false;
  var _actionBusy = false;
  ActiveCallDetail? _detail;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  String? get _resolvedCallId {
    final raw = widget.callId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  bool get _hasCallId => _resolvedCallId != null;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ActiveCallRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ActiveCallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.callId != widget.callId ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!_hasCallId) {
      setState(() {
        _detail = null;
        _loading = false;
        _loadFailed = false;
        _muted = false;
        _speakerOn = false;
        _cameraOn = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final detail = await _repo.load(_resolvedCallId!);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _loadFailed = false;
        _muted = false;
        _speakerOn = false;
        _cameraOn = detail?.kind == ActiveCallKind.video;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _loading = false;
        _loadFailed = true;
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
    await fire.fire(childId: _resolvedCallId ?? 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  Future<void> _toggleMute() async {
    final id = _resolvedCallId;
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
            next ? l10n.activeCallMuteOnToast : l10n.activeCallMuteOffToast,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _actionBusy = false);
    }
  }

  Future<void> _toggleSpeaker() async {
    final id = _resolvedCallId;
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
                ? l10n.activeCallSpeakerOnToast
                : l10n.activeCallSpeakerOffToast,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _actionBusy = false);
    }
  }

  Future<void> _toggleVideo() async {
    final id = _resolvedCallId;
    if (id == null || _detail == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final next = !_cameraOn;
      await _repo.setCamera(id, cameraOn: next);
      if (!mounted) return;
      setState(() {
        _cameraOn = next;
        _actionBusy = false;
      });
      widget.onVideo?.call(next);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? l10n.activeCallCameraOnToast(_detail!.peerLabel)
                : l10n.activeCallCameraOffToast,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _actionBusy = false);
    }
  }

  Future<void> _endCall() async {
    final id = _resolvedCallId;
    if (id == null || _detail == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await _repo.end(id);
      if (!mounted) return;
      setState(() => _actionBusy = false);
      widget.onEnd?.call();
      if (widget.onEnd != null) return;
      context.go('/scr-fat-024');
    } on Object {
      if (!mounted) return;
      setState(() => _actionBusy = false);
    }
  }

  void _onDrawOpen() {
    if (widget.onDrawOpen != null) {
      widget.onDrawOpen!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.activeCallDrawToast)),
    );
  }

  void _onXoPlay() {
    if (widget.onXoPlay != null) {
      widget.onXoPlay!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.activeCallXoToast)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ActiveCallKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.activeCallTitle,
          key: ActiveCallKeys.title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          // P-4 — SOS never gated by empty/loading/error.
          IconButton(
            key: ActiveCallKeys.sosCta,
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
      body: SafeArea(child: _buildBody(context, l10n, colors)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (!_isParent) {
      return AppEmptyState(
        key: ActiveCallKeys.childLean,
        title: l10n.activeCallChildLeanTitle,
        message: l10n.activeCallChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: ActiveCallKeys.loading,
        label: l10n.activeCallLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: ActiveCallKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    if (!_hasCallId) {
      return AppEmptyState(
        key: ActiveCallKeys.missingId,
        title: l10n.activeCallMissingIdTitle,
        message: l10n.activeCallMissingIdMessage,
      );
    }

    if (_detail == null) {
      return AppEmptyState(
        key: ActiveCallKeys.notFound,
        title: l10n.activeCallNotFoundTitle,
        message: l10n.activeCallNotFoundMessage,
      );
    }

    return _ActiveCallBody(
      detail: _detail!,
      muted: _muted,
      speakerOn: _speakerOn,
      cameraOn: _cameraOn,
      actionBusy: _actionBusy,
      onMute: _toggleMute,
      onSpeaker: _toggleSpeaker,
      onVideo: _toggleVideo,
      onEnd: _endCall,
      onDrawOpen: _onDrawOpen,
      onXoPlay: _onXoPlay,
      l10n: l10n,
      colors: colors,
    );
  }
}

class _ActiveCallBody extends StatelessWidget {
  const _ActiveCallBody({
    required this.detail,
    required this.muted,
    required this.speakerOn,
    required this.cameraOn,
    required this.actionBusy,
    required this.onMute,
    required this.onSpeaker,
    required this.onVideo,
    required this.onEnd,
    required this.onDrawOpen,
    required this.onXoPlay,
    required this.l10n,
    required this.colors,
  });

  final ActiveCallDetail detail;
  final bool muted;
  final bool speakerOn;
  final bool cameraOn;
  final bool actionBusy;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onVideo;
  final VoidCallback onEnd;
  final VoidCallback onDrawOpen;
  final VoidCallback onXoPlay;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;

    return SingleChildScrollView(
      key: ActiveCallKeys.body,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Semantics(
              label: detail.peerLabel,
              child: Container(
                key: ActiveCallKeys.avatar,
                width: 110,
                height: 110,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(detail.avatarColor),
                  shape: BoxShape.circle,
                  boxShadow: [shadows.shCard],
                ),
                child: Text(detail.emoji, style: const TextStyle(fontSize: 52)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            detail.peerLabel,
            key: ActiveCallKeys.peerLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.activeCallStatusActive(detail.elapsedLabel),
            key: ActiveCallKeys.statusLine,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 34),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundCallAction(
                key: ActiveCallKeys.mute,
                semanticsLabel: muted
                    ? l10n.activeCallUnmuteSemantics
                    : l10n.activeCallMuteSemantics,
                icon: muted ? Icons.mic_off : Icons.mic,
                onPressed: actionBusy ? null : onMute,
                colors: colors,
                shadows: shadows,
                active: muted,
              ),
              const SizedBox(width: 14),
              _RoundCallAction(
                key: ActiveCallKeys.speaker,
                semanticsLabel: l10n.activeCallSpeakerSemantics,
                icon: speakerOn ? Icons.volume_up : Icons.volume_up_outlined,
                onPressed: actionBusy ? null : onSpeaker,
                colors: colors,
                shadows: shadows,
                active: speakerOn,
              ),
              const SizedBox(width: 14),
              _RoundCallAction(
                key: ActiveCallKeys.video,
                semanticsLabel: l10n.activeCallVideoSemantics,
                icon: cameraOn ? Icons.videocam : Icons.videocam_outlined,
                onPressed: actionBusy ? null : onVideo,
                colors: colors,
                shadows: shadows,
                active: cameraOn,
              ),
              const SizedBox(width: 14),
              _RoundCallAction(
                key: ActiveCallKeys.end,
                semanticsLabel: l10n.activeCallEndSemantics,
                icon: Icons.call_end,
                onPressed: actionBusy ? null : onEnd,
                colors: colors,
                shadows: shadows,
                gradient: gradients.gradCoral,
                inkOnGradient: true,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            l10n.activeCallHonestyNote,
            key: ActiveCallKeys.honesty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            key: ActiveCallKeys.playTogether,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              boxShadow: [shadows.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.activeCallPlayTogetherTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PlayRow(
                    emoji: '🎨',
                    title: l10n.activeCallDrawTitle,
                    subtitle: l10n.activeCallDrawSubtitle,
                    ctaLabel: l10n.activeCallDrawCta,
                    ctaKey: ActiveCallKeys.drawOpen,
                    onPressed: onDrawOpen,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _PlayRow(
                    emoji: '❌⭕',
                    title: l10n.activeCallXoTitle,
                    subtitle: l10n.activeCallXoSubtitle,
                    ctaLabel: l10n.activeCallXoCta,
                    ctaKey: ActiveCallKeys.xoPlay,
                    onPressed: onXoPlay,
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundCallAction extends StatelessWidget {
  const _RoundCallAction({
    super.key,
    required this.semanticsLabel,
    required this.icon,
    required this.onPressed,
    required this.colors,
    required this.shadows,
    this.active = false,
    this.gradient,
    this.inkOnGradient = false,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback? onPressed;
  final FamilyColors colors;
  final FamilyShadows shadows;
  final bool active;
  final LinearGradient? gradient;
  final bool inkOnGradient;

  @override
  Widget build(BuildContext context) {
    final bg = gradient == null
        ? (active ? colors.p100 : colors.surface)
        : null;
    final fg = inkOnGradient
        ? Colors.white
        : (active ? colors.p700 : colors.ink);

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              gradient: gradient,
              boxShadow: [gradient != null ? shadows.shCoral : shadows.shCard],
            ),
            child: Icon(icon, size: 22, color: fg),
          ),
        ),
      ),
    );
  }
}

class _PlayRow extends StatelessWidget {
  const _PlayRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.ctaKey,
    required this.onPressed,
    required this.colors,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final Key ctaKey;
  final VoidCallback onPressed;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          key: ctaKey,
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
            foregroundColor: colors.p700,
          ),
          child: Text(
            ctaLabel,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
