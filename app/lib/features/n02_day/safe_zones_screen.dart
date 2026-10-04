import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/active_child_resolver.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';

/// Widget keys for SCR-FAT-016 acceptance.
abstract final class SafeZonesKeys {
  static const screen = Key('safe_zones_screen');
  static const loading = Key('safe_zones_loading');
  static const empty = Key('safe_zones_empty');
  static const error = Key('safe_zones_error');
  static const body = Key('safe_zones_body');
  static const honestyBanner = Key('safe_zones_honesty');
  static const gpsBanner = Key('safe_zones_gps_banner');
  static const readOnlyBanner = Key('safe_zones_readonly');
  static const section = Key('safe_zones_section');
  static const addHeaderCta = Key('safe_zones_add_header');
  static const drawCta = Key('safe_zones_draw');
  static const appliesNote = Key('safe_zones_applies');
  static const sosCta = Key('safe_zones_sos');
  static const childLean = Key('safe_zones_child_lean');

  static Key zone(String id) => Key('safe_zones_zone_$id');

  /// Legacy master switch key — kept for older tests; prefer flag keys.
  static Key zoneSwitch(String id) => Key('safe_zones_switch_$id');
  static Key zoneArrive(String id) => Key('safe_zones_arrive_$id');
  static Key zoneLeave(String id) => Key('safe_zones_leave_$id');
  static Key zoneNoShow(String id) => Key('safe_zones_noshow_$id');
  static Key zoneNoShowDeadline(String id) =>
      Key('safe_zones_noshow_deadline_$id');
}

/// SCR-FAT-016 — المناطق الآمنة (parent family safe-zones list).
///
/// Mock-first list opened from FAT-014 CTA. Family-level zones with
/// arrival/departure alert toggles + create → FAT-017. Optional parametric
/// [childId] forwarded for draw context. Mother needs [MotherLevel.full] to
/// edit (prototype `can('zones')`); lower levels see read-only banner.
/// Life360 honesty. P-4 SOS ungated. RoleGuard lean for child. No Firebase.
class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({
    super.key,
    this.childId,
    this.repository,
    this.roleOverride,
    this.motherLevel,
    this.canEditOverride,
    this.sosFire,
    this.onSos,
    this.onCreateZone,
  });

  /// Optional route `?childId=` — forwarded to FAT-017; list is family-wide.
  final String? childId;

  /// Null → FS-001 Domain via [Stage1LocationRuntime] (Slice 01 AUTH-FS001).
  /// Inject [repository] in tests to keep Stage-1 InMemory.
  final SafeZonesRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother permission level (ADR-035). Null → Identity [resolveAuthorizationContext].
  final MotherLevel? motherLevel;

  /// Test seam — when set, overrides role/level edit gate.
  final bool? canEditOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — SOS fire / navigate.
  final VoidCallback? onSos;

  /// Test seam — create / draw → FAT-017.
  final VoidCallback? onCreateZone;

  @override
  SafeZonesScreenState createState() => SafeZonesScreenState();
}

class SafeZonesScreenState extends State<SafeZonesScreen> {
  SafeZonesRepository? _repo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  SafeZonesSnapshot? _snapshot;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  MotherLevel get _motherLevel =>
      widget.motherLevel ??
      resolveAuthorizationContext(context, fallbackRole: _role).motherLevel;

