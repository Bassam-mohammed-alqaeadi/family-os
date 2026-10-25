import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/screen_time_app_rules_sheet.dart';
import 'package:family_os/features/n03_screen_time/screen_time_panel_cards.dart';
import 'package:family_os/features/n03_screen_time/screen_time_panel_contracts.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';

/// The screen-time surface, rendered from what the server enforces.
///
/// This is the whole point of the wave, so the rule is stated once and then followed
/// literally: **every number on this panel came from the server, and every control writes to
/// it.** There is no local fallback, no seeded sample and no optimistic "locked" that the
/// server never agreed to - a family that sees "time is up" here is looking at the same
/// decision the child's phone will get when it asks.
///
/// What it renders, and why each part exists:
///
///   * the computed state, in one sentence a parent can read at a glance, with the reason
///     the server gave (`instant_lock`, `bedtime`, `school_mode`, `daily_limit`) - never a
///     reason this panel invented;
///   * today's counted minutes and what is left, exactly as the server adds them up;
///   * the policy the family owns: the daily cap, the bedtime window, the school window and
///     whether school mode is on. Each edit sends only the field it changed, so a screen that
///     moves bedtime cannot silently rewrite the cap - and `expectedVersion` makes a stale
///     screen a 409 instead of a silent overwrite;
///   * the instant lock: who it belongs to, when it started, and one button that either
///     switches the phone off now or switches it back on. The state drawn afterwards is the
///     server's answer, not the intent;
///   * the child's open question, with the two answers a family has: give minutes, or say no;
///   * the extension block: the quick presets beside a custom number, the instant lock with
///     the server's own confirmation, today's usage per app, the earned-minutes decision, the
///     week's school-day set, and the app and category rules behind one sheet;
///   * what the contract does not carry yet — a separate weekend bedtime, a daily budget per
///     category — shown as a control **and** a sentence saying where it stops, rather than a
///     field that saves into this build's memory and calls it a setting.
///
/// When the server cannot be reached, the last true answer stays on screen **and says that it
/// is the last one**. When there was never an answer, the panel shows no numbers at all.
class ScreenTimeServerPanel extends StatefulWidget {
  const ScreenTimeServerPanel({
    super.key,
    required this.childId,
    this.authority,
    this.canEdit = true,
    this.idempotencyKey,
  });

  final ChildId childId;

  /// Test seam. Null means "the authority bound at boot", which is how the app runs.
  final ScreenTimeServerAuthority? authority;

  /// Role-based: a mother below full level, or a child's own view, may read and not write.
  final bool canEdit;

  /// Test seam for byte-stable idempotency keys.
  final String Function()? idempotencyKey;

  @override
  State<ScreenTimeServerPanel> createState() => _ScreenTimeServerPanelState();
}

class _ScreenTimeServerPanelState extends State<ScreenTimeServerPanel> {
  FoundationGateScreenTimeSnapshot? _snapshot;
  ScreenTimeAuthorityStatus? _status;
  var _busy = false;
  late final TextEditingController _capController;
  int _capVersion = 0;
  String? _capError;

  /// The school-day set as the parent has it in the chips, against `policy.schoolDays`.
  Set<int> _schoolDaysDraft = const {};

  /// The fields the base contract does not carry (see `screen_time_panel_contracts.dart`).
  /// Both are the source's answer, never a local guess: null means "nothing has answered".
  ScreenTimePolicyExtension? _extension;
  ScreenTimeExtensionStatus? _extensionStatus;
  String? _weekendWriteLine;

  /// True only between a lock write and the next read, and only when that read agrees.
  /// The pill therefore says "the server confirmed this", not "a button was pressed".
  var _lockAcknowledged = false;

  /// The cap's quick picks. `0` is unlimited, which is the family's right and the one number
  /// the contract already answers for without a second field.
  static const List<int> _capPresets = [0, 30, 60, 90, 120, 180];

  ScreenTimeServerAuthority? get _authority =>
      widget.authority ?? activeScreenTimeServerAuthority;

  String _key() =>
      widget.idempotencyKey?.call() ??
      'w5-${DateTime.now().microsecondsSinceEpoch}';

  /// The one read-only rule on this panel: someone who may not write gets a control with no
  /// `onPressed`, not a control that is hidden. A greyed button says "you can see this decision
  /// and you are not making it"; a missing button looks like a broken screen.
  bool get _editable => widget.canEdit && !_busy;

