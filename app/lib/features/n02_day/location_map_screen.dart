import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/silent_locate_sheet.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/active_child_resolver.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';

Color _swatchColor(DayChildSwatch swatch, FamilyColors colors) =>
    switch (swatch) {
      DayChildSwatch.purple => colors.p500,
      DayChildSwatch.sky => colors.sky,
      DayChildSwatch.amber => colors.amber,
    };

/// Widget keys for SCR-FAT-014 acceptance.
abstract final class LocationMapKeys {
  static const screen = Key('location_map_screen');
  static const loading = Key('location_map_loading');
  static const empty = Key('location_map_empty');
  static const notFound = Key('location_map_not_found');
  static const error = Key('location_map_error');
  static const body = Key('location_map_body');
  static const mapCanvas = Key('location_map_canvas');
  static const pinsList = Key('location_map_pins_list');
  static const dayThread = Key('location_map_day_thread');
  static const safeZonesCta = Key('location_map_safe_zones');
  static const honestyBanner = Key('location_map_honesty');
  static const gpsBanner = Key('location_map_gps_banner');
  static const silentLocateCta = Key('location_map_silent_locate');
  static Key networkChip(String id) => Key('location_map_network_$id');
  static const sosCta = Key('location_map_sos');
  static const childLean = Key('location_map_child_lean');

  static Key pin(String id) => Key('location_map_pin_$id');
  static Key pinRow(String id) => Key('location_map_row_$id');
}

/// SCR-FAT-014 — خريطة الموقع (parent live location map).
///
/// Mock-first stylized map (no Firebase / no real GPS SDK). Optional parametric
/// [childId] focuses the day-thread; family pins remain visible. RoleGuard lean
/// for child. Competitive honesty (Life360): location ≠ full parental control.
/// P-4: SOS CTA stays enabled even when map is empty / loading / error.
class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({
    super.key,
    this.childId,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.onOpenHistory,
    this.onOpenSafeZones,
    this.onSos,
    this.onAddChild,
    this.onSilentLocate,
    this.familyId,
  });

  /// From route `?childId=`; null → family map, thread defaults to first pin.
  final String? childId;

  /// Null → [stage1LocationMapRepository].
  final LocationMapRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — pin row / full history → `/scr-fat-015`.
  final void Function(String childId)? onOpenHistory;

  /// Test seam — safe zones → `/scr-fat-016`.
  final VoidCallback? onOpenSafeZones;

  /// Test seam — SOS fire / navigate.
  final VoidCallback? onSos;

  /// Test seam — empty CTA → add child.
  final VoidCallback? onAddChild;

  /// Test seam — silent locate (skips sheet when set).
  final void Function(String childId)? onSilentLocate;

  /// Family for silent locate domain lookup.
  final FamilyId? familyId;

  @override
  LocationMapScreenState createState() => LocationMapScreenState();
}

class LocationMapScreenState extends State<LocationMapScreen> {
  late final LocationMapRepository _repo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  LocationMapSnapshot? _snapshot;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  String? get _resolvedChildId {
    final raw = widget.childId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1LocationMapRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant LocationMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final snap = await _repo.load(focusChildId: _resolvedChildId);
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

  void _goAddChild() {
    if (widget.onAddChild != null) {
      widget.onAddChild!();
      return;
    }
    context.push('/scr-fat-003');
  }

  void _goHistory(String childId) {
    if (widget.onOpenHistory != null) {
      widget.onOpenHistory!(childId);
      return;
    }
    context.push('/scr-fat-015?childId=${Uri.encodeComponent(childId)}');
  }

  void _goSafeZones() {
    if (widget.onOpenSafeZones != null) {
      widget.onOpenSafeZones!();
      return;
    }
    final id = _resolvedChildId;
    final path = id == null
        ? '/scr-fat-016'
        : '/scr-fat-016?childId=${Uri.encodeComponent(id)}';
    context.push(path);
  }

  bool get _canInitiateSilentLocate {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      final level = resolveAuthorizationContext(
        context,
        fallbackRole: _role,
      ).motherLevel;
      // L2: Primary + Partner + Full may initiate; Observer may not.
      return level != MotherLevel.observer;
    }
    return false;
  }

