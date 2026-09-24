import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/child_stickers_backgrounds_models.dart';
import 'package:family_os/features/n02_day/child_stickers_backgrounds_repository.dart';

abstract final class ChildStickersBackgroundsKeys {
  static const screen = Key('child_stickers_backgrounds_screen');
  static const loading = Key('child_stickers_backgrounds_loading');
  static const empty = Key('child_stickers_backgrounds_empty');
  static const body = Key('child_stickers_backgrounds_body');
  static const stickers = Key('child_stickers_backgrounds_stickers');
  static const unlockCta = Key('child_stickers_backgrounds_unlock');
  static const backgrounds = Key('child_stickers_backgrounds_bgs');
  static const parentLean = Key('child_stickers_backgrounds_parent_lean');
  static const sosIconCta = Key('child_stickers_backgrounds_sos_icon');

  static Key background(String id) => Key('child_stickers_backgrounds_bg_$id');
}

/// SCR-CHD-037 — ملصقاتي وخلفياتي (modest pack · chat wallpaper).
class ChildStickersBackgroundsScreen extends StatefulWidget {
  const ChildStickersBackgroundsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildStickersBackgroundsRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildStickersBackgroundsScreen> createState() =>
      _ChildStickersBackgroundsScreenState();
}

class _ChildStickersBackgroundsScreenState
    extends State<ChildStickersBackgroundsScreen> {
  late ChildStickersBackgroundsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildStickersBackgroundsSnapshot _snap =
      const ChildStickersBackgroundsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildStickersBackgroundsRepository;
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

  void _go(String id) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(id);
      return;
    }
    context.push(screenPath(id));
  }

  Future<void> _selectBg(String id) async {
    final snap = await _repo.selectBackground(id);
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childStickersBackgroundsBgToast);
  }

  Future<void> _remindUnlock() async {
    await _repo.remindSpaceUnlock();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      message: l10n.childStickersBackgroundsUnlockToast(_snap.wardsRemaining),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildStickersBackgroundsKeys.screen,
      backgroundColor: colors.childBg,
      appBar: AppBar(
        backgroundColor: colors.childBg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childStickersBackgroundsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildStickersBackgroundsKeys.sosIconCta,
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
        key: ChildStickersBackgroundsKeys.parentLean,
        title: l10n.childStickersBackgroundsParentLeanTitle,
        message: l10n.childStickersBackgroundsParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildStickersBackgroundsKeys.loading,
        child: Semantics(
          label: l10n.childStickersBackgroundsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildStickersBackgroundsKeys.empty,
        title: l10n.childStickersBackgroundsEmptyTitle,
        message: l10n.childStickersBackgroundsEmptyMessage,
        actionLabel: l10n.childStickersBackgroundsEmptyCta,
        onAction: () => _go('SCR-CHD-007'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildStickersBackgroundsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: ChildStickersBackgroundsKeys.stickers,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.childStickersBackgroundsStickersTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final s in _snap.stickers)
                      Opacity(
                        opacity: s.locked ? 0.35 : 1,
                        child: Text(
                          s.emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.childStickersBackgroundsSpaceHint,
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: ChildStickersBackgroundsKeys.unlockCta,
                  onPressed: _remindUnlock,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: colors.teal,
                  ),
                  child: Text(l10n.childStickersBackgroundsUnlockCta),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: ChildStickersBackgroundsKeys.backgrounds,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.childStickersBackgroundsBgTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final bg in _snap.backgrounds) ...[
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: l10n.childStickersBackgroundsBgSemantics(
                            bg.id,
                          ),
                          child: InkWell(
                            key: ChildStickersBackgroundsKeys.background(bg.id),
                            onTap: () => _selectBg(bg.id),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 70,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(bg.colorA), Color(bg.colorB)],
                                ),
                                border: _snap.selectedBackgroundId == bg.id
                                    ? Border.all(color: colors.teal, width: 3)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BannerNote(
            message: l10n.childStickersBackgroundsBanner,
            variant: BannerVariant.t,
          ),
        ],
      ),
    );
  }
}
