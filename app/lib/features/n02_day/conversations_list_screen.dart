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
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';
import 'package:family_os/features/n02_day/family_chat_connection_banner.dart';
import 'package:family_os/features/n02_day/family_chat_server_authority.dart';
import 'package:family_os/features/n02_day/family_chat_server_repository.dart';
import 'package:family_os/features/n02_day/family_chat_labels.dart';
import 'package:family_os/foundation_gate/family_chat_api_client.dart';

Color _swatchColor(ConversationSwatch swatch, FamilyColors colors) =>
    switch (swatch) {
      ConversationSwatch.family => colors.p500,
      ConversationSwatch.mother => colors.coral,
      ConversationSwatch.purple => colors.p500,
      ConversationSwatch.sky => colors.sky,
      ConversationSwatch.amber => colors.amber,
    };

/// Widget keys for SCR-FAT-021 acceptance.
abstract final class ConversationsListKeys {
  static const screen = Key('conversations_list_screen');
  static const loading = Key('conversations_list_loading');
  static const empty = Key('conversations_list_empty');
  static const error = Key('conversations_list_error');
  static const body = Key('conversations_list_body');
  static const honestyBanner = Key('conversations_list_honesty');
  static const sosCta = Key('conversations_list_sos');
  static const childLean = Key('conversations_list_child_lean');
  static const newChatCta = Key('conversations_list_new_chat');
  static const sectionHeader = Key('conversations_list_section');
  static const connection = Key('conversations_list_connection');
  static const createChatDialog = Key('conversations_list_create_dialog');
  static const createChatTitle = Key('conversations_list_create_title');
  static const createChatType = Key('conversations_list_create_type');
  static const createChatChild = Key('conversations_list_create_child');
  static const createChatRosterLoading =
      Key('conversations_list_create_roster_loading');
  static const createChatRosterFailure =
      Key('conversations_list_create_roster_failure');
  static const createChatConfirm = Key('conversations_list_create_confirm');

  static Key row(String id) => Key('conversations_list_row_$id');
}

/// SCR-FAT-021 — قائمة المحادثات (parent family-tab conversations list).
///
/// Server-owned family chat list. Rows open FAT-022 with `chatWith`; updates are polled while
/// visible because the W9 contract does not define push. P-4 SOS remains ungated.
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({
    super.key,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.chatAvailability,
    this.onSos,
    this.onOpenChat,
    this.onNewChat,
  });

  /// Null → [stage1ConversationsListRepository].
  final ConversationsListRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [activeSosFireService].
  final SosFireService? sosFire;

  /// UI-007 seam — null → [stage1ChatAvailability] (always usable).
  final ChatAvailability? chatAvailability;

  /// Test seam — SOS fire / navigate.
  final VoidCallback? onSos;

  /// Test seam — FAT-022 open with chatWith.
  final void Function(ConversationThread thread)? onOpenChat;

  /// Test seam — new conversation CTA.
  final VoidCallback? onNewChat;

  @override
  ConversationsListScreenState createState() => ConversationsListScreenState();
}

