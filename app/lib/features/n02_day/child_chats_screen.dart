import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/shell_tab_more_tools.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/child_chats_repository.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';
import 'package:family_os/features/n02_day/family_chat_connection_banner.dart';
import 'package:family_os/features/n02_day/family_chat_server_repository.dart';
import 'package:family_os/features/n02_day/family_chat_labels.dart';

Color _swatchColor(ConversationSwatch swatch, FamilyColors colors) =>
    switch (swatch) {
      ConversationSwatch.family => colors.p500,
      ConversationSwatch.mother => colors.coral,
      ConversationSwatch.purple => colors.p500,
      ConversationSwatch.sky => colors.sky,
      ConversationSwatch.amber => colors.amber,
    };

/// Widget keys for SCR-CHD-007 acceptance.
abstract final class ChildChatsKeys {
  static const screen = Key('child_chats_screen');
  static const loading = Key('child_chats_loading');
  static const empty = Key('child_chats_empty');
  static const error = Key('child_chats_error');
  static const body = Key('child_chats_body');
  static const honestyBanner = Key('child_chats_honesty');
  static const safeCircleBanner = Key('child_chats_safe_circle');
  static const sosCta = Key('child_chats_sos');
  static const parentLean = Key('child_chats_parent_lean');
  static const callContactsCta = Key('child_chats_call_contacts');
  static const connection = Key('child_chats_connection');

  static Key row(String id) => Key('child_chats_row_$id');
}

/// SCR-CHD-007 — محادثاتي (child family-tab chats list).
///
/// Closed circle only (family · father · mother). UI-007 / ChatAvailability —
/// never gated by billing; chat never locks when time expires. Rows open
/// CHD-008 with `chatWith` (FAT-022 pattern). Phone-contacts CTA (عل-٤).
/// P-4 SOS ungated. RoleGuard lean for parent; server refresh is polled while visible.
class ChildChatsScreen extends StatefulWidget {
  const ChildChatsScreen({
    super.key,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.chatAvailability,
    this.onSos,
    this.onOpenChat,
    this.onCallContacts,
  });

  /// Null → [stage1ChildChatsRepository].
  final ChildChatsRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [activeSosFireService].
  final SosFireService? sosFire;

  /// UI-007 seam — null → [stage1ChatAvailability] (always usable).
  final ChatAvailability? chatAvailability;

  /// Test seam — SOS fire / navigate.
  final VoidCallback? onSos;

  /// Test seam — CHD-008 open with chatWith.
  final void Function(ConversationThread thread)? onOpenChat;

  /// Test seam — phone contacts CTA (عل-٤).
  final VoidCallback? onCallContacts;

  @override
  ChildChatsScreenState createState() => ChildChatsScreenState();
}

class ChildChatsScreenState extends State<ChildChatsScreen> {
  late ChildChatsRepository _repo;
  Timer? _refreshTimer;
  var _loading = true;
  var _loadFailed = false;
  var _refreshing = false;
  var _sosBusy = false;
  var _creatingThread = false;
  var _requestInFlight = false;
  FamilyChatConnectionState _connectionState =
      FamilyChatConnectionState.checking;
  ConversationsListSnapshot? _snapshot;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  bool get _isChild => _role == AppRole.child;

