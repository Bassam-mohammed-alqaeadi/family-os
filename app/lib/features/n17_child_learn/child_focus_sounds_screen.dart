import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_models.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_repository.dart';

abstract final class ChildFocusSoundsKeys {
  static const screen = Key('child_focus_sounds_screen');
  static const loading = Key('child_focus_sounds_loading');
  static const empty = Key('child_focus_sounds_empty');
  static const body = Key('child_focus_sounds_body');
  static const grid = Key('child_focus_sounds_grid');
  static const autoToggle = Key('child_focus_sounds_auto');
  static const fadeToggle = Key('child_focus_sounds_fade');
  static const startFocusCta = Key('child_focus_sounds_start_focus');
  static const parentLean = Key('child_focus_sounds_parent_lean');
  static const sosIconCta = Key('child_focus_sounds_sos_icon');

  static Key sound(String id) => Key('child_focus_sounds_$id');
}

/// SCR-CHD-035 — أصوات التركيز (nature loops · → CHD-018).
class ChildFocusSoundsScreen extends StatefulWidget {
  const ChildFocusSoundsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildFocusSoundsRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildFocusSoundsScreen> createState() => _ChildFocusSoundsScreenState();
}

class _ChildFocusSoundsScreenState extends State<ChildFocusSoundsScreen> {
  late ChildFocusSoundsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildFocusSoundsSnapshot _snap = const ChildFocusSoundsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildFocusSoundsRepository;
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

  Future<void> _play(FocusSoundOption sound) async {
    final snap = await _repo.playSound(sound.id);
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: _toast(l10n, sound.toastKey));
  }

  Future<void> _toggleAuto(bool v) async {
    final snap = await _repo.setAutoWithFocus(v);
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  Future<void> _toggleFade(bool v) async {
    final snap = await _repo.setFadeLastTwo(v);
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  String _label(AppLocalizations l10n, String key) => switch (key) {
    'rain' => l10n.childFocusSoundsRain,
    'waves' => l10n.childFocusSoundsWaves,
    'forest' => l10n.childFocusSoundsForest,
    'fire' => l10n.childFocusSoundsFire,
    _ => key,
  };

  String _toast(AppLocalizations l10n, String key) => switch (key) {
    'toastRain' => l10n.childFocusSoundsToastRain,
    'toastWaves' => l10n.childFocusSoundsToastWaves,
    'toastForest' => l10n.childFocusSoundsToastForest,
    'toastFire' => l10n.childFocusSoundsToastFire,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildFocusSoundsKeys.screen,
      backgroundColor: colors.childBg,
      appBar: AppBar(
        backgroundColor: colors.childBg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childFocusSoundsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildFocusSoundsKeys.sosIconCta,
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
        key: ChildFocusSoundsKeys.parentLean,
        title: l10n.childFocusSoundsParentLeanTitle,
        message: l10n.childFocusSoundsParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildFocusSoundsKeys.loading,
        child: Semantics(
          label: l10n.childFocusSoundsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildFocusSoundsKeys.empty,
        title: l10n.childFocusSoundsEmptyTitle,
        message: l10n.childFocusSoundsEmptyMessage,
        actionLabel: l10n.childFocusSoundsEmptyCta,
        onAction: () => _go('SCR-CHD-018'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildFocusSoundsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            key: ChildFocusSoundsKeys.grid,
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              for (final s in _snap.sounds)
                OutlinedButton(
                  key: ChildFocusSoundsKeys.sound(s.id),
                  onPressed: () => _play(s),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 84),
                    foregroundColor: colors.teal,
                    side: BorderSide(
                      color: _snap.activeSoundId == s.id
                          ? colors.teal
                          : colors.border,
                      width: _snap.activeSoundId == s.id ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        _label(l10n, s.labelKey),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childFocusSoundsWithFocusTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                SwitchListTile(
                  key: ChildFocusSoundsKeys.autoToggle,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.childFocusSoundsAutoTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    l10n.childFocusSoundsAutoSub,
                    style: TextStyle(color: colors.ink2, fontSize: 11.5),
                  ),
                  value: _snap.autoWithFocus,
                  activeThumbColor: colors.teal,
                  onChanged: _toggleAuto,
                ),
                SwitchListTile(
                  key: ChildFocusSoundsKeys.fadeToggle,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.childFocusSoundsFadeTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    l10n.childFocusSoundsFadeSub,
                    style: TextStyle(color: colors.ink2, fontSize: 11.5),
                  ),
                  value: _snap.fadeLastTwoMinutes,
                  activeThumbColor: colors.teal,
                  onChanged: _toggleFade,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: ChildFocusSoundsKeys.startFocusCta,
            label: l10n.childFocusSoundsStartCta,
            onPressed: () => _go('SCR-CHD-018'),
          ),
          const SizedBox(height: 12),
          BannerNote(
            message: l10n.childFocusSoundsBanner,
            variant: BannerVariant.t,
          ),
        ],
      ),
    );
  }
}
