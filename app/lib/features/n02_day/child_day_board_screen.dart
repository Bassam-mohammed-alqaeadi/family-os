import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_guard.dart';
import 'package:family_os/app/shell_tab_more_tools.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/mode_disclosure_card.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/time_warning_banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/modes/modes.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/core/screen_time/screen_time_runtime.dart';
import 'package:family_os/foundation_gate/child_screen_time_state_client.dart';
import 'package:family_os/foundation_gate/device_screen_time_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/core/screen_time/stage1_time_request_runtime.dart';
import 'package:family_os/features/n02_day/child_day_board_economy.dart';
import 'package:family_os/features/n02_day/child_day_board_kit.dart';
import 'package:family_os/features/n02_day/day_board_motion.dart';
import 'package:family_os/features/n09_smart_modes/modes_ux_bridge.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/foundation_gate/native_child_pairing_copy.dart';
import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';

/// Widget keys for SCR-CHD-004 / SET-019 / UI-005 / UI-017 acceptance.
abstract final class ChildDayBoardKeys {
  static const statusCard = Key('child_day_board_status_card');
  static const activeModeLabel = Key('child_day_board_active_mode');
  static const modeExpiry = Key('child_day_board_mode_expiry');
  static const idleStatus = Key('child_day_board_idle_status');
  static const remainingMinutes = Key('child_day_board_remaining');
  static const earnedExtensionNote = Key('child_day_board_earned_note');
  static const serverStale = Key('child_day_board_server_stale');
  static const warningBanner = Key('child_day_board_warning_banner');
  static const warningRequest = Key('child_day_board_warning_request');
  static const warningQuran = Key('child_day_board_warning_quran');
  static const warningChat = Key('child_day_board_warning_chat');
  static const warningSos = Key('child_day_board_warning_sos');
  static const emptyState = Key('child_day_board_empty');
  static const offlineBanner = Key('child_day_board_offline_banner');
  static const lastSyncedLine = Key('child_day_board_last_synced');

  /// UI-017 — decorative status pulse (reduce-motion gated).
  static const statusMotion = Key('child_day_board_status_motion');
  static const modeDisclosure = Key('child_day_board_mode_disclosure');

  /// Polish wave — the sections that turn the board into a control panel a child can read.
  static const heroCard = ChildDayBoardPolishKeys.heroCard;
  static const heroRing = ChildDayBoardPolishKeys.heroRing;
  static const heroTone = ChildDayBoardPolishKeys.heroTone;
  static const heroLegend = ChildDayBoardPolishKeys.heroLegend;
  static const routineCard = ChildDayBoardPolishKeys.routineCard;
  static const tasksCard = ChildDayBoardPolishKeys.tasksCard;
  static const tasksState = ChildDayBoardPolishKeys.tasksState;
  static const tasksOpenAll = ChildDayBoardPolishKeys.tasksOpenAll;
  static const safetyCard = ChildDayBoardPolishKeys.safetyCard;
  static const safetyHold = ChildDayBoardPolishKeys.safetyHold;
  static const touchpointsCard = ChildDayBoardPolishKeys.touchpointsCard;
}

/// SCR-CHD-004 — لوحة يومي (SET-019 + UI-005).
///
/// Streams: [SmartModeActivationBus] + [PolicySyncBus] so parent mode/cap
/// edits update same session after sync (P12 / Rule 23). Empty day → SHR-006.
/// Never plants prototype minutes or child display names.
class ChildDayBoardScreen extends StatefulWidget {
  ChildDayBoardScreen({
    super.key,
    ChildId? childId,
    this.screenTimeChildId,
    this.serverScreenTime,
    this.activationBus,
    this.syncBus,
    this.modes,
    this.timeRequestService,
    this.initialPolicy,
    this.emptyDay = false,
    this.showModeNotices = true,
    this.onEmptyAction,
    this.tasksBridge,
    this.safetyHoldDuration = const Duration(seconds: 3),
  }) : childId = childId ?? ChildId(SmartModePrefs.defaultChildId);

