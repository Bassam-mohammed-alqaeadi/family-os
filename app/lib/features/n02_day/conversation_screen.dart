import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/data/communication_repository.dart';
import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/chat_thread_widgets.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';

/// Widget keys for SCR-FAT-022 acceptance.
abstract final class ConversationKeys {
  static const screen = Key('conversation_screen');
  static const loading = Key('conversation_loading');
  static const empty = Key('conversation_empty');
  static const missingPeer = Key('conversation_missing_peer');
  static const notFound = Key('conversation_not_found');
  static const error = Key('conversation_error');
  static const body = Key('conversation_body');
  static const settingsTag = Key('conversation_settings');
  static const familyPinNote = Key('conversation_family_pin');
  static const toneBridge = Key('conversation_tone_bridge');
  static const composer = Key('conversation_composer');
  static const input = Key('conversation_input');
  static const send = Key('conversation_send');
  static const attach = Key('conversation_attach');
  static const sosCta = Key('conversation_sos');
  static const childLean = Key('conversation_child_lean');
  static const title = Key('conversation_title');
  static const pinnedBar = Key('conversation_pinned_bar');
  static const pinnedBarUnpin = Key('conversation_pinned_unpin');
  static const replyBanner = Key('conversation_reply_banner');
  static const replyCancel = Key('conversation_reply_cancel');
  static const wallpaper = Key('conversation_wallpaper');

  /// Residual: the false "🔒 مشفّرة طرفيًا" badge lives in the ARB but is no
  /// longer rendered (ADR-053 «نترك» — no key management exists). Kept so a
  /// legacy lookup compiles.
  static const encryptedTag = Key('conversation_encrypted');

  static Key bubble(String id) => Key('conversation_bubble_$id');
  static Key toneChip(int i) => Key('conversation_tone_$i');
}

/// SCR-FAT-022 — المحادثة (parent conversation thread), ADR-053 line.
///
/// Opened from FAT-021 with `?chatWith=`. UI-007 / ChatAvailability — never
/// gated by billing. Send mock seam via [ConversationRepository.send]. P-4 SOS
/// ungated. Mother OK; child lean. Mock-first — Rule 23 empty default.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    this.chatWith,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.chatAvailability,
    this.onSos,
    this.onSend,
    this.onAttach,
    this.onOpenSettings,
  });

  /// From route `?chatWith=` (FAT-021 peer id).
  final String? chatWith;

  /// Null → [stage1ConversationRepository].
  final ConversationRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// UI-007 seam — null → [stage1ChatAvailability] (always usable).
  final ChatAvailability? chatAvailability;

  final VoidCallback? onSos;

  /// Test seam — fired after successful send with body text.
  final void Function(String text)? onSend;

  final VoidCallback? onAttach;
  final VoidCallback? onOpenSettings;

  @override
  ConversationScreenState createState() => ConversationScreenState();
}

class ConversationScreenState extends State<ConversationScreen> {
  late final ConversationRepository _repo;
  final _inputCtrl = TextEditingController();
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  var _sending = false;
  var _markedRead = false;
  ConversationDetail? _detail;
  ConversationMessage? _replyTo;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  ChatAvailability get _chat =>
      widget.chatAvailability ?? stage1ChatAvailability;