class ConversationsListScreenState extends State<ConversationsListScreen> {
  late ConversationsListRepository _repo;
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
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  ChatAvailability get _chat =>
      widget.chatAvailability ?? stage1ChatAvailability;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ConversationsListRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ConversationsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1ConversationsListRepository;
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
    if (mounted) {
      setState(() {
        _loading = !hadSnapshot;
        _refreshing = hadSnapshot;
        _loadFailed = false;
        if (_connectionState != FamilyChatConnectionState.connected) {
          _connectionState = FamilyChatConnectionState.reconnecting;
        }
      });
    }
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
    await parentSosSenderOf(context).fireThrough(fire);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
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
        path: '/scr-fat-022',
        queryParameters: {'chatWith': thread.chatWith},
      ).toString(),
    );
  }

  Future<void> _onNewChat() async {
    if (!_chat.isUsable || _creatingThread) return;
    if (widget.onNewChat != null) {
      widget.onNewChat!();
      return;
    }
    final repository = _repo;
    final l10n = AppLocalizations.of(context);
    if (repository is! FamilyChatThreadListRepository ||
        repository.surface != FamilyChatSurface.guardian) {
      AppToast.show(context, message: l10n.familyChatUnavailable);
      return;
    }
    final request = await _showCreateDialog(repository);
    if (request == null || !mounted) return;

    setState(() => _creatingThread = true);
    try {
      final thread = await repository.createThread(
        kind: request.kind,
        title: request.title,
        childIds: request.childId == null ? const <String>[] : <String>[request.childId!],
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      context.push(
        Uri(
          path: '/scr-fat-022',
          queryParameters: <String, String>{'chatWith': thread.id},
        ).toString(),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _connectionState = familyChatConnectionStateFor(error));
      AppToast.show(
        context,
        message: familyChatConnectionMessage(l10n, _connectionState) ??
            l10n.familyChatCreateFailed,
      );
    } finally {
      if (mounted) setState(() => _creatingThread = false);
    }
  }

  Future<_CreateChatRequest?> _showCreateDialog(
    FamilyChatThreadListRepository repository,
  ) async {
    final l10n = AppLocalizations.of(context);
    var childOptionsFuture = repository.loadChildOptions();
    final titleController = TextEditingController();
    var kind = FamilyChatThreadKind.family;
    String? childId;
    var availableChildIds = <String>{};

    try {
      return await showDialog<_CreateChatRequest>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final canCreate = kind == FamilyChatThreadKind.family ||
                (childId != null && availableChildIds.contains(childId));
            return AlertDialog(
              key: ConversationsListKeys.createChatDialog,
              title: Text(l10n.familyChatCreateHeading),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<FamilyChatThreadKind>(
                      key: ConversationsListKeys.createChatType,
                      value: kind,
                      decoration: InputDecoration(
                        labelText: l10n.familyChatCreateTypeLabel,
                      ),
                      items: <DropdownMenuItem<FamilyChatThreadKind>>[
                        DropdownMenuItem(
                          value: FamilyChatThreadKind.family,
                          child: Text(l10n.familyChatFamilyThread),
                        ),
                        DropdownMenuItem(
                          value: FamilyChatThreadKind.child,
                          child: Text(l10n.familyChatChildThread),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            kind = value;
                            childId = null;
                          });
                        }
                      },
                    ),
                    if (kind == FamilyChatThreadKind.child) ...[
                      const SizedBox(height: 12),
                      FutureBuilder<List<FamilyChatChildOption>>(
                        future: childOptionsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return Padding(
                              key: ConversationsListKeys
                                  .createChatRosterLoading,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(l10n.familyChatConnecting),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return FamilyChatConnectionBanner(
                              key: ConversationsListKeys
                                  .createChatRosterFailure,
                              state: familyChatConnectionStateFor(
                                snapshot.error!,
                              ),
                              onRetry: () => setDialogState(() {
                                childId = null;
                                availableChildIds = <String>{};
                                childOptionsFuture =
                                    repository.loadChildOptions();
                              }),
                            );
                          }

                          final children = snapshot.data ??
                              const <FamilyChatChildOption>[];
                          availableChildIds = children
                              .map((child) => child.id)
                              .toSet();
                          if (children.isEmpty) {
                            return Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(l10n.familyChatNoChildrenAvailable),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            key: ConversationsListKeys.createChatChild,
                            value: children.any((child) => child.id == childId)
                                ? childId
                                : null,
                            decoration: InputDecoration(
                              labelText: l10n.familyChatCreateChildLabel,
                            ),
                            hint: Text(l10n.familyChatCreateChildLabel),
                            items: children
                                .map(
                                  (child) => DropdownMenuItem<String>(
                                    value: child.id,
                                    child: Text(
                                      child.displayName?.trim().isNotEmpty ==
                                              true
                                          ? child.displayName!.trim()
                                          : l10n.familyChatChildFallback,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) =>
                                setDialogState(() => childId = value),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      key: ConversationsListKeys.createChatTitle,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.familyChatCancel),
                ),
                FilledButton(
                  key: ConversationsListKeys.createChatConfirm,
                  onPressed: canCreate
                      ? () => Navigator.of(dialogContext).pop(
                            _CreateChatRequest(
                              kind: kind,
                              title: titleController.text.trim(),
                              childId: kind == FamilyChatThreadKind.child
                                  ? childId
                                  : null,
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
    } finally {
      titleController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ConversationsListKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.conversationsListTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          // P-4 — SOS never gated by empty/loading/error.
          IconButton(
            key: ConversationsListKeys.sosCta,
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
        key: ConversationsListKeys.childLean,
        title: l10n.conversationsListChildLeanTitle,
        message: l10n.conversationsListChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: ConversationsListKeys.loading,
        label: l10n.conversationsListLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return Column(
        children: [
          FamilyChatConnectionBanner(
            key: ConversationsListKeys.connection,
            state: _connectionState,
            onRetry: _load,
          ),
          Expanded(
            child: AppErrorState(
              key: ConversationsListKeys.error,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            FamilyChatConnectionBanner(
              key: ConversationsListKeys.connection,
              state: _connectionState,
              onRetry: _load,
            ),
            if (_refreshing) const LinearProgressIndicator(minHeight: 2),
            BannerNote(
              key: ConversationsListKeys.honestyBanner,
              variant: BannerVariant.t,
              message: _repo is FamilyChatThreadListRepository
                  ? l10n.familyChatListPollingNotice
                  : l10n.conversationsListHonestyBanner,
            ),
            const SizedBox(height: 24),
            AppEmptyState(
              key: ConversationsListKeys.empty,
              title: l10n.conversationsListEmptyTitle,
              message: l10n.conversationsListEmptyMessage,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: ConversationsListKeys.newChatCta,
              onPressed: _creatingThread ? null : _onNewChat,
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(l10n.conversationsListNewChatCta),
            ),
            const ShellTabMoreTools(tabId: 'family'),
          ],
        ),
      );
    }

    final ordered = snap.ordered;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        key: ConversationsListKeys.body,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FamilyChatConnectionBanner(
              key: ConversationsListKeys.connection,
              state: _connectionState,
              onRetry: _load,
            ),
            BannerNote(
              key: ConversationsListKeys.honestyBanner,
              variant: BannerVariant.t,
              message: _repo is FamilyChatThreadListRepository
                  ? l10n.familyChatListPollingNotice
                  : l10n.conversationsListHonestyBanner,
            ),
            const SizedBox(height: 14),
            Row(
              key: ConversationsListKeys.sectionHeader,
              children: [
                Expanded(
                  child: Text(
                    l10n.conversationsListSectionTitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                TextButton(
                  key: ConversationsListKeys.newChatCta,
                  onPressed: _creatingThread ? null : _onNewChat,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.tealDeep,
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: Text(l10n.conversationsListNewChatCta),
                ),
              ],
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(
                  Theme.of(context).extension<FamilyRadii>()!.card,
                ),
                border: Border.all(color: colors.border.withValues(alpha: 0.85)),
                boxShadow: [
                  Theme.of(context).extension<FamilyShadows>()!.shCard,
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                child: Column(
                  children: [
                    for (var i = 0; i < ordered.length; i++)
                      _ConversationRow(
                        thread: ordered[i],
                        showDivider: i < ordered.length - 1,
                        onTap: () => _onRowTap(ordered[i]),
                      ),
                  ],
                ),
              ),
            ),
            const ShellTabMoreTools(tabId: 'family'),
        ),
      ),
    );
  }
}

final class _CreateChatRequest {
  const _CreateChatRequest({
    required this.kind,
    required this.title,
    required this.childId,
  });

  final FamilyChatThreadKind kind;
  final String title;
  final String? childId;
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
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
      key: ConversationsListKeys.row(thread.id),
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
          Text(
            timeLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          if (thread.hasUnread) ...[
            const SizedBox(height: 4),
            Tag(label: '${thread.unreadCount}', variant: TagVariant.p),
          ],
        ],
      ),
      onTap: onTap,
      showDivider: showDivider,
    );
  }
}
