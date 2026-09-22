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

/// Widget keys for SCR-FAT-068 / SET-017 / UI-018 acceptance.
abstract final class PlatformMonitoringKeys {
  static const honestyBanner = Key('platform_monitoring_honesty_banner');
  static const offlineBanner = Key('platform_monitoring_offline_banner');

  static Key platformSection(PlatformId platform) =>
      Key('platform_monitoring_section_${platform.name}');

  static Key featureTile(PlatformId platform, MonitoringFeature f) =>
      Key('platform_monitoring_tile_${platform.name}_${f.name}');

  static Key featureSwitch(PlatformId platform, MonitoringFeature f) =>
      Key('platform_monitoring_switch_${platform.name}_${f.name}');

  static Key featureBadge(PlatformId platform, MonitoringFeature f) =>
      Key('platform_monitoring_badge_${platform.name}_${f.name}');
}

/// SCR-FAT-068 — مراقبة المنصات (SET-017 / UI-018 unavailable ≠ on).
///
/// Lists platforms (iOS/Android) × features with [CapabilityHonestyTile].
/// Reuses SET-016 capability table / effective() / DesiredMonitoringPrefs.
/// Publishes sync so child transparency matches effective (P-7 / P12).
class PlatformMonitoringScreen extends StatefulWidget {
  const PlatformMonitoringScreen({
    super.key,
    this.childId = DesiredMonitoringPrefs.defaultChildId,
    this.repository,
    this.syncBus,
    this.offline = false,
    this.childDevicePlatform = PlatformId.ios,
  });

  final String childId;

  /// Rule 25 seam — null → prefs-backed Stage-1 store.
  final DesiredMonitoringPrefsRepository? repository;

  /// P12 sync — null → [stage1DesiredMonitoringSyncBus].
  final DesiredMonitoringSyncBus? syncBus;

  /// UI-018 offline = last capability matrix + desired.
  final bool offline;

  /// Child device platform used when publishing effective transparency.
  final PlatformId childDevicePlatform;

  @override
  State<PlatformMonitoringScreen> createState() =>
      _PlatformMonitoringScreenState();
}

class _PlatformMonitoringScreenState extends State<PlatformMonitoringScreen> {
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
      platform: widget.childDevicePlatform,
      offline: widget.offline,
    );
    setState(() {
      _prefs = loaded;
      _loading = false;
    });
  }

  Future<void> _onToggle(
    PlatformId platform,
    MonitoringFeature feature,
    bool value,
  ) async {
    final capability = PlatformCapabilityTable.level(platform, feature);
    if (!switchInteractive(capability)) return;

    final next = _prefs.withFeature(feature, value);
    setState(() => _prefs = next);
    await _repository.save(next);
    _syncBus.publish(
      next,
      platform: widget.childDevicePlatform,
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

  String _platformHeading(AppLocalizations l10n, PlatformId platform) =>
      switch (platform) {
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
          l10n.platformMonitoringTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                BannerNote(
                  key: PlatformMonitoringKeys.honestyBanner,
                  variant: BannerVariant.t,
                  message: l10n.platformMonitoringHonestyBanner,
                ),
                if (widget.offline) ...[
                  const SizedBox(height: 8),
                  BannerNote(
                    key: PlatformMonitoringKeys.offlineBanner,
                    variant: BannerVariant.a,
                    message: l10n.platformMonitoringOfflineBanner,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.platformMonitoringSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                    height: 1.5,
                  ),
                ),
                for (final platform in PlatformId.values) ...[
                  const SizedBox(height: 20),
                  Text(
                    key: PlatformMonitoringKeys.platformSection(platform),
                    _platformHeading(l10n, platform),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final feature in MonitoringFeature.values) ...[
                    KeyedSubtree(
                      key: PlatformMonitoringKeys.featureTile(
                        platform,
                        feature,
                      ),
                      child: CapabilityHonestyTile(
                        label: _featureLabel(l10n, feature),
                        desired: _prefs.desiredFor(feature),
                        capability: PlatformCapabilityTable.level(
                          platform,
                          feature,
                        ),
                        unavailableLabel:
                            l10n.smartSupervisionUnavailableBadge,
                        limitedLabel: l10n.smartSupervisionLimitedBadge,
                        limitedHint: l10n.platformMonitoringLimitedHint,
                        switchKey: PlatformMonitoringKeys.featureSwitch(
                          platform,
                          feature,
                        ),
                        badgeKey: PlatformMonitoringKeys.featureBadge(
                          platform,
                          feature,
                        ),
                        onChanged: (v) => _onToggle(platform, feature, v),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
              ),
            ),
    );
  }
}
