import 'dart:async';

import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n02_day/day_board_motion.dart';

/// Widget keys for SCR-CHD-004 / SET-019 / UI-005 / UI-017 acceptance.
abstract final class ChildDayBoardKeys {
  static const statusCard = Key('child_day_board_status_card');
  static const activeModeLabel = Key('child_day_board_active_mode');
  static const modeExpiry = Key('child_day_board_mode_expiry');
  static const idleStatus = Key('child_day_board_idle_status');
  static const remainingMinutes = Key('child_day_board_remaining');
  static const emptyState = Key('child_day_board_empty');
  static const offlineBanner = Key('child_day_board_offline_banner');
  static const lastSyncedLine = Key('child_day_board_last_synced');

  /// UI-017 — decorative status pulse (reduce-motion gated).
  static const statusMotion = Key('child_day_board_status_motion');
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
    this.activationBus,
    this.syncBus,
    this.initialPolicy,
    this.emptyDay = false,
    this.showModeNotices = true,
    this.onEmptyAction,
  }) : childId = childId ?? ChildId(SmartModePrefs.defaultChildId);

  /// Parametric child key (Rule 13 / G8) — never a display name.
  final ChildId childId;

  /// P12 smart-mode sync — null → [stage1SmartModeActivationBus].
  final SmartModeActivationBus? activationBus;

  /// P12 screen-time policy sync — null → [stage1PolicySyncBus].
  final PolicySyncBus? syncBus;

  /// Optional seed before first bus event (tests / hydrate from repo).
  final ScreenTimePolicy? initialPolicy;

  /// When true, body is SHR-006 [AppEmptyState] (no planted day content).
  final bool emptyDay;

  /// Soft enter/exit [AppToast] (SET-019 notification).
  final bool showModeNotices;

  /// Optional CTA on empty state.
  final VoidCallback? onEmptyAction;

  @override
  State<ChildDayBoardScreen> createState() => _ChildDayBoardScreenState();
}

class _ChildDayBoardScreenState extends State<ChildDayBoardScreen> {
  late final SmartModeActivationBus _activationBus;
  late final PolicySyncBus _syncBus;
  StreamSubscription<ChildPolicyMirror>? _policySub;
  late SmartModeActivation _activation;
  late ChildPolicyMirror _mirror;
  BuiltInModeId? _prevModeId;
  var _prevActive = false;
  var _hasExplicitPolicy = false;

  String get _childKey => widget.childId.value;

  @override
  void initState() {
    super.initState();
    _activationBus = widget.activationBus ?? stage1SmartModeActivationBus;
    _syncBus = widget.syncBus ?? stage1PolicySyncBus;
    _activation = _activationBus.activationOf(_childKey);
    _prevModeId = _activation.active ? _activation.modeId : null;
    _prevActive = _activation.active;
    _activationBus.addListener(_onActivationBus);

    if (widget.initialPolicy != null) {
      _syncBus.hydrate(widget.childId, policy: widget.initialPolicy);
      _hasExplicitPolicy = true;
    }
    _mirror = _syncBus.mirrorOf(widget.childId);
    if (_mirror.lastAppliedAt != null || _mirror.applyCount > 0) {
      _hasExplicitPolicy = true;
    }
    _policySub = _syncBus.watch(widget.childId).listen((next) {
      if (!mounted) return;
      setState(() {
        _mirror = next;
        if (next.lastAppliedAt != null || next.applyCount > 0) {
          _hasExplicitPolicy = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _activationBus.removeListener(_onActivationBus);
    _policySub?.cancel();
    super.dispose();
  }

  void _onActivationBus() {
    final next = _activationBus.activationOf(_childKey);
    if (!mounted) return;
    final wasActive = _prevActive;
    final wasMode = _prevModeId;
    setState(() => _activation = next);
    _prevActive = next.active;
    _prevModeId = next.active ? next.modeId : null;
    if (!widget.showModeNotices) return;
    _maybeToast(
      wasActive: wasActive,
      wasMode: wasMode,
      next: next,
    );
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

  bool get _showRemaining => _hasExplicitPolicy && !widget.emptyDay;

  bool get _childOffline => !_syncBus.isChildOnline(widget.childId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final active = _activation.active && _activation.modeId != null;
    final modeId = _activation.modeId;

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
        child: widget.emptyDay
            ? AppEmptyState(
                key: ChildDayBoardKeys.emptyState,
                contextName: l10n.childDayBoardTitle,
                onAction: widget.onEmptyAction,
              )
            : ListView(
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
                    const SizedBox(height: 16),
                    Text(
                      l10n.childTimeMirrorRemainingLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.ink2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      key: ChildDayBoardKeys.remainingMinutes,
                      l10n.childTimeMirrorRemainingMinutes(
                        _mirror.remainingMinutes,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DayBoardMotionPulse(
                    key: ChildDayBoardKeys.statusMotion,
                    preferredDuration: const Duration(milliseconds: 1400),
                    enabled: active,
                    mode: DayBoardMotionPulseMode.opacity,
                    child: Container(
                      key: ChildDayBoardKeys.statusCard,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: active
                            ? _modeTint(colors, modeId!)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(16),
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
                                Text(
                                  key: ChildDayBoardKeys.activeModeLabel,
                                  l10n.childDayBoardActiveStatus(
                                    _modeLabel(l10n, modeId!),
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: colors.ink,
                                  ),
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
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
