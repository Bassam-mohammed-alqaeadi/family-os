import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/ai_safety_ticket_review_panel.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/screen_camera_parent_panel.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/offline_ai_safety/offline_ai_safety.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/screen_camera/screen_camera.dart';
import 'package:family_os/features/n08_platform/smart_alerts_models.dart';
import 'package:family_os/features/n08_platform/smart_alerts_repository.dart';

/// Widget keys for SCR-FAT-065 acceptance.
abstract final class SmartAlertsKeys {
  static const screen = Key('smart_alerts_screen');
  static const loading = Key('smart_alerts_loading');
  static const empty = Key('smart_alerts_empty');
  static const body = Key('smart_alerts_body');
  static const honestyBanner = Key('smart_alerts_honesty');
  static const scPolicyBanner = Key('smart_alerts_sc_policy');
  static const fs007Banner = Key('smart_alerts_fs007');
  static const alertsList = Key('smart_alerts_list');
  static const toolsList = Key('smart_alerts_tools');
  static const detectCard = Key('smart_alerts_detect');
  static const settingsCta = Key('smart_alerts_settings');
  static const childLean = Key('smart_alerts_child_lean');
  static const sosIconCta = Key('smart_alerts_sos_icon');

  static Key alert(String id) => Key('smart_alerts_row_$id');
  static Key toolSwitch(String id) => Key('smart_alerts_tool_$id');
}

