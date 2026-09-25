import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/location_history_repository.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';

/// Widget keys for SCR-FAT-015 acceptance.
abstract final class LocationHistoryKeys {
  static const screen = Key('location_history_screen');
  static const loading = Key('location_history_loading');
  static const missingId = Key('location_history_missing_id');
  static const empty = Key('location_history_empty');
  static const notFound = Key('location_history_not_found');
  static const error = Key('location_history_error');
  static const body = Key('location_history_body');
  static const honestyBanner = Key('location_history_honesty');
  static const gpsBanner = Key('location_history_gps_banner');
  static const threadSection = Key('location_history_thread');
  static const frequentSection = Key('location_history_frequent');
  static const retentionNote = Key('location_history_retention');
  static const sosCta = Key('location_history_sos');
  static const childLean = Key('location_history_child_lean');

  static Key day(String id) => Key('location_history_day_$id');
  static Key place(String id) => Key('location_history_place_$id');
}

/// SCR-FAT-015 — سجل المواقع (parent location history / day thread).
///
/// Mock-first full history opened from FAT-014 pin rows / «السجل الكامل».
/// Parametric [childId]. Day cards + S-SEC-023 frequent places + 90-day
/// retention honesty. Life360: history ≠ parental control. P-4 SOS ungated.
/// RoleGuard lean for child. No Firebase.
class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({
    super.key,
    this.childId,
    this.repository,
    this.roleOverride,
    this.sosFire,
    this.onSos,
    this.onOpenMap,
  });

  /// From route `?childId=`; null/empty → missing-id empty state.
  final String? childId;

  /// Null → FS-001 Domain trail via [Stage1LocationRuntime] (Slice 01).
  /// Inject [repository] in tests to keep Stage-1 InMemory.
  final LocationHistoryRepository? repository;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — SOS fire / navigate.
  final VoidCallback? onSos;

  /// Test seam — empty CTA → live map.
  final VoidCallback? onOpenMap;

  @override
  LocationHistoryScreenState createState() => LocationHistoryScreenState();
}

