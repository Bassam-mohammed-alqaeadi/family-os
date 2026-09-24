import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/child_media_share_models.dart';
import 'package:family_os/features/n02_day/child_media_share_repository.dart';

/// Widget keys for SCR-CHD-023 acceptance.
abstract final class ChildMediaShareKeys {
  static const screen = Key('child_media_share_screen');
  static const loading = Key('child_media_share_loading');
  static const empty = Key('child_media_share_empty');
  static const body = Key('child_media_share_body');
  static const hero = Key('child_media_share_hero');
  static const quickActions = Key('child_media_share_qact');
  static const recentList = Key('child_media_share_recent');
  static const safeCircleBanner = Key('child_media_share_safe_circle');
  static const parentLean = Key('child_media_share_parent_lean');
  static const sosIconCta = Key('child_media_share_sos_icon');

  static Key quickAction(String id) => Key('child_media_share_qact_$id');
  static Key row(String id) => Key('child_media_share_row_$id');
}

/// SCR-CHD-023 — مشاركة وسائط (child media share).
///
/// Prototype CHD-023 · RoleGuard child · photo/voice/file quick actions ·
/// recent shares + transcription note · family-circle banner · P-4 SOS ·
/// Rule 12/23 · minutes-only economy (no rewards on this screen).
class ChildMediaShareScreen extends StatefulWidget {
  const ChildMediaShareScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildMediaShareRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildMediaShareScreen> createState() => _ChildMediaShareScreenState();
}

class _ChildMediaShareScreenState extends State<ChildMediaShareScreen> {
  late ChildMediaShareRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildMediaShareSnapshot _snap = const ChildMediaShareSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildMediaShareRepository;
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

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _sharePhoto() {
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childMediaSharePhotoToast,
    );
  }

  void _shareVoice() {
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childMediaShareVoiceToast,
    );
  }

  void _shareFile() {
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childMediaShareFileToast,
    );
  }

  String _title(AppLocalizations l10n, String key) {
    return switch (key) {
      'photoGoal' => l10n.childMediaShareTitlePhotoGoal,
      'voiceShoes' => l10n.childMediaShareTitleVoiceShoes,
      _ => l10n.childMediaShareTitlePhotoGoal,
    };
  }

  String _subtitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'photoGoalSub' => l10n.childMediaShareSubPhotoGoal,
      'voiceShoesSub' => l10n.childMediaShareSubVoiceShoes,
      _ => l10n.childMediaShareSubPhotoGoal,
    };
  }

  IconData _typeIcon(ChildMediaShareType type) {
    return switch (type) {
      ChildMediaShareType.photo => Icons.photo_camera_outlined,
      ChildMediaShareType.voice => Icons.mic_outlined,
      ChildMediaShareType.file => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildMediaShareKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childMediaShareTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildMediaShareKeys.sosIconCta,
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
    );
  }

  Widget _buildBody(AppLocalizations l10n, FamilyColors colors) {
    if (!_isChild) {
      return AppEmptyState(
        key: ChildMediaShareKeys.parentLean,
        title: l10n.childMediaShareParentLeanTitle,
        message: l10n.childMediaShareParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildMediaShareKeys.loading,
        child: Semantics(
          label: l10n.childMediaShareLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildMediaShareKeys.empty,
        title: l10n.childMediaShareEmptyTitle,
        message: l10n.childMediaShareEmptyMessage,
        actionLabel: l10n.childMediaShareEmptyCta,
        onAction: () => _go('SCR-CHD-007'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildMediaShareKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ChildMediaShareKeys.hero,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors.teal, colors.teal600]),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Text(
                l10n.childMediaShareHeroHeadline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _QuickActionsRow(
            l10n: l10n,
            colors: colors,
            radii: radii,
            onPhoto: _sharePhoto,
            onVoice: _shareVoice,
            onFile: _shareFile,
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.childMediaShareRecentHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Column(
                    key: ChildMediaShareKeys.recentList,
                    children: [
                      for (final item in _snap.recentShares)
                        RowTile(
                          key: ChildMediaShareKeys.row(item.id),
                          leading: Icon(
                            _typeIcon(item.type),
                            size: 22,
                            color: colors.ink2,
                          ),
                          title: _title(l10n, item.titleKey),
                          subtitle: _subtitle(l10n, item.subtitleKey),
                          showDivider: item != _snap.recentShares.last,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          BannerNote(
            key: ChildMediaShareKeys.safeCircleBanner,
            variant: BannerVariant.t,
            message: l10n.childMediaShareSafeCircleBanner,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.l10n,
    required this.colors,
    required this.radii,
    required this.onPhoto,
    required this.onVoice,
    required this.onFile,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onPhoto;
  final VoidCallback onVoice;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ChildMediaShareKeys.quickActions,
      children: [
        Expanded(
          child: _QuickAction(
            actionKey: ChildMediaShareKeys.quickAction('photo'),
            colors: colors,
            radii: radii,
            icon: Icons.photo_camera_outlined,
            label: l10n.childMediaShareQuickPhoto,
            semanticsLabel: l10n.childMediaSharePhotoSemantics,
            onTap: onPhoto,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            actionKey: ChildMediaShareKeys.quickAction('voice'),
            colors: colors,
            radii: radii,
            icon: Icons.mic_outlined,
            label: l10n.childMediaShareQuickVoice,
            semanticsLabel: l10n.childMediaShareVoiceSemantics,
            onTap: onVoice,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            actionKey: ChildMediaShareKeys.quickAction('file'),
            colors: colors,
            radii: radii,
            icon: Icons.insert_drive_file_outlined,
            label: l10n.childMediaShareQuickFile,
            semanticsLabel: l10n.childMediaShareFileSemantics,
            onTap: onFile,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.actionKey,
    required this.colors,
    required this.radii,
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
  });

  final Key actionKey;
  final FamilyColors colors;
  final FamilyRadii radii;
  final IconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        child: InkWell(
          key: actionKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: colors.teal),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