  Future<void> _openSilentLocate(String childId, String label) async {
    if (!_canInitiateSilentLocate) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: AppLocalizations.of(context).locationMapSilentLocateDenied,
      );
      return;
    }
    if (widget.onSilentLocate != null) {
      widget.onSilentLocate!(childId);
      return;
    }
    await Stage1LocationRuntime.ensureOpen();
    if (!mounted) return;
    final family = widget.familyId ?? resolveActiveFamilyId();
    await SilentLocateSheet.show(
      context,
      childId: childId,
      childLabel: label,
      gpsStatus: CapabilityStatus.notImplemented,
      onRequest: () => SilentLocateService.request(
        domain: Stage1LocationRuntime.store,
        familyId: family,
        childId: ChildId(childId),
        nativeGpsStatus: CapabilityStatus.notImplemented,
      ),
    );
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    final viewed = childIdFromParam(
      _resolvedChildId ??
          _snapshot?.focusChildId ??
          _snapshot?.pins.firstOrNull?.id,
    );
    final sender = sosSenderForRole(context, _role, viewedChild: viewed);
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
      key: LocationMapKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(l10n.locationMapTitle),
        actions: [
          // P-4 — SOS never gated by map empty/loading/error.
          IconButton(
            key: LocationMapKeys.sosCta,
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
        key: LocationMapKeys.childLean,
        title: l10n.locationMapChildLeanTitle,
        message: l10n.locationMapChildLeanMessage,
      );
    }

    if (_loading) {
      return Semantics(
        key: LocationMapKeys.loading,
        label: l10n.locationMapLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: LocationMapKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    final snap = _snapshot;
    if (snap == null) {
      return AppEmptyState(
        key: LocationMapKeys.notFound,
        title: l10n.locationMapNotFoundTitle,
        message: l10n.locationMapNotFoundMessage,
      );
    }

    if (snap.isEmpty) {
      return AppEmptyState(
        key: LocationMapKeys.empty,
        title: l10n.locationMapEmptyTitle,
        message: l10n.locationMapEmptyMessage,
        actionLabel: l10n.childrenListAddChild,
        onAction: _goAddChild,
      );
    }

    return SingleChildScrollView(
      key: LocationMapKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: LocationMapKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.locationMapHonestyBanner,
          ),
          const SizedBox(height: 8),
          BannerNote(
            key: LocationMapKeys.gpsBanner,
            variant: BannerVariant.a,
            message: l10n.locationGpsNotImplementedBanner,
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: CapabilityHonestyBadge(
              status: CapabilityStatus.notImplemented,
            ),
          ),
          const SizedBox(height: 12),
          _MapCanvas(
            pins: snap.pins,
            zones: snap.zones,
            focusChildId: snap.focusChildId,
            l10n: l10n,
          ),
          const SizedBox(height: 12),
          _PinsCard(pins: snap.pins, l10n: l10n, onOpenHistory: _goHistory),
          if (snap.threadStops.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DayThreadCard(
              displayName: snap.focusDisplayName,
              stops: snap.threadStops,
              focusChildId: snap.focusChildId ?? snap.pins.first.id,
              l10n: l10n,
              onOpenFullHistory: _goHistory,
            ),
          ],
          const SizedBox(height: 12),
          PrimaryBtn(
            key: LocationMapKeys.silentLocateCta,
            label: l10n.locationMapSilentLocateCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: () => _openSilentLocate(
              snap.focusChildId ?? snap.pins.first.id,
              snap.focusDisplayName.isNotEmpty
                  ? snap.focusDisplayName
                  : (snap.pins.first.displayName),
            ),
            semanticsLabel: l10n.locationMapSilentLocateCta,
          ),
          const SizedBox(height: 8),
          PrimaryBtn(
            key: LocationMapKeys.safeZonesCta,
            label: l10n.locationMapSafeZonesCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _goSafeZones,
            semanticsLabel: l10n.locationMapSafeZonesSemantics,
          ),
        ],
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.pins,
    required this.zones,
    required this.focusChildId,
    required this.l10n,
  });

  final List<LocationMapPin> pins;
  final List<LocationMapZone> zones;
  final String? focusChildId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Semantics(
      container: true,
      label: l10n.locationMapCanvasSemantics,
      child: DecoratedBox(
        key: LocationMapKeys.mapCanvas,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.border),
          boxShadow: [Theme.of(context).extension<FamilyShadows>()!.shCard],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radii.card),
          // Keep landmark layout stable under RTL (map is geographic, not text).
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  const h = 300.0;
                  return Stack(
                    children: [
                      const Positioned.fill(child: _MapScapeBackground()),
                      for (final zone in zones)
                        Positioned(
                          left:
                              zone.xFraction * w -
                              (zone.diameterFraction * w) / 2,
                          top:
                              zone.yFraction * h -
                              (zone.diameterFraction * h) / 2,
                          width: zone.diameterFraction * w,
                          height: zone.diameterFraction * h,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: zone.purpleTint
                                  ? colors.p400.withValues(alpha: 0.08)
                                  : colors.mint.withValues(alpha: 0.14),
                              border: Border.all(
                                color: zone.purpleTint
                                    ? colors.p400
                                    : colors.mint,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      for (final pin in pins)
                        Positioned(
                          left: pin.xFraction * w - 22,
                          top: pin.yFraction * h - 22,
                          child: _MapPinMarker(
                            pin: pin,
                            focused: pin.id == focusChildId,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stylized neighborhood canvas (prototype `mapScape`) — tokens only.
/// VX-B4 · G-12 — fractional layout (no fixed-pixel overflow on 360 dp).
class _MapScapeBackground extends StatelessWidget {
  const _MapScapeBackground();

  static const _designW = 400.0;
  static const _designH = 220.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Color.lerp(colors.bg, colors.mint100, 0.35)!,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          double lx(double d) => d / _designW * w;
          double ty(double d) => d / _designH * h;
          double dw(double d) => d / _designW * w;
          double dh(double d) => d / _designH * h;

          return Stack(
            children: [
              Positioned(
                left: lx(14),
                top: ty(12),
                child: _LandmarkBlock(
                  width: dw(122),
                  height: dh(66),
                  label: l10n.locationMapLandmarkHome,
                  emoji: '🏠',
                  fill: Color.lerp(colors.border, colors.amber100, 0.4)!,
                ),
              ),
              Positioned(
                left: lx(182),
                top: ty(10),
                child: _LandmarkBlock(
                  width: dw(104),
                  height: dh(68),
                  label: '',
                  emoji: '',
                  fill: Color.lerp(colors.border, colors.amber100, 0.4)!,
                ),
              ),
              Positioned(
                left: lx(322),
                top: ty(8),
                child: _LandmarkBlock(
                  width: dw(60),
                  height: dh(72),
                  label: l10n.locationMapLandmarkSchool,
                  emoji: '🏫',
                  fill: Color.lerp(colors.sky, colors.surface, 0.55)!,
                ),
              ),
              Positioned(
                left: lx(18),
                top: ty(128),
                child: _LandmarkBlock(
                  width: dw(94),
                  height: dh(76),
                  label: l10n.locationMapLandmarkPark,
                  emoji: '🌳',
                  fill: Color.lerp(colors.mint100, colors.mint, 0.15)!,
                  radius: 10,
                ),
              ),
              Positioned(
                left: lx(182),
                top: ty(126),
                child: _LandmarkBlock(
                  width: dw(100),
                  height: dh(80),
                  label: l10n.locationMapLandmarkClub,
                  emoji: '⚽',
                  fill: Color.lerp(colors.mint100, colors.border, 0.3)!,
                ),
              ),
              Positioned(
                left: lx(308),
                top: ty(128),
                child: _LandmarkBlock(
                  width: dw(74),
                  height: dh(76),
                  label: l10n.locationMapLandmarkMosque,
                  emoji: '🕌',
                  fill: Color.lerp(colors.amber100, colors.border, 0.35)!,
                ),
              ),
              Positioned(
                left: 0,
                top: ty(90),
                right: 0,
                child: ColoredBox(
                  color: colors.surface,
                  child: SizedBox(
                    height: dh(24).clamp(16, 32),
                    child: Center(
                      child: Text(
                        l10n.locationMapLandmarkStreet,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: colors.ink2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: ty(101),
                right: 0,
                child: CustomPaint(
                  size: const Size(double.infinity, 2),
                  painter: _DashedLinePainter(color: colors.amber),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LandmarkBlock extends StatelessWidget {
  const _LandmarkBlock({
    required this.width,
    required this.height,
    required this.label,
    required this.emoji,
    required this.fill,
    this.radius = 6,
  });

  final double width;
  final double height;
  final String label;
  final String emoji;
  final Color fill;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emoji.isNotEmpty)
            Text(emoji, style: const TextStyle(fontSize: 16)),
          if (label.isNotEmpty)
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dash = 11.0;
    const gap = 9.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MapPinMarker extends StatelessWidget {
  const _MapPinMarker({required this.pin, required this.focused});

  final LocationMapPin pin;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final base = _swatchColor(pin.swatch, colors);

    return Semantics(
      key: LocationMapKeys.pin(pin.id),
      label: '${pin.displayName}, ${pin.locationLabel}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: focused ? 48 : 44,
            height: focused ? 48 : 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(base, colors.surface, 0.25)!, base],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.ink.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: focused ? colors.mint : colors.surface,
                width: focused ? 2.5 : 2,
              ),
            ),
            child: Text(pin.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: colors.ink.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              pin.displayName,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinsCard extends StatelessWidget {
  const _PinsCard({
    required this.pins,
    required this.l10n,
    required this.onOpenHistory,
  });

  final List<LocationMapPin> pins;
  final AppLocalizations l10n;
  final void Function(String childId) onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;

    return DecoratedBox(
      key: LocationMapKeys.pinsList,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border.withValues(alpha: 0.85)),
        boxShadow: [shadows.shCard],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < pins.length; i++) ...[
              _PinRow(
                pin: pins[i],
                l10n: l10n,
                onTap: () => onOpenHistory(pins[i].id),
              ),
              if (i < pins.length - 1) Divider(height: 1, color: colors.border),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinRow extends StatelessWidget {
  const _PinRow({required this.pin, required this.l10n, required this.onTap});

  final LocationMapPin pin;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final base = _swatchColor(pin.swatch, colors);
    final subtitle = pin.safeZoneLabel.isEmpty
        ? l10n.locationMapPinSubtitle(pin.lastSeenLabel, pin.batteryLabel)
        : l10n.locationMapPinSubtitleInZone(
            pin.safeZoneLabel,
            pin.lastSeenLabel,
            pin.batteryLabel,
          );
    final warnSuffix = pin.batteryWarn ? ' ⚠️' : '';
    final networkLabel = switch (pin.networkClass) {
      LocationNetworkClass.online => l10n.locationMapNetworkOnline,
      LocationNetworkClass.offline => l10n.locationMapNetworkOffline,
      LocationNetworkClass.unknown => l10n.locationMapNetworkUnknown,
      LocationNetworkClass.unavailable => l10n.locationMapNetworkUnavailable,
    };

    return Column(
      key: LocationMapKeys.pinRow(pin.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RowTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: base,
            child: Text(pin.emoji, style: const TextStyle(fontSize: 18)),
          ),
          title: l10n.locationMapPinTitle(pin.displayName, pin.locationLabel),
          subtitle: '$subtitle$warnSuffix',
          trailing: Text(
            l10n.locationMapHistoryLink,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.p600,
            ),
          ),
          onTap: onTap,
          showDivider: false,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 56,
            end: 12,
            bottom: 8,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              key: LocationMapKeys.networkChip(pin.id),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.p50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                networkLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.ink2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayThreadCard extends StatelessWidget {
  const _DayThreadCard({
    required this.displayName,
    required this.stops,
    required this.focusChildId,
    required this.l10n,
    required this.onOpenFullHistory,
  });

  final String displayName;
  final List<LocationThreadStop> stops;
  final String focusChildId;
  final AppLocalizations l10n;
  final void Function(String childId) onOpenFullHistory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;

    return DecoratedBox(
      key: LocationMapKeys.dayThread,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border.withValues(alpha: 0.85)),
        boxShadow: [shadows.shCard],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.locationMapThreadTitle(displayName),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onOpenFullHistory(focusChildId),
                  child: Text(
                    l10n.locationMapFullHistoryLink,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.p600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final stop in stops)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stop.isCurrent ? colors.mint : colors.border,
                        border: Border.all(
                          color: stop.isCurrent ? colors.mintInk : colors.ink2,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.ink,
                            ),
                          ),
                          Text(
                            stop.timeLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: colors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
