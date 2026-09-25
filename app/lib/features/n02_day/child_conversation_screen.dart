import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/data/communication_repository.dart';
import 'package:family_os/core/data/communication_rules.dart';
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
import 'package:family_os/features/n02_day/chat_thread_widgets.dart';
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
  static const settingsTag = Key('child_conversation_settings');
  static const pinnedBar = Key('child_conversation_pinned_bar');
  static const pinnedBarUnpin = Key('child_conversation_pinned_unpin');
  static const replyBanner = Key('child_conversation_reply_banner');
  static const replyCancel = Key('child_conversation_reply_cancel');
  static const wallpaper = Key('child_conversation_wallpaper');

  static Key bubble(String id) => Key('child_conversation_bubble_$id');
}

/// SCR-CHD-008 — المحادثة (child thread), ADR-053 line.
///
/// From CHD-007 `?chatWith=`. UI-007 never billing-gated. Chat never locks when
/// time expires. Incoming-call card for parent DMs. P-4 SOS → CHD-005.
/// Parent lean. Mock-first — Rule 23 empty default. Child tone (turquoise).
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
  var _markedRead = false;
  ConversationDetail? _detail;
  ConversationMessage? _replyTo;

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

  Future<void> _load({bool markRead = true}) async {
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
      if (markRead && !_markedRead && detail != null) {
        await _repo.markThreadRead(peer);
        _markedRead = true;
      }
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
      await _repo.send(
        peer,
        text,
        timeLabel: l10n.childConversationNowLabel,
        replyToId: _replyTo?.id,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _replyTo = null;
        if (preset == null) _inputCtrl.clear();
      });
      await _load(markRead: false);
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

  Future<void> _openMessageSheet(ConversationMessage message) async {
    final peer = _peer;
    if (peer == null) return;
    final l10n = AppLocalizations.of(context);
    final editable = senderMayEdit(
      senderKey: message.isMine ? 'me' : 'them',
      actorKey: 'me',
      sentAt: message.sentAt ?? DateTime.now(),
      now: DateTime.now(),
      deleted: message.deleted,
    );
    final action = await showChatMessageSheet(
      context,
      message: message,
      editable: editable,
      l10n: l10n,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case ChatMessageAction.reply:
        setState(() => _replyTo = message);
      case ChatMessageAction.pin:
        await _run(peer, () => _repo.pinMessage(peer, message.id));
      case ChatMessageAction.unpin:
        await _run(peer, () => _repo.unpinMessage(peer, message.id));
      case ChatMessageAction.edit:
        await _edit(peer, message);
      case ChatMessageAction.delete:
        await _delete(peer, message);
    }
  }

  /// Runs a write and reloads; a refused write (the rules') is announced, never
  /// swallowed.
  Future<void> _run(String peer, Future<void> Function() write) async {
    final l10n = AppLocalizations.of(context);
    try {
      await write();
      if (!mounted) return;
      await _load(markRead: false);
    } on MessageEditRefused {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationEditRefused)),
      );
    } on MessagePinRefused {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationEditRefused)),
      );
    }
  }

  Future<void> _edit(String peer, ConversationMessage message) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => EditMessageDialog(
        title: l10n.conversationEditTitle,
        hint: l10n.conversationEditHint,
        initialText: message.body,
        saveLabel: l10n.conversationEditSave,
        cancelLabel: l10n.conversationEditCancel,
        fieldKey: const Key('child_conversation_edit_field'),
      ),
    );
    if (result == null || !mounted) return;
    await _run(peer, () => _repo.editMessage(peer, message.id, result));
  }

  Future<void> _delete(String peer, ConversationMessage message) async {
    await _run(peer, () => _repo.deleteMessage(peer, message.id));
  }

  Future<void> _openSettings() async {
    final detail = _detail;
    final peer = _peer;
    if (detail == null || peer == null) return;
    final l10n = AppLocalizations.of(context);
    await showChatSettingsSheet(
      context,
      detail: detail,
      l10n: l10n,
      handlers: ChatSettingsHandlers(
        onMute: (preset) => _repo.setMuted(peer, preset),
        onUnmute: () => _repo.unmute(peer),
        onArchive: (archived) => _repo.setArchived(peer, archived),
        onPin: (pinned) => _repo.setPinned(peer, pinned),
        onLook: (wallpaper, theme) => _repo.setLook(
          peer,
          wallpaper: wallpaper,
          bubbleTheme: theme,
        ),
      ),
    );
    if (!mounted) return;
    await _load(markRead: false);
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
            if (_detail != null)
              IconButton(
                key: ChildConversationKeys.settingsTag,
                tooltip: l10n.chatSettingsTitle,
                onPressed: _openSettings,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.settings_outlined, color: colors.ink2),
              ),
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
    final wallpaper = chatWallpaperColor(colors, detail.wallpaper);

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
        if (detail.pinnedMessage != null)
          ChatPinnedBar(
            key: ChildConversationKeys.pinnedBar,
            unpinKey: ChildConversationKeys.pinnedBarUnpin,
            label: l10n.conversationPinnedBarLabel,
            unpinLabel: l10n.conversationMenuUnpin,
            preview: detail.pinnedMessage!.body,
            mediaLabel: chatMediaLabel(l10n, detail.pinnedMessage!.kind),
            onUnpin: () => _run(_peer!, () => _repo.unpinMessage(
                  _peer!,
                  detail.pinnedMessage!.id,
                )),
          ),
        Expanded(
          child: ColoredBox(
            key: ChildConversationKeys.wallpaper,
            color: wallpaper ?? Colors.transparent,
            child: detail.isEmpty
                ? AppEmptyState(
                    key: ChildConversationKeys.empty,
                    title: l10n.childConversationEmptyTitle,
                    message: l10n.childConversationEmptyMessage,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    children: [
                      for (final m in detail.messages) ...[
                        ChatBubble(
                          bubbleKey: ChildConversationKeys.bubble(m.id),
                          message: m,
                          tone: ChatTone.child,
                          theme: detail.bubbleTheme,
                          replyPrefix: l10n.conversationReplyPrefix,
                          deletedLabel: l10n.conversationDeletedMessage,
                          editedTag: l10n.conversationEditedTag,
                          mediaLabel: chatMediaLabel(l10n, m.kind),
                          onLongPress: () => _openMessageSheet(m),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ),
        if (_replyTo != null)
          Padding(
            key: ChildConversationKeys.replyBanner,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.conversationReplyPrefix}: '
                    '${_replyTo!.deleted ? l10n.conversationDeletedMessage : _replyTo!.body}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ),
                IconButton(
                  key: ChildConversationKeys.replyCancel,
                  tooltip: l10n.conversationReplyCancel,
                  onPressed: () => setState(() => _replyTo = null),
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(Icons.close, size: 18, color: colors.ink2),
                ),
              ],
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
