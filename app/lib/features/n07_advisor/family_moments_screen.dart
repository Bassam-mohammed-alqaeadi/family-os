import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n07_advisor/family_moments_models.dart';
import 'package:family_os/features/n07_advisor/family_moments_repository.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

abstract final class FamilyMomentsKeys {
  static const screen = Key('family_moments_screen');
  static const loading = Key('family_moments_loading');
  static const empty = Key('family_moments_empty');
  static const body = Key('family_moments_body');
  static const hero = Key('family_moments_hero');
  static const stars = Key('family_moments_stars');
  static const shareCta = Key('family_moments_share');
  static const touchCta = Key('family_moments_touch');
  static const album = Key('family_moments_album');
  static const addMomentCta = Key('family_moments_add');
  static const childLean = Key('family_moments_child_lean');
  static const sosIconCta = Key('family_moments_sos_icon');
}

/// SCR-FAT-086 — لحظات عائلتنا (weekly pride · album · touch).
class FamilyMomentsScreen extends StatefulWidget {
  const FamilyMomentsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final FamilyMomentsRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<FamilyMomentsScreen> createState() => _FamilyMomentsScreenState();
}

class _FamilyMomentsScreenState extends State<FamilyMomentsScreen> {
  late FamilyMomentsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  FamilyMomentsSnapshot _snap = const FamilyMomentsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;
  bool get _canAct {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel != MotherLevel.observer;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1ReportsRuntime.familyMoments;
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

  Future<void> _sharePride() async {
    if (!_canAct) return;
    final snap = await _repo.sharePrideCard();
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.familyMomentsPrideToast);
  }

