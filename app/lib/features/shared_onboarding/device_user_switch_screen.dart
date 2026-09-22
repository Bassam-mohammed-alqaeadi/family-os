import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/device_user_switch_repository.dart';

/// Widget keys for SCR-SHR-008 acceptance.
abstract final class DeviceUserSwitchKeys {
  static const screen = Key('device_user_switch_screen');
  static const title = Key('device_user_switch_title');
  static const loading = Key('device_user_switch_loading');
  static const empty = Key('device_user_switch_empty');
  static const error = Key('device_user_switch_error');
  static const list = Key('device_user_switch_list');
  static const addAccount = Key('device_user_switch_add');
  static const childLean = Key('device_user_switch_child_lean');
  static const confirmDialog = Key('device_user_switch_confirm');
  static const confirmPassword = Key('device_user_switch_password');
  static const confirmSubmit = Key('device_user_switch_confirm_submit');
  static const confirmCancel = Key('device_user_switch_confirm_cancel');

  static Key row(String id) => Key('device_user_switch_row_$id');
}

/// SCR-SHR-008 — تبديل المستخدم على الجهاز.
///
/// Prototype SHR-008 · shared device father↔mother · mock local profiles only
/// (no account-switch backend). Password confirm when leaving the active
/// profile. Add-account toast honesty. RoleGuard lean for child. Rule 12/23.
class DeviceUserSwitchScreen extends StatefulWidget {
  const DeviceUserSwitchScreen({
    super.key,
    this.repository,
    this.roleOverride,
    this.onSwitched,
    this.onAddAccount,
  });

  /// Null → [stage1DeviceUserSwitchRepository].
  final DeviceUserSwitchRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Test seam — after successful switch (role already updated).
  final void Function(DeviceUserProfile profile)? onSwitched;

  /// Test seam — add account CTA.
  final VoidCallback? onAddAccount;

  @override
  State<DeviceUserSwitchScreen> createState() => DeviceUserSwitchScreenState();
}

class DeviceUserSwitchScreenState extends State<DeviceUserSwitchScreen> {
  late final DeviceUserSwitchRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  List<DeviceUserProfile> _profiles = const [];

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1DeviceUserSwitchRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant DeviceUserSwitchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1DeviceUserSwitchRepository;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final profiles = await _repo.listProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _profiles = const [];
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Color _avatarColor(FamilyColors colors, DeviceUserProfile p) {
    final hex = p.avatarColorHex;
    if (hex != null && hex.length >= 7) {
      final parsed = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
      if (parsed != null) return Color(0xFF000000 | parsed);
    }
    return switch (p.role) {
      AppRole.father => colors.p500,
      AppRole.mother => colors.coral,
      AppRole.child => colors.sky,
    };
  }

  String _roleSubtitle(AppLocalizations l10n, DeviceUserProfile p) {
    return switch (p.role) {
      AppRole.father => l10n.deviceUserSwitchRoleOwner,
      AppRole.mother => _motherSubtitle(l10n, p.motherLevel),
      AppRole.child => l10n.deviceUserSwitchRoleChild,
    };
  }

  String _motherSubtitle(AppLocalizations l10n, MotherLevel? level) {
    final base = l10n.deviceUserSwitchRoleMother;
    if (level == null) return base;
    final levelLabel = switch (level) {
      MotherLevel.observer => l10n.inviteMotherLevelObserverTitle,
      MotherLevel.partner => l10n.inviteMotherLevelPartnerTitle,
      MotherLevel.full => l10n.inviteMotherLevelFullTitle,
    };
    return l10n.deviceUserSwitchRoleMotherWithLevel(levelLabel);
  }

  String _rowTitle(AppLocalizations l10n, DeviceUserProfile p, bool active) {
    if (active) return l10n.deviceUserSwitchSelfName(p.displayName);
    return p.displayName;
  }

  Future<void> _onProfileTap(DeviceUserProfile profile) async {
    if (!_isParent) return;
    final active = profile.role == _role;
    if (active) return;

    final confirmed = await _confirmSwitch(profile);
    if (!confirmed || !mounted) return;

    _applySwitch(profile);
  }