  ChatAvailability get _chat =>
      widget.chatAvailability ?? stage1ChatAvailability;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildChatsRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ChildChatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1ChildChatsRepository;
      _refreshTimer?.cancel();
      _snapshot = null;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleRefresh() {
    if (_repo is! FamilyChatThreadListRepository) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    final hadSnapshot = _snapshot != null;
    setState(() {
      _loading = !hadSnapshot;
      _refreshing = hadSnapshot;
      _loadFailed = false;
      if (_connectionState != FamilyChatConnectionState.connected) {
        _connectionState = FamilyChatConnectionState.reconnecting;
      }
    });
    try {
      final snap = await _repo.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
        _refreshing = false;
        _loadFailed = false;
        _connectionState = FamilyChatConnectionState.connected;
      });
      _scheduleRefresh();
    } on Object catch (error) {
      if (!mounted) return;
      final discard = familyChatFailureRequiresDiscard(error);
      setState(() {
        _loading = false;
        _refreshing = false;
        _loadFailed = !hadSnapshot || discard;
        if (discard) _snapshot = null;
        _connectionState = familyChatConnectionStateFor(error);
      });
    } finally {
      _requestInFlight = false;
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
    context.push('/scr-chd-005');
  }

  void _onRowTap(ConversationThread thread) {
    // UI-007 — chat never blocked by billing; AlwaysOn always usable.
    if (!_chat.isUsable) return;
    if (widget.onOpenChat != null) {
      widget.onOpenChat!(thread);
      return;
    }
    context.push(
      Uri(
        path: '/scr-chd-008',
        queryParameters: {'chatWith': thread.chatWith},
      ).toString(),
    );
  }

  void _onCallContacts() {
    if (widget.onCallContacts != null) {
      widget.onCallContacts!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childChatsCallContactsToast);
  }

  Future<void> _onNewChat() async {
    final l10n = AppLocalizations.of(context);
    final repository = _repo;
    if (!_isChild || _creatingThread || repository is! FamilyChatThreadListRepository) {
      return;
    }
    final List<FamilyChatParticipant> roster;
    try {
      roster = await repository.loadParticipants();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _connectionState = familyChatConnectionStateFor(error));
      AppToast.show(
        context,
        message: familyChatConnectionMessage(l10n, _connectionState) ?? l10n.familyChatUnavailable,
      );
      return;
    }
    if (!mounted) return;
    final available = roster.where((participant) => !participant.isSelf).toList(growable: false);
    if (available.isEmpty) {
      AppToast.show(context, message: l10n.familyChatNoParticipantsAvailable);
      return;
    }
    final titleController = TextEditingController();
    var kind = FamilyChatThreadKind.direct;
    final selectedKeys = <String>{};
    String participantKey(FamilyChatParticipant participant) =>
        '${participant.kind.wireValue}:${participant.id}';
    final choice = await showDialog<_ChildCreateChatChoice>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selected = available
              .where((participant) => selectedKeys.contains(participantKey(participant)))
              .toList(growable: false);
          final canCreate = kind == FamilyChatThreadKind.direct
              ? selected.length == 1
              : selected.length >= 2 && selected.length <= 23;
          return AlertDialog(
            title: Text(l10n.familyChatCreateHeading),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<FamilyChatThreadKind>(
                      initialValue: kind,
                      decoration: InputDecoration(labelText: l10n.familyChatCreateTypeLabel),
                      items: <DropdownMenuItem<FamilyChatThreadKind>>[
                        DropdownMenuItem(value: FamilyChatThreadKind.direct, child: Text(l10n.familyChatDirectThread)),
                        DropdownMenuItem(value: FamilyChatThreadKind.group, child: Text(l10n.familyChatGroupThread)),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          kind = value;
                          if (kind == FamilyChatThreadKind.direct && selectedKeys.length > 1) {
                            final keep = selectedKeys.first;
                            selectedKeys..clear()..add(keep);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.familyChatSelectParticipants),
                    for (final participant in available)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          participant.displayName?.trim().isNotEmpty == true
                              ? participant.displayName!.trim()
                              : participant.kind == FamilyChatParticipantKind.child
                                  ? l10n.familyChatChildFallback
                                  : l10n.dayBoardGuardianFallback,
                        ),
                        value: selectedKeys.contains(participantKey(participant)),
                        onChanged: (checked) => setDialogState(() {
                          final key = participantKey(participant);
                          if (checked == true) {
                            if (kind == FamilyChatThreadKind.direct) selectedKeys.clear();
                            selectedKeys.add(key);
                          } else {
                            selectedKeys.remove(key);
                          }
                        }),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.familyChatCreateTitleLabel,
                        hintText: l10n.familyChatCreateTitleHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.familyChatCancel)),
              FilledButton(
                onPressed: canCreate
                    ? () => Navigator.of(dialogContext).pop(
                          _ChildCreateChatChoice(
                            kind: kind,
                            title: titleController.text.trim(),
                            participants: selected
                                .map((participant) => FamilyChatParticipantReference(
                                      kind: participant.kind,
                                      id: participant.id,
                                    ))
                                .toList(growable: false),
                          ),
                        )
                    : null,
                child: Text(l10n.familyChatCreateButton),
              ),
            ],
          );
        },
      ),
    );
    titleController.dispose();
    if (choice == null || !mounted) return;
    setState(() => _creatingThread = true);
    try {
      final thread = await repository.createThread(
        kind: choice.kind,
        title: choice.title,
        participants: choice.participants,
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      // The conversation route resolves the newly created room through the server on open.
      context.push(
        Uri(path: '/scr-chd-008', queryParameters: <String, String>{'chatWith': thread.chatWith}).toString(),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _connectionState = familyChatConnectionStateFor(error));
      AppToast.show(
        context,
        message: familyChatConnectionMessage(l10n, _connectionState) ?? l10n.familyChatCreateFailed,
      );
    } finally {
      if (mounted) setState(() => _creatingThread = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildChatsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childChatsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          // P-4 — SOS never gated by empty/loading/error.
          IconButton(
            key: ChildChatsKeys.sosCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _sosBusy ? null : _openSos,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.sos, color: colors.coral),
          ),
          if (_isChild && _repo is FamilyChatThreadListRepository)
            IconButton(
              key: const Key('child_chats_new_chat'),
              tooltip: l10n.familyChatCreateHeading,
              onPressed: _creatingThread ? null : _onNewChat,
              icon: _creatingThread
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_comment_outlined),
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
    if (!_isChild) {
      return AppEmptyState(
        key: ChildChatsKeys.parentLean,
        title: l10n.childChatsParentLeanTitle,
        message: l10n.childChatsParentLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: ChildChatsKeys.loading,
        label: l10n.childChatsLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return Column(
        children: [
          FamilyChatConnectionBanner(
            key: ChildChatsKeys.connection,
            state: _connectionState,
            onRetry: _load,
          ),
          Expanded(
            child: AppErrorState(
              key: ChildChatsKeys.error,
              kind: AppErrorKind.network,
              onRetry: _load,
            ),
          ),
        ],
      );
    }

    final snap = _snapshot ?? const ConversationsListSnapshot();
    if (snap.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FamilyChatConnectionBanner(
              key: ChildChatsKeys.connection,
              state: _connectionState,
              onRetry: _load,
            ),
            if (_refreshing) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: BannerNote(
                key: ChildChatsKeys.honestyBanner,
                variant: BannerVariant.t,
                message: _repo is FamilyChatThreadListRepository
                    ? l10n.familyChatListPollingNotice
                    : l10n.honestyChildGentleLine,
              ),
            ),
            SizedBox(
              height: 300,
              child: AppEmptyState(
                key: ChildChatsKeys.empty,
                title: l10n.childChatsEmptyTitle,
                message: l10n.childChatsEmptyMessage,
              ),
            ),
          ],
        ),
      );
    }

    final ordered = snap.ordered;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        key: ChildChatsKeys.body,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FamilyChatConnectionBanner(
              key: ChildChatsKeys.connection,
              state: _connectionState,
              onRetry: _load,
            ),
            if (_refreshing) const LinearProgressIndicator(minHeight: 2),
            BannerNote(
            key: ChildChatsKeys.honestyBanner,
            variant: BannerVariant.t,
            message: _repo is FamilyChatThreadListRepository
                    ? l10n.familyChatListPollingNotice
                    : l10n.honestyChildGentleLine,
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(
                Theme.of(context).extension<FamilyRadii>()!.card,
              ),
              border: Border.all(color: colors.border.withValues(alpha: 0.85)),
              boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Column(
                children: [
                  for (var i = 0; i < ordered.length; i++)
                    _ChildChatRow(
                      thread: ordered[i],
                      showDivider: i < ordered.length - 1,
                      onTap: () => _onRowTap(ordered[i]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryBtn(
            key: ChildChatsKeys.callContactsCta,
            label: l10n.childChatsCallContactsCta,
            semanticsLabel: l10n.childChatsCallContactsSemantics,
            variant: PrimaryBtnVariant.teal,
            onPressed: _onCallContacts,
          ),
          const SizedBox(height: 12),
          BannerNote(
            key: ChildChatsKeys.safeCircleBanner,
            variant: BannerVariant.t,
            message: l10n.childChatsSafeCircleBanner,
          ),
          const ShellTabMoreTools(tabId: 'cfam'),
          ],
        ),
      ),
    );
  }
}

