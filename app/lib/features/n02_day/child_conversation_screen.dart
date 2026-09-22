import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';

/// Widget keys for SCR-CHD-008 acceptance.
abstract final class ChildConversationKeys {
  static const screen = Key('child_conversation_screen');
  static const loading = Key('child_conversation_loading');
  static const empty = Key('child_conversation_empty');
  static const missingPeer = Key('child_conversation_missing_peer');
  static const notFound = Key('child_conversation_not_found');
  static const error = Key('child_conversation_error');
  static const body = Key('child_conversation_body');
  static const incomingCall = Key('child_conversation_incoming_call');
  static const answerCall = Key('child_conversation_answer_call');
  static const neverLockBanner = Key('child_conversation_never_lock');
  static const composer = Key('child_conversation_composer');
  static const input = Key('child_conversation_input');
  static const send = Key('child_conversation_send');
  static const sosCta = Key('child_conversation_sos');
  static const parentLean = Key('child_conversation_parent_lean');
  static const title = Key('child_conversation_title');

  static Key bubble(String id) => Key('child_conversation_bubble_$id');
}

/// SCR-CHD-008 — المحادثة (child thread).
///
/// From CHD-007 `?chatWith=`. UI-007 never billing-gated. Chat never locks when
/// time expires. Incoming-call card for parent DMs. P-4 SOS → CHD-005.
/// Parent lean. Mock-first — Rule 23 empty default.
class ChildConversationScreen extends StatefulWidget {
  const ChildConversationScreen({
    super.key,
    this.chatWith,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.chatAvailability,
    this.onSos,
    this.onSend,
    this.onAnswerCall,
  });

  final String? chatWith;
  final ConversationRepository? repository;
  final AppRole? roleOverride;
  final SosFireService? sosFire;
  final ChatAvailability? chatAvailability;
  final VoidCallback? onSos;
  final void Function(String text)? onSend;
  final VoidCallback? onAnswerCall;

  @override
  State<ChildConversationScreen> createState() =>
      _ChildConversationScreenState();
}

class _ChildConversationScreenState extends State<ChildConversationScreen> {
  late final ConversationRepository _repo;
  final _inputCtrl = TextEditingController();
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  var _sending = false;
  var _callAnswered = false;
  ConversationDetail? _detail;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  ChatAvailability get _chat =>
      widget.chatAvailability ?? stage1ChatAvailability;

  String? get _peer {
    final raw = widget.chatWith?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  bool get _showIncomingCall {
    final p = _peer;
    if (p == null || _callAnswered) return false;
    return p == 'father' || p == 'mother';
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ConversationRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final peer = _peer;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _detail = null;
    });
    if (peer == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final detail = await _repo.load(peer);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
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

  Future<void> _send([String? preset]) async {
    final peer = _peer;
    final text = (preset ?? _inputCtrl.text).trim();
    if (peer == null || text.isEmpty || !_chat.canSend || _sending) return;
    setState(() => _sending = true);
    try {
      final l10n = AppLocalizations.of(context);
      final msg = await _repo.send(
        peer,
        text,
        timeLabel: l10n.childConversationNowLabel,
      );
      if (!mounted) return;
      final prev = _detail;
      setState(() {
        _sending = false;
        if (preset == null) _inputCtrl.clear();
        if (prev != null) {
          _detail = prev.copyWith(messages: [...prev.messages, msg]);
        }
      });
      widget.onSend?.call(text);
    } on Object {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  void _answerCall() {
    setState(() => _callAnswered = true);
    if (widget.onAnswerCall != null) {
      widget.onAnswerCall!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.childConversationAnswerToast)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final titleText = _detail?.title ?? l10n.childConversationTitle;

    return FamilyUiModeScope(
      mode: FamilyUiMode.child,
      child: Scaffold(
        key: ChildConversationKeys.screen,
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                key: ChildConversationKeys.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              if (_detail?.subtitle.isNotEmpty == true)
                Text(
                  _detail!.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.ink2,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              key: ChildConversationKeys.sosCta,
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
        key: ChildConversationKeys.parentLean,
        title: l10n.childConversationParentLeanTitle,
        message: l10n.childConversationParentLeanMessage,
      );
    }
    if (_loading) {
      return Semantics(
        key: ChildConversationKeys.loading,
        label: l10n.childConversationLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadFailed) {
      return AppErrorState(
        key: ChildConversationKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }
    if (_peer == null) {
      return AppEmptyState(
        key: ChildConversationKeys.missingPeer,
        title: l10n.childConversationMissingPeerTitle,
        message: l10n.childConversationMissingPeerMessage,
      );
    }
    if (_detail == null) {
      return AppEmptyState(
        key: ChildConversationKeys.notFound,
        title: l10n.childConversationNotFoundTitle,
        message: l10n.childConversationNotFoundMessage,
      );
    }

    final detail = _detail!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Column(
      key: ChildConversationKeys.body,
      children: [
        if (_showIncomingCall)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              key: ChildConversationKeys.incomingCall,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.teal, width: 2),
              ),
              child: Row(
                children: [
                  Text(
                    '📞',
                    style: TextStyle(fontSize: 26, color: colors.teal),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.childConversationIncomingTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        Text(
                          l10n.childConversationIncomingSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: PrimaryBtn(
                      key: ChildConversationKeys.answerCall,
                      label: l10n.childConversationAnswerCta,
                      variant: PrimaryBtnVariant.teal,
                      onPressed: _answerCall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: BannerNote(
            key: ChildConversationKeys.neverLockBanner,
            variant: BannerVariant.t,
            message: l10n.childConversationNeverLockBanner,
          ),
        ),
        Expanded(
          child: detail.isEmpty
              ? AppEmptyState(
                  key: ChildConversationKeys.empty,
                  title: l10n.childConversationEmptyTitle,
                  message: l10n.childConversationEmptyMessage,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: detail.messages.length,
                  itemBuilder: (context, i) {
                    final m = detail.messages[i];
                    return _ChildBubble(
                      message: m,
                      colors: colors,
                      radii: radii,
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            key: ChildConversationKeys.composer,
            children: [
              Expanded(
                child: TextField(
                  key: ChildConversationKeys.input,
                  controller: _inputCtrl,
                  enabled: _chat.canSend && !_sending,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: l10n.childConversationInputHint,
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: colors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: ChildConversationKeys.send,
                tooltip: l10n.childConversationSendSemantics,
                onPressed: _chat.canSend && !_sending ? () => _send() : null,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(colors.teal),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                  shape: const WidgetStatePropertyAll(CircleBorder()),
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChildBubble extends StatelessWidget {
  const _ChildBubble({
    required this.message,
    required this.colors,
    required this.radii,
  });

  final ConversationMessage message;
  final FamilyColors colors;
  final FamilyRadii radii;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        key: ChildConversationKeys.bubble(message.id),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? colors.teal.withValues(alpha: 0.18) : colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: mine ? colors.teal : colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.senderLabel != null)
              Text(
                message.senderLabel!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.ink2,
                ),
              ),
            Text(
              message.body,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colors.ink,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.timeLabel,
              style: TextStyle(fontSize: 10.5, color: colors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}
