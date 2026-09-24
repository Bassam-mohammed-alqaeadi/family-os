import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/road_safety_models.dart';
import 'package:family_os/features/n02_day/road_safety_repository.dart';

abstract final class RoadSafetyKeys {
  static const screen = Key('road_safety_screen');
  static const loading = Key('road_safety_loading');
  static const empty = Key('road_safety_empty');
  static const body = Key('road_safety_body');
  static const honesty = Key('road_safety_honesty');
  static const crashSwitch = Key('road_safety_crash_swt');
  static const phoneSwitch = Key('road_safety_phone_swt');
  static const tripCard = Key('road_safety_trip');
  static const dialogue = Key('road_safety_dialogue');
  static const observerHint = Key('road_safety_observer');
  static const childLean = Key('road_safety_child_lean');
  static const sosIconCta = Key('road_safety_sos_icon');
}

/// SCR-FAT-077 — السلامة على الطريق.
class RoadSafetyScreen extends StatefulWidget {
  const RoadSafetyScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final RoadSafetyRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<RoadSafetyScreen> createState() => _RoadSafetyScreenState();
}

class _RoadSafetyScreenState extends State<RoadSafetyScreen> {
  late RoadSafetyRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  RoadSafetySnapshot _snap = const RoadSafetySnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;
  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;
  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;
  bool get _canEdit {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1RoadSafetyRepository;
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

  void _go(String id) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(id);
      return;
    }
    context.push(screenPath(id));
  }

  void _blocked(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.roadSafetyObserverBlocked);
  }

  Future<void> _setCrash(bool v) async {
    if (!_canEdit) {
      _blocked(AppLocalizations.of(context));
      return;
    }
    final snap = await _repo.setCrashDetection(v);
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  Future<void> _setPhone(bool v) async {
    if (!_canEdit) {
      _blocked(AppLocalizations.of(context));
      return;
    }
    final snap = await _repo.setPhoneWhileDriving(v);
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: RoadSafetyKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.roadSafetyTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: RoadSafetyKeys.sosIconCta,
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
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: RoadSafetyKeys.childLean,
        title: l10n.roadSafetyChildLeanTitle,
        message: l10n.roadSafetyChildLeanMessage,
        actionLabel: l10n.roadSafetySosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }
    if (_loading) {
      return Center(
        key: RoadSafetyKeys.loading,
        child: Semantics(
          label: l10n.roadSafetyLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: RoadSafetyKeys.empty,
        title: l10n.roadSafetyEmptyTitle,
        message: l10n.roadSafetyEmptyMessage,
        actionLabel: l10n.roadSafetyEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: RoadSafetyKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: RoadSafetyKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.roadSafetyObserverHint,
            ),
            const SizedBox(height: 10),
          ],
          BannerNote(
            key: RoadSafetyKeys.honesty,
            variant: BannerVariant.t,
            message: l10n.roadSafetyHonestyBanner,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: colors.mint),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      child: Column(
                        children: [
                          _ToggleRow(
                            emoji: '🛡',
                            title: l10n.roadSafetyCrashTitle,
                            sub: l10n.roadSafetyCrashSub,
                            value: _snap.crashDetection,
                            swKey: RoadSafetyKeys.crashSwitch,
                            enabled: _canEdit,
                            onChanged: _setCrash,
                            colors: colors,
                          ),
                          _ToggleRow(
                            emoji: '📊',
                            title: l10n.roadSafetyReportTitle,
                            sub: l10n.roadSafetyReportSub,
                            value: true,
                            swKey: const Key('road_safety_report_tag'),
                            enabled: false,
                            onChanged: null,
                            colors: colors,
                            trailing: Tag(
                              label: l10n.roadSafetyWeeklyTag,
                              variant: TagVariant.t,
                            ),
                          ),
                          _ToggleRow(
                            emoji: '📵',
                            title: l10n.roadSafetyPhoneTitle,
                            sub: l10n.roadSafetyPhoneSub,
                            value: _snap.phoneWhileDriving,
                            swKey: RoadSafetyKeys.phoneSwitch,
                            enabled: _canEdit,
                            onChanged: _setPhone,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: RoadSafetyKeys.tripCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.roadSafetyTripHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: l10n.roadSafetyStatSpeed,
                          value: l10n.roadSafetyStatSpeedValue(
                            _snap.topSpeedKmh,
                          ),
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(
                          label: l10n.roadSafetyStatBrakes,
                          value: l10n.roadSafetyStatBrakesValue(
                            _snap.hardBrakes,
                          ),
                          colors: colors,
                          warn: _snap.hardBrakes > 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(
                          label: l10n.roadSafetyStatPhone,
                          value: _snap.phoneTouches == 0
                              ? l10n.roadSafetyStatPhoneZero
                              : '${_snap.phoneTouches}',
                          colors: colors,
                          good: _snap.phoneTouches == 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    key: RoadSafetyKeys.dialogue,
                    l10n.roadSafetyDialogueStep,
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
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.value,
    required this.swKey,
    required this.enabled,
    required this.onChanged,
    required this.colors,
    this.trailing,
  });

  final String emoji;
  final String title;
  final String sub;
  final bool value;
  final Key swKey;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final FamilyColors colors;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Switch.adaptive(
              key: swKey,
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: colors.mint,
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.colors,
    this.warn = false,
    this.good = false,
  });

  final String label;
  final String value;
  final FamilyColors colors;
  final bool warn;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: warn
                    ? colors.amberInk
                    : good
                    ? colors.teal600
                    : colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
