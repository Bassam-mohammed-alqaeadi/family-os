import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/family_chat_connection_banner.dart';
import 'package:family_os/features/n02_day/live_conversation_repository.dart';
import 'package:family_os/features/n02_day/family_chat_labels.dart';

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
  static const connection = Key('child_conversation_connection');
  static const loadMore = Key('child_conversation_load_more');
  static const mediaUnavailable = Key('child_conversation_media_unavailable');
  static const serverStorageNotice = Key('child_conversation_server_storage');

  static Key bubble(String id) => Key('child_conversation_bubble_$id');
}

/// SCR-CHD-008 — المحادثة (child thread).
///
/// From CHD-007 `?chatWith=`. UI-007 never billing-gated. Chat never locks when
/// time expires. Incoming-call card for parent DMs. P-4 SOS → CHD-005.
/// Parent lean. Server state refreshes by polling; no push transport is claimed.
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
  late ConversationRepository _repo;
  final _inputCtrl = TextEditingController();
  Timer? _pollTimer;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  var _sending = false;
  var _refreshing = false;
  var _loadingMore = false;
  var _connectionIssue = false;
  var _callAnswered = false;
  FamilyChatConnectionState _connectionState =
      FamilyChatConnectionState.checking;
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
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChildConversationScreen oldWidget) {
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
    final peer = _peer;
    if (peer == null) {
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
      final detail = await _repo.load(peer);
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
        if (discard) _detail = null;
        _loadFailed = discard || _detail == null;
        _loading = false;
        _connectionIssue = true;
        _connectionState = familyChatConnectionStateFor(error);
      });
    }
  }

  Future<void> _refresh() async {
    final peer = _peer;
    final repository = _repo;
    if (peer == null ||
        repository is! LiveConversationRepository ||
        _refreshing ||
        _loadingMore ||
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
        _loadFailed = false;
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
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

  Future<void> _loadMore() async {
    final peer = _peer;
    final repository = _repo;
    if (peer == null ||
        repository is! LiveConversationRepository ||
        _loadingMore ||
        !repository.hasMore(peer)) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final updated = await repository.loadNextPage(peer);
      if (!mounted) return;
      setState(() {
        _detail = updated ?? _detail;
        _loadingMore = false;
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
      });
    } on Object catch (error) {
      if (!mounted) return;
      final discard = familyChatFailureRequiresDiscard(error);
      setState(() {
        _loadingMore = false;
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
    await childSosSenderOf(context).fireThrough(fire);
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
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
        if (preset == null) _inputCtrl.clear();
        if (prev != null) _detail = _upsertDetail(prev, msg);
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
    final index = messages.indexWhere((item) => item.id == message.id);
    if (index < 0) {
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
    final peer = _peer;
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
    final peer = _peer;
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

  void _answerCall() {
    setState(() => _callAnswered = true);
    if (widget.onAnswerCall != null) {
      widget.onAnswerCall!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childConversationAnswerToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final titleText = _detail == null
        ? l10n.childConversationTitle
        : localizedConversationThreadTitle(
            l10n,
            _detail!.chatWith,
            _detail!.title,
            isFamilyThread: _detail!.familyPinnedNote,
          );

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
      return Column(
        children: [
          FamilyChatConnectionBanner(
            key: ChildConversationKeys.connection,
            state: _connectionState,
            onRetry: _load,
          ),
          Expanded(
            child: AppErrorState(
              key: ChildConversationKeys.error,
              kind: AppErrorKind.network,
              onRetry: _load,
            ),
          ),
        ],
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
        if (_connectionIssue)
          FamilyChatConnectionBanner(
            key: ChildConversationKeys.connection,
            state: _connectionState,
            onRetry: _refresh,
          ),
        if (_refreshing) const LinearProgressIndicator(minHeight: 2),
        if (detail.serverAuthoritative)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              l10n.childFamilyChatServerPollingNotice,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: BannerNote(
            key: ChildConversationKeys.neverLockBanner,
            variant: BannerVariant.t,
            message: detail.serverAuthoritative
                ? l10n.familyChatNeverLocks
                : l10n.childConversationNeverLockBanner,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                if (detail.hasMoreMessages)
                  Center(
                    child: TextButton.icon(
                      key: ChildConversationKeys.loadMore,
                      onPressed: _loadingMore ? null : _loadMore,
                      icon: _loadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.history),
                      label: Text(l10n.familyChatLoadMore),
                    ),
                  ),
                if (detail.isEmpty)
                  SizedBox(
                    height: 220,
                    child: AppEmptyState(
                      key: ChildConversationKeys.empty,
                      title: l10n.childConversationEmptyTitle,
                      message: l10n.childConversationEmptyMessage,
                    ),
                  ),
                for (final message in detail.messages)
                  _ChildBubble(
                    message: message,
                    colors: colors,
                    radii: radii,
                    serverAuthoritative: detail.serverAuthoritative,
                    onEdit: () => _editMessage(message),
                    onDelete: () => _deleteMessage(message),
                  ),
                if (detail.serverAuthoritative)
                  Padding(
                    key: ChildConversationKeys.serverStorageNotice,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.familyChatStorageNotice,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            key: ChildConversationKeys.composer,
            children: [
              if (detail.serverAuthoritative) ...[
                IconButton(
                  tooltip: l10n.familyChatMediaUnavailableSemantics,
                  onPressed: null,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                  icon: const Icon(Icons.attach_file),
                ),
                IconButton(
                  tooltip: l10n.familyChatMediaUnavailableSemantics,
                  onPressed: null,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                  icon: const Icon(Icons.mic_none_outlined),
                ),
              ],
              Expanded(
                child: TextField(
                  key: ChildConversationKeys.input,
                  controller: _inputCtrl,
                  enabled: _chat.canSend && !_sending && !_connectionIssue,
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
                onPressed: _chat.canSend && !_sending && !_connectionIssue
                    ? () => _send()
                    : null,
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
        if (detail.serverAuthoritative)
          Padding(
            key: ChildConversationKeys.mediaUnavailable,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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

class _ChildBubble extends StatelessWidget {
  const _ChildBubble({
    required this.message,
    required this.colors,
    required this.radii,
    required this.serverAuthoritative,
    required this.onEdit,
    required this.onDelete,
  });

  final ConversationMessage message;
  final FamilyColors colors;
  final FamilyRadii radii;
  final bool serverAuthoritative;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = message.isMine;
    final senderLabel = localizedFamilyChatSenderLabel(
      l10n,
      message.senderLabel,
    );
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
            if (senderLabel != null)
              Text(
                senderLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.ink2,
                ),
              ),
            Text(
              message.deleted
                  ? l10n.familyChatMessageDeleted
                  : message.body,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: message.deleted ? colors.ink2 : colors.ink,
                height: 1.45,
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
                    ].join(' · '),
                    style: TextStyle(fontSize: 10.5, color: colors.ink2),
                  ),
                ),
                if (serverAuthoritative && mine && !message.deleted)
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
    );
  }
}
