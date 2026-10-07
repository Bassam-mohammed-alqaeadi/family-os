import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
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
///   * the child's open question, with the two answers a family has: give minutes, or say no.
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

  ScreenTimeServerAuthority? get _authority =>
      widget.authority ?? activeScreenTimeServerAuthority;

  String _key() =>
      widget.idempotencyKey?.call() ??
      'w5-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _capController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _capController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final authority = _authority;
    if (authority == null) {
      setState(() {
        _status = ScreenTimeAuthorityStatus.notConfigured;
        _snapshot = null;
      });
      return;
    }
    final answer = await authority.read(widget.childId.value);
    if (!mounted) return;
    setState(() => _apply(answer));
    if (answer.isReady) {
      _capController.text = '${answer.value!.policy.dailyLimitMinutes}';
      _capVersion = answer.value!.policy.version ?? 0;
    }
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
    final parsed = int.tryParse(_capController.text.trim());
    if (parsed == null || parsed < 0 || parsed > 1440) return;
    await _run(
      (authority) => authority.writePolicy(
        widget.childId.value,
        dailyLimitMinutes: parsed,
        expectedVersion: _capVersion,
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

  Future<void> _toggleLock({required bool lock}) => _run(
    (authority) => lock
        ? authority.lockNow(widget.childId.value, idempotencyKey: _key)
        : authority.releaseLock(widget.childId.value, idempotencyKey: _key),
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

    return ListView(
      key: const Key('screen_time_server_panel'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        _statusBanner(l10n, status, snapshot),
        const SizedBox(height: 12),
        if (snapshot != null) ...[
          _stateCard(l10n, colors, snapshot),
          const SizedBox(height: 12),
          _policyCard(l10n, colors, snapshot),
          const SizedBox(height: 12),
          _lockCard(l10n, colors, snapshot),
          if (snapshot.openRequest != null) ...[
            const SizedBox(height: 12),
            _requestCard(l10n, colors, snapshot.openRequest!),
          ],
        ],
      ],
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
        l10n.screenTimeServerNoSession,
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
      // The quiet case: nothing to warn about, and a green banner every load is noise.
      return const SizedBox.shrink();
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
    return Card(
      key: const Key('screen_time_server_state_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sentence,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.screenTimeServerTodayMinutes(snapshot.countableUsedMinutes),
              style: TextStyle(fontSize: 14, color: colors.ink2),
            ),
            if (remaining != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.childTimeMirrorRemainingMinutes(remaining),
                style: TextStyle(fontSize: 14, color: colors.ink2),
              ),
            ],
            if (snapshot.grantedMinutes > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.remainingMinutesGrantLabel,
                style: TextStyle(fontSize: 13, color: colors.ink2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _policyCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateScreenTimeSnapshot snapshot,
  ) {
    final policy = snapshot.policy;
    final editable = widget.canEdit && !_busy;
    return Card(
      key: const Key('screen_time_server_policy_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('screen_time_server_cap_field'),
                    controller: _capController,
                    enabled: editable,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.screenTimeServerCap,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PrimaryBtn(
                  key: const Key('screen_time_server_cap_save'),
                  label: l10n.screenTimeServerSave,
                  onPressed: editable ? _saveCap : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.screenTimeServerBedtime} · ${_clock(policy.bedtimeStartMinute)} – '
              '${_clock(policy.bedtimeEndMinute)}',
              style: TextStyle(fontSize: 14, color: colors.ink),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  key: const Key('screen_time_server_bedtime_start'),
                  onPressed: editable
                      ? () => _pickBedtime(
                          l10n.screenTimeServerBedtime,
                          policy.bedtimeStartMinute,
                        )
                      : null,
                  child: Text(l10n.childScreenTimeStart),
                ),
                TextButton(
                  key: const Key('screen_time_server_bedtime_end'),
                  onPressed: editable
                      ? () => _pickBedtime(
                          l10n.screenTimeServerBedtime,
                          policy.bedtimeEndMinute,
                        )
                      : null,
                  child: Text(l10n.childScreenTimeEnd),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('screen_time_server_school_toggle'),
              value: policy.schoolModeEnabled,
              onChanged: editable ? _toggleSchoolMode : null,
              title: Text(l10n.screenTimeServerSchoolMode),
              subtitle: Text(
                '${_clock(policy.schoolStartMinute)} – ${_clock(policy.schoolEndMinute)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateScreenTimeSnapshot snapshot,
  ) {
    final lock = snapshot.lock;
    final live = lock?.live ?? false;
    final editable = widget.canEdit && !_busy;
    return Card(
      key: const Key('screen_time_server_lock_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.instantLockTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              live ? l10n.screenTimeServerStateLock : l10n.screenTimeServerStateFree,
              style: TextStyle(fontSize: 14, color: colors.ink2),
            ),
            const SizedBox(height: 12),
            PrimaryBtn(
              key: const Key('screen_time_server_lock_button'),
              label: live
                  ? l10n.screenTimeServerUnlock
                  : l10n.screenTimeServerLockNow,
              onPressed: editable ? () => _toggleLock(lock: !live) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateTimeRequest request,
  ) {
    final editable = widget.canEdit && !_busy;
    return Card(
      key: const Key('screen_time_server_request_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.screenTimeServerOpenRequest(request.requestedMinutes),
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
                  label: l10n.screenTimeServerApprove,
                  onPressed: editable
                      ? () => _answer(request, approve: true)
                      : null,
                ),
                const SizedBox(width: 12),
                TextButton(
                  key: const Key('screen_time_server_request_deny'),
                  onPressed: editable
                      ? () => _answer(request, approve: false)
                      : null,
                  child: Text(l10n.screenTimeServerDeny),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
