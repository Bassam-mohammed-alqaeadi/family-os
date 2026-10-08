import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/identity/active_child_resolver.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/family_chat_connection_banner.dart';
import 'package:family_os/features/n02_day/live_conversation_repository.dart';
import 'package:family_os/features/n02_day/family_chat_labels.dart';

/// Widget keys for SCR-FAT-022 acceptance.
abstract final class ConversationKeys {
  static const screen = Key('conversation_screen');
  static const loading = Key('conversation_loading');
  static const empty = Key('conversation_empty');
  static const missingPeer = Key('conversation_missing_peer');
  static const notFound = Key('conversation_not_found');
  static const error = Key('conversation_error');
  static const body = Key('conversation_body');
  static const encryptedTag = Key('conversation_encrypted');
  static const serverStoredTag = Key('conversation_server_stored');
  static const settingsTag = Key('conversation_settings');
  static const familyPinNote = Key('conversation_family_pin');
  static const honestyBanner = Key('conversation_honesty');
  static const toneBridge = Key('conversation_tone_bridge');
  static const composer = Key('conversation_composer');
  static const input = Key('conversation_input');
  static const send = Key('conversation_send');
  static const attach = Key('conversation_attach');
  static const sosCta = Key('conversation_sos');
  static const childLean = Key('conversation_child_lean');
  static const title = Key('conversation_title');
  static const connection = Key('conversation_connection');
  static const loadOlder = Key('conversation_load_older');
  static const mediaUnavailable = Key('conversation_media_unavailable');

  static Key bubble(String id) => Key('conversation_bubble_$id');
  static Key toneChip(int i) => Key('conversation_tone_$i');
}

