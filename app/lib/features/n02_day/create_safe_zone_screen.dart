import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart'
    show toEasternDigits;
import 'package:family_os/features/n02_day/safe_zones_repository.dart';

/// Widget keys for SCR-FAT-017 acceptance.
abstract final class CreateSafeZoneKeys {
  static const screen = Key('create_safe_zone_screen');
  static const body = Key('create_safe_zone_body');
  static const honestyBanner = Key('create_safe_zone_honesty');
  static const drawBanner = Key('create_safe_zone_draw');
  static const readOnlyBanner = Key('create_safe_zone_readonly');
  static const map = Key('create_safe_zone_map');
  static const tapHint = Key('create_safe_zone_tap_hint');
  static const centerPlaced = Key('create_safe_zone_center_placed');
  static const pin = Key('create_safe_zone_pin');
  static const circle = Key('create_safe_zone_circle');
  static const radiusSlider = Key('create_safe_zone_radius');
  static const nameField = Key('create_safe_zone_name');
  static const alertsCard = Key('create_safe_zone_alerts');
  static const alertArrival = Key('create_safe_zone_alert_arrival');
  static const alertDeparture = Key('create_safe_zone_alert_departure');
  static const alertNoShow = Key('create_safe_zone_alert_noshow');
  static const saveCta = Key('create_safe_zone_save');
  static const appliesNote = Key('create_safe_zone_applies');
  static const sosCta = Key('create_safe_zone_sos');
  static const childLean = Key('create_safe_zone_child_lean');
}

/// SCR-FAT-017 — إنشاء منطقة آمنة (draw / create safe zone).
///
/// Mock-first map draw: tap → center, drag → move, radius slider 50–500 m
/// (step 25), name + arrival/departure/no-show alerts. Saves into
/// [SafeZonesRepository] (FAT-016 seam). Mother needs [MotherLevel.full] to
/// draw (prototype `can('zones')`). Life360 honesty. P-4 SOS ungated.
/// RoleGuard lean for child. No Firebase / no real GPS SDK.
class CreateSafeZoneScreen extends StatefulWidget {
  const CreateSafeZoneScreen({
    super.key,
    this.childId,
    this.repository,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.canEditOverride,
    this.sosFire,
    this.onSos,
    this.onSaved,
    this.idFactory,
  });

  /// Optional route `?childId=` — forwarded back to FAT-016 list context.
  final String? childId;

  /// Null → [stage1SafeZonesRepository].
  final SafeZonesRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother permission level (ADR-035). Father ignores.
  final MotherLevel motherLevel;

  /// Test seam — when set, overrides role/level edit gate.
  final bool? canEditOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — SOS fire / navigate.
  final VoidCallback? onSos;

  /// Test seam — after successful save (skips pop/go).
  final VoidCallback? onSaved;

  /// Test seam — stable zone ids (default: `z_<epochMs>`).
  final String Function()? idFactory;

  @override
  CreateSafeZoneScreenState createState() => CreateSafeZoneScreenState();
}

class CreateSafeZoneScreenState extends State<CreateSafeZoneScreen> {
  static const int _minRadius = 50;
  static const int _maxRadius = 500;
  static const int _radiusStep = 25;
  static const int _defaultRadius = 200;

  late final SafeZonesRepository _repo;
  late final TextEditingController _nameController;

  var _radiusMeters = _defaultRadius;
  Offset? _centerFrac;
  var _alertArrival = true;
  var _alertDeparture = true;
  var _alertNoShow = false;
  var _sosBusy = false;
  var _saving = false;
  var _nameSeeded = false;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  /// Father always; mother only at [MotherLevel.full] (prototype zones≥full).
  bool get _canEdit {
    if (widget.canEditOverride != null) return widget.canEditOverride!;
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  String? get _resolvedChildId {
    final raw = widget.childId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1SafeZonesRepository;
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameSeeded) {
      _nameSeeded = true;
      _nameController.text =
          AppLocalizations.of(context).createSafeZoneNameHint;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _metersLabel(AppLocalizations l10n) {
    final raw = '$_radiusMeters';
    final digits = l10n.localeName.startsWith('ar')
        ? toEasternDigits(_radiusMeters)
        : raw;
    return digits;
  }

  void _placeOrMove(Offset local, Size size) {
    if (!_canEdit || size.width <= 0 || size.height <= 0) return;
    final dx = (local.dx / size.width).clamp(0.0, 1.0);
    final dy = (local.dy / size.height).clamp(0.0, 1.0);
    setState(() => _centerFrac = Offset(dx, dy));
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    final id = _resolvedChildId ?? 'family';
    await fire.fire(childId: id);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  void _showNeedCenter(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.createSafeZoneNeedCenter)),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_canEdit || _saving) return;
    if (_centerFrac == null) {
      _showNeedCenter(l10n);
      return;
    }

    final name = _nameController.text.trim().isEmpty
        ? l10n.createSafeZoneNameHint
        : _nameController.text.trim();
    final meters = _metersLabel(l10n);
    final id = widget.idFactory?.call() ??
        'z_${DateTime.now().millisecondsSinceEpoch}';
    final alertsOn = _alertArrival || _alertDeparture || _alertNoShow;

    setState(() => _saving = true);
    await _repo.add(
      SafeZone(
        id: id,
        emoji: '🥋',
        name: name,
        description: l10n.createSafeZoneRadiusDesc(meters),
        alertsEnabled: alertsOn,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.createSafeZoneSavedToast(name))),
    );

