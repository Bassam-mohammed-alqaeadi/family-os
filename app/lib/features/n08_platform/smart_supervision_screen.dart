import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs_repository.dart';
import 'package:family_os/core/policy/desired_monitoring_sync_bus.dart';
import 'package:family_os/core/policy/monitoring_feature.dart';
import 'package:family_os/core/policy/platform_capability_table.dart';
import 'package:family_os/core/policy/platform_id.dart';
import 'package:family_os/features/n08_platform/capability_honesty_tile.dart';

/// Widget keys for SCR-FAT-067 / SET-016 / UI-018 acceptance.
abstract final class SmartSupervisionKeys {
  static const honestyBanner = Key('smart_supervision_honesty_banner');
  static const offlineBanner = Key('smart_supervision_offline_banner');
  static const platformLabel = Key('smart_supervision_platform');

  static Key featureSwitch(MonitoringFeature f) =>
      Key('smart_supervision_switch_${f.name}');

  static Key featureBadge(MonitoringFeature f) =>
      Key('smart_supervision_badge_${f.name}');

  static Key featureRow(MonitoringFeature f) =>
      Key('smart_supervision_row_${f.name}');
}

/// SCR-FAT-067 — إعدادات الرقابة الذكية (SET-016 / UI-018 capability honesty).
///
/// Renders desired AND capability via shared [CapabilityHonestyTile] (SET-017).
/// Publishes to [DesiredMonitoringSyncBus] so child transparency matches
/// **effective** (UI-018 / P-7 / P12).
class SmartSupervisionScreen extends StatefulWidget {
  const SmartSupervisionScreen({
    super.key,
    this.childId = DesiredMonitoringPrefs.defaultChildId,
    this.platform = PlatformId.android,
    this.repository,
    this.syncBus,
    this.offline = false,
  });

  final String childId;

  /// Injected platform (mock-first; real TargetPlatform deferred).
  final PlatformId platform;

  /// Rule 25 seam — null → prefs-backed Stage-1 store.
  final DesiredMonitoringPrefsRepository? repository;

  /// P12 sync — null → [stage1DesiredMonitoringSyncBus].
  final DesiredMonitoringSyncBus? syncBus;

  /// UI-018 offline = last capability (fixture) + desired.
  final bool offline;

  @override
  State<SmartSupervisionScreen> createState() => _SmartSupervisionScreenState();
}

class _SmartSupervisionScreenState extends State<SmartSupervisionScreen> {
  late final DesiredMonitoringPrefsRepository _repository;
  late final DesiredMonitoringSyncBus _syncBus;
  late DesiredMonitoringPrefs _prefs;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        PrefsDesiredMonitoringPrefsRepository(stage1DesiredMonitoringPrefsStore);
    _syncBus = widget.syncBus ?? stage1DesiredMonitoringSyncBus;
    _prefs = DesiredMonitoringPrefs.defaults(childId: widget.childId);
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repository.load(widget.childId);
    if (!mounted) return;
    _syncBus.hydrate(
      loaded,
      platform: widget.platform,
      offline: widget.offline,
    );
    setState(() {
      _prefs = loaded;
      _loading = false;
    });
  }

  Future<void> _onToggle(MonitoringFeature feature, bool value) async {
    final capability =
        PlatformCapabilityTable.level(widget.platform, feature);
    if (!switchInteractive(capability)) return;

    final next = _prefs.withFeature(feature, value);
    setState(() => _prefs = next);
    await _repository.save(next);
    _syncBus.publish(
      next,
      platform: widget.platform,
      offline: widget.offline,
    );
  }

  String _featureLabel(AppLocalizations l10n, MonitoringFeature f) =>
      switch (f) {
        MonitoringFeature.webFilter => l10n.smartSupervisionWebFilter,
        MonitoringFeature.appLimits => l10n.smartSupervisionAppLimits,
        MonitoringFeature.notificationListen =>
          l10n.smartSupervisionNotificationListen,
        MonitoringFeature.locationAlways => l10n.smartSupervisionLocationAlways,
      };

  String _platformLabel(AppLocalizations l10n) => switch (widget.platform) {
        PlatformId.android => l10n.smartSupervisionPlatformAndroid,
        PlatformId.ios => l10n.smartSupervisionPlatformIos,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.smartSupervisionTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                BannerNote(
                  key: SmartSupervisionKeys.honestyBanner,
                  variant: BannerVariant.t,
                  message: l10n.smartSupervisionHonestyBanner,
                ),
                if (widget.offline) ...[
                  const SizedBox(height: 8),
                  BannerNote(
                    key: SmartSupervisionKeys.offlineBanner,
                    variant: BannerVariant.a,
                    message: l10n.platformMonitoringOfflineBanner,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  key: SmartSupervisionKeys.platformLabel,
                  _platformLabel(l10n),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.ink2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.smartSupervisionSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                for (final feature in MonitoringFeature.values) ...[
                  KeyedSubtree(
                    key: SmartSupervisionKeys.featureRow(feature),
                    child: CapabilityHonestyTile(
                      label: _featureLabel(l10n, feature),
                      desired: _prefs.desiredFor(feature),
                      capability: PlatformCapabilityTable.level(
                        widget.platform,
                        feature,
                      ),
                      unavailableLabel: l10n.smartSupervisionUnavailableBadge,
                      limitedLabel: l10n.smartSupervisionLimitedBadge,
                      limitedHint: l10n.platformMonitoringLimitedHint,
                      switchKey: SmartSupervisionKeys.featureSwitch(feature),
                      badgeKey: SmartSupervisionKeys.featureBadge(feature),
                      onChanged: (v) => _onToggle(feature, v),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}