  String? get _resolvedPeer {
    final raw = widget.chatWith?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  bool get _hasPeer => _resolvedPeer != null;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ConversationRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatWith != widget.chatWith ||
        oldWidget.repository != widget.repository) {
      _markedRead = false;
      _load();
    }
  }

  Future<void> _load({bool markRead = true}) async {
    if (!_hasPeer) {
      setState(() {
        _detail = null;
        _loading = false;
        _loadFailed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final peer = _resolvedPeer!;
      final detail = await _repo.load(peer);
      if (markRead && !_markedRead && detail != null) {
        // S-COM-005 — opening a thread marks the other side's messages read.
        await _repo.markThreadRead(peer);
        _markedRead = true;
      }
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _loadFailed = false;
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
    await fire.fire(childId: _resolvedPeer ?? 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  Future<void> _send([String? preset]) async {
    if (!_chat.canSend || _sending) return;
    final peer = _resolvedPeer;
    if (peer == null || _detail == null) return;
    final text = (preset ?? _inputCtrl.text).trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final l10n = AppLocalizations.of(context);
      await _repo.send(
        peer,
        text,
        timeLabel: l10n.conversationSentNow,
        replyToId: _replyTo?.id,
      );
      if (!mounted) return;
      setState(() {
        _replyTo = null;
        if (preset == null) _inputCtrl.clear();
      });
      await _load(markRead: false);
      if (!mounted) return;
      setState(() => _sending = false);
      widget.onSend?.call(text);
    } on Object {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  void _onAttach() {
    if (!_chat.isUsable) return;
    if (widget.onAttach != null) {
      widget.onAttach!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.conversationAttachToast)),
    );
  }

  Future<void> _openMessageSheet(ConversationMessage message) async {
    final peer = _resolvedPeer;
    final l10n = AppLocalizations.of(context);
    if (peer == null) return;
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
        await _pin(peer, message.id);
      case ChatMessageAction.unpin:
        await _unpin(peer, message.id);
      case ChatMessageAction.edit:
        await _edit(peer, message);
      case ChatMessageAction.delete:
        await _delete(peer, message);
    }
  }

  Future<void> _pin(String peer, String messageId) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _repo.pinMessage(peer, messageId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationPinToast)),
      );
      await _load(markRead: false);
    } on MessagePinRefused {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationEditRefused)),
      );
    }
  }

  Future<void> _unpin(String peer, String messageId) async {
    final l10n = AppLocalizations.of(context);
    await _repo.unpinMessage(peer, messageId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.conversationUnpinToast)),
    );
    await _load(markRead: false);
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
        fieldKey: const Key('conversation_edit_field'),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await _repo.editMessage(peer, message.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationEditToast)),
      );
      await _load(markRead: false);
    } on MessageEditRefused {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationEditRefused)),
      );
    }
  }

  Future<void> _delete(String peer, ConversationMessage message) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _repo.deleteMessage(peer, message.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationDeleteToast)),
      );
      await _load(markRead: false);
    } on MessageEditRefused {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationEditRefused)),
      );
    }
  }

  Future<void> _openSettings() async {
    final detail = _detail;
    final peer = _resolvedPeer;
    if (detail == null || peer == null) {
      widget.onOpenSettings?.call();
      return;
    }
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
    final titleText = _detail?.title ?? l10n.conversationTitle;

    return Scaffold(
      key: ConversationKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          titleText,
          key: ConversationKeys.title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          // P-4 — SOS never gated by empty/loading/error.
          IconButton(
            key: ConversationKeys.sosCta,
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
        key: ConversationKeys.childLean,
        title: l10n.conversationChildLeanTitle,
        message: l10n.conversationChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: ConversationKeys.loading,
        label: l10n.conversationLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: ConversationKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    if (!_hasPeer) {
      return AppEmptyState(
        key: ConversationKeys.missingPeer,
        title: l10n.conversationMissingPeerTitle,
        message: l10n.conversationMissingPeerMessage,
      );
    }

    if (_detail == null) {
      return AppEmptyState(
        key: ConversationKeys.notFound,
        title: l10n.conversationNotFoundTitle,
        message: l10n.conversationNotFoundMessage,
      );
    }

    final detail = _detail!;
    final wallpaper = chatWallpaperColor(colors, detail.wallpaper);
    return Column(
      key: ConversationKeys.body,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail.subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              detail.subtitle,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
          ),
        if (detail.pinnedMessage != null)
          ChatPinnedBar(
            key: ConversationKeys.pinnedBar,
            unpinKey: ConversationKeys.pinnedBarUnpin,
            label: l10n.conversationPinnedBarLabel,
            unpinLabel: l10n.conversationMenuUnpin,
            preview: detail.pinnedMessage!.body,
            mediaLabel: chatMediaLabel(l10n, detail.pinnedMessage!.kind),
            onUnpin: () => _unpin(_resolvedPeer!, detail.pinnedMessage!.id),
          ),
        Expanded(
          child: ColoredBox(
            key: ConversationKeys.wallpaper,
            color: wallpaper ?? Colors.transparent,
            child: detail.isEmpty
                ? AppEmptyState(
                    key: ConversationKeys.empty,
                    title: l10n.conversationEmptyTitle,
                    message: l10n.conversationEmptyMessage,
                  )
                : _ThreadScroll(
                    detail: detail,
                    l10n: l10n,
                    onSettings: _openSettings,
                    onLongPress: _openMessageSheet,
                  ),
          ),
        ),
        if (_replyTo != null)
          _ReplyBanner(
            message: _replyTo!,
            l10n: l10n,
            colors: colors,
            onCancel: () => setState(() => _replyTo = null),
          ),
        if (detail.toneChips.isNotEmpty)
          _ToneChips(chips: detail.toneChips, onTap: (text) => _send(text)),
        _Composer(
          controller: _inputCtrl,
          enabled: _chat.canSend && !_sending,
          sending: _sending,
          onAttach: _onAttach,
          onSend: () => _send(),
          l10n: l10n,
        ),
      ],
    );
  }
}