    if (widget.onSaved != null) {
      widget.onSaved!();
      return;
    }

    final childId = _resolvedChildId;
    final listPath = childId == null
        ? '/scr-fat-016'
        : '/scr-fat-016?childId=${Uri.encodeComponent(childId)}';
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(listPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: CreateSafeZoneKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.createSafeZoneTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: CreateSafeZoneKeys.sosCta,
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
        key: CreateSafeZoneKeys.childLean,
        title: l10n.createSafeZoneChildLeanTitle,
        message: l10n.createSafeZoneChildLeanMessage,
      );
    }

    return SingleChildScrollView(
      key: CreateSafeZoneKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: CreateSafeZoneKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.createSafeZoneHonestyBanner,
          ),
          const SizedBox(height: 10),
          BannerNote(
            key: CreateSafeZoneKeys.drawBanner,
            variant: BannerVariant.t,
            message: l10n.createSafeZoneDrawBanner,
          ),
          if (!_canEdit) ...[
            const SizedBox(height: 10),
            BannerNote(
              key: CreateSafeZoneKeys.readOnlyBanner,
              variant: BannerVariant.a,
              message: l10n.createSafeZoneReadOnlyBanner,
            ),
          ],
          const SizedBox(height: 12),
          _DrawMap(
            canEdit: _canEdit,
            centerFrac: _centerFrac,
            radiusMeters: _radiusMeters,
            l10n: l10n,
            onPlace: _placeOrMove,
          ),
          if (_centerFrac != null) ...[
            const SizedBox(height: 8),
            Text(
              key: CreateSafeZoneKeys.centerPlaced,
              l10n.createSafeZoneCenterPlaced,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l10n.createSafeZoneRadiusLabel(_metersLabel(l10n)),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          Semantics(
            label: l10n.createSafeZoneRadiusSemantics,
            slider: true,
            value: '$_radiusMeters',
            child: Slider(
              key: CreateSafeZoneKeys.radiusSlider,
              value: _radiusMeters.toDouble(),
              min: _minRadius.toDouble(),
              max: _maxRadius.toDouble(),
              divisions: (_maxRadius - _minRadius) ~/ _radiusStep,
              onChanged: _canEdit
                  ? (v) => setState(() {
                        _radiusMeters =
                            (v / _radiusStep).round() * _radiusStep;
                      })
                  : null,
              activeColor: colors.mint,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: CreateSafeZoneKeys.nameField,
            controller: _nameController,
            enabled: _canEdit,
            decoration: InputDecoration(
              labelText: l10n.createSafeZoneNameLabel,
              hintText: l10n.createSafeZoneNameHint,
            ),
          ),
          const SizedBox(height: 14),
          _AlertsCard(
            canEdit: _canEdit,
            l10n: l10n,
            arrival: _alertArrival,
            departure: _alertDeparture,
            noShow: _alertNoShow,
            onArrival: (v) => setState(() => _alertArrival = v),
            onDeparture: (v) => setState(() => _alertDeparture = v),
            onNoShow: (v) => setState(() => _alertNoShow = v),
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: CreateSafeZoneKeys.saveCta,
            label: l10n.createSafeZoneSaveCta,
            onPressed: _canEdit && !_saving ? () => _save(l10n) : null,
            semanticsLabel: l10n.createSafeZoneSaveSemantics,
          ),
          const SizedBox(height: 12),
          Text(
            key: CreateSafeZoneKeys.appliesNote,
            l10n.createSafeZoneAppliesNote,
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

class _DrawMap extends StatelessWidget {
  const _DrawMap({
    required this.canEdit,
    required this.centerFrac,
    required this.radiusMeters,
    required this.l10n,
    required this.onPlace,
  });

  final bool canEdit;
  final Offset? centerFrac;
  final int radiusMeters;
  final AppLocalizations l10n;
  final void Function(Offset local, Size size) onPlace;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Semantics(
      label: l10n.createSafeZoneMapSemantics,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const height = 230.0;
          final size = Size(width, height);
          final circlePx = radiusMeters * 0.68;

          return DecoratedBox(
            key: CreateSafeZoneKeys.map,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radii.card),
              child: SizedBox(
                height: height,
                width: width,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: canEdit
                      ? (d) => onPlace(d.localPosition, size)
                      : null,
                  onPanUpdate: canEdit && centerFrac != null
                      ? (d) => onPlace(d.localPosition, size)
                      : null,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _MapScapeBackground()),
                      if (centerFrac == null)
                        Positioned.fill(
                          child: ColoredBox(
                            color: colors.ink.withValues(alpha: 0.22),
                            child: Center(
                              child: DecoratedBox(
                                key: CreateSafeZoneKeys.tapHint,
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colors.ink.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  child: Text(
                                    l10n.createSafeZoneTapHint,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: colors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        Positioned(
                          left: centerFrac!.dx * width - circlePx / 2,
                          top: centerFrac!.dy * height - circlePx / 2,
                          child: IgnorePointer(
                            child: Container(
                              key: CreateSafeZoneKeys.circle,
                              width: circlePx,
                              height: circlePx,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.mint.withValues(alpha: 0.16),
                                border: Border.all(
                                  color: colors.mint,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: centerFrac!.dx * width - 16,
                          top: centerFrac!.dy * height - 36,
                          child: Semantics(
                            key: CreateSafeZoneKeys.pin,
                            label: l10n.createSafeZonePinSemantics,
                            child: const Text(
                              '📍',
                              style: TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Stylized neighborhood canvas (prototype `mapScape`) — tokens + ARB landmarks.
class _MapScapeBackground extends StatelessWidget {
  const _MapScapeBackground();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Color.lerp(colors.bg, colors.mint100, 0.35)!,
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 12,
            child: _LandmarkBlock(
              width: 122,
              height: 66,
              label: l10n.locationMapLandmarkHome,
              emoji: '🏠',
              fill: Color.lerp(colors.border, colors.amber100, 0.4)!,
            ),
          ),
          Positioned(
            left: 182,
            top: 10,
            child: _LandmarkBlock(
              width: 104,
              height: 68,
              label: '',
              emoji: '',
              fill: Color.lerp(colors.border, colors.amber100, 0.4)!,
            ),
          ),
          Positioned(
            left: 322,
            top: 8,
            child: _LandmarkBlock(
              width: 60,
              height: 72,
              label: l10n.locationMapLandmarkSchool,
              emoji: '🏫',
              fill: Color.lerp(colors.sky, colors.surface, 0.55)!,
            ),
          ),
          Positioned(
            left: 18,
            top: 128,
            child: _LandmarkBlock(
              width: 94,
              height: 76,
              label: l10n.locationMapLandmarkPark,
              emoji: '🌳',
              fill: Color.lerp(colors.mint100, colors.mint, 0.15)!,
              radius: 10,
            ),
          ),
          Positioned(
            left: 182,
            top: 126,
            child: _LandmarkBlock(
              width: 100,
              height: 80,
              label: l10n.locationMapLandmarkClub,
              emoji: '⚽',
              fill: Color.lerp(colors.mint100, colors.border, 0.3)!,
            ),
          ),
          Positioned(
            left: 308,
            top: 128,
            child: _LandmarkBlock(
              width: 74,
              height: 76,
              label: l10n.locationMapLandmarkMosque,
              emoji: '🕌',
              fill: Color.lerp(colors.amber100, colors.border, 0.35)!,
            ),
          ),
          Positioned(
            left: 0,
            top: 90,
            right: 0,
            child: ColoredBox(
              color: colors.surface,
              child: SizedBox(
                height: 24,
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
            top: 101,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 2),
              painter: _DashedLinePainter(color: colors.amber),
            ),
          ),
        ],
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
          if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 16)),
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

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.canEdit,
    required this.l10n,
    required this.arrival,
    required this.departure,
    required this.noShow,
    required this.onArrival,
    required this.onDeparture,
    required this.onNoShow,
  });

  final bool canEdit;
  final AppLocalizations l10n;
  final bool arrival;
  final bool departure;
  final bool noShow;
  final ValueChanged<bool> onArrival;
  final ValueChanged<bool> onDeparture;
  final ValueChanged<bool> onNoShow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;

    return Semantics(
      container: true,
      label: l10n.createSafeZoneAlertsHeading,
      child: DecoratedBox(
        key: CreateSafeZoneKeys.alertsCard,
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
              Text(
                l10n.createSafeZoneAlertsHeading,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 4),
              RowTile(
                key: CreateSafeZoneKeys.alertArrival,
                leading: Icon(Icons.login, color: colors.mint, size: 22),
                title: l10n.createSafeZoneAlertArrival,
                showDivider: true,
                trailing: Switch.adaptive(
                  value: arrival,
                  onChanged: canEdit ? onArrival : null,
                  activeThumbColor: colors.mint,
                ),
              ),
              RowTile(
                key: CreateSafeZoneKeys.alertDeparture,
                leading: Icon(Icons.logout, color: colors.mint, size: 22),
                title: l10n.createSafeZoneAlertDeparture,
                showDivider: true,
                trailing: Switch.adaptive(
                  value: departure,
                  onChanged: canEdit ? onDeparture : null,
                  activeThumbColor: colors.mint,
                ),
              ),
              RowTile(
                key: CreateSafeZoneKeys.alertNoShow,
                leading: Icon(Icons.schedule, color: colors.amber, size: 22),
                title: l10n.createSafeZoneAlertNoShow,
                subtitle: l10n.createSafeZoneAlertNoShowHint,
                showDivider: false,
                trailing: Switch.adaptive(
                  value: noShow,
                  onChanged: canEdit ? onNoShow : null,
                  activeThumbColor: colors.mint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
