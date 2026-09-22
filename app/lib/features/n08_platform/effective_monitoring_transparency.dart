import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/capability_level.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/policy/desired_monitoring_sync_bus.dart';
import 'package:family_os/core/policy/monitoring_feature.dart';
import 'package:family_os/core/policy/platform_capability_table.dart';
import 'package:family_os/core/policy/platform_id.dart';

/// Widget keys for UI-018 child effective-monitoring transparency (P-7).
abstract final class EffectiveMonitoringTransparencyKeys {
  static const section = Key('effective_monitoring_transparency');
  static const offlineBanner = Key('effective_monitoring_offline_banner');
  static const empty = Key('effective_monitoring_empty');

  static Key featureLine(MonitoringFeature f) =>
      Key('effective_monitoring_line_${f.name}');

  static Key featureBadge(MonitoringFeature f) =>
      Key('effective_monitoring_badge_${f.name}');
}

/// Read-only child honesty list of **effective** monitoring (UI-018 / P-7).
///
/// Never mirrors raw desired: unavailable stays off; reportsOnly shows limited.
class EffectiveMonitoringTransparency extends StatefulWidget {
  const EffectiveMonitoringTransparency({
    super.key,
    this.childId = DesiredMonitoringPrefs.defaultChildId,
    this.platform = PlatformId.ios,
    this.syncBus,
    this.initialPrefs,
    this.offline = false,
  });

  final String childId;
  final PlatformId platform;
  final DesiredMonitoringSyncBus? syncBus;
  final DesiredMonitoringPrefs? initialPrefs;
  final bool offline;

  @override
  State<EffectiveMonitoringTransparency> createState() =>
      _EffectiveMonitoringTransparencyState();
}

class _EffectiveMonitoringTransparencyState
    extends State<EffectiveMonitoringTransparency> {
  late final DesiredMonitoringSyncBus _syncBus;
  late DesiredMonitoringPrefs _prefs;
  late PlatformId _platform;
  late bool _offline;

  @override
  void initState() {
    super.initState();
    _syncBus = widget.syncBus ?? stage1DesiredMonitoringSyncBus;
    _prefs = widget.initialPrefs ??
        _syncBus.prefsOf(widget.childId) ??
        DesiredMonitoringPrefs.defaults(childId: widget.childId);
    _platform = _syncBus.prefsOf(widget.childId) != null
        ? _syncBus.platformOf(widget.childId)
        : widget.platform;
    _offline = widget.offline || _syncBus.offlineOf(widget.childId);
    _syncBus.hydrate(_prefs, platform: _platform, offline: _offline);
    _syncBus.addListener(_onBus);
  }

  @override
  void dispose() {
    _syncBus.removeListener(_onBus);
    super.dispose();
  }

  void _onBus() {
    final next = _syncBus.prefsOf(widget.childId);
    if (next == null) return;
    if (!mounted) return;
    setState(() {
      _prefs = next;
      _platform = _syncBus.platformOf(widget.childId);
      _offline = _syncBus.offlineOf(widget.childId);
    });
  }

  String _featureLabel(AppLocalizations l10n, MonitoringFeature f) =>
      switch (f) {
        MonitoringFeature.webFilter => l10n.smartSupervisionWebFilter,
        MonitoringFeature.appLimits => l10n.smartSupervisionAppLimits,
        MonitoringFeature.notificationListen =>
          l10n.smartSupervisionNotificationListen,
        MonitoringFeature.locationAlways => l10n.smartSupervisionLocationAlways,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    final lines = <(MonitoringFeature, CapabilityLevel)>[
      for (final f in MonitoringFeature.values)
        (
          f,
          effectiveMonitoring(
            desired: _prefs.desiredFor(f),
            capability: PlatformCapabilityTable.level(_platform, f),
          ),
        ),
    ];
    // Active honesty: full + reportsOnly only — unavailable never listed as on.
    final visible =
        lines.where((e) => e.$2 != CapabilityLevel.unavailable).toList();

    return Column(
      key: EffectiveMonitoringTransparencyKeys.section,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.effectiveMonitoringSectionTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.effectiveMonitoringChildSubtitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
            height: 1.45,
          ),
        ),
        if (_offline) ...[
          const SizedBox(height: 10),
          BannerNote(
            key: EffectiveMonitoringTransparencyKeys.offlineBanner,
            variant: BannerVariant.a,
            message: l10n.platformMonitoringOfflineBanner,
          ),
        ],
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Text(
            key: EffectiveMonitoringTransparencyKeys.empty,
            l10n.effectiveMonitoringEmpty,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          )
        else
          for (final (feature, level) in visible) ...[
            _EffectiveLine(
              feature: feature,
              level: level,
              label: _featureLabel(l10n, feature),
              limitedLabel: l10n.smartSupervisionLimitedBadge,
              fullLabel: l10n.effectiveMonitoringFullBadge,
            ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}

class _EffectiveLine extends StatelessWidget {
  const _EffectiveLine({
    required this.feature,
    required this.level,
    required this.label,
    required this.limitedLabel,
    required this.fullLabel,
  });

  final MonitoringFeature feature;
  final CapabilityLevel level;
  final String label;
  final String limitedLabel;
  final String fullLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final badgeLabel = switch (level) {
      CapabilityLevel.full => fullLabel,
      CapabilityLevel.reportsOnly => limitedLabel,
      CapabilityLevel.unavailable => '',
    };
    final badgeVariant = switch (level) {
      CapabilityLevel.full => TagVariant.g,
      CapabilityLevel.reportsOnly => TagVariant.a,
      CapabilityLevel.unavailable => TagVariant.a,
    };
    final ink = level == CapabilityLevel.reportsOnly
        ? colors.amberDeep
        : colors.ink;

    return Semantics(
      container: true,
      label: '$label. $badgeLabel',
      child: Padding(
        key: EffectiveMonitoringTransparencyKeys.featureLine(feature),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              level == CapabilityLevel.full
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: level == CapabilityLevel.full
                  ? colors.tealDeep
                  : colors.amberInk,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
            Tag(
              key: EffectiveMonitoringTransparencyKeys.featureBadge(feature),
              label: badgeLabel,
              variant: badgeVariant,
            ),
          ],
        ),
      ),
    );
  }
}