class _ThreadScroll extends StatelessWidget {
  const _ThreadScroll({
    required this.detail,
    required this.l10n,
    required this.onSettings,
    required this.onLongPress,
  });

  final ConversationDetail detail;
  final AppLocalizations l10n;
  final VoidCallback onSettings;
  final void Function(ConversationMessage message) onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      children: [
        Row(
          children: [
            const Spacer(),
            TextButton(
              key: ConversationKeys.settingsTag,
              onPressed: onSettings,
              style: TextButton.styleFrom(
                foregroundColor: colors.teal600,
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                l10n.conversationSettingsTag,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final m in detail.messages) ...[
          ChatBubble(
            bubbleKey: ConversationKeys.bubble(m.id),
            message: m,
            tone: ChatTone.parent,
            theme: detail.bubbleTheme,
            replyPrefix: l10n.conversationReplyPrefix,
            deletedLabel: l10n.conversationDeletedMessage,
            editedTag: l10n.conversationEditedTag,
            mediaLabel: chatMediaLabel(l10n, m.kind),
            onLongPress: () => onLongPress(m),
          ),
          const SizedBox(height: 8),
        ],
        if (detail.familyPinnedNote)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              key: ConversationKeys.familyPinNote,
              l10n.conversationFamilyPinNote,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({
    required this.message,
    required this.l10n,
    required this.colors,
    required this.onCancel,
  });

  final ConversationMessage message;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ConversationKeys.replyBanner,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${l10n.conversationReplyPrefix}: '
              '${message.deleted ? l10n.conversationDeletedMessage : message.body}',
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
            key: ConversationKeys.replyCancel,
            tooltip: l10n.conversationReplyCancel,
            onPressed: onCancel,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Icon(Icons.close, size: 18, color: colors.ink2),
          ),
        ],
      ),
    );
  }
}

class _ToneChips extends StatelessWidget {
  const _ToneChips({required this.chips, required this.onTap});

  final List<String> chips;
  final void Function(String text) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final l10n = AppLocalizations.of(context);

    return Column(
      key: ConversationKeys.toneBridge,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final text = chips[i];
              return ActionChip(
                key: ConversationKeys.toneChip(i),
                label: Text(
                  text,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colors.p700,
                  ),
                ),
                backgroundColor: colors.p50,
                side: BorderSide(color: colors.p400),
                onPressed: () => onTap(text),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Text(
            l10n.conversationToneBridgeNote,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.onAttach,
    required this.onSend,
    required this.l10n,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Padding(
      key: ConversationKeys.composer,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          IconButton(
            key: ConversationKeys.attach,
            tooltip: l10n.conversationAttachSemantics,
            onPressed: enabled ? onAttach : null,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.attach_file, color: colors.ink2),
          ),
          Expanded(
            child: TextField(
              key: ConversationKeys.input,
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: l10n.conversationInputHint,
                filled: true,
                fillColor: colors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(99),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(99),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(99),
                  borderSide: BorderSide(color: colors.p500, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: ConversationKeys.send,
            tooltip: l10n.conversationSendSemantics,
            onPressed: enabled && !sending ? onSend : null,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
              backgroundColor: WidgetStatePropertyAll(colors.p500),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
              shape: const WidgetStatePropertyAll(CircleBorder()),
            ),
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
