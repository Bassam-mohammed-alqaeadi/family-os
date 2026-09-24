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
import 'package:family_os/features/n02_day/child_arrival_models.dart';
import 'package:family_os/features/n02_day/child_arrival_repository.dart';

/// Widget keys for SCR-CHD-024 acceptance.
abstract final class ChildArrivalKeys {
  static const screen = Key('child_arrival_screen');
  static const loading = Key('child_arrival_loading');
  static const empty = Key('child_arrival_empty');
  static const body = Key('child_arrival_body');
  static const headline = Key('child_arrival_headline');
  static const zonesGrid = Key('child_arrival_zones');
  static const liveCard = Key('child_arrival_live');
  static const parentLean = Key('child_arrival_parent_lean');
  static const sosIconCta = Key('child_arrival_sos_icon');

  static Key zone(String id) => Key('child_arrival_zone_$id');
}

/// SCR-CHD-024 — أنا وصلت + موقعي (child arrival check-in).
///
/// Prototype CHD-024 · RoleGuard child · safe-zone one-tap reassure ·
/// live location status · check-in→004 · P-4 SOS · Rule 12/23.
class ChildArrivalScreen extends StatefulWidget {
  const ChildArrivalScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildArrivalRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildArrivalScreen> createState() => _ChildArrivalScreenState();
}

class _ChildArrivalScreenState extends State<ChildArrivalScreen> {
  late ChildArrivalRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  ChildArrivalSnapshot _snap = const ChildArrivalSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildArrivalRepository;
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

  String _zoneName(AppLocalizations l10n, String key) {
    return switch (key) {
      'school' => l10n.childArrivalZoneSchool,
      'home' => l10n.childArrivalZoneHome,
      _ => l10n.childArrivalZoneSchool,
    };
  }

  String _zoneDesc(AppLocalizations l10n, String key) {
    return switch (key) {
      'schoolDesc' => l10n.childArrivalZoneSchoolDesc,
      'homeDesc' => l10n.childArrivalZoneHomeDesc,
      _ => l10n.childArrivalZoneSchoolDesc,
    };
  }

  IconData _zoneIcon(String key) {
    return switch (key) {
      'home' => Icons.home_rounded,
      _ => Icons.school_rounded,
    };
  }

  Future<void> _checkIn(ChildArrivalZone zone) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    await _repo.checkIn(zone.id);
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(
      context,
      message: l10n.childArrivalCheckInToast(_zoneName(l10n, zone.nameKey)),
    );
    _go('SCR-CHD-004');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildArrivalKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childArrivalTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildArrivalKeys.sosIconCta,
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
        key: ChildArrivalKeys.parentLean,
        title: l10n.childArrivalParentLeanTitle,
        message: l10n.childArrivalParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildArrivalKeys.loading,
        child: Semantics(
          label: l10n.childArrivalLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildArrivalKeys.empty,
        title: l10n.childArrivalEmptyTitle,
        message: l10n.childArrivalEmptyMessage,
        actionLabel: l10n.childArrivalEmptyCta,
        onAction: () => _go('SCR-CHD-004'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildArrivalKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.volunteer_activism, size: 42, color: colors.teal600),
          const SizedBox(height: 8),
          Text(
            key: ChildArrivalKeys.headline,
            l10n.childArrivalHeadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.childArrivalSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            key: ChildArrivalKeys.zonesGrid,
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: [
              for (final z in _snap.zones)
                Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(radii.card),
                  child: InkWell(
                    key: ChildArrivalKeys.zone(z.id),
                    borderRadius: BorderRadius.circular(radii.card),
                    onTap: _busy ? null : () => _checkIn(z),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radii.card),
                        border: Border.all(color: colors.teal, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _zoneIcon(z.iconKey),
                              size: 28,
                              color: colors.teal600,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.childArrivalZoneCta(
                                _zoneName(l10n, z.nameKey),
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                              ),
                            ),
                            Text(
                              _zoneDesc(l10n, z.descKey),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          BannerNote(
            key: ChildArrivalKeys.liveCard,
            variant: BannerVariant.t,
            message: l10n.childArrivalSilentBanner,
          ),
        ],
      ),
    );
  }
}
