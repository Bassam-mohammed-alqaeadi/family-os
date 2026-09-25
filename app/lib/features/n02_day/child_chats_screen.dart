import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/bottom_sheet_host.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/chat_thread_widgets.dart';
import 'package:family_os/features/n02_day/child_chats_repository.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';

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

  static Key row(String id) => Key('child_chats_row_$id');
  static Key rowMenu(String id) => Key('child_chats_menu_$id');
  static Key pinnedIndicator(String id) => Key('child_chats_pinned_$id');
  static Key mutedIndicator(String id) => Key('child_chats_muted_$id');
  static Key archivedIndicator(String id) => Key('child_chats_archived_$id');
}

/// One quick action offered on a child's conversation row (ADR-053).
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

/// SCR-CHD-007 — محادثاتي (child family-tab chats list).
///
/// Closed circle only (family · father · mother). UI-007 / ChatAvailability —
/// never gated by billing; chat never locks when time expires. Rows open
/// CHD-008 with `chatWith` (FAT-022 pattern). Phone-contacts CTA (عل-٤).
/// P-4 SOS ungated. RoleGuard lean for parent. Mock-first — Rule 23 empty default.
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

  /// P-4 SOS seam — null → [stage1SosFireService].
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
  late final ChildChatsRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
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
    await fire.fire(childId: 'self');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.childChatsCallContactsToast)),
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
      return AppErrorState(
        key: ChildChatsKeys.error,
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
              key: ChildChatsKeys.honestyBanner,
              variant: BannerVariant.t,
              message: l10n.childChatsHonestyBanner,
            ),
          ),
          Expanded(
            child: AppEmptyState(
              key: ChildChatsKeys.empty,
              title: l10n.childChatsEmptyTitle,
              message: l10n.childChatsEmptyMessage,
            ),
          ),
        ],
      );
    }

    final ordered = snap.ordered;
    return SingleChildScrollView(
      key: ChildChatsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: ChildChatsKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.childChatsHonestyBanner,
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
                      l10n: l10n,
                      showDivider: i < ordered.length - 1,
                      onTap: () => _onRowTap(ordered[i]),
                      onMenu: () => _openRowMenu(ordered[i]),
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
        ],
      ),
    );
  }
}

class _ChildChatRow extends StatelessWidget {
  const _ChildChatRow({
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
      key: ChildChatsKeys.row(thread.id),
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
              if (thread.pinned)
                Text(
                  key: ChildChatsKeys.pinnedIndicator(thread.id),
                  l10n.conversationPinnedIndicator,
                  style: TextStyle(fontSize: 10, color: colors.ink2),
                ),
              if (thread.muted)
                Text(
                  key: ChildChatsKeys.mutedIndicator(thread.id),
                  l10n.conversationMutedIndicator,
                  style: TextStyle(fontSize: 10, color: colors.ink2),
                ),
              if (thread.archived)
                Text(
                  key: ChildChatsKeys.archivedIndicator(thread.id),
                  l10n.conversationArchivedIndicator,
                  style: TextStyle(fontSize: 10, color: colors.ink2),
                ),
              if (thread.hasUnread)
                Tag(label: '${thread.unreadCount}', variant: TagVariant.t)
              else
                Text(
                  thread.timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
            ],
          ),
          IconButton(
            key: ChildChatsKeys.rowMenu(thread.id),
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
            key: Key('child_chats_action_${action.name}'),
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
