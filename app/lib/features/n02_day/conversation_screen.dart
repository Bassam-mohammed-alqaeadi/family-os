import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:family_os/features/n02_day/media_compose.dart';
import 'package:family_os/features/n02_day/voice_note_player.dart';
import 'package:family_os/features/n02_day/family_chat_labels.dart';
import 'package:family_os/foundation_gate/family_chat_realtime_client.dart';

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
  static const realtimeStatus = Key('conversation_realtime_status');

  static Key mediaView(String messageId) => Key('conversation_media_$messageId');
  static const toneBridge = Key('conversation_tone_bridge');
  static const composer = Key('conversation_composer');
  static const input = Key('conversation_input');
  static const send = Key('conversation_send');
  static const attach = Key('conversation_attach');
  static const attachGallery = Key('conversation_attach_gallery');
  static const attachCamera = Key('conversation_attach_camera');
  static const attachVoice = Key('conversation_attach_voice');
  static const pendingMedia = Key('conversation_pending_media');
  static const pendingMediaRemove = Key('conversation_pending_media_remove');
  static const sosCta = Key('conversation_sos');
  static const childLean = Key('conversation_child_lean');
  static const title = Key('conversation_title');
  static const connection = Key('conversation_connection');
  static const loadOlder = Key('conversation_load_older');
  static const mediaUnavailable = Key('conversation_media_unavailable');

  static Key bubble(String id) => Key('conversation_bubble_$id');
  static Key voicePlay(String id) => Key('conversation_voice_play_$id');
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
  LiveHintConversationRepository? _hintRepo;
  /// A photo the person has chosen and is captioning. It is sent only by the send button.
  ConversationMediaDraft? _pendingMedia;
  StreamSubscription<FamilyChatRealtimeHint>? _hintSub;
  StreamSubscription<FamilyChatRealtimeState>? _realtimeSub;
  var _realtimeState = FamilyChatRealtimeState.stopped;
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
    _detachRealtime();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatWith != widget.chatWith ||
        oldWidget.repository != widget.repository) {
      _detachRealtime();
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
    _startRealtime();
  }

  /// The socket is an accelerator, never the source of truth. A hint asks the REST API again; the
  /// 15-second poll above stays on as the fallback for when the socket is down or refused.
  void _startRealtime() {
    final repo = _repo;
    final peer = _resolvedPeer;
    if (repo is! LiveHintConversationRepository || peer == null) return;
    if (_hintRepo != repo) {
      _detachRealtime();
      _hintRepo = repo;
      _hintSub = repo.hints.listen(_onRealtimeHint);
      _realtimeSub = repo.realtimeStates.listen((state) {
        if (!mounted) return;
        setState(() => _realtimeState = state);
      });
    }
    unawaited(repo.watchRealtime(peer));
  }

  void _onRealtimeHint(FamilyChatRealtimeHint hint) {
    if (!mounted || hint.threadId != _resolvedPeer) return;
    unawaited(_refresh());
  }

  void _detachRealtime() {
    final repo = _hintRepo;
    _hintSub?.cancel();
    _realtimeSub?.cancel();
    _hintSub = null;
    _realtimeSub = null;
    _hintRepo = null;
    if (repo != null) unawaited(repo.stopRealtime());
  }

  String _realtimeLabel(AppLocalizations l10n) => switch (_realtimeState) {
    FamilyChatRealtimeState.live => l10n.familyChatRealtimeLive,
    FamilyChatRealtimeState.retrying => l10n.familyChatRealtimeRetrying,
    FamilyChatRealtimeState.connecting ||
    FamilyChatRealtimeState.stopped => l10n.familyChatRealtimePolling,
  };

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
    final photo = preset == null ? _pendingMedia : null;
    if (text.isEmpty && photo == null) return;

    if (photo != null) {
      // The typed text is the photo's caption. The input clears only when the send succeeded.
      await _deliverMedia(photo.withCaption(text));
      if (mounted && _pendingMedia == null) _inputCtrl.clear();
      return;
    }

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

  /// The live media repository, when this surface may send photos and voice notes.
  LiveMediaConversationRepository? get _mediaRepo {
    final repo = _repo;
    return repo is LiveMediaConversationRepository && repo.canSendMedia ? repo : null;
  }

  Future<void> _onAttach() async {
    if (!_chat.isUsable) return;
    if (widget.onAttach != null) {
      widget.onAttach!();
      return;
    }
    if (_mediaRepo == null) {
      final l10n = AppLocalizations.of(context);
      AppToast.show(context, message: l10n.conversationAttachToast);
      return;
    }
    final choice = await showModalBottomSheet<_AttachChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => _AttachSheet(l10n: AppLocalizations.of(context)),
    );
    if (!mounted || choice == null) return;
    await _compose(choice);
  }

  Future<void> _compose(_AttachChoice choice) async {
    final l10n = AppLocalizations.of(context);
    try {
      switch (choice) {
        case _AttachChoice.gallery:
          final draft = await pickConversationPhoto(ImageSource.gallery);
          if (draft != null && mounted) setState(() => _pendingMedia = draft);
        case _AttachChoice.camera:
          final draft = await pickConversationPhoto(ImageSource.camera);
          if (draft != null && mounted) setState(() => _pendingMedia = draft);
        case _AttachChoice.voice:
          final recording = await showVoiceNoteRecorder(context);
          if (recording == null || !mounted) return;
          await _deliverMedia(
            newConversationMediaDraft(
              kind: ConversationMediaKind.audio,
              bytes: recording.bytes,
              mimeType: 'audio/mp4',
              durationMs: recording.durationMs,
            ),
          );
      }
    } on MediaComposeException catch (error) {
      if (mounted) AppToast.show(context, message: mediaComposeMessage(l10n, error.problem));
    } on Object {
      if (mounted) AppToast.show(context, message: l10n.mediaComposeFailed);
    }
  }

  /// Uploads one composed photo or voice note and posts the message that carries it.
  Future<void> _deliverMedia(ConversationMediaDraft draft) async {
    final peer = _resolvedPeer;
    final media = _mediaRepo;
    if (peer == null || media == null || _detail == null || _sending) return;
    setState(() => _sending = true);
    try {
      final l10n = AppLocalizations.of(context);
      final sent = await media.sendMedia(
        peer,
        draft,
        timeLabel: l10n.conversationSentNow,
      );
      if (!mounted) return;
      setState(() {
        final detail = _detail;
        if (detail != null) _detail = _upsertDetail(detail, sent);
        _sending = false;
        _connectionIssue = false;
        _connectionState = FamilyChatConnectionState.connected;
        if (_pendingMedia?.clientMediaId == draft.clientMediaId) _pendingMedia = null;
      });
      unawaited(_refresh());
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
            key: ConversationKeys.realtimeStatus,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(
              _realtimeLabel(l10n),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
          ),
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
          mediaEnabled: _mediaRepo != null,
          pendingMedia: _pendingMedia,
          onRemovePending: () => setState(() => _pendingMedia = null),
          sending: _sending,
          onAttach: _onAttach,
          onSend: () => _send(),
          l10n: l10n,
        ),
        if (detail.serverAuthoritative && _mediaRepo == null)
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
    final receiptLine = isMine ? _receiptLabel(l10n, message.receipt) : null;
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
                if (message.media != null && !message.deleted) ...[
                  _MediaView(
                    key: ConversationKeys.mediaView(message.id),
                    media: message.media!,
                    foreground: fg,
                    surface: colors.surface,
                  ),
                  const SizedBox(height: 6),
                ],
                if (message.deleted || message.body.isNotEmpty)
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
                          if (receiptLine != null) receiptLine,
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

  /// "N of M" for my message, from aggregate counts only. Never names, never per-person ticks.
  String? _receiptLabel(AppLocalizations l10n, ConversationReceipt? receipt) {
    if (receipt == null || receipt.otherParticipantCount <= 0) return null;
    if (receipt.readCount > 0) {
      return l10n.familyChatReceiptRead(
        receipt.readCount,
        receipt.otherParticipantCount,
      );
    }
    if (receipt.deliveredCount > 0) {
      return l10n.familyChatReceiptDelivered(
        receipt.deliveredCount,
        receipt.otherParticipantCount,
      );
    }
    return null;
  }

  /// One tick records only this device's send state. Other people's receipts are the counts above,
  /// never ✓✓: the legacy delivered/read aliases are not drawn as ticks.
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
    required this.pendingMedia,
    required this.onRemovePending,
    required this.sending,
    required this.onAttach,
    required this.onSend,
    required this.l10n,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool mediaEnabled;
  final ConversationMediaDraft? pendingMedia;
  final VoidCallback onRemovePending;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final photo = pendingMedia;

    return Column(
      key: ConversationKeys.composer,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photo != null)
          Padding(
            key: ConversationKeys.pendingMedia,
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Image.memory(
                    photo.bytes,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.mediaPhotoPendingLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ),
                IconButton(
                  key: ConversationKeys.pendingMediaRemove,
                  tooltip: l10n.mediaPhotoRemove,
                  onPressed: sending ? null : onRemovePending,
                  icon: Icon(Icons.close, color: colors.ink2),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: _composerRow(context, colors),
        ),
      ],
    );
  }

  Widget _composerRow(BuildContext context, FamilyColors colors) {
    return Row(
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
    );
  }
}

