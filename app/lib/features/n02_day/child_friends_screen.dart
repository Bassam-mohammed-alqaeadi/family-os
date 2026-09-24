import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/child_friends_models.dart';
import 'package:family_os/features/n02_day/child_friends_repository.dart';

abstract final class ChildFriendsKeys {
  static const screen = Key('child_friends_screen');
  static const loading = Key('child_friends_loading');
  static const empty = Key('child_friends_empty');
  static const body = Key('child_friends_body');
  static const addCta = Key('child_friends_add');
  static const parentLean = Key('child_friends_parent_lean');
  static const sosIconCta = Key('child_friends_sos_icon');

  static Key friend(String id) => Key('child_friends_row_$id');
  static Key chat(String id) => Key('child_friends_chat_$id');
  static Key call(String id) => Key('child_friends_call_$id');
}

/// SCR-CHD-030 — أصدقائي (approved circle · father gate).
class ChildFriendsScreen extends StatefulWidget {
  const ChildFriendsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildFriendsRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildFriendsScreen> createState() => _ChildFriendsScreenState();
}

class _ChildFriendsScreenState extends State<ChildFriendsScreen> {
  late ChildFriendsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildFriendsSnapshot _snap = const ChildFriendsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildFriendsRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'self');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-CHD-005'));
  }

  String _name(AppLocalizations l10n, String key) => switch (key) {
    'friendOne' => l10n.childFriendsNameOne,
    'pendingFriend' => l10n.childFriendsNamePending,
    _ => key,
  };

  String _meta(AppLocalizations l10n, String key) => switch (key) {
    'slot47' => l10n.childFriendsMetaSlot47,
    'awaitingFather' => l10n.childFriendsMetaAwaiting,
    _ => key,
  };

  Future<void> _chat(String id) async {
    await _repo.openChat(id);
    if (!mounted) return;
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childFriendsChatToast,
    );
  }

  Future<void> _call(String id) async {
    await _repo.callFriend(id);
    if (!mounted) return;
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childFriendsCallToast,
    );
  }

  Future<void> _add() async {
    await _repo.requestAddFriend(nameKey: 'newFriend', placeKey: 'club');
    if (!mounted) return;
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childFriendsAddToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildFriendsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childFriendsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildFriendsKeys.sosIconCta,
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
      body: SafeArea(child: _body(l10n, colors)),
    );
  }

  Widget _body(AppLocalizations l10n, FamilyColors colors) {
    if (!_isChild) {
      return AppEmptyState(
        key: ChildFriendsKeys.parentLean,
        title: l10n.childFriendsParentLeanTitle,
        message: l10n.childFriendsParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildFriendsKeys.loading,
        child: Semantics(
          label: l10n.childFriendsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildFriendsKeys.empty,
        title: l10n.childFriendsEmptyTitle,
        message: l10n.childFriendsEmptyMessage,
        actionLabel: l10n.childFriendsEmptyCta,
        onAction: _add,
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildFriendsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  for (final f in _snap.friends)
                    Padding(
                      key: ChildFriendsKeys.friend(f.id),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colors.mint,
                            child: const Text(
                              '👦',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name(l10n, f.nameKey),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: colors.ink,
                                  ),
                                ),
                                Text(
                                  _meta(l10n, f.metaKey),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.teal600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 88,
                            child: PrimaryBtn(
                              key: ChildFriendsKeys.chat(f.id),
                              label: l10n.childFriendsChatCta,
                              variant: PrimaryBtnVariant.teal,
                              fullWidth: false,
                              onPressed: () => _chat(f.id),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            key: ChildFriendsKeys.call(f.id),
                            tooltip: l10n.childFriendsCallCta,
                            onPressed: () => _call(f.id),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: Icon(Icons.call, color: colors.teal600),
                          ),
                        ],
                      ),
                    ),
                  for (final p in _snap.pending)
                    Padding(
                      key: ChildFriendsKeys.friend(p.id),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colors.amber,
                                child: Text(
                                  String.fromCharCode(
                                    _name(l10n, p.nameKey).runes.first,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _name(l10n, p.nameKey),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: colors.ink,
                                      ),
                                    ),
                                    Text(
                                      _meta(l10n, p.metaKey),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Tag(
                                label: l10n.childFriendsPendingTag,
                                variant: TagVariant.a,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(
                color: colors.border,
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                children: [
                  Text(
                    l10n.childFriendsAddHeading,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.childFriendsAddSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryBtn(
                    key: ChildFriendsKeys.addCta,
                    label: l10n.childFriendsAddCta,
                    variant: PrimaryBtnVariant.teal,
                    onPressed: _add,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          BannerNote(
            variant: BannerVariant.t,
            message: l10n.childFriendsSafetyBanner,
          ),
        ],
      ),
    );
  }
}
