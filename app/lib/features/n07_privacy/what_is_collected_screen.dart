import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/ai_safety_child_transparency_card.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/screen_camera_transparency_card.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/offline_ai_safety/offline_ai_safety.dart';
import 'package:family_os/core/policy/collection_scope.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/policy/desired_monitoring_sync_bus.dart';
import 'package:family_os/core/policy/platform_id.dart';
import 'package:family_os/core/policy/privacy_collection_policy.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/policy/privacy_collection_sync_bus.dart';
import 'package:family_os/core/screen_camera/screen_camera.dart';
import 'package:family_os/features/n08_platform/effective_monitoring_transparency.dart';

/// Widget keys for SCR-CHD-010 / SET-012 acceptance.
abstract final class WhatIsCollectedKeys {
  static const list = Key('what_is_collected_list');
  static const empty = Key('what_is_collected_empty');
  static const updatedAt = Key('what_is_collected_updated_at');
  static const transparencyStack = Key('what_is_collected_transparency_stack');

  static Key scopeLine(CollectionScope scope) =>
      Key('what_is_collected_scope_${scope.key}');
}

/// SCR-CHD-010 — ماذا يُجمع عني (SET-012 / UI-018 / P-7 / `S-ADM-035`).
///
/// Read-only honesty list of **enabled** scopes only. Listens to
/// [PrivacyCollectionSyncBus] so father saves update same session (P12).
/// Also mirrors **effective** platform monitoring (UI-018 / SET-016/017).
class WhatIsCollectedScreen extends StatefulWidget {
  const WhatIsCollectedScreen({
    super.key,
    this.childId,
    this.repository,
    this.syncBus,
    this.monitoringSyncBus,
    this.monitoringChildId = DesiredMonitoringPrefs.defaultChildId,
    this.monitoringPlatform = PlatformId.ios,
    this.screenCamera,
    this.offlineAi,
  });

  /// Stage-1 demo child when null.
  final ChildId? childId;

  /// Rule 25 seam — null → prefs-backed Stage-1 store.
  final PrivacyCollectionRepository? repository;

  /// P12 sync — null → [stage1PrivacyCollectionSyncBus].
  final PrivacyCollectionSyncBus? syncBus;

  /// UI-018 effective monitoring sync — null → [stage1DesiredMonitoringSyncBus].
  final DesiredMonitoringSyncBus? monitoringSyncBus;

  final String monitoringChildId;
  final PlatformId monitoringPlatform;

  /// FS-004 domain seam — null hides Screen & Camera transparency.
  final ScreenCameraService? screenCamera;

  /// FS-007 domain seam — null hides Offline AI Safety child card.
  final OfflineAiSafetyService? offlineAi;

  @override
  State<WhatIsCollectedScreen> createState() => _WhatIsCollectedScreenState();
}

class _WhatIsCollectedScreenState extends State<WhatIsCollectedScreen> {
  late final ChildId _childId;
  late final PrivacyCollectionRepository _repository;
  late final PrivacyCollectionSyncBus _syncBus;
  late PrivacyCollectionPolicy _policy;
  var _loading = true;
  ScreenCameraDocument? _scDoc;
  ChildSafetyTransparency? _aiTransparency;

  @override
  void initState() {
    super.initState();
    _childId = widget.childId ?? ChildId('demo-child');
    _repository =
        widget.repository ??
        PrefsPrivacyCollectionRepository(
          stage1PrivacyCollectionPrefsStore,
          audit: stage1PrivacyCollectionAudit,
        );
    _syncBus = widget.syncBus ?? stage1PrivacyCollectionSyncBus;
    _policy = PrivacyCollectionPolicy.defaults(childId: _childId.value);
    _syncBus.addListener(_onBus);
    _load();
  }

  @override
  void dispose() {
    _syncBus.removeListener(_onBus);
    super.dispose();
  }

  void _onBus() {
    final next = _syncBus.policyOf(_childId.value);
    if (next == null) return;
    if (!mounted) return;
    setState(() => _policy = next);
  }