class LocationHistoryScreenState extends State<LocationHistoryScreen> {
  LocationHistoryRepository? _repo;
  var _loading = true;
  var _loadFailed = false;
  var _sosBusy = false;
  LocationHistorySnapshot? _snapshot;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapAndLoad();
    });
  }

  @override
  void didUpdateWidget(covariant LocationHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId ||
        oldWidget.repository != widget.repository) {
      _bootstrapAndLoad();
    }
  }

  Future<void> _bootstrapAndLoad() async {
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
        _repo = DomainLocationHistoryRepository(
          domain: Stage1LocationRuntime.store,
          familyId: FamilyId('fam_stage1'),
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
    final id = _resolvedChildId;
    if (id == null) {
      setState(() {
        _loading = false;
        _loadFailed = false;
        _snapshot = null;
      });
      return;
    }

    final repo = _repo;
    if (repo == null) return;

    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final snap = await repo.load(id);
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

  void _goMap() {
    if (widget.onOpenMap != null) {
      widget.onOpenMap!();
      return;
    }
    final id = _resolvedChildId;
    final path = id == null
        ? '/scr-fat-014'
        : '/scr-fat-014?childId=${Uri.encodeComponent(id)}';
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
    final id = _resolvedChildId ?? _snapshot?.childId ?? 'family';
    await fire.fire(childId: id);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push('/scr-fat-018');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final title = _snapshot == null
        ? l10n.locationHistoryTitle
        : l10n.locationHistoryThreadTitle(_snapshot!.displayName);

    return Scaffold(
      key: LocationHistoryKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          // P-4 — SOS never gated by history empty/loading/error.
          IconButton(
            key: LocationHistoryKeys.sosCta,
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
        key: LocationHistoryKeys.childLean,
        title: l10n.locationHistoryChildLeanTitle,
        message: l10n.locationHistoryChildLeanMessage,
      );
    }

    if (_resolvedChildId == null) {
      return AppEmptyState(
        key: LocationHistoryKeys.missingId,
        title: l10n.locationHistoryMissingIdTitle,
        message: l10n.locationHistoryMissingIdMessage,
        actionLabel: l10n.locationHistoryOpenMapCta,
        onAction: _goMap,
      );
    }

    if (_loading) {
      return Semantics(
        key: LocationHistoryKeys.loading,
        label: l10n.locationHistoryLoadingSemantics,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return AppErrorState(
        key: LocationHistoryKeys.error,
        kind: AppErrorKind.network,
        onRetry: _load,
      );
    }

    final snap = _snapshot;
    if (snap == null) {
      return AppEmptyState(
        key: LocationHistoryKeys.notFound,
        title: l10n.locationHistoryNotFoundTitle,
        message: l10n.locationHistoryNotFoundMessage,
        actionLabel: l10n.locationHistoryOpenMapCta,
        onAction: _goMap,
      );
    }

    if (snap.isEmpty) {
      return AppEmptyState(
        key: LocationHistoryKeys.empty,
        title: l10n.locationHistoryEmptyTitle,
        message: l10n.locationHistoryEmptyMessage,
        actionLabel: l10n.locationHistoryOpenMapCta,
        onAction: _goMap,
      );
    }

    return SingleChildScrollView(
      key: LocationHistoryKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: LocationHistoryKeys.honestyBanner,
            variant: BannerVariant.t,
            message: l10n.locationHistoryHonestyBanner,
          ),
          const SizedBox(height: 8),
          BannerNote(
            key: LocationHistoryKeys.gpsBanner,
            variant: BannerVariant.a,
            message: l10n.locationGpsNotImplementedBanner,
          ),
          const SizedBox(height: 12),
          _ThreadSection(days: snap.days),
          if (snap.frequentPlaces.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FrequentPlacesCard(
              displayName: snap.displayName,
              places: snap.frequentPlaces,
              l10n: l10n,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            key: LocationHistoryKeys.retentionNote,
            l10n.locationHistoryRetentionNote,
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

class _ThreadSection extends StatelessWidget {
  const _ThreadSection({required this.days});

  final List<LocationHistoryDay> days;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: LocationHistoryKeys.threadSection,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _DayCard(day: days[i]),
        ],
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final LocationHistoryDay day;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;

    return Semantics(
      container: true,
      label: day.heading,
      child: DecoratedBox(
        key: LocationHistoryKeys.day(day.id),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.border.withValues(alpha: 0.85)),
          boxShadow: [shadows.shCard],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                day.heading,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < day.stops.length; i++) ...[
                _ThreadStop(stop: day.stops[i], colors: colors),
                if (i < day.stops.length - 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 7),
                    child: SizedBox(
                      height: 10,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          width: 2,
                          height: 10,
                          color: colors.border,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadStop extends StatelessWidget {
  const _ThreadStop({required this.stop, required this.colors});

  final LocationHistoryStop stop;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    final dotColor = stop.isCurrent ? colors.mint : colors.p400;

    return Semantics(
      label: '${stop.title}. ${stop.timeLabel}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stop.isCurrent ? colors.mint : colors.surface,
                border: Border.all(color: dotColor, width: 2.5),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                    height: 1.3,
                  ),
                ),
                Text(
                  stop.timeLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: colors.ink2,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequentPlacesCard extends StatelessWidget {
  const _FrequentPlacesCard({
    required this.displayName,
    required this.places,
    required this.l10n,
  });

  final String displayName;
  final List<LocationFrequentPlace> places;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;

    return DecoratedBox(
      key: LocationHistoryKeys.frequentSection,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border.withValues(alpha: 0.85)),
        boxShadow: [shadows.shCard],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.locationHistoryFrequentTitle(displayName),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(
                  label: l10n.locationHistoryFrequentNewBadge,
                  variant: TagVariant.p,
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < places.length; i++) ...[
              _FrequentPlaceRow(place: places[i], l10n: l10n),
              if (i < places.length - 1)
                Divider(height: 1, color: colors.border),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.locationHistoryFrequentHint,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: colors.ink2,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequentPlaceRow extends StatelessWidget {
  const _FrequentPlaceRow({required this.place, required this.l10n});

  final LocationFrequentPlace place;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isRegular = place.regularity == LocationPlaceRegularity.regular;
    final tagLabel = isRegular
        ? l10n.locationHistoryPlaceRegular
        : l10n.locationHistoryPlaceNovel;
    final tagVariant = isRegular ? TagVariant.g : TagVariant.a;

    return RowTile(
      key: LocationHistoryKeys.place(place.id),
      leading: Text(place.emoji, style: const TextStyle(fontSize: 22)),
      title: place.title,
      subtitle: place.subtitle,
      trailing: Tag(label: tagLabel, variant: tagVariant),
      showDivider: false,
    );
  }
}