  Future<void> _remindTouch() async {
    if (!_canAct) return;
    final snap = await _repo.remindTouch();
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.familyMomentsTouchToast);
  }

  Future<void> _addMoment() async {
    if (!_canAct) return;
    final snap = await _repo.addMoment();
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.familyMomentsAddToast);
  }

  String _child(AppLocalizations l10n, String key) => switch (key) {
    'childTwo' => l10n.familyMomentsChildTwo,
    _ => l10n.familyMomentsChildOne,
  };

  String _starTitle(AppLocalizations l10n, FamilyMomentStar s) {
    final child = _child(l10n, s.childLabelKey);
    return switch (s.titleKey) {
      'starQuran' => l10n.familyMomentsStarQuran(child),
      'starMath' => l10n.familyMomentsStarMath(child),
      'starSleep' => l10n.familyMomentsStarSleep(child),
      _ => s.titleKey,
    };
  }

  String _starSub(AppLocalizations l10n, String key) => switch (key) {
    'starQuranSub' => l10n.familyMomentsStarQuranSub,
    'starMathSub' => l10n.familyMomentsStarMathSub,
    'starSleepSub' => l10n.familyMomentsStarSleepSub,
    _ => key,
  };

  String _cap(AppLocalizations l10n, String key) => switch (key) {
    'capGarden' => l10n.familyMomentsCapGarden,
    'capPrayer' => l10n.familyMomentsCapPrayer,
    'capCook' => l10n.familyMomentsCapCook,
    'capRead' => l10n.familyMomentsCapRead,
    'capWalk' => l10n.familyMomentsCapWalk,
    'capLaugh' => l10n.familyMomentsCapLaugh,
    'capNew' => l10n.familyMomentsCapNew,
    _ => key,
  };

  String _by(AppLocalizations l10n, String key) => switch (key) {
    'byMother' => l10n.familyMomentsByMother,
    'byFather' => l10n.familyMomentsByFather,
    'byChildOne' => l10n.familyMomentsChildOne,
    'byChildTwo' => l10n.familyMomentsChildTwo,
    _ => key,
  };

  String _when(AppLocalizations l10n, String key) => switch (key) {
    'whenYesterday' => l10n.familyMomentsWhenYesterday,
    'whenTue' => l10n.familyMomentsWhenTue,
    'whenMon' => l10n.familyMomentsWhenMon,
    'whenSun' => l10n.familyMomentsWhenSun,
    'whenSat' => l10n.familyMomentsWhenSat,
    'whenFri' => l10n.familyMomentsWhenFri,
    'whenNow' => l10n.familyMomentsWhenNow,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: FamilyMomentsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.familyMomentsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: FamilyMomentsKeys.sosIconCta,
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
    if (_isChild) {
      return AppEmptyState(
        key: FamilyMomentsKeys.childLean,
        title: l10n.familyMomentsChildLeanTitle,
        message: l10n.familyMomentsChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: FamilyMomentsKeys.loading,
        child: Semantics(
          label: l10n.familyMomentsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: FamilyMomentsKeys.empty,
        title: l10n.familyMomentsEmptyTitle,
        message: l10n.familyMomentsEmptyMessage,
        actionLabel: l10n.familyMomentsEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: FamilyMomentsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(l10n, colors, radii),
          const SizedBox(height: 12),
          _starsCard(l10n, colors, radii),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: FamilyMomentsKeys.shareCta,
            label: l10n.familyMomentsShareCta,
            onPressed: _canAct ? _sharePride : null,
          ),
          const SizedBox(height: 12),
          _touchCard(l10n, colors, radii),
          const SizedBox(height: 12),
          _albumCard(l10n, colors, radii),
          const SizedBox(height: 12),
          BannerNote(
            message: l10n.familyMomentsFridayBanner,
            variant: BannerVariant.t,
          ),
        ],
      ),
    );
  }

  Widget _hero(AppLocalizations l10n, FamilyColors colors, FamilyRadii radii) {
    return Container(
      key: FamilyMomentsKeys.hero,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.teal, colors.teal.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radii.card),
      ),
      child: Column(
        children: [
          Text(
            l10n.familyMomentsWeekLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          Text(
            l10n.familyMomentsHeroTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(l10n.familyMomentsStatLearn, '${_snap.learnHours}'),
              _stat(l10n.familyMomentsStatVerses, '${_snap.versesMemorized}'),
              _stat(l10n.familyMomentsStatTasks, '${_snap.tasksDone}'),
              _stat(l10n.familyMomentsStatAlerts, '${_snap.worryAlerts}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _starsCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FamilyRadii radii,
  ) {
    return Container(
      key: FamilyMomentsKeys.stars,
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
            l10n.familyMomentsStarsTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          for (final s in _snap.stars) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.teal.withValues(alpha: 0.15),
                    child: Text(
                      String.fromCharCode(
                        _child(l10n, s.childLabelKey).runes.first,
                      ),
                      style: TextStyle(
                        color: colors.teal,
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
                          _starTitle(l10n, s),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _starSub(l10n, s.subKey),
                          style: TextStyle(color: colors.ink2, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Text(s.emoji, style: const TextStyle(fontSize: 22)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _touchCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FamilyRadii radii,
  ) {
    return Container(
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
            l10n.familyMomentsTouchTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.familyMomentsTouchBody,
            style: TextStyle(color: colors.ink2, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: FamilyMomentsKeys.touchCta,
            onPressed: _canAct ? _remindTouch : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: colors.teal,
              side: BorderSide(color: colors.teal),
            ),
            child: Text(l10n.familyMomentsTouchCta),
          ),
        ],
      ),
    );
  }

  Widget _albumCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FamilyRadii radii,
  ) {
    return Container(
      key: FamilyMomentsKeys.album,
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
            l10n.familyMomentsAlbumTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              for (final item in _snap.album)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        _cap(l10n, item.captionKey),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colors.ink,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_by(l10n, item.byKey)} · ${_when(l10n, item.whenKey)}',
                        style: TextStyle(fontSize: 8.5, color: colors.ink2),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: FamilyMomentsKeys.addMomentCta,
            onPressed: _canAct ? _addMoment : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: colors.teal,
              side: BorderSide(color: colors.teal),
            ),
            child: Text(l10n.familyMomentsAddCta),
          ),
        ],
      ),
    );
  }
}