  /// Parametric child key (Rule 13 / G8) — never a display name.
  final ChildId childId;

  /// Same child in the Screen Time family-scoped key (policy mirror + time
  /// grants); null → [childId].
  final ChildId? screenTimeChildId;

  /// The child's own server-read screen time state client (via native proxy).
  final ChildScreenTimeStateClient? serverScreenTime;

  /// P12 smart-mode sync — null → [stage1SmartModeActivationBus].
  final SmartModeActivationBus? activationBus;

  /// P12 screen-time policy sync — null → [stage1PolicySyncBus].
  final PolicySyncBus? syncBus;

  /// FS-005 domain seam — when set, shows multi-mode disclosure (W-C01/02).
  final ModesService? modes;

  /// Optional inject — null → [ScreenTimeRuntime] / [Stage1TimeRequestRuntime].
  final TimeRequestService? timeRequestService;

  /// Optional seed before first bus event (tests / hydrate from repo).
  final ScreenTimePolicy? initialPolicy;

  /// When true, body is SHR-006 [AppEmptyState] (no planted day content).
  final bool emptyDay;

  /// Soft enter/exit [AppToast] (SET-019 notification).
  final bool showModeNotices;

  /// Optional CTA on empty state.
  final VoidCallback? onEmptyAction;

  /// The child's tasks and rewards, read from the family tasks server. Null → the authority
  /// the app bound at boot; a test may hand in its own.
  final ChildDayBoardTasksBridge? tasksBridge;

  /// How long the safety button must be held before it opens the emergency screen. Kept a
  /// parameter because a deliberate press is the point, and a test must be able to hold.
  final Duration safetyHoldDuration;

  @override
  State<ChildDayBoardScreen> createState() => _ChildDayBoardScreenState();
}