  /// Father always; mother only at [MotherLevel.full] (prototype zones≥full).
  bool get _canEdit {
    if (widget.canEditOverride != null) return widget.canEditOverride!;
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return _motherLevel == MotherLevel.full;
    }
    return false;
  }

  String? get _resolvedChildId {
    final raw = widget.childId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  IdentityRuntime? _identity;
  FamilyId? _boundFamily;

  /// Family whose zones are listed — the active family (follows switches).
  FamilyId get familyId => resolveActiveFamilyIdOf(context);

  @override
  void initState() {
    super.initState();
    _identity = CurrentIdentity.maybeOf(context);
    _boundFamily = _identity?.activeFamilyId;
    _identity?.addListener(_onIdentityChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapAndLoad();
    });
  }

  @override
  void dispose() {
    _identity?.removeListener(_onIdentityChanged);
    super.dispose();
  }

  void _onIdentityChanged() {
    final next = _identity?.activeFamilyId;
    if (next == _boundFamily) return;
    _boundFamily = next;
    if (!mounted) return;
    _bootstrapAndLoad();
  }

  @override
  void didUpdateWidget(covariant SafeZonesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _bootstrapAndLoad();
    }
  }

  Future<void> _bootstrapAndLoad() async {
    final familyId = _boundFamily ?? resolveActiveFamilyId();
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      if (widget.repository != null) {
        _repo = widget.repository;
      } else {
        await Stage1LocationRuntime.ensureOpen();
        if (!mounted) return;
        _repo = DomainSafeZonesRepository(
          domain: Stage1LocationRuntime.store,
          familyId: familyId,
        );
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final snap = await repo.load();
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

  Future<void> _toggleFlag(
    SafeZone zone, {
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
  }) async {
    if (!_canEdit) return;
    final repo = _repo;
    if (repo == null) return;
    await repo.setAlertFlag(
      zone.id,
      alertEnter: alertEnter,
      alertExit: alertExit,
      alertNoShow: alertNoShow,
    );
    if (!mounted) return;
    final snap = _snapshot;
    if (snap == null) return;
    setState(() {
      _snapshot = SafeZonesSnapshot(
        zones: [
          for (final z in snap.zones)
            if (z.id == zone.id)
              z.copyWith(
                alertEnter: alertEnter,
                alertExit: alertExit,
                alertNoShow: alertNoShow,
              )
            else
              z,
        ],
      );
    });
  }

  void _goCreate() {
    if (widget.onCreateZone != null) {
      widget.onCreateZone!();
      return;
    }
    final id = _resolvedChildId;
    final path = id == null
        ? '/scr-fat-017'
        : '/scr-fat-017?childId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    final sender = sosSenderForRole(
      context,
      _role,
      viewedChild: childIdFromParam(_resolvedChildId),
    );
    await sender.fireThrough(fire);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: SafeZonesKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.safeZonesTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          // P-4 — SOS never gated by empty/loading/error/read-only.
          IconButton(
            key: SafeZonesKeys.sosCta,
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
    if (!_isParent) {
      return AppEmptyState(
        key: SafeZonesKeys.childLean,
        title: l10n.safeZonesChildLeanTitle,
        message: l10n.safeZonesChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: SafeZonesKeys.loading,
        label: l10n.safeZonesLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: SafeZonesKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    final snap = _snapshot ?? const SafeZonesSnapshot(zones: []);
    if (snap.isEmpty) {
      return AppEmptyState(
        key: SafeZonesKeys.empty,
        title: l10n.safeZonesEmptyTitle,
        message: l10n.safeZonesEmptyMessage,
        actionLabel: _canEdit ? l10n.safeZonesEmptyCta : null,
        onAction: _canEdit ? _goCreate : null,
      );
    }

    return SingleChildScrollView(
      key: SafeZonesKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: SafeZonesKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.safeZonesHonestyBanner,
          ),
          const SizedBox(height: 8),
          BannerNote(
            key: SafeZonesKeys.gpsBanner,
            variant: BannerVariant.a,
            message: l10n.locationGpsNotImplementedBanner,
          ),
          if (!_canEdit) ...[
            const SizedBox(height: 10),
            BannerNote(
              key: SafeZonesKeys.readOnlyBanner,
              variant: BannerVariant.a,
              message: l10n.safeZonesReadOnlyBanner,
            ),
          ],
          const SizedBox(height: 12),
          _ZonesCard(
            zones: snap.zones,
            canEdit: _canEdit,
            l10n: l10n,
            onToggleFlag: _toggleFlag,
            onAdd: _canEdit ? _goCreate : null,
          ),
          const SizedBox(height: 14),
          PrimaryBtn(
            key: SafeZonesKeys.drawCta,
            label: l10n.safeZonesDrawCta,
            onPressed: _canEdit ? _goCreate : null,
            semanticsLabel: l10n.safeZonesDrawSemantics,
          ),
          const SizedBox(height: 12),
          Text(
            key: SafeZonesKeys.appliesNote,
            l10n.safeZonesAppliesNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: colors.ink2,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZonesCard extends StatelessWidget {
  const _ZonesCard({
    required this.zones,
    required this.canEdit,
    required this.l10n,
    required this.onToggleFlag,
    required this.onAdd,
  });

  final List<SafeZone> zones;
  final bool canEdit;
  final AppLocalizations l10n;
  final Future<void> Function(
    SafeZone zone, {
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
  })
  onToggleFlag;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;

    return Semantics(
      container: true,
      label: l10n.safeZonesSectionTitle,
      child: DecoratedBox(
        key: SafeZonesKeys.section,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.border.withValues(alpha: 0.85)),
          boxShadow: [shadows.shCard],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.safeZonesSectionTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  if (onAdd != null)
                    PrimaryBtn(
                      key: SafeZonesKeys.addHeaderCta,
                      label: l10n.safeZonesAddHeaderCta,
                      fullWidth: false,
                      onPressed: onAdd,
                      semanticsLabel: l10n.safeZonesAddHeaderSemantics,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < zones.length; i++) ...[
                _ZoneCard(
                  zone: zones[i],
                  canEdit: canEdit,
                  l10n: l10n,
                  colors: colors,
                  onToggleFlag: onToggleFlag,
                ),
                if (i < zones.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.canEdit,
    required this.l10n,
    required this.colors,
    required this.onToggleFlag,
  });

  final SafeZone zone;
  final bool canEdit;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final Future<void> Function(
    SafeZone zone, {
    bool? alertEnter,
    bool? alertExit,
    bool? alertNoShow,
  })
  onToggleFlag;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: SafeZonesKeys.zone(zone.id),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(zone.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zone.description,
                      style: TextStyle(fontSize: 12, color: colors.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _AlertFlagRow(
            switchKey: SafeZonesKeys.zoneArrive(zone.id),
            label: l10n.createSafeZoneAlertArrival,
            value: zone.alertEnter,
            canEdit: canEdit,
            colors: colors,
            onChanged: (v) => onToggleFlag(zone, alertEnter: v),
          ),
          _AlertFlagRow(
            switchKey: SafeZonesKeys.zoneLeave(zone.id),
            label: l10n.createSafeZoneAlertDeparture,
            value: zone.alertExit,
            canEdit: canEdit,
            colors: colors,
            onChanged: (v) => onToggleFlag(zone, alertExit: v),
          ),
          _AlertFlagRow(
            switchKey: SafeZonesKeys.zoneNoShow(zone.id),
            label: l10n.createSafeZoneAlertNoShow,
            value: zone.alertNoShow,
            canEdit: canEdit,
            colors: colors,
            onChanged: (v) => onToggleFlag(zone, alertNoShow: v),
          ),
          if (zone.alertNoShow && zone.noShowDeadlineMinutes != null)
            Padding(
              key: SafeZonesKeys.zoneNoShowDeadline(zone.id),
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                l10n.safeZonesNoShowDeadline(
                  _formatNoShowDeadline(zone.noShowDeadlineMinutes!),
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.ink2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatNoShowDeadline(int minutes) {
  final h = (minutes ~/ 60).clamp(0, 23);
  final m = (minutes % 60).clamp(0, 59);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

class _AlertFlagRow extends StatelessWidget {
  const _AlertFlagRow({
    required this.switchKey,
    required this.label,
    required this.value,
    required this.canEdit,
    required this.colors,
    required this.onChanged,
  });

  final Key switchKey;
  final String label;
  final bool value;
  final bool canEdit;
  final FamilyColors colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      toggled: value,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
            ),
            Switch.adaptive(
              key: switchKey,
              value: value,
              onChanged: canEdit ? onChanged : null,
              activeThumbColor: colors.mint,
            ),
          ],
        ),
      ),
    );
  }
}