/// SCR-FAT-065 — التنبيهات الذكية (smart watch alerts hub).
///
/// Prototype FAT-065 · amber not red · describes behavior not child ·
/// Arabizi+dialect unique claim · tools toggles · →066/067 · mother levels ·
/// P-4 SOS · Rule 12/23.
class SmartAlertsScreen extends StatefulWidget {
  const SmartAlertsScreen({
    super.key,
    this.repository,
    this.screenCamera,
    this.offlineAi,
    this.childId,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final SmartAlertsRepository? repository;

  /// FS-004 domain seam — null skips Screen & Camera panel (Stage-1 tools only).
  final ScreenCameraService? screenCamera;

  /// FS-007 domain seam — null skips Offline AI Safety ticket panel.
  final OfflineAiSafetyService? offlineAi;

  /// Child scope for FS-004 policy when [screenCamera] is set.
  final ChildId? childId;

  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<SmartAlertsScreen> createState() => _SmartAlertsScreenState();
}

class _SmartAlertsScreenState extends State<SmartAlertsScreen> {
  late SmartAlertsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  SmartAlertsSnapshot _snap = const SmartAlertsSnapshot();
  ScreenCameraDocument? _scDoc;
  ScreenCameraService? _sc;
  OfflineAiSafetyService? _ai;
  List<SafetyTicket> _aiTickets = const [];
  Map<String, SafetySignal> _aiSignals = const {};
  String? _selectedTicketId;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _canEditTools {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  bool get _canReviewAi {
    final actor = _aiActor;
    return actor.canReviewTicket;
  }

  SafetyAiActor get _aiActor {
    if (_role == AppRole.father) return const SafetyAiActor.father();
    if (_role == AppRole.mother) {
      return SafetyAiActor.mother(widget.motherLevel);
    }
    return const SafetyAiActor.child();
  }

  ScreenCameraActor get _scActor {
    if (_role == AppRole.father) return const ScreenCameraActor.father();
    return ScreenCameraActor.mother(widget.motherLevel);
  }

  ChildId get _childId => widget.childId ?? ChildId('demo-child');

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1SmartAlertsRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    _sc = widget.screenCamera;
    _ai = widget.offlineAi;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _refreshAiTickets(OfflineAiSafetyService ai) async {
    final tickets = await ai.listTickets();
    final signals = await ai.listSignals();
    final map = <String, SafetySignal>{
      for (final s in signals) s.id: s,
    };
    if (!mounted) return;
    setState(() {
      _ai = ai;
      _aiTickets = tickets;
      _aiSignals = map;
      if (_selectedTicketId != null &&
          !tickets.any((t) => t.id == _selectedTicketId && t.isOpen)) {
        _selectedTicketId = null;
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.load();
    var sc = widget.screenCamera ?? _sc;
    if (sc == null && _isParent) {
      try {
        await Stage1ScreenCameraRuntime.ensureOpen();
        sc = Stage1ScreenCameraRuntime.service;
      } catch (_) {
        sc = null;
      }
    }
    var ai = widget.offlineAi ?? _ai;
    if (ai == null && _isParent) {
      try {
        await Stage1OfflineAiSafetyRuntime.ensureOpen();
        ai = Stage1OfflineAiSafetyRuntime.service;
      } catch (_) {
        ai = null;
      }
    }
    if (ai != null) {
      try {
        await _refreshAiTickets(ai);
      } catch (_) {
        // Keep alerts UI even if AI store fails.
      }
    }
    if (sc != null) {
      try {
        final scDoc = await sc.loadEffective(_childId);
        final tools = [
          for (final t in snap.tools)
            if (t.id == 'screenshot')
              SmartWatchTool(
                id: t.id,
                titleKey: t.titleKey,
                subtitleKey: t.subtitleKey,
                enabled: scDoc.monitorScreenshots,
              )
            else
              t,
        ];
        if (!mounted) return;
        setState(() {
          _sc = sc;
          _scDoc = scDoc;
          _snap = SmartAlertsSnapshot(alerts: snap.alerts, tools: tools);
          _loading = false;
        });
        return;
      } catch (_) {
        // Fall through to alerts-only snap.
      }
    }
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _aiResolve(String ticketId) async {
    final ai = _ai;
    if (ai == null || !_canReviewAi) return;
    await ai.closeTicket(
      ticketId: ticketId,
      actor: _aiActor,
      actorId: _role.name,
      closeStatus: SafetyTicketStatus.resolved,
    );
    await _refreshAiTickets(ai);
  }

  Future<void> _aiDismissFp(String ticketId) async {
    final ai = _ai;
    if (ai == null || !_canReviewAi) return;
    await ai.closeTicket(
      ticketId: ticketId,
      actor: _aiActor,
      actorId: _role.name,
      closeStatus: SafetyTicketStatus.dismissedFp,
    );
    await _refreshAiTickets(ai);
  }

  Future<void> _aiSuggest(String ticketId) async {
    final ai = _ai;
    if (ai == null || !_canReviewAi) return;
    await ai.createSuggestion(
      ticketId: ticketId,
      target: SafetySuggestionTarget.webFilter,
      summary: 'Suggest keyword/URL review',
      actor: _aiActor,
    );
    await _refreshAiTickets(ai);
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

  String _alertTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'withdrawal' => l10n.smartAlertsAlertWithdrawal,
      'arabizi' => l10n.smartAlertsAlertArabizi,
      _ => l10n.smartAlertsAlertWithdrawal,
    };
  }

  String _alertSub(AppLocalizations l10n, String key) {
    return switch (key) {
      'withdrawalSub' => l10n.smartAlertsAlertWithdrawalSub,
      'arabiziSub' => l10n.smartAlertsAlertArabiziSub,
      _ => l10n.smartAlertsAlertWithdrawalSub,
    };
  }

  String _tag(AppLocalizations l10n, String key) {
    return switch (key) {
      'new' => l10n.smartAlertsTagNew,
      'yesterday' => l10n.smartAlertsTagYesterday,
      _ => l10n.smartAlertsTagNew,
    };
  }

  String _toolTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'searchScan' => l10n.smartAlertsToolSearchScan,
      'imageScan' => l10n.smartAlertsToolImageScan,
      'screenshot' => l10n.smartAlertsToolScreenshot,
      'offline' => l10n.smartAlertsToolOffline,
      _ => l10n.smartAlertsToolSearchScan,
    };
  }

  String _toolSub(AppLocalizations l10n, String key) {
    return switch (key) {
      'searchScanSub' => l10n.smartAlertsToolSearchScanSub,
      'imageScanSub' => l10n.smartAlertsToolImageScanSub,
      'screenshotSub' => l10n.smartAlertsToolScreenshotSub,
      'offlineSub' => l10n.smartAlertsToolOfflineSub,
      _ => l10n.smartAlertsToolSearchScanSub,
    };
  }

  Future<void> _toggleTool(SmartWatchTool tool, bool value) async {
    if (!_canEditTools || _busy) return;
    setState(() => _busy = true);
    if (tool.id == 'screenshot' && _sc != null) {
      try {
        final doc = await _sc!.setScreenshotMonitoring(
          childId: _childId,
          enabled: value,
          monitoredPackageIds: _scDoc?.monitoredPackageIds ?? const {},
          actor: _scActor,
        );
        final snap = await _repo.setToolEnabled(tool.id, value);
        if (!mounted) return;
        setState(() {
          _scDoc = doc;
          _snap = snap;
          _busy = false;
        });
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _busy = false);
        return;
      }
    }
    final snap = await _repo.setToolEnabled(tool.id, value);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
  }

  Future<void> _saveSc(
    ScreenCameraDocument Function(ScreenCameraDocument) edit,
  ) async {
    final sc = _sc;
    final current = _scDoc;
    if (sc == null || current == null || !_canEditTools || _busy) return;
    setState(() => _busy = true);
    try {
      final next = await sc.saveChildPolicy(
        childId: _childId,
        draft: edit(current),
        actor: _scActor,
      );
      if (!mounted) return;
      // Keep screenshot tool row in sync.
      final snap = await _repo.setToolEnabled(
        'screenshot',
        next.monitorScreenshots,
      );
      if (!mounted) return;
      setState(() {
        _scDoc = next;
        _snap = snap;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: SmartAlertsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.smartAlertsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: SmartAlertsKeys.sosIconCta,
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
    if (_isChild) {
      return AppEmptyState(
        key: SmartAlertsKeys.childLean,
        title: l10n.smartAlertsChildLeanTitle,
        message: l10n.smartAlertsChildLeanMessage,
      );
    }
    if (!_isParent) {
      return AppEmptyState(
        key: SmartAlertsKeys.childLean,
        title: l10n.smartAlertsChildLeanTitle,
        message: l10n.smartAlertsChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: SmartAlertsKeys.loading,
        child: Semantics(
          label: l10n.smartAlertsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    // FS-007 KEEP/REFINE: open tickets (or an injected offlineAi seam) keep the
    // review surface alive on an empty alerts inventory. Auto Stage1 AI with
    // zero open tickets must not swallow the classic empty → FAT-003 CTA.
    final openAiTickets = _aiTickets.where((t) => t.isOpen).toList();
    if (_snap.isEmpty &&
        openAiTickets.isEmpty &&
        widget.offlineAi == null) {
      return AppEmptyState(
        key: SmartAlertsKeys.empty,
        title: l10n.smartAlertsEmptyTitle,
        message: l10n.smartAlertsEmptyMessage,
        actionLabel: l10n.smartAlertsEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    return SingleChildScrollView(
      key: SmartAlertsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_snap.isEmpty)
            BannerNote(
              key: SmartAlertsKeys.honestyBanner,
              variant: BannerVariant.t,
              message: l10n.smartAlertsEmptyMessage,
            )
          else
            BannerNote(
              key: SmartAlertsKeys.honestyBanner,
              variant: BannerVariant.t,
              message: l10n.smartAlertsHonestyBanner,
            ),
          if (_sc != null) ...[
            const SizedBox(height: 10),
            BannerNote(
              key: SmartAlertsKeys.scPolicyBanner,
              variant: BannerVariant.a,
              message: l10n.fs004SmartAlertsPolicyOwned,
            ),
          ],
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: colors.amber),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Column(
                        key: SmartAlertsKeys.alertsList,
                        children: [
                          for (final a in _snap.alerts)
                            ListTile(
                              key: SmartAlertsKeys.alert(a.id),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              title: Text(
                                _alertTitle(l10n, a.titleKey),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: colors.ink,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Text(
                                _alertSub(l10n, a.subtitleKey),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.ink2,
                                ),
                              ),
                              trailing: Tag(
                                label: _tag(l10n, a.tagKey),
                                variant: TagVariant.a,
                              ),
                              onTap: () => _go(a.detailScreenId),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.smartAlertsWatchHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _watchRow(
                    colors,
                    l10n.smartAlertsWatchKeywords,
                    l10n.smartAlertsWatchKeywordsSub,
                  ),
                  _watchRow(
                    colors,
                    l10n.smartAlertsWatchEmotions,
                    l10n.smartAlertsWatchEmotionsSub,
                  ),
                  _watchRow(
                    colors,
                    l10n.smartAlertsWatchImages,
                    l10n.smartAlertsWatchImagesSub,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                    child: Text(
                      l10n.smartAlertsToolsHeading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Column(
                    key: SmartAlertsKeys.toolsList,
                    children: [
                      for (final t in _snap.tools)
                        if (!(t.id == 'screenshot' && _scDoc != null))
                          SwitchListTile(
                            key: SmartAlertsKeys.toolSwitch(t.id),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            title: Text(
                              _toolTitle(l10n, t.titleKey),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.ink,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text(
                              _toolSub(l10n, t.subtitleKey),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.ink2,
                              ),
                            ),
                            value: t.enabled,
                            onChanged: _canEditTools
                                ? (v) => _toggleTool(t, v)
                                : null,
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_scDoc != null) ...[
            const SizedBox(height: 12),
            ScreenCameraParentPanel(
              document: _scDoc!,
              canConfigure: _canEditTools,
              cameraOsPlane: CapabilityStatus.mockRemote,
              capturePlane: CapabilityStatus.mockRemote,
              onCameraOsChanged: (v) =>
                  _saveSc((d) => d.copyWith(preventCameraOs: v)),
              onCaptureChanged: (v) =>
                  _saveSc((d) => d.copyWith(preventCapture: v)),
              onMonitorChanged: (v) =>
                  _saveSc((d) => d.copyWith(monitorScreenshots: v)),
              onProtectChanged: (v) =>
                  _saveSc((d) => d.copyWith(protectSensitiveSurfaces: v)),
            ),
          ],
          if (_ai != null) ...[
            const SizedBox(height: 12),
            Text(
              key: SmartAlertsKeys.fs007Banner,
              l10n.fs007SmartAlertsEntry,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 8),
            AiSafetyTicketReviewPanel(
              tickets: _aiTickets,
              signalsById: _aiSignals,
              canReview: _canReviewAi,
              selectedTicketId: _selectedTicketId,
              onSelect: (id) => setState(() => _selectedTicketId = id),
              onResolve: _aiResolve,
              onDismissFp: _aiDismissFp,
              onSuggestWebFilter: _aiSuggest,
            ),
          ],
          const SizedBox(height: 12),
          DecoratedBox(
            key: SmartAlertsKeys.detectCard,
            decoration: BoxDecoration(
              color: colors.p50,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.smartAlertsDetectHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.smartAlertsDetectBody,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: SmartAlertsKeys.settingsCta,
            label: l10n.smartAlertsSettingsCta,
            variant: PrimaryBtnVariant.ghost,
            onPressed: () => _go('SCR-FAT-067'),
          ),
        ],
      ),
    );
  }

  Widget _watchRow(FamilyColors colors, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                    fontSize: 13,
                  ),
                ),
                Text(sub, style: TextStyle(fontSize: 12, color: colors.ink2)),
              ],
            ),
          ),
          Tag(
            label: AppLocalizations.of(context).smartAlertsTagActive,
            variant: TagVariant.g,
          ),
        ],
      ),
    );
  }
}
