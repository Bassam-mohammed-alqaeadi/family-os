import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/bottom_sheet_host.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/chat_thread_widgets.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';

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

  static Key row(String id) => Key('conversations_list_row_$id');
  static Key rowMenu(String id) => Key('conversations_list_menu_$id');
  static Key pinnedIndicator(String id) =>
      Key('conversations_list_pinned_$id');
  static Key mutedIndicator(String id) => Key('conversations_list_muted_$id');
  static Key archivedIndicator(String id) =>
      Key('conversations_list_archived_$id');
}

/// One quick action offered on a conversation row (ADR-053 per-chat settings).
enum _RowAction {
  muteEightHours,
  muteOneWeek,
  muteForever,
  unmute,
  archive,
  unarchive,
  pin,
  unpin,
}

/// SCR-FAT-021 — قائمة المحادثات (parent family-tab conversations list).
///
/// Pinned family chat first. UI-007 / ChatAvailability — never gated by billing.
/// Rows open FAT-022 with `chatWith`. P-4 SOS ungated. RoleGuard lean for child.
/// Mock-first — no Firebase. Rule 23: default empty until repo seed.
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

  /// P-4 SOS seam — null → [stage1SosFireService].
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
  late final ConversationsListRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
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
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final snap = await _repo.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _snapshot = null;
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
    await fire.fire(childId: 'family');
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

  void _onNewChat() {
    if (!_chat.isUsable) return;
    if (widget.onNewChat != null) {
      widget.onNewChat!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.conversationsListNewChatToast)),
    );
  }

  Future<void> _openRowMenu(ConversationThread thread) async {
    final l10n = AppLocalizations.of(context);
    final action = await _showRowActions(context, thread, l10n);
    if (action == null || !mounted) return;
    switch (action) {
      case _RowAction.muteEightHours:
        await _repo.setMuted(thread.id, kMuteEightHours);
      case _RowAction.muteOneWeek:
        await _repo.setMuted(thread.id, kMuteOneWeek);
      case _RowAction.muteForever:
        await _repo.setMuted(thread.id, null);
      case _RowAction.unmute:
        await _repo.unmute(thread.id);
      case _RowAction.archive:
        await _repo.setArchived(thread.id, true);
      case _RowAction.unarchive:
        await _repo.setArchived(thread.id, false);
      case _RowAction.pin:
        await _repo.setPinned(thread.id, true);
      case _RowAction.unpin:
        await _repo.setPinned(thread.id, false);
    }
    if (!mounted) return;
    await _load();
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
      return AppErrorState(
        key: ConversationsListKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    final snap = _snapshot ?? const ConversationsListSnapshot();
    if (snap.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BannerNote(
              key: ConversationsListKeys.honestyBanner,
              variant: BannerVariant.t,
              message: l10n.conversationsListHonestyBanner,
            ),
          ),
          Expanded(
            child: AppEmptyState(
              key: ConversationsListKeys.empty,
              title: l10n.conversationsListEmptyTitle,
              message: l10n.conversationsListEmptyMessage,
            ),
          ),
        ],
      );
    }

    final ordered = snap.ordered;
    return SingleChildScrollView(
      key: ConversationsListKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: ConversationsListKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.conversationsListHonestyBanner,
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
                onPressed: _onNewChat,
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
              boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Column(
                children: [
                  for (var i = 0; i < ordered.length; i++)
                    _ConversationRow(
                      thread: ordered[i],
                      l10n: l10n,
                      showDivider: i < ordered.length - 1,
                      onTap: () => _onRowTap(ordered[i]),
                      onMenu: () => _openRowMenu(ordered[i]),
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

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.thread,
    required this.l10n,
    required this.showDivider,
    required this.onTap,
    required this.onMenu,
  });

  final ConversationThread thread;
  final AppLocalizations l10n;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final avatarColor = _swatchColor(thread.swatch, colors);
    final isVoice = thread.previewKind == ConversationPreviewKind.voice;

    return RowTile(
      key: ConversationsListKeys.row(thread.id),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: avatarColor,
        child: Text(thread.emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: thread.title,
      subtitle: chatPreviewText(l10n, thread.preview, isVoice: isVoice),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _RowBadges(thread: thread, l10n: l10n),
              Text(
                thread.timeLabel,
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
          IconButton(
            key: ConversationsListKeys.rowMenu(thread.id),
            tooltip: l10n.conversationQuickActionsSemantics,
            onPressed: onMenu,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
            icon: Icon(Icons.more_vert, size: 20, color: colors.ink2),
          ),
        ],
      ),
      onTap: onTap,
      showDivider: showDivider,
    );
  }
}

/// Row badges: pinned, muted, archived — shown, never used to hide a row.
class _RowBadges extends StatelessWidget {
  const _RowBadges({required this.thread, required this.l10n});

  final ConversationThread thread;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final badges = <Widget>[
      if (thread.pinned)
        Text(
          key: ConversationsListKeys.pinnedIndicator(thread.id),
          l10n.conversationPinnedIndicator,
          style: TextStyle(fontSize: 10, color: colors.ink2),
        ),
      if (thread.muted)
        Text(
          key: ConversationsListKeys.mutedIndicator(thread.id),
          l10n.conversationMutedIndicator,
          style: TextStyle(fontSize: 10, color: colors.ink2),
        ),
      if (thread.archived)
        Text(
          key: ConversationsListKeys.archivedIndicator(thread.id),
          l10n.conversationArchivedIndicator,
          style: TextStyle(fontSize: 10, color: colors.ink2),
        ),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, children: badges);
  }
}

Future<_RowAction?> _showRowActions(
  BuildContext context,
  ConversationThread thread,
  AppLocalizations l10n,
) {
  final options = <(_RowAction, String)>[
    if (!thread.muted) ...[
      (_RowAction.muteEightHours, l10n.conversationMuteEightHours),
      (_RowAction.muteOneWeek, l10n.conversationMuteOneWeek),
      (_RowAction.muteForever, l10n.conversationMuteForever),
    ] else
      (_RowAction.unmute, l10n.conversationUnmute),
    if (thread.archived)
      (_RowAction.unarchive, l10n.conversationRowMenuUnarchive)
    else
      (_RowAction.archive, l10n.conversationRowMenuArchive),
    // The family chat is pinned دائمًا — a fixed right, not a toggle.
    if (!thread.isFamily)
      thread.pinned
          ? (_RowAction.unpin, l10n.conversationRowMenuUnpin)
          : (_RowAction.pin, l10n.conversationRowMenuPin),
  ];

  return BottomSheetHost.show<_RowAction>(
    context,
    semanticLabel: l10n.conversationQuickActionsSemantics,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            thread.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
        for (final (action, label) in options)
          ListTile(
            key: Key('conversations_list_action_${action.name}'),
            title: Text(label),
            onTap: () => Navigator.of(sheetContext).pop(action),
          ),
        if (thread.isFamily)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.conversationFamilyAlwaysPinned,
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
      ],
    ),
  );
}