enum _AttachChoice { gallery, camera, voice }

/// The three ways to add to a message. Photos become a draft to caption; a voice note is recorded
/// and sent as its own message.
class _AttachSheet extends StatelessWidget {
  const _AttachSheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: ConversationKeys.attachGallery,
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.conversationAttachPhotoGallery),
            onTap: () => Navigator.of(context).pop(_AttachChoice.gallery),
          ),
          ListTile(
            key: ConversationKeys.attachCamera,
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.conversationAttachPhotoCamera),
            onTap: () => Navigator.of(context).pop(_AttachChoice.camera),
          ),
          ListTile(
            key: ConversationKeys.attachVoice,
            leading: const Icon(Icons.mic_none),
            title: Text(l10n.conversationAttachVoice),
            onTap: () => Navigator.of(context).pop(_AttachChoice.voice),
          ),
        ],
      ),
    );
  }
}

/// A photo or voice note. Photos are fetched when the bubble first appears, and any failure shows
/// as unavailable. Voice notes play in place: the bytes are fetched and verified on first play.
class _MediaView extends StatefulWidget {
  const _MediaView({
    super.key,
    required this.media,
    required this.foreground,
    required this.surface,
  });

  final ConversationMedia media;
  final Color foreground;
  final Color surface;

  @override
  State<_MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<_MediaView> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant _MediaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.id != widget.media.id) _start();
  }

  void _start() {
    final media = widget.media;
    final load = media.loadBytes;
    _bytes = media.available &&
            media.kind == ConversationMediaKind.image &&
            load != null
        ? load()
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = widget.media;
    if (!media.available) return _note(l10n.familyChatMediaItemUnavailable);

    if (media.kind == ConversationMediaKind.audio) {
      return VoiceNotePlayer(
        media: media,
        foreground: widget.foreground,
        surface: widget.surface,
        buttonKey: ConversationKeys.voicePlay(media.id),
      );
    }

    if (_bytes == null) return _note(l10n.familyChatMediaNotOnThisDevice);
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _note(l10n.familyChatMediaLoading);
        }
        final bytes = snapshot.data;
        if (bytes == null) return _note(l10n.familyChatMediaItemUnavailable);
        return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                _note(l10n.familyChatMediaItemUnavailable),
          ),
        );
      },
    );
  }

  Widget _note(String text) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: widget.surface.withValues(alpha: 0.18),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: widget.foreground,
        height: 1.35,
      ),
    ),
  );
}