  @override
  void initState() {
    super.initState();
    _capController = TextEditingController();
    _capController.addListener(_onCapChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _onCapChanged() {
    if (_capError != null) setState(() => _capError = null);
  }

  @override
  void dispose() {
    _capController.removeListener(_onCapChanged);
    _capController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final authority = _authority;
    if (authority == null) {
      setState(() {
        _status = ScreenTimeAuthorityStatus.notConfigured;
        _snapshot = null;
        _lockAcknowledged = false;
      });
      return;
    }
    final answer = await authority.read(widget.childId.value);
    if (!mounted) return;
    setState(() {
      // A refresh is the panel admitting it no longer knows what the phone is doing, so the
      // "confirmed by the server" pill does not survive one.
      _lockAcknowledged = false;
      _apply(answer);
    });
    if (answer.isReady) {
      final policy = answer.value!.policy;
      _capController.text = '${policy.dailyLimitMinutes}';
      _capVersion = policy.version ?? 0;
      setState(() => _schoolDaysDraft = {...policy.schoolDays});
      await _loadExtension();
    }
  }

  /// The read of the not-yet-built fields. Unbound, this answers `notConfigured` without
  /// touching the network — which is what keeps the panel's contract "one read per open".
  Future<void> _loadExtension() async {
    final answer = await screenTimePolicyExtensionSource.read(
      widget.childId.value,
    );
    if (!mounted) return;
    setState(() {
      _extensionStatus = answer.status;
      _extension = answer.value;
    });
  }

  void _apply<T>(ScreenTimeAuthorityAnswer<T> answer) {
    _status = answer.status;
    final value = answer.value;
    if (value is FoundationGateScreenTimeSnapshot) _snapshot = value;
    if (value is FoundationGateScreenPolicy) {
      final current = _snapshot;
      if (current != null) _snapshot = _withPolicy(current, value);
    }
    if (value is FoundationGateUnlockOutcome) _snapshot = value.snapshot;
  }

  /// The policy the server just answered with, folded into the last snapshot.
  ///
  /// The write returns the policy alone, so the state block beside it stays the one the read
  /// produced - a lock does not disappear because a cap changed, and a call to `read` is what
  /// settles anything that did.
  FoundationGateScreenTimeSnapshot _withPolicy(
    FoundationGateScreenTimeSnapshot snapshot,
    FoundationGateScreenPolicy policy,
  ) => FoundationGateScreenTimeSnapshot(
    childId: snapshot.childId,
    date: snapshot.date,
    policy: policy,
    state: snapshot.state,
    lock: snapshot.lock,
    countableUsedMinutes: snapshot.countableUsedMinutes,
    grantedMinutes: snapshot.grantedMinutes,
    remainingMinutes: snapshot.remainingMinutes,
    usageByApp: snapshot.usageByApp,
    openRequest: snapshot.openRequest,
  );

  Future<void> _run<T>(
    Future<ScreenTimeAuthorityAnswer<T>> Function(ScreenTimeServerAuthority) action,
  ) async {
    final authority = _authority;
    if (authority == null || _busy) return;
    setState(() => _busy = true);
    final answer = await action(authority);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _apply(answer);
    });
    if (answer.isReady) {
      // The write answered with part of the truth; the read settles the rest, so nothing on
      // this screen is a guess assembled from two different moments by hand.
      await _refresh();
    }
  }