final class _ChildCreateChatChoice {
  const _ChildCreateChatChoice({
    required this.kind,
    required this.title,
    required this.participants,
  });

  final FamilyChatThreadKind kind;
  final String title;
  final List<FamilyChatParticipantReference> participants;
}

class _ChildChatRow extends StatelessWidget {
  const _ChildChatRow({
    required this.thread,
    required this.showDivider,
    required this.onTap,
  });

  final ConversationThread thread;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final avatarColor = _swatchColor(thread.swatch, colors);
    final title = localizedConversationThreadTitle(
      l10n,
      thread.chatWith,
      thread.title,
      threadKind: thread.threadKind,
    );
    final preview = thread.lastMessageDeleted
        ? l10n.familyChatMessageDeleted
        : localizedConversationThreadPreview(
            l10n,
            thread.chatWith,
            thread.preview,
          );
    final timeLabel = thread.lastMessageAt == null
        ? thread.timeLabel
        : intl.DateFormat.Hm(l10n.localeName)
            .format(thread.lastMessageAt!.toLocal());

    return RowTile(
      key: ChildChatsKeys.row(thread.id),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: avatarColor,
        child: Text(thread.emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: title,
      subtitle: preview,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (thread.hasUnread)
            Tag(label: '${thread.unreadCount}', variant: TagVariant.t)
          else
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
        ],
      ),
      onTap: onTap,
      showDivider: showDivider,
    );
  }
}
