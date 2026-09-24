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
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/friend_approval_models.dart';
import 'package:family_os/features/n02_day/friend_approval_repository.dart';

/// Widget keys for SCR-FAT-071 acceptance.
abstract final class FriendApprovalKeys {
  static const screen = Key('friend_approval_screen');
  static const loading = Key('friend_approval_loading');
  static const empty = Key('friend_approval_empty');
  static const body = Key('friend_approval_body');
  static const profileCard = Key('friend_approval_profile');
  static const channelsCard = Key('friend_approval_channels');
  static const textSwitch = Key('friend_approval_text_swt');
  static const callsSwitch = Key('friend_approval_calls_swt');
  static const approveCta = Key('friend_approval_approve');
  static const declineCta = Key('friend_approval_decline');
  static const observerHint = Key('friend_approval_observer');
  static const childLean = Key('friend_approval_child_lean');
  static const sosIconCta = Key('friend_approval_sos_icon');
}

/// SCR-FAT-071 — موافقة طلب صديق (friend request approval).
///
/// Prototype FAT-071 · partner+ may approve · observer view-only ·
/// Rule 12/23 · P-4 SOS · empty → FAT-070.
class FriendApprovalScreen extends StatefulWidget {
  const FriendApprovalScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final FriendApprovalRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<FriendApprovalScreen> createState() => _FriendApprovalScreenState();
}

class _FriendApprovalScreenState extends State<FriendApprovalScreen> {
  late FriendApprovalRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  FriendApprovalSnapshot _snap = const FriendApprovalSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  bool get _canApprove {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1FriendApprovalRepository;
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
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _blockedToast(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.friendApprovalObserverBlocked);
  }

  String _friendName(AppLocalizations l10n) {
    return switch (_snap.nameKey) {
      'pendingFriend' => l10n.friendApprovalNamePending,
      _ => l10n.friendApprovalNamePending,
    };
  }

  String _school(AppLocalizations l10n) {
    return switch (_snap.schoolKey) {
      'classmateSchool' => l10n.friendApprovalSchoolClassmate,
      _ => l10n.friendApprovalSchoolClassmate,
    };
  }

  String _childName(AppLocalizations l10n) {
    return switch (_snap.childNameKey) {
      'childOne' => l10n.friendApprovalChildOne,
      'childTwo' => l10n.friendApprovalChildTwo,
      'childThree' => l10n.friendApprovalChildThree,
      _ => l10n.friendApprovalChildOne,
    };
  }

  Future<void> _setText(bool value) async {
    if (!_canApprove) {
      _blockedToast(AppLocalizations.of(context));
      return;
    }
    final snap = await _repo.setAllowText(value);
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  Future<void> _setCalls(bool value) async {
    if (!_canApprove) {
      _blockedToast(AppLocalizations.of(context));
      return;
    }
    final snap = await _repo.setAllowCalls(value);
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context);
    if (!_canApprove) {
      _blockedToast(l10n);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    await _repo.approve();
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(
      context,
      message: l10n.friendApprovalApprovedToast(
        _friendName(l10n),
        _childName(l10n),
      ),
    );
    _go('SCR-FAT-070');
  }

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context);
    if (!_canApprove) {
      _blockedToast(l10n);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    await _repo.declineGently();
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(
      context,
      message: l10n.friendApprovalDeclinedToast(
        _childName(l10n),
        _friendName(l10n),
      ),
    );
    _go('SCR-FAT-070');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: FriendApprovalKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.friendApprovalTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: FriendApprovalKeys.sosIconCta,
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
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: FriendApprovalKeys.childLean,
        title: l10n.friendApprovalChildLeanTitle,
        message: l10n.friendApprovalChildLeanMessage,
        actionLabel: l10n.friendApprovalSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: FriendApprovalKeys.loading,
        child: Semantics(
          label: l10n.friendApprovalLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: FriendApprovalKeys.empty,
        title: l10n.friendApprovalEmptyTitle,
        message: l10n.friendApprovalEmptyMessage,
        actionLabel: l10n.friendApprovalEmptyCta,
        onAction: () => _go('SCR-FAT-070'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final friend = _friendName(l10n);
    final child = _childName(l10n);

    return SingleChildScrollView(
      key: FriendApprovalKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: FriendApprovalKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.friendApprovalObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          DecoratedBox(
            key: FriendApprovalKeys.profileCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colors.mint,
                    child: Text(
                      friend.isNotEmpty ? friend.substring(0, 1) : '?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: colors.mintInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    friend,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.friendApprovalProfileSub(child, _school(l10n)),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: FriendApprovalKeys.channelsCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.friendApprovalChannelsHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ChannelRow(
                    emoji: '💬',
                    title: l10n.friendApprovalChannelText,
                    trailing: Switch.adaptive(
                      key: FriendApprovalKeys.textSwitch,
                      value: _snap.allowText,
                      onChanged: _canApprove ? _setText : null,
                      activeThumbColor: colors.mint,
                    ),
                  ),
                  _ChannelRow(
                    emoji: '📞',
                    title: l10n.friendApprovalChannelCalls,
                    trailing: Switch.adaptive(
                      key: FriendApprovalKeys.callsSwitch,
                      value: _snap.allowCalls,
                      onChanged: _canApprove ? _setCalls : null,
                      activeThumbColor: colors.mint,
                    ),
                  ),
                  _ChannelRow(
                    emoji: '🕓',
                    title: l10n.friendApprovalChannelSchedule,
                    subtitle: l10n.friendApprovalChannelScheduleSub,
                    trailing: Tag(
                      label: l10n.friendApprovalScheduleAutoTag,
                      variant: TagVariant.t,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_canApprove) ...[
            PrimaryBtn(
              key: FriendApprovalKeys.approveCta,
              label: l10n.friendApprovalApproveCta,
              variant: PrimaryBtnVariant.mint,
              onPressed: _busy ? null : _approve,
            ),
            const SizedBox(height: 8),
            PrimaryBtn(
              key: FriendApprovalKeys.declineCta,
              label: l10n.friendApprovalDeclineCta,
              variant: PrimaryBtnVariant.ghost,
              onPressed: _busy ? null : _decline,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.emoji,
    required this.title,
    required this.trailing,
    this.subtitle,
  });

  final String emoji;
  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Semantics(
      container: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