/// SCR-FAT-022 — المحادثة (parent conversation thread).
///
/// Opened from FAT-021 with `?chatWith=`. Server membership owns access; visible messages
/// refresh by polling because the W9 contract has no push channel. P-4 SOS remains ungated.
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

  /// P-4 SOS seam — null → [activeSosFireService].
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
  late ConversationRepository _repo;
  final _inputCtrl = TextEditingController();
  Timer? _pollTimer;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  var _sending = false;
  var _refreshing = false;
  var _loadingOlder = false;
  var _connectionIssue = false;
  FamilyChatConnectionState _connectionState =
      FamilyChatConnectionState.checking;
  ConversationDetail? _detail;

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
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatWith != widget.chatWith ||
        oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1ConversationRepository;
      _pollTimer?.cancel();
      _detail = null;
      unawaited(_load());
    }
  }

  void _schedulePolling() {
    if (_repo is! LiveConversationRepository) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_refresh());
    });
  }

  Future<void> _load() async {
    if (!_hasPeer) {
      setState(() {
        _detail = null;
        _loading = false;
        _loadFailed = false;
        _connectionIssue = false;
      });
      return;
    }
    setState(() {
      _loading = _detail == null;
      _loadFailed = false;
      if (_connectionState != FamilyChatConnectionState.connected) {
        _connectionState = FamilyChatConnectionState.checking;
      }
    });
    try {
      final detail = await _repo.load(_resolvedPeer!);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _loadFailed = false;
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
      });
      if (detail != null) _schedulePolling();
    } on Object catch (error) {
      if (!mounted) return;
      final discard = familyChatFailureRequiresDiscard(error);
      setState(() {
        _loading = false;
        if (discard) _detail = null;
        _loadFailed = discard || _detail == null;
        _connectionIssue = true;
        _connectionState = familyChatConnectionStateFor(error);
      });
    }
  }

  Future<void> _refresh() async {
    final peer = _resolvedPeer;
    final repository = _repo;
    if (peer == null ||
        repository is! LiveConversationRepository ||
        _refreshing ||
        _loadingOlder ||
        _sending) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      final updated = await repository.refresh(peer);
      if (!mounted) return;
      setState(() {
        _detail = updated ?? _detail;
        _refreshing = false;
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
        _loadFailed = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      final discard = familyChatFailureRequiresDiscard(error);
      setState(() {
        _refreshing = false;
        if (discard) {
          _detail = null;
          _loadFailed = true;
        }
        _connectionIssue = true;
        _connectionState = familyChatConnectionStateFor(error);
      });
    }
  }

  Future<void> _loadOlder() async {
    final peer = _resolvedPeer;
    final repository = _repo;
    if (peer == null ||
        repository is! LiveConversationRepository ||
        _loadingOlder ||
        !repository.hasMore(peer)) {
      return;
    }
    setState(() => _loadingOlder = true);
    try {
      final updated = await repository.loadNextPage(peer);
      if (!mounted) return;
      setState(() {
        _detail = updated ?? _detail;
        _loadingOlder = false;
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
      });
    } on Object catch (error) {
      if (!mounted) return;
      final discard = familyChatFailureRequiresDiscard(error);
      setState(() {
        _loadingOlder = false;
        if (discard) {
          _detail = null;
          _loadFailed = true;
        }
        _connectionIssue = true;
        _connectionState = familyChatConnectionStateFor(error);
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
    final fire = widget.sosFire ?? activeSosFireService;
    final sender = sosSenderForRole(
      context,
      _role,
      viewedChild: familyChildOrNull(
        _resolvedPeer,
        runtime: identityOf(context),
      ),
    );
    await sender.fireThrough(fire);
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
      final sent = await _repo.send(
        peer,
        text,
        timeLabel: l10n.conversationSentNow,
      );
      if (!mounted) return;
      setState(() {
        final detail = _detail;
        if (detail != null) _detail = _upsertDetail(detail, sent);
        _sending = false;
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
        if (preset == null) _inputCtrl.clear();
      });
      widget.onSend?.call(text);
      if (_repo is LiveConversationRepository) {
        unawaited(_refresh());
      } else {
        final refreshed = await _repo.load(peer);
        if (!mounted) return;
        if (refreshed != null) {
          setState(() => _detail = _mergeDetails(_detail, refreshed));
        }
      }
    } on Object catch (error) {
      if (!mounted) return;
      final discard = familyChatFailureRequiresDiscard(error);
      setState(() {
        _sending = false;
        if (discard) {
          _detail = null;
          _loadFailed = true;
        }
        _connectionIssue = true;
        _connectionState = familyChatConnectionStateFor(error);
      });
    }
  }

  ConversationDetail _upsertDetail(
    ConversationDetail detail,
    ConversationMessage message,
  ) {
    final messages = List<ConversationMessage>.of(detail.messages);
    final index = messages.indexWhere((existing) => existing.id == message.id);
    if (index == -1) {
      messages.add(message);
    } else {
      messages[index] = message;
    }
    if (messages.every((item) => item.seq != null)) {
      messages.sort((left, right) => left.seq!.compareTo(right.seq!));
    }
    return detail.copyWith(messages: messages);
  }

  ConversationDetail _mergeDetails(
    ConversationDetail? current,
    ConversationDetail refreshed,
  ) {
    var result = refreshed;
    if (current == null) return result;
    for (final message in current.messages) {
      result = _upsertDetail(result, message);
    }
    return result;
  }

  Future<void> _editMessage(ConversationMessage message) async {
    final peer = _resolvedPeer;
    final repository = _repo;
    if (peer == null ||
        repository is! LiveConversationRepository ||
        !message.isMine ||
        message.deleted) {
      return;
    }
    final controller = TextEditingController(text: message.body);
    final l10n = AppLocalizations.of(context);
    final editedBody = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.familyChatEditHeading),
          content: TextField(
            controller: controller,
            maxLength: 2000,
            minLines: 1,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setDialogState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.familyChatCancel),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.familyChatEditSave),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
    if (editedBody == null || !mounted) return;

    try {
      final updated = await repository.editMessage(peer, message, editedBody);
      if (!mounted) return;
      setState(() {
        final detail = _detail;
        if (detail != null) _detail = _upsertDetail(detail, updated);
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
      });
    } on Object catch (error) {
      if (!mounted) return;
      final discard = familyChatFailureRequiresDiscard(error);
      setState(() {
        if (discard) {
          _detail = null;
          _loadFailed = true;
        }
        _connectionIssue = true;
        _connectionState = familyChatConnectionStateFor(error);
      });
    }
  }

  Future<void> _deleteMessage(ConversationMessage message) async {
    final peer = _resolvedPeer;
    final repository = _repo;
    if (peer == null ||
        repository is! LiveConversationRepository ||
        !message.isMine ||
        message.deleted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.familyChatDeleteHeading),
        content: Text(l10n.familyChatDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.familyChatCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.familyChatDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final deleted = await repository.deleteMessage(peer, message);
      if (!mounted) return;
      setState(() {
        final detail = _detail;
        if (detail != null) _detail = _upsertDetail(detail, deleted);
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
      });
    } on Object catch (error) {
      if (!mounted) return;
      final discard = familyChatFailureRequiresDiscard(error);
      setState(() {
        if (discard) {
          _detail = null;
          _loadFailed = true;
        }
        _connectionIssue = true;
        _connectionState = familyChatConnectionStateFor(error);
      });
    }
  }

  void _onAttach() {
    if (!_chat.isUsable) return;
    if (widget.onAttach != null) {
      widget.onAttach!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.conversationAttachToast);
  }

  void _onSettings() {
    if (widget.onOpenSettings != null) {
      widget.onOpenSettings!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.conversationSettingsToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final titleText = _detail == null
        ? l10n.conversationTitle
        : localizedConversationThreadTitle(
            l10n,
            _detail!.chatWith,
            _detail!.title,
            threadKind: _detail!.threadKind,
            isFamilyThread: _detail!.familyPinnedNote,
          );

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
      return Column(
        children: [
          FamilyChatConnectionBanner(
            key: ConversationKeys.connection,
            state: _connectionState,
            onRetry: _load,
          ),
          Expanded(
            child: AppErrorState(
              key: ConversationKeys.error,
              kind: AppErrorKind.network,
              onRetry: _load,
            ),
          ),
        ],
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
    return Column(
      key: ConversationKeys.body,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_connectionIssue)
          FamilyChatConnectionBanner(
            key: ConversationKeys.connection,
            state: _connectionState,
            onRetry: _refresh,
          ),
        if (_refreshing) const LinearProgressIndicator(minHeight: 2),
        if (detail.serverAuthoritative)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              l10n.familyChatServerPollingNotice,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
          ),
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
        Expanded(
          child: detail.isEmpty
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Text(
                        key: detail.familyPinnedNote
                            ? ConversationKeys.familyPinNote
                            : ConversationKeys.honestyBanner,
                        detail.familyPinnedNote
                            ? l10n.conversationFamilyPinNote
                            : l10n.conversationLocalHonestyBanner,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: AppEmptyState(
                        key: ConversationKeys.empty,
                        title: l10n.conversationEmptyTitle,
                        message: l10n.conversationEmptyMessage,
                      ),
                    ),
                  ],
                )
              : _ThreadScroll(
                  detail: detail,
                  l10n: l10n,
                  onSettings: _onSettings,
                  onRefresh: _refresh,
                  onLoadOlder: _loadOlder,
                  loadingOlder: _loadingOlder,
                  onEdit: _editMessage,
                  onDelete: _deleteMessage,
                ),
        ),
        if (detail.toneChips.isNotEmpty)
          _ToneChips(chips: detail.toneChips, onTap: (text) => _send(text)),
        _Composer(
          controller: _inputCtrl,
          enabled: _chat.canSend && !_sending && !_connectionIssue,
          mediaEnabled: !detail.serverAuthoritative,
          sending: _sending,
          onAttach: _onAttach,
          onSend: () => _send(),
          l10n: l10n,
        ),
        if (detail.serverAuthoritative)
          Padding(
            key: ConversationKeys.mediaUnavailable,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.familyChatMediaUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
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
    required this.onRefresh,
    required this.onLoadOlder,
    required this.loadingOlder,
    required this.onEdit,
    required this.onDelete,
  });

  final ConversationDetail detail;
  final AppLocalizations l10n;
  final VoidCallback onSettings;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadOlder;
  final bool loadingOlder;
  final void Function(ConversationMessage message) onEdit;
  final void Function(ConversationMessage message) onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        children: [
          if (detail.hasMoreMessages)
            Align(
              alignment: AlignmentDirectional.center,
              child: TextButton.icon(
                key: ConversationKeys.loadOlder,
                onPressed: loadingOlder ? null : onLoadOlder,
                icon: loadingOlder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.history),
                label: Text(l10n.familyChatLoadMore),
              ),
            ),
          Row(
          children: [
            if (detail.serverAuthoritative)
              Tag(
                key: ConversationKeys.serverStoredTag,
                label: l10n.familyChatServerStoredTag,
                variant: TagVariant.p,
              )
            else
              Tag(
                key: ConversationKeys.encryptedTag,
                label: l10n.conversationEncryptedTag,
                variant: TagVariant.p,
              ),
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
          _Bubble(
            message: m,
            colors: colors,
            serverAuthoritative: detail.serverAuthoritative,
            onEdit: () => onEdit(m),
            onDelete: () => onDelete(m),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            key: detail.familyPinnedNote
                ? ConversationKeys.familyPinNote
                : ConversationKeys.honestyBanner,
            detail.serverAuthoritative
                ? l10n.familyChatStorageNotice
                : detail.familyPinnedNote
                ? l10n.conversationFamilyPinNote
                : l10n.conversationLocalHonestyBanner,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.colors,
    required this.serverAuthoritative,
    required this.onEdit,
    required this.onDelete,
  });

  final ConversationMessage message;
  final FamilyColors colors;
  final bool serverAuthoritative;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMine = message.isMine;
    final bg = isMine ? colors.p500 : colors.surface;
    final fg = isMine ? Colors.white : colors.ink;
    final align = isMine
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final radii = const BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(18),
    );

    final statusSuffix = isMine ? _statusTicks(message.status) : '';
    final senderLabel = localizedFamilyChatSenderLabel(
      l10n,
      message.senderLabel,
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: DecoratedBox(
          key: ConversationKeys.bubble(message.id),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radii,
            border: isMine
                ? null
                : Border.all(color: colors.border.withValues(alpha: 0.85)),
            boxShadow: [
              if (!isMine) Theme.of(context).extension<FamilyShadows>()!.shCard,
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (senderLabel != null) ...[
                  Text(
                    senderLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isMine ? Colors.white70 : colors.p600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message.deleted
                      ? l10n.familyChatMessageDeleted
                      : message.body,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: message.deleted ? colors.ink2 : fg,
                    height: 1.35,
                    fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        <String>[
                          if (message.editedAt != null) l10n.familyChatEdited,
                          if (message.createdAt != null)
                            intl.DateFormat.Hm(l10n.localeName)
                                .format(message.createdAt!.toLocal())
                          else if (message.timeLabel.isNotEmpty)
                            message.timeLabel,
                          if (statusSuffix.isNotEmpty) statusSuffix.trim(),
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isMine ? Colors.white70 : colors.ink2,
                        ),
                      ),
                    ),
                    if (serverAuthoritative && isMine && !message.deleted)
                      PopupMenuButton<String>(
                        tooltip: l10n.familyChatMessageActionsSemantics,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        iconSize: 17,
                        onSelected: (action) {
                          if (action == 'edit') onEdit();
                          if (action == 'delete') onDelete();
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(l10n.familyChatEdit),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(l10n.familyChatDelete),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One tick records the send state only; this contract has no per-device delivery receipt.
  /// Never draw ✓✓ from aggregate read counts or the legacy delivered/read aliases.
  String _statusTicks(ConversationDeliveryStatus status) => switch (status) {
    ConversationDeliveryStatus.sending => ' · …',
    ConversationDeliveryStatus.sent ||
    ConversationDeliveryStatus.delivered ||
    ConversationDeliveryStatus.read => ' ✓',
  };
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
    required this.mediaEnabled,
    required this.sending,
    required this.onAttach,
    required this.onSend,
    required this.l10n,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool mediaEnabled;
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
            tooltip: mediaEnabled
                ? l10n.conversationAttachSemantics
                : l10n.familyChatMediaUnavailableSemantics,
            onPressed: enabled && mediaEnabled ? onAttach : null,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