  Future<void> _saveCap() async {
    final raw = _capController.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 1440) {
      setState(() {
        _capError = AppLocalizations.of(context).screenTimeServerCapInvalid;
      });
      return;
    }
    await _run(
      (authority) => authority.writePolicy(
        widget.childId.value,
        dailyLimitMinutes: parsed,
        expectedVersion: _capVersion,
        idempotencyKey: _key,
      ),
    );
  }

  Future<void> _instantGrant(int minutes) async {
    final snapshot = _snapshot;
    if (snapshot?.openRequest != null) {
      await _answer(snapshot!.openRequest!, approve: true);
      return;
    }
    await _run(
      (authority) => authority.grantInstantMinutes(
        widget.childId.value,
        minutes: minutes,
        idempotencyKey: _key,
      ),
    );
  }

  /// The bedtime window, picked in the family's own clock.
  ///
  /// Both ends travel together and are sent as minutes-of-day, which is what the contract
  /// stores: a window with a timezone attached would be a window that moves when the family
  /// travels, and that is not what a bedtime is.
  Future<void> _pickBedtime(String label, int? current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _asTimeOfDay(current),
      helpText: label,
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    final snapshot = _snapshot;
    if (snapshot == null) return;
    final isStart = current == snapshot.policy.bedtimeStartMinute;
    await _run(
      (authority) => authority.writePolicy(
        widget.childId.value,
        bedtimeStartMinute: isStart ? minutes : null,
        bedtimeEndMinute: isStart ? null : minutes,
        idempotencyKey: _key,
      ),
    );
  }

  Future<void> _toggleSchoolMode(bool enabled) => _run(
    (authority) => authority.writePolicy(
      widget.childId.value,
      schoolModeEnabled: enabled,
      idempotencyKey: _key,
    ),
  );

  Future<void> _toggleEarnedMinutes(bool enabled) => _run(
    (authority) => authority.writePolicy(
      widget.childId.value,
      earnedMinutesExtendLimit: enabled,
      idempotencyKey: _key,
    ),
  );

  Future<void> _toggleLock({required bool lock}) async {
    setState(() => _lockAcknowledged = false);
    await _run(
      (authority) => lock
          ? authority.lockNow(widget.childId.value, idempotencyKey: _key)
          : authority.releaseLock(widget.childId.value, idempotencyKey: _key),
    );
    if (!mounted) return;
    // `_run` already re-read, so this compares the press against the server's latest answer —
    // a lock it refused stays unconfirmed, and the card keeps drawing what it was told.
    if ((_snapshot?.lock?.live ?? false) == lock) {
      setState(() => _lockAcknowledged = true);
    }
  }

  /// A custom number of minutes, asked for in a sheet and granted through the same write the
  /// presets use. One path, so "+15" and "23" cannot drift into two different meanings.
  Future<void> _openCustomGrant() async {
    final l10n = AppLocalizations.of(context);
    final minutes = await showScreenTimeCustomGrantSheet(
      context,
      title: l10n.screenTimeServerExtensionCustomTitle,
      helper: l10n.screenTimeServerExtensionCustomHelper,
      confirmLabel: l10n.screenTimeServerExtensionCustomConfirm,
      invalidLabel: l10n.screenTimeServerExtensionCustomInvalid,
    );
    if (minutes == null) return;
    await _instantGrant(minutes);
  }

  /// The school-day set is written as one decision, not as seven.
  Future<void> _saveSchoolDays() => _run(
    (authority) => authority.writePolicy(
      widget.childId.value,
      schoolDays: (_schoolDaysDraft.toList()..sort()),
      expectedVersion: _capVersion,
      idempotencyKey: _key,
    ),
  );

  void _toggleDay(int weekday) {
    setState(() {
      final next = Set<int>.of(_schoolDaysDraft);
      if (!next.add(weekday)) next.remove(weekday);
      _schoolDaysDraft = next;
    });
  }

  /// The weekend bedtime, which the base contract has no field for.
  ///
  /// The picker is open and the write is real — it goes to the extension source. Unbound, that
  /// source answers `notConfigured`, and the card says exactly that instead of pretending the
  /// window was saved. Building the control now is what makes the backend's job a route
  /// instead of a redesign.
  Future<void> _pickWeekendBedtime({required bool startsNight}) async {
    final l10n = AppLocalizations.of(context);
    final current = _extension?.bedtimeWindows[ScreenTimeWeekPart.weekend];
    final picked = await showTimePicker(
      context: context,
      initialTime: _asTimeOfDay(
        startsNight ? current?.startMinute : current?.endMinute,
      ),
      helpText: startsNight
          ? l10n.screenTimeServerWeekWeekendBedtimeStart
          : l10n.screenTimeServerWeekWeekendBedtimeEnd,
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    final start = startsNight
        ? minutes
        : (current?.startMinute ?? _snapshot?.policy.bedtimeStartMinute ?? 0);
    final end = startsNight
        ? (current?.endMinute ?? _snapshot?.policy.bedtimeEndMinute ?? 0)
        : minutes;
    final windows = Map<ScreenTimeWeekPart, ScreenTimeBedtimeWindow>.of(
      _extension?.bedtimeWindows ?? const {},
    );
    windows[ScreenTimeWeekPart.weekend] = ScreenTimeBedtimeWindow(
      weekPart: ScreenTimeWeekPart.weekend,
      startMinute: start,
      endMinute: end,
    );
    setState(() {
      _busy = true;
      _weekendWriteLine = null;
    });
    final answer = await screenTimePolicyExtensionSource.write(
      widget.childId.value,
      policyExtension: ScreenTimePolicyExtension(
        bedtimeWindows: windows,
        categoryBudgets: _extension?.categoryBudgets ?? const {},
      ),
      idempotencyKey: _key,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _extensionStatus = answer.status;
      _weekendWriteLine = answer.isReady
          ? l10n.screenTimeServerSaved
          : screenTimeExtensionStatusLabel(l10n, answer.status);
    });
    await _loadExtension();
  }

  Future<void> _openAppRules() => showScreenTimeAppRulesSheet(
    context,
    authority: _authority,
    childId: widget.childId.value,
    canEdit: widget.canEdit,
    idempotencyKey: _key,
  );

  Future<void> _answer(
    FoundationGateTimeRequest request, {
    required bool approve,
  }) => _run(
    (authority) => authority.answer(
      widget.childId.value,
      requestId: request.id,
      decision: approve
          ? FoundationGateTimeRequestDecision.approve
          : FoundationGateTimeRequestDecision.deny,
      idempotencyKey: _key,
    ),
  );

  static TimeOfDay _asTimeOfDay(int? minutes) {
    final value = minutes ?? 0;
    return TimeOfDay(hour: (value ~/ 60) % 24, minute: value % 60);
  }

  String _stamp(DateTime at) => _clock(at.toLocal().hour * 60 + at.toLocal().minute);

  /// ISO weekday (Mon = 1 … Sun = 7) → the localized name, so the card never hardcodes one.
  static Map<int, String> _dayLabels(AppLocalizations l10n) => {
    1: l10n.screenTimeServerDayMon,
    2: l10n.screenTimeServerDayTue,
    3: l10n.screenTimeServerDayWed,
    4: l10n.screenTimeServerDayThu,
    5: l10n.screenTimeServerDayFri,
    6: l10n.screenTimeServerDaySat,
    7: l10n.screenTimeServerDaySun,
  };

  String _clock(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final snapshot = _snapshot;
    final status = _status;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        key: const Key('screen_time_server_panel'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        // A guardian panel is a fixed set of decisions, not a feed. Building it whole keeps
        // every card reachable to a screen reader, to `ensureVisible`, and to a parent who
        // taps "review the request" from the notification before they have scrolled at all.
        scrollCacheExtent: const ScrollCacheExtent.viewport(4.0),
        children: [
          _statusBanner(l10n, status, snapshot),
          const SizedBox(height: 4),
          // The order is a guardian's day, not a list of endpoints: what is true now, what to
          // do about it now, then the rules to set up. The cap stays the third card because
          // its field is the one control a parent comes here to fix in passing.
          if (snapshot != null) ...[
            _stateCard(l10n, colors, snapshot),
            const SizedBox(height: 4),
            _lockCard(l10n, snapshot),
            const SizedBox(height: 4),
            _capCard(l10n, snapshot),
            const SizedBox(height: 4),
            if (snapshot.openRequest != null)
              _requestCard(l10n, colors, snapshot.openRequest!)
            else
              _extensionCard(l10n, snapshot),
            const SizedBox(height: 4),
            _insightsCard(l10n, snapshot),
            const SizedBox(height: 4),
            _earnedMinutesCard(l10n, snapshot),
            const SizedBox(height: 4),
            _weekCard(l10n, snapshot),
            const SizedBox(height: 4),
            _appsCard(l10n, snapshot),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(
    AppLocalizations l10n,
    ScreenTimeAuthorityStatus? status,
    FoundationGateScreenTimeSnapshot? snapshot,
  ) {
    // Every status here is one of the four honest ones, and the sentence says which. There is
    // deliberately no fifth "we will try to make it work locally" - a family reading this
    // needs to know whether the phone is being limited, not how hard the app is trying.
    final (Key key, String message, BannerVariant variant) = switch (status) {
      null => (
        const Key('screen_time_server_loading'),
        l10n.screenTimeServerLoading,
        BannerVariant.t,
      ),
      ScreenTimeAuthorityStatus.ready => (
        const Key('screen_time_server_ready'),
        l10n.screenTimeServerSaved,
        BannerVariant.t,
      ),
      ScreenTimeAuthorityStatus.notConfigured => (
        const Key('screen_time_server_no_session'),
        l10n.screenTimeServerNoSession,
        BannerVariant.a,
      ),
      ScreenTimeAuthorityStatus.accessDenied => (
        const Key('screen_time_server_denied'),
        l10n.screenTimeServerDenied,
        BannerVariant.a,
      ),
      ScreenTimeAuthorityStatus.refused => (
        const Key('screen_time_server_refused'),
        l10n.screenTimeServerRefused,
        BannerVariant.a,
      ),
      ScreenTimeAuthorityStatus.unreachable => (
        const Key('screen_time_server_unreachable'),
        snapshot == null
            ? l10n.screenTimeServerUnreachableNoData
            : l10n.screenTimeServerUnreachable,
        BannerVariant.a,
      ),
    };
    if (status == ScreenTimeAuthorityStatus.ready) {
      if (snapshot != null && !snapshot.policy.configured) {
        return BannerNote(
          key: const Key('screen_time_server_empty'),
          variant: BannerVariant.t,
          message: l10n.screenTimeServerEmpty,
        );
      }
      // The quiet case: nothing to warn about, and a green banner every load is noise.
      return const SizedBox.shrink();
    }
    if (status == ScreenTimeAuthorityStatus.unreachable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BannerNote(key: key, variant: variant, message: message),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const Key('screen_time_server_retry_button'),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.screenTimeServerRetry),
              onPressed: _busy ? null : _refresh,
            ),
          ),
        ],
      );
    }
    return BannerNote(key: key, variant: variant, message: message);
  }

  Widget _stateCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateScreenTimeSnapshot snapshot,
  ) {
    final state = snapshot.state;
    final sentence = switch (state.reason) {
      FoundationGateScreenReason.instantLock => l10n.screenTimeServerStateLock,
      FoundationGateScreenReason.bedtime => l10n.screenTimeServerStateBedtime,
      FoundationGateScreenReason.schoolMode => l10n.screenTimeServerStateSchool,
      FoundationGateScreenReason.dailyLimit => l10n.screenTimeServerStateLimit,
      _ => state.kind == FoundationGateScreenStateKind.limited
          ? l10n.screenTimeServerStateLimited
          : l10n.screenTimeServerStateFree,
    };
    final remaining = snapshot.remainingMinutes;
    final used = snapshot.countableUsedMinutes;
    final dailyCap = snapshot.policy.dailyLimitMinutes;
    final granted = snapshot.grantedMinutes;
    final totalAllowed = dailyCap + granted;
    final progress = totalAllowed > 0
        ? (used / totalAllowed).clamp(0.0, 1.0)
        : (used > 0 ? 1.0 : 0.0);
    final progressColor = (remaining != null && remaining == 0)
        ? colors.coral
        : ((remaining != null && remaining <= 15)
            ? colors.amberDeep
            : colors.mintInk);

    return AppCard(
      key: const Key('screen_time_server_state_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sentence,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.screenTimeServerTodayMinutes(used),
            style: TextStyle(fontSize: 13, color: colors.ink2),
          ),
          if (remaining != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.childTimeMirrorRemainingMinutes(remaining),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
          ],
          if (granted > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.remainingMinutesGrantLabel,
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              key: const Key('screen_time_server_progress_bar'),
              value: progress,
              minHeight: 6,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.screenTimeServerProgressLabel,
                style: TextStyle(fontSize: 10, color: colors.ink2),
              ),
              Text(
                l10n.screenTimeServerTotalLimit(totalAllowed),
                style: TextStyle(fontSize: 10, color: colors.ink2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The instant lock: what the server decided, when it decided it, and the one button that
  /// changes it. The confirmed pill is the only thing on this panel that speaks about the
  /// write itself, and it only appears once a read agrees with it.
  Widget _lockCard(
    AppLocalizations l10n,
    FoundationGateScreenTimeSnapshot snapshot,
  ) {
    final lock = snapshot.lock;
    final live = lock?.live ?? false;
    return ScreenTimeLockControlCard(
      title: l10n.instantLockTitle,
      stateLine: live
          ? l10n.screenTimeServerLockStateLocked
          : l10n.screenTimeServerLockStateUnlocked,
      buttonLabel: live
          ? l10n.screenTimeServerUnlock
          : l10n.screenTimeServerLockNow,
      live: live,
      enabled: _editable,
      onToggle: () => _toggleLock(lock: !live),
      sinceLine: live && lock != null
          ? l10n.screenTimeServerLockSince(_stamp(lock.lockedAt))
          : null,
      confirmedLabel: _lockAcknowledged
          ? l10n.screenTimeServerLockConfirmed
          : null,
      busyLabel: _busy ? l10n.screenTimeServerLockBusy : null,
      releaseNote: live ? l10n.screenTimeServerLockReleaseNote : null,
    );
  }

  /// The daily cap, its quick picks, and the write that saves it.
  Widget _capCard(
    AppLocalizations l10n,
    FoundationGateScreenTimeSnapshot snapshot,
  ) => ScreenTimeCapCard(
    // The heading and the field label are deliberately different strings: the same sentence
    // twice in one card reads like a bug, and `screenTimeServerCap` is the one the field
    // needs because it carries the "0 = no limit" rule.
    title: l10n.childScreenTimeDailyCap,
    fieldLabel: l10n.screenTimeServerCap,
    controller: _capController,
    errorText: _capError,
    saveLabel: l10n.screenTimeServerSave,
    presetsLabel: l10n.screenTimeServerCapPresets,
    presetMinutes: _capPresets,
    presetLabel: l10n.screenTimeServerCapPresetValue,
    unlimitedLabel: l10n.screenTimeServerCapUnlimited,
    selectedMinutes: snapshot.policy.dailyLimitMinutes,
    enabled: _editable,
    onSave: _saveCap,
    onPickPreset: (minutes) => _capController.text = '$minutes',
  );

  /// Quick minutes, a custom number, and the answer each one got.
  ///
  /// A pending question wins over this card on purpose: while a question is open, "+15" IS the
  /// answer to it, and drawing both would let a parent grant twice for one ask.
  Widget _extensionCard(
    AppLocalizations l10n,
    FoundationGateScreenTimeSnapshot snapshot,
  ) => ScreenTimeExtensionCard(
    title: l10n.screenTimeServerExtensionTitle,
    hint: l10n.screenTimeServerExtensionHint,
    presets: {
      15: l10n.screenTimeServerGrant15,
      30: l10n.screenTimeServerGrant30,
      60: l10n.screenTimeServerGrant60,
    },
    customLabel: l10n.screenTimeServerExtensionCustom,
    onGrant: _instantGrant,
    onCustom: _openCustomGrant,
    enabled: _editable,
    busyLabel: _busy ? l10n.screenTimeServerExtensionPending : null,
  );

  /// Today's minutes, split per app — all of it from the read that already happened.
  Widget _insightsCard(
    AppLocalizations l10n,
    FoundationGateScreenTimeSnapshot snapshot,
  ) => ScreenTimeInsightsCard(
    title: l10n.screenTimeServerInsightsTitle,
    usedLabel: l10n.screenTimeServerInsightsUsed,
    capLabel: l10n.screenTimeServerInsightsCap,
    grantedLabel: l10n.screenTimeServerInsightsGranted,
    hint: l10n.screenTimeServerInsightsHint,
    topLabel: l10n.screenTimeServerInsightsTop,
    emptyLabel: l10n.screenTimeServerInsightsNoUsage,
    overCapLabel: l10n.screenTimeServerInsightsOverCap,
    shareLabel: l10n.screenTimeServerInsightsShare,
    minutesLabel: l10n.remainingMinutesValue,
    unlimitedLabel: l10n.screenTimeServerCapUnlimited,
    usedMinutes: snapshot.countableUsedMinutes,
    capMinutes: snapshot.policy.dailyLimitMinutes,
    grantedMinutes: snapshot.grantedMinutes,
    usageByApp: snapshot.usageByApp,
    onOpenApps: _busy ? null : _openAppRules,
    openAppsLabel: l10n.screenTimeServerAppsRules,
  );

  /// The earned-minutes decision, with both sides of its arithmetic spelled out.
  Widget _earnedMinutesCard(
    AppLocalizations l10n,
    FoundationGateScreenTimeSnapshot snapshot,
  ) {
    final enabled = snapshot.policy.earnedMinutesExtendLimit;
    return ScreenTimeEarnedMinutesCard(
      title: l10n.screenTimeServerEarnedMinutesTitle,
      subtitle: l10n.screenTimeServerEarnedMinutesSubtitle,
      preview: l10n.screenTimeServerEarnedMinutesPreview,
      hint: enabled
          ? l10n.screenTimeServerEarnedMinutesOnHint
          : l10n.screenTimeServerEarnedMinutesOffHint,
      value: enabled,
      enabled: _editable,
      onChanged: _toggleEarnedMinutes,
    );
  }

  /// The week: school-day chips, the bedtime window, and the weekend window the extension
  /// carries when the deployment has one.
  Widget _weekCard(
    AppLocalizations l10n,
    FoundationGateScreenTimeSnapshot snapshot,
  ) {
    final policy = snapshot.policy;
    final weekend = _extension?.bedtimeWindows[ScreenTimeWeekPart.weekend];
    final stored = weekend != null &&
        _extensionStatus == ScreenTimeExtensionStatus.ready;
    return ScreenTimeWeekScheduleCard(
      title: l10n.screenTimeServerWeekTitle,
      schoolModeLabel: l10n.screenTimeServerSchoolMode,
      schoolRangeLine:
          '${_clock(policy.schoolStartMinute)} – ${_clock(policy.schoolEndMinute)}',
      schoolDaysLabel: l10n.screenTimeServerWeekSchoolDays,
      weekdaysLabel: l10n.screenTimeServerWeekWeekdays,
      weekendLabel: l10n.screenTimeServerWeekWeekend,
      dayLabels: _dayLabels(l10n),
      draftDays: _schoolDaysDraft,
      savedDays: policy.schoolDays,
      schoolEnabled: policy.schoolModeEnabled,
      bedtimeLabel: l10n.screenTimeServerBedtime,
      bedtimeLine:
          '${_clock(policy.bedtimeStartMinute)} – ${_clock(policy.bedtimeEndMinute)}',
      bedtimeHint: l10n.screenTimeServerWeekBedtimeHint,
      weekendLabelLine: l10n.screenTimeServerWeekWeekend,
      weekendLine: stored
          ? '${weekend.startClock} – ${weekend.endClock}'
          : l10n.screenTimeServerWeekWeekendNote,
      weekendPending: !stored,
      weekendStartLabel: l10n.screenTimeServerWeekWeekendBedtimeStart,
      weekendEndLabel: l10n.screenTimeServerWeekWeekendBedtimeEnd,
      bedtimeStartLabel: l10n.screenTimeServerWeekBedtimeStart,
      bedtimeEndLabel: l10n.screenTimeServerWeekBedtimeEnd,
      saveLabel: l10n.screenTimeServerWeekSave,
      weekendWriteLine: _weekendWriteLine,
      enabled: _editable,
      onToggleDay: _toggleDay,
      onToggleSchoolMode: _toggleSchoolMode,
      onPickBedtimeStart: () => _pickBedtime(
        l10n.screenTimeServerWeekBedtimeStart,
        policy.bedtimeStartMinute,
      ),
      onPickBedtimeEnd: () => _pickBedtime(
        l10n.screenTimeServerWeekBedtimeEnd,
        policy.bedtimeEndMinute,
      ),
      onPickWeekendStart: () => _pickWeekendBedtime(startsNight: true),
      onPickWeekendEnd: () => _pickWeekendBedtime(startsNight: false),
      onSaveDays: _saveSchoolDays,
    );
  }

  /// The app-rules door. The panel does not read the app list on its own — the sheet does,
  /// when the parent opens it, so one panel load is still exactly one read.
  Widget _appsCard(
    AppLocalizations l10n,
    FoundationGateScreenTimeSnapshot snapshot,
  ) {
    final status = _extensionStatus;
    return ScreenTimeAppsCard(
      title: l10n.screenTimeServerAppsTitle,
      subtitle: l10n.screenTimeServerAppsSubtitle,
      actionLabel: l10n.screenTimeServerAppsOpen,
      enabled: !_busy,
      onOpen: _openAppRules,
      summaryLine: status == null || status == ScreenTimeExtensionStatus.ready
          ? null
          : screenTimeExtensionStatusLabel(l10n, status),
    );
  }

  Widget _requestCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateTimeRequest request,
  ) {
    return AppCard(
      key: const Key('screen_time_server_request_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.screenTimeServerOpenRequest(request.requestedMinutes),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PrimaryBtn(
                key: const Key('screen_time_server_request_approve'),
                fullWidth: false,
                label: l10n.screenTimeServerApprove,
                onPressed: _editable
                    ? () => _answer(request, approve: true)
                    : null,
              ),
              const SizedBox(width: 12),
              TextButton(
                key: const Key('screen_time_server_request_deny'),
                onPressed: _editable
                    ? () => _answer(request, approve: false)
                    : null,
                child: Text(l10n.screenTimeServerDeny),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