  Future<bool> _confirmSwitch(DeviceUserProfile profile) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _SwitchConfirmDialog(
          profileName: profile.displayName,
          l10n: l10n,
        );
      },
    );
    return result ?? false;
  }

  void _applySwitch(DeviceUserProfile profile) {
    final notifier = CurrentRole.maybeNotifierOf(context);
    if (notifier != null) {
      notifier.value = profile.role;
    }

    if (widget.onSwitched != null) {
      widget.onSwitched!(profile);
      return;
    }

    context.go('/scr-fat-010');
  }

  void _onAddAccount() {
    if (widget.onAddAccount != null) {
      widget.onAddAccount!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.deviceUserSwitchAddAccountToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: DeviceUserSwitchKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          key: DeviceUserSwitchKeys.title,
          l10n.deviceUserSwitchTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
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
        key: DeviceUserSwitchKeys.childLean,
        title: l10n.deviceUserSwitchChildLeanTitle,
        message: l10n.deviceUserSwitchChildLeanMessage,
      );
    }

    if (_loading) {
      return const Center(
        key: DeviceUserSwitchKeys.loading,
        child: CircularProgressIndicator(),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: DeviceUserSwitchKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    if (_profiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AppEmptyState(
                key: DeviceUserSwitchKeys.empty,
                title: l10n.deviceUserSwitchEmptyTitle,
                message: l10n.deviceUserSwitchEmptyMessage,
              ),
            ),
            PrimaryBtn(
              key: DeviceUserSwitchKeys.addAccount,
              label: l10n.deviceUserSwitchAddAccountCta,
              variant: PrimaryBtnVariant.sec,
              onPressed: _onAddAccount,
            ),
          ],
        ),
      );
    }

    return ListView(
      key: DeviceUserSwitchKeys.list,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(
              Theme.of(context).extension<FamilyRadii>()!.card,
            ),
            border: Border.all(color: colors.border),
            boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < _profiles.length; i++) ...[
                  _ProfileRow(
                    profile: _profiles[i],
                    active: _profiles[i].role == _role,
                    title: _rowTitle(
                      l10n,
                      _profiles[i],
                      _profiles[i].role == _role,
                    ),
                    subtitle: _roleSubtitle(l10n, _profiles[i]),
                    avatarColor: _avatarColor(colors, _profiles[i]),
                    activeLabel: l10n.deviceUserSwitchActiveTag,
                    enterLabel: l10n.deviceUserSwitchEnterHint,
                    onTap: () => _onProfileTap(_profiles[i]),
                  ),
                  if (i < _profiles.length - 1)
                    Divider(height: 1, color: colors.border),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryBtn(
          key: DeviceUserSwitchKeys.addAccount,
          label: l10n.deviceUserSwitchAddAccountCta,
          variant: PrimaryBtnVariant.sec,
          onPressed: _onAddAccount,
        ),
      ],
    );
  }
}

class _SwitchConfirmDialog extends StatefulWidget {
  const _SwitchConfirmDialog({
    required this.profileName,
    required this.l10n,
  });

  final String profileName;
  final AppLocalizations l10n;

  @override
  State<_SwitchConfirmDialog> createState() => _SwitchConfirmDialogState();
}

class _SwitchConfirmDialogState extends State<_SwitchConfirmDialog> {
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.trim().isEmpty) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      key: DeviceUserSwitchKeys.confirmDialog,
      title: Text(l10n.deviceUserSwitchConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deviceUserSwitchConfirmBody(widget.profileName),
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            key: DeviceUserSwitchKeys.confirmPassword,
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.deviceUserSwitchPasswordLabel,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: DeviceUserSwitchKeys.confirmCancel,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.deviceUserSwitchConfirmCancel),
        ),
        TextButton(
          key: DeviceUserSwitchKeys.confirmSubmit,
          onPressed: _submit,
          child: Text(l10n.deviceUserSwitchConfirmSubmit),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.profile,
    required this.active,
    required this.title,
    required this.subtitle,
    required this.avatarColor,
    required this.activeLabel,
    required this.enterLabel,
    required this.onTap,
  });

  final DeviceUserProfile profile;
  final bool active;
  final String title;
  final String subtitle;
  final Color avatarColor;
  final String activeLabel;
  final String enterLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return RowTile(
      key: DeviceUserSwitchKeys.row(profile.id),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: avatarColor,
        child: Text(
          profile.monogram,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.surface,
          ),
        ),
      ),
      title: title,
      subtitle: subtitle,
      trailing: active
          ? Tag(label: activeLabel, variant: TagVariant.p)
          : Text(
              enterLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
      onTap: active ? null : onTap,
      showDivider: false,
    );
  }
}