class _ChildDayBoardScreenState extends State<ChildDayBoardScreen>
    with WidgetsBindingObserver {
  late final SmartModeActivationBus _activationBus;
  late final PolicySyncBus _syncBus;
  StreamSubscription<ChildPolicyMirror>? _policySub;
  late SmartModeActivation _activation;
  late ChildPolicyMirror _mirror;
  TimeRequestService? _requestService;
  ModesEvaluation? _modesEval;
  ModesService? _bootstrappedModes;
  int _temporaryGrantRemaining = 0;
  BuiltInModeId? _prevModeId;
  var _prevActive = false;
  var _hasExplicitPolicy = false;
  late final ChildScreenTimeStateClient _serverClient =
      widget.serverScreenTime ?? childScreenTimeState();
  DeviceScreenTimeReading? _serverReading;
  var _serverStale = false;
  ChildDayBoardEconomy _economy = const ChildDayBoardEconomy.loading();
  late final ChildDayBoardTasksBridge _tasks =
      widget.tasksBridge ?? ChildDayBoardTasksBridge();
  DateTime _lastLoadedDate = DateTime.now();
  Timer? _midnightTimer;
  bool _isExplicitMirror(ChildPolicyMirror mirror) {
    return mirror.lastAppliedAt != null ||
        mirror.applyCount > 0 ||
        mirror.policy != ScreenTimePolicy.defaults() ||
        mirror.temporaryGrantRemaining > 0;
  }

  String get _childKey => widget.childId.value;

  ChildId get _screenTimeChild => widget.screenTimeChildId ?? widget.childId;

  @override
  void initState() {
    super.initState();
    _activationBus = widget.activationBus ?? stage1SmartModeActivationBus;
    _syncBus = widget.syncBus ?? stage1PolicySyncBus;
    _activation = _activationBus.activationOf(_childKey);
    _prevModeId = _activation.active ? _activation.modeId : null;
    _prevActive = _activation.active;
    _activationBus.addListener(_onActivationBus);
    if (widget.modes != null) {
      _loadModesEval();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bootstrapModes();
      });
    }

    if (widget.initialPolicy != null) {
      _syncBus.hydrate(_screenTimeChild, policy: widget.initialPolicy);
      _hasExplicitPolicy = true;
    }
    _mirror = _syncBus.mirrorOf(_screenTimeChild);
    if (_isExplicitMirror(_mirror)) {
      _hasExplicitPolicy = true;
    }
    _policySub = _syncBus.watch(_screenTimeChild).listen((next) {
      if (!mounted) return;
      setState(() {
        _mirror = next;
        if (_isExplicitMirror(next)) {
          _hasExplicitPolicy = true;
        }
      });
    });
    stage1TimeRequestDecisionBus.addListener(_onDecision);
    _bootstrapTimeRequests();
    _setupRevocationWatcher();
    WidgetsBinding.instance.addObserver(this);
    _lastLoadedDate = DateTime.now();
    _scheduleMidnightCheck();
    _loadServerState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  /// The tasks strip is a window onto the family server, so it loads on its own clock and
  /// says which of the five states it is in. A child's board must not wait on it, and must
  /// not turn a refusal into an empty day.
  Future<void> _loadTasks() async {
    try {
      final next = await _tasks.load(_childKey);
      if (!mounted) return;
      setState(() => _economy = next);
    } catch (error, stack) {
      debugPrint('CHD-004: tasks economy read failed — $error\n$stack');
      if (!mounted) return;
      setState(() => _economy = const ChildDayBoardEconomy.error());
    }
  }

  /// Hook for tests and for a parent's pull-to-refresh: re-read the child's economy.
  Future<void> loadTasks() => _loadTasks();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (now.day != _lastLoadedDate.day || now.month != _lastLoadedDate.month) {
        _lastLoadedDate = now;
        _scheduleMidnightCheck();
      }
      _loadServerState();
    }
  }

  void _scheduleMidnightCheck() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final duration = midnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(duration, () {
      if (!mounted) return;
      _lastLoadedDate = DateTime.now();
      _loadServerState();
      _scheduleMidnightCheck();
    });
  }

  Future<void> _loadServerState() async {
    try {
      final reading = await _serverClient.read();
      if (!mounted) return;
      setState(() {
        _serverReading = reading;
        _serverStale = false;
      });
    } on FoundationGateApiException {
      if (!mounted) return;
      // No previous answer: say nothing and keep the local behaviour.
      // A later failure must not silently pass the old number off as current.
      setState(() {
        _serverStale = _serverReading != null;
      });
    }
  }

  /// Hook to trigger server state refresh.
  Future<void> loadServerState() => _loadServerState();

  /// Pull-to-refresh answers both questions the board asks: what the phone counted, and what
  /// the family still owes the child.
  Future<void> _refreshAll() async {
    await Future.wait<void>([_loadServerState(), _loadTasks()]);
  }

  Timer? _revocationWatcher;

  void _setupRevocationWatcher() {
    NativeChildTelemetryBridge.addRevocationListener(_onDeviceRevocationTriggered);
    _revocationWatcher = Timer.periodic(const Duration(seconds: 4), (_) async {
      final status = await NativeChildTelemetryBridge.status();
      if (status.credentialRevoked) {
        _onDeviceRevocationTriggered();
      }
    });
  }

  void _onDeviceRevocationTriggered() {
    if (!mounted) return;
    _revocationWatcher?.cancel();
    _revocationWatcher = null;
    final copy = NativeChildPairingCopy.of(context);
    AppToast.show(context, message: copy.deviceUnlinkedFromFamily);
    CurrentRole.maybeNotifierOf(context)?.value = AppRole.father;
    context.go('/scr-shr-001');
  }

  Future<void> _bootstrapTimeRequests() async {
    if (widget.timeRequestService != null) {
      _requestService = widget.timeRequestService;
      await _refreshGrantRemaining();
      return;
    }
    try {
      // HOST-ROUTER-B — TimeRequest/Grant via ScreenTimeRuntime.
      await ScreenTimeRuntime.ensureOpen();
      _requestService =
          ScreenTimeRuntime.timeRequest ??
          await Stage1TimeRequestRuntime.ensureOpen();
      await _refreshGrantRemaining();
    } catch (e, st) {
      debugPrint(
        'DOM-ST-02C: TimeRequest Local KV bootstrap failed — '
        'no Memory Prefs fallback: $e\n$st',
      );
      if (!mounted) return;
      _requestService = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _revocationWatcher?.cancel();
    NativeChildTelemetryBridge.removeRevocationListener(_onDeviceRevocationTriggered);
    _activationBus.removeListener(_onActivationBus);
    _policySub?.cancel();
    stage1TimeRequestDecisionBus.removeListener(_onDecision);
    super.dispose();
  }

  void _onDecision() {
    _refreshGrantRemaining();
  }

  Future<void> _refreshGrantRemaining() async {
    final service = _requestService;
    if (service == null) return;
    final remaining = await service.activeGrantRemaining(_screenTimeChild);
    if (!mounted) return;
    setState(() => _temporaryGrantRemaining = remaining);
  }

  void _onActivationBus() {
    final next = _activationBus.activationOf(_childKey);
    if (!mounted) return;
    final wasActive = _prevActive;
    final wasMode = _prevModeId;
    setState(() => _activation = next);
    _prevActive = next.active;
    _prevModeId = next.active ? next.modeId : null;
    _loadModesEval();
    if (!widget.showModeNotices) return;
    _maybeToast(wasActive: wasActive, wasMode: wasMode, next: next);
  }

  Future<void> _bootstrapModes() async {
    try {
      await Stage1ModesRuntime.ensureOpen();
      if (!mounted) return;
      _bootstrappedModes = Stage1ModesRuntime.service;
      await _loadModesEval();
    } catch (_) {
      // Modes optional — activation bus + ST Prefs still drive the board.
    }
  }

  Future<void> _loadModesEval() async {
    final modes = widget.modes ?? _bootstrappedModes;
    if (modes == null) return;
    try {
      final eval = await modes.evaluateChild(widget.childId);
      if (!mounted) return;
      setState(() => _modesEval = eval);
    } catch (_) {
      // Domain optional — keep activation bus path.
    }
  }

  Map<String, String> _modeDocLabels(AppLocalizations l10n) {
    return {
      for (final id in BuiltInModeId.values)
        ModesUxBridge.modeDocumentId(id): _modeLabel(l10n, id),
    };
  }

  void _maybeToast({
    required bool wasActive,
    required BuiltInModeId? wasMode,
    required SmartModeActivation next,
  }) {
    final l10n = AppLocalizations.of(context);
    if (next.active && next.modeId != null) {
      if (!wasActive || wasMode != next.modeId) {
        AppToast.show(
          context,
          message: l10n.childDayBoardModeEnter(_modeLabel(l10n, next.modeId!)),
        );
      }
      return;
    }
    if (wasActive && wasMode != null) {
      AppToast.show(
        context,
        message: l10n.childDayBoardModeExit(_modeLabel(l10n, wasMode)),
      );
    }
  }

  String _modeLabel(AppLocalizations l10n, BuiltInModeId id) => switch (id) {
    BuiltInModeId.sleep => l10n.smartModeSleep,
    BuiltInModeId.school => l10n.smartModeSchool,
    BuiltInModeId.study => l10n.smartModeStudy,
    BuiltInModeId.ramadan => l10n.smartModeRamadan,
    BuiltInModeId.exams => l10n.smartModeExams,
    BuiltInModeId.vacation => l10n.smartModeVacation,
    BuiltInModeId.custom => l10n.smartModeCustom,
  };

  Color _modeTint(FamilyColors colors, BuiltInModeId id) => switch (id) {
    BuiltInModeId.sleep => colors.p100,
    BuiltInModeId.school => colors.sky.withValues(alpha: 0.25),
    BuiltInModeId.study => colors.amber100,
    BuiltInModeId.ramadan => colors.teal100,
    BuiltInModeId.exams => colors.coral100,
    BuiltInModeId.vacation => colors.mint100,
    BuiltInModeId.custom => colors.p50,
  };

  Color _modeBorder(FamilyColors colors, BuiltInModeId id) => switch (id) {
    BuiltInModeId.sleep => colors.p500,
    BuiltInModeId.school => colors.sky,
    BuiltInModeId.study => colors.amber,
    BuiltInModeId.ramadan => colors.teal,
    BuiltInModeId.exams => colors.coral,
    BuiltInModeId.vacation => colors.mint,
    BuiltInModeId.custom => colors.p400,
  };

  String _formatExpiry(DateTime expiresAt) {
    final local = expiresAt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatSyncedAt(DateTime at) {
    final local = at.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _showRemaining {
    if (widget.emptyDay) return false;
    if (_serverReading != null) return true;
    return _hasExplicitPolicy && !widget.emptyDay;
  }

  bool get _childOffline => !_syncBus.isChildOnline(_screenTimeChild);

  int get _effectiveRemaining =>
      _mirror.dailyRemaining + _temporaryGrantRemaining;

  /// The minutes economy the hero ring draws, assembled from whichever answer this board has.
  ChildTimeRingModel get _ringModel {
    final reading = _serverReading;
    final policy = _mirror.policy;
    var earned = 0;
    for (final wallet in policy.wallets) {
      earned += wallet.earnedMinutes.inMinutes;
    }
    final grant = _temporaryGrantRemaining > 0
        ? _temporaryGrantRemaining
        : _mirror.temporaryGrantRemaining;
    return ChildTimeRingModel.resolve(
      serverAnswered: reading != null,
      serverRemainingMinutes: reading?.remainingMinutes,
      serverCapMinutes: reading?.capMinutes,
      serverUsedMinutes: reading?.countableUsedMinutes ?? 0,
      serverGrantedMinutes: reading?.grantedMinutes ?? 0,
      serverEarnedExtend:
          reading?.earnedMinutesExtendLimit ?? policy.earnedMinutesExtendLimit,
      mirrorCapMinutes: policy.dailyCapMinutes,
      mirrorUsedMinutes: policy.usedMinutesToday,
      mirrorGrantRemaining: grant,
      mirrorEarnedMinutes: earned,
      mirrorEarnedExtend: policy.earnedMinutesExtendLimit,
      hasExplicitPolicy: _hasExplicitPolicy,
      bedtimeNow:
          _routinePhase == ChildRoutinePhase.sleep ||
          _routinePhase == ChildRoutinePhase.windDown,
    );
  }

  ChildRoutinePhase get _routinePhase => ChildRoutinePhaseResolver.resolve(
    modeActive: _activation.active && _activation.modeId != null,
    modeId: _activation.modeId,
    serverReasonCode: _serverReading?.reasonCode,
    schedules: _mirror.schedules,
  );

  /// The one sentence the ring wears. It is a conclusion about minutes the board already
  /// has, never encouragement the widget invented: "no limit" says the server said so, and
  /// a spent day says so calmly.
  String _toneLine(AppLocalizations l10n, ChildTimeRingModel ring) {
    if (ring.noLimit) return l10n.childDayBoardTimeHeroNoLimit;
    return switch (ring.tone) {
      ChildTimeRingTone.plenty => l10n.childDayBoardTimeHeroAbundant,
      ChildTimeRingTone.nearEnd => l10n.childDayBoardTimeHeroNearEnd,
      ChildTimeRingTone.depleted => l10n.childDayBoardTimeHeroDepleted,
      ChildTimeRingTone.bedtime => l10n.childDayBoardTimeHeroWindDown,
      ChildTimeRingTone.unknown => l10n.childDayBoardTimeHeroLoading,
    };
  }

  String _taskStatusLabel(AppLocalizations l10n, ChildEarnTaskStatus status) =>
      switch (status) {
        ChildEarnTaskStatus.notSent => l10n.childDayBoardTasksStatusPending,
        ChildEarnTaskStatus.awaitingGuardian =>
          l10n.childDayBoardTasksStatusClaimed,
        ChildEarnTaskStatus.rewarded => l10n.childDayBoardTasksStatusConfirmed,
        ChildEarnTaskStatus.declined => l10n.childDayBoardTasksStatusDeclined,
        ChildEarnTaskStatus.closed => l10n.childDayBoardTasksStatusArchived,
      };

  String _economyStateMessage(
    AppLocalizations l10n,
    ChildDayBoardEconomyPhase phase,
  ) => switch (phase) {
    ChildDayBoardEconomyPhase.loading => l10n.childDayBoardTasksLoading,
    ChildDayBoardEconomyPhase.empty => l10n.childDayBoardTasksEmpty,
    ChildDayBoardEconomyPhase.noServer => l10n.childDayBoardTasksUnavailable,
    ChildDayBoardEconomyPhase.error => l10n.childDayBoardTasksRefused,
    ChildDayBoardEconomyPhase.ready => l10n.childDayBoardTasksSubtitle,
  };

  /// The shortcuts a child should not have to hunt for.
  ///
  /// Every one of them is a route this app already has, and the two that reach a parent reach
  /// the family thread and the thread list — the surfaces that know which guardians are
  /// actually there. A board that invented "chat with dad" would be naming a thread the
  /// server never created, and a child tapping a button that goes nowhere at 9pm is worse
  /// than a board with one fewer chip.
  List<FamilyTouchpoint> _touchpoints(AppLocalizations l10n) {
    return [
      FamilyTouchpoint(
        id: 'family',
        label: l10n.childDayBoardTouchpointsFamilyThread,
        glyph: Icons.forum_rounded,
        onTap: () => context.push(
          Uri(
            path: screenPath('SCR-CHD-008'),
            queryParameters: const <String, String>{'chatWith': 'family'},
          ).toString(),
        ),
      ),
      FamilyTouchpoint(
        id: 'chats',
        label: l10n.childDayBoardTouchpointsAllChats,
        glyph: Icons.chat_rounded,
        onTap: () => context.push(screenPath('SCR-CHD-007')),
      ),
      FamilyTouchpoint(
        id: 'ask',
        label: l10n.childDayBoardTouchpointsAskTime,
        glyph: Icons.more_time_rounded,
        onTap: () => context.push(screenPath('SCR-CHD-020')),
      ),
      FamilyTouchpoint(
        id: 'quran',
        label: l10n.childDayBoardTouchpointsQuran,
        glyph: Icons.menu_book_rounded,
        onTap: () => context.push(screenPath('SCR-CHD-025')),
      ),
      FamilyTouchpoint(
        id: 'wallet',
        label: l10n.childDayBoardTouchpointsWallet,
        glyph: Icons.savings_rounded,
        onTap: () => context.push(screenPath('SCR-CHD-019')),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final active = _activation.active && _activation.modeId != null;
    final modeId = _activation.modeId;
    final ring = _ringModel;
    final remaining = _serverReading != null
        ? _serverReading!.remainingMinutes
        : (_hasExplicitPolicy ? _effectiveRemaining : null);

    return Scaffold(
      backgroundColor: colors.childBg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.childDayBoardTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: widget.emptyDay
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
                  children: [
                    AppEmptyState(
                      key: ChildDayBoardKeys.emptyState,
                      contextName: l10n.childDayBoardTitle,
                      onAction: widget.onEmptyAction,
                    ),
                    const ShellTabMoreTools(tabId: 'myday'),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
                  children: [
                    if (_childOffline) ...[
                      BannerNote(
                        key: ChildDayBoardKeys.offlineBanner,
                        message: l10n.childDayBoardOfflineBanner(
                          _mirror.lastAppliedAt != null
                              ? _formatSyncedAt(_mirror.lastAppliedAt!)
                              : l10n.dayBoardSyncUnknown,
                        ),
                        variant: BannerVariant.a,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      l10n.childDayBoardSubtitle,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.ink2,
                        height: 1.5,
                      ),
                    ),
                    if (_mirror.lastAppliedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        key: ChildDayBoardKeys.lastSyncedLine,
                        l10n.childDayBoardLastSynced(
                          _formatSyncedAt(_mirror.lastAppliedAt!),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.ink2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_showRemaining) ...[
                      const SizedBox(height: 14),
                      if (_serverStale) ...[
                        BannerNote(
                          key: ChildDayBoardKeys.serverStale,
                          message: l10n.screenTimeServerUnreachable,
                          variant: BannerVariant.a,
                        ),
                        const SizedBox(height: 10),
                      ],
                      ChildTimeHeroRing(
                        model: ring,
                        title: l10n.childDayBoardTimeHeroTitle,
                        remainingLabel: l10n.childTimeMirrorRemainingLabel,
                        remainingKey: ChildDayBoardKeys.remainingMinutes,
                        remainingValue: _serverReading != null
                            ? (_serverReading!.remainingMinutes == null
                                  ? l10n.childDayBoardNoLimit
                                  : l10n.childTimeMirrorRemainingMinutes(
                                      _serverReading!.remainingMinutes!,
                                    ))
                            : l10n.childTimeMirrorRemainingMinutes(
                                _effectiveRemaining,
                              ),
                        baseLabel: l10n.childDayBoardTimeHeroBase,
                        earnedLabel: l10n.childDayBoardTimeHeroEarned,
                        grantLabel: l10n.childDayBoardTimeHeroGrant,
                        toneLine: _toneLine(l10n, ring),
                        semanticsLabel: ring.usedFraction == null
                            ? l10n.childDayBoardTimeHeroNoLimit
                            : l10n.childDayBoardTimeHeroRingSemantics(
                                (ring.usedFraction! * 100).round(),
                              ),
                        pulse:
                            remaining != null &&
                            remaining >= 0 &&
                            remaining <= 5,
                        extendNote: Text(
                          key: ChildDayBoardKeys.earnedExtensionNote,
                          (_serverReading?.earnedMinutesExtendLimit ??
                                  _mirror.policy.earnedMinutesExtendLimit)
                              ? l10n.childDayBoardEarnedExtendsOn
                              : l10n.childDayBoardEarnedExtendsOff,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.ink2,
                            height: 1.45,
                          ),
                        ),
                        footer: remaining != null &&
                                TimeWarningBanner.shouldShow(remaining)
                            ? _warningFooter(l10n, colors, remaining)
                            : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    DayBoardMotionPulse(
                      key: ChildDayBoardKeys.statusMotion,
                      preferredDuration: const Duration(milliseconds: 1400),
                      enabled: active,
                      mode: DayBoardMotionPulseMode.opacity,
                      child: Container(
                        key: ChildDayBoardKeys.statusCard,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: active ? _modeTint(colors, modeId!) : colors.surface,
                          borderRadius: BorderRadius.circular(radii.cardChild),
                          border: Border.all(
                            color: active
                                ? _modeBorder(colors, modeId!)
                                : colors.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: active
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _ModeGlyph(modeId: modeId!),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          key: ChildDayBoardKeys.activeModeLabel,
                                          l10n.childDayBoardActiveStatus(
                                            _modeLabel(l10n, modeId),
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: colors.ink,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_activation.expiresAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      key: ChildDayBoardKeys.modeExpiry,
                                      l10n.childDayBoardModeExpiry(
                                        _formatExpiry(_activation.expiresAt!),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.ink2,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Text(
                                key: ChildDayBoardKeys.idleStatus,
                                l10n.childDayBoardIdleStatus,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colors.ink2,
                                  height: 1.35,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ChildRoutineBadgeCard(
                      phase: _routinePhase,
                      title: l10n.childDayBoardRoutineTitle,
                      hint: l10n.childDayBoardRoutineHint,
                      sleepLabel: l10n.childDayBoardRoutineSleep,
                      schoolLabel: l10n.childDayBoardRoutineSchool,
                      freeLabel: l10n.childDayBoardRoutineFree,
                      windDownLabel: l10n.childDayBoardRoutineWindDown,
                    ),
                    if (_modesEval != null) ...[
                      const SizedBox(height: 12),
                      KeyedSubtree(
                        key: ChildDayBoardKeys.modeDisclosure,
                        child: ModeDisclosureCard(
                          evaluation: _modesEval!,
                          labelsByModeId: _modeDocLabels(l10n),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ChildEarnTasksCard(
                      economy: _economy,
                      title: l10n.childDayBoardTasksTitle,
                      subtitle: l10n.childDayBoardTasksSubtitle,
                      stateMessage: (phase) => _economyStateMessage(l10n, phase),
                      pointsLabel: (points) =>
                          l10n.childDayBoardTasksPoints(points),
                      statusLabel: (status) => _taskStatusLabel(l10n, status),
                      openAllLabel: l10n.childDayBoardTasksOpenAll,
                      onOpenAll: () => context.push(screenPath('SCR-CHD-022')),
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      key: ChildDayBoardKeys.safetyCard,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(radii.cardChild),
                        border: Border.all(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.childDayBoardSafetyTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: colors.ink,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChildSafetyHoldButton(
                              holdDuration: widget.safetyHoldDuration,
                              onHoldCompleted:
                                  () => context.push(screenPath('SCR-CHD-005')),
                              title: l10n.childDayBoardSafetyReady,
                              instruction: l10n.childDayBoardSafetyHold,
                              releasedMessage: l10n.childDayBoardSafetyReleased,
                              progressLabel: (seconds) =>
                                  l10n.childDayBoardSafetyProgress(seconds),
                              semanticsLabel: l10n.childDayBoardSafetySemantics,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FamilyTouchpointStrip(
                      title: l10n.childDayBoardTouchpointsTitle,
                      subtitle: l10n.childDayBoardTouchpointsSubtitle,
                      points: _touchpoints(l10n),
                    ),
                    const ShellTabMoreTools(tabId: 'myday'),
                  ],
                ),
        ),
      ),
    );
  }

  /// The protected actions that stay open when the day runs out. Same five keys the S-3
  /// acceptance names, now inside the ring so a child sees the warning beside the number it
  /// describes instead of below a screen of chrome.
  Widget _warningFooter(
    AppLocalizations l10n,
    FamilyColors colors,
    int remainingMinutes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TimeWarningBanner(
          key: ChildDayBoardKeys.warningBanner,
          remainingMinutes: remainingMinutes,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            PrimaryBtn(
              key: ChildDayBoardKeys.warningRequest,
              label: l10n.childTimeRequestSubmitCta,
              variant: PrimaryBtnVariant.teal,
              onPressed: () => context.push(screenPath('SCR-CHD-020')),
            ),
            PrimaryBtn(
              key: ChildDayBoardKeys.warningQuran,
              label: l10n.timeExpiryQuranCta,
              variant: PrimaryBtnVariant.sec,
              onPressed: () => context.push(screenPath('SCR-CHD-025')),
            ),
            PrimaryBtn(
              key: ChildDayBoardKeys.warningChat,
              label: l10n.timeExpiryChatCta,
              variant: PrimaryBtnVariant.sec,
              onPressed: () => context.push(screenPath('SCR-CHD-008')),
            ),
            PrimaryBtn(
              key: ChildDayBoardKeys.warningSos,
              label: l10n.timeExpirySosCta,
              variant: PrimaryBtnVariant.coral,
              onPressed: () => context.push(screenPath('SCR-CHD-005')),
            ),
          ],
        ),
      ],
    );
  }
}

/// The mode's own mark, so an active mode is recognised before it is read.
///
/// It is an icon and nothing else: the words beside it are the ARB's, and the pairing of the
/// two is the only place a child learns which glyph means sleep.
class _ModeGlyph extends StatelessWidget {
  const _ModeGlyph({required this.modeId});

  final BuiltInModeId modeId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final (icon, tint) = switch (modeId) {
      BuiltInModeId.sleep => (Icons.nights_stay, colors.p500),
      BuiltInModeId.school => (Icons.school, colors.sky),
      BuiltInModeId.study => (Icons.menu_book, colors.amber),
      BuiltInModeId.ramadan => (Icons.mosque, colors.teal),
      BuiltInModeId.exams => (Icons.assignment, colors.coral),
      BuiltInModeId.vacation => (Icons.emoji_people, colors.mint),
      BuiltInModeId.custom => (Icons.tune, colors.p400),
    };
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        border: Border.all(color: tint.withValues(alpha: 0.5)),
      ),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}