  Future<void> _load() async {
    final loaded = await _repository.load(_childId.value);
    ScreenCameraDocument? scDoc;
    var sc = widget.screenCamera;
    if (sc == null) {
      try {
        await Stage1ScreenCameraRuntime.ensureOpen();
        sc = Stage1ScreenCameraRuntime.service;
      } catch (_) {
        sc = null;
      }
    }
    if (sc != null) {
      try {
        scDoc = await sc.loadEffective(_childId);
      } catch (_) {
        scDoc = null;
      }
    }
    ChildSafetyTransparency? aiCard;
    var ai = widget.offlineAi;
    if (ai == null) {
      try {
        await Stage1OfflineAiSafetyRuntime.ensureOpen();
        ai = Stage1OfflineAiSafetyRuntime.service;
      } catch (_) {
        ai = null;
      }
    }
    if (ai != null) {
      try {
        final model = await ai.activeModel();
        final localOk = model != null && model.mayExecute;
        // KEEP/REFINE honesty: name configured tools even when local plane is
        // degraded; never silently omit the child transparency surface.
        aiCard = ai.childTransparency(
          searchConfigured: true,
          imageConfigured: true,
          screenshotConfigured: scDoc?.monitorScreenshots ?? false,
          localPlaneAvailable: localOk,
        );
      } catch (_) {
        aiCard = ai.childTransparency(
          searchConfigured: true,
          imageConfigured: true,
          screenshotConfigured: scDoc?.monitorScreenshots ?? false,
          localPlaneAvailable: false,
        );
      }
    }
    if (!mounted) return;
    _syncBus.hydrate(loaded);
    setState(() {
      _policy = loaded;
      _scDoc = scDoc;
      _aiTransparency = aiCard;
      _loading = false;
    });
  }

  String _scopeLabel(AppLocalizations l10n, CollectionScope scope) {
    return switch (scope) {
      CollectionScope.location => l10n.privacyScopeLocation,
      CollectionScope.screenTime => l10n.privacyScopeScreenTime,
      CollectionScope.webActivity => l10n.privacyScopeWebActivity,
      CollectionScope.communications => l10n.privacyScopeCommunications,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final enabled = _policy.enabledScopes;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.whatIsCollectedTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                key: WhatIsCollectedKeys.list,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    l10n.whatIsCollectedSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.ink2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BannerNote(
                    message: l10n.whatIsCollectedHonestyNote,
                    variant: BannerVariant.t,
                  ),
                  if (_policy.updatedAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      key: WhatIsCollectedKeys.updatedAt,
                      l10n.whatIsCollectedLastUpdated(
                        _policy.updatedAt!.toLocal().toIso8601String(),
                      ),
                      style: TextStyle(fontSize: 12, color: colors.ink2),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (enabled.isEmpty)
                    Text(
                      key: WhatIsCollectedKeys.empty,
                      l10n.whatIsCollectedEmpty,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    )
                  else
                    for (final scope in enabled)
                      ListTile(
                        key: WhatIsCollectedKeys.scopeLine(scope),
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.check_circle_outline,
                          color: colors.tealDeep,
                        ),
                        title: Text(
                          _scopeLabel(l10n, scope),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                      ),
                  const SizedBox(height: 28),
                  EffectiveMonitoringTransparency(
                    childId: widget.monitoringChildId,
                    platform: widget.monitoringPlatform,
                    syncBus: widget.monitoringSyncBus,
                  ),
                  // Single ListView child so FS-004 + FS-007 cards always mount
                  // together (sibling inflate after either card was dropping the next).
                  if (_aiTransparency != null || _scDoc != null) ...[
                    const SizedBox(height: 20),
                    Column(
                      key: WhatIsCollectedKeys.transparencyStack,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_aiTransparency != null)
                          AiSafetyChildTransparencyCard(
                            transparency: _aiTransparency!,
                          ),
                        if (_aiTransparency != null && _scDoc != null)
                          const SizedBox(height: 20),
                        if (_scDoc != null)
                          ScreenCameraTransparencyCard(
                            document: _scDoc!,
                            cameraOsPlane: CapabilityStatus.mockRemote,
                            capturePlane: CapabilityStatus.mockRemote,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
