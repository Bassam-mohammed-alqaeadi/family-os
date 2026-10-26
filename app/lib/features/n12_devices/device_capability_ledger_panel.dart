import 'package:flutter/material.dart';
import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/device_capability_honesty_badge.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/features/n12_devices/device_ledger_server_authority.dart';
import 'package:family_os/foundation_gate/family_capability_api_client.dart';
import 'package:family_os/foundation_gate/family_command_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Keys the journey test taps and the accessibility audit finds.
@visibleForTesting
class DeviceLedgerKeys {
  const DeviceLedgerKeys._();

  static const Key panel = Key('device_ledger_panel');
  static const Key capabilitiesCard = Key('device_ledger_capabilities_card');
  static const Key ordersCard = Key('device_ledger_orders_card');
  static const Key ordersCount = Key('device_ledger_orders_count');
  static const Key summary = Key('device_ledger_summary');
  static const Key empty = Key('device_ledger_empty');
  static const Key note = Key('device_ledger_note');
  static const Key busy = Key('device_ledger_busy');
  static const Key refreshCta = Key('device_ledger_refresh_cta');
  static const Key lockHint = Key('device_ledger_lock_hint');
  static const Key status = Key('device_ledger_status');

  static Key row(FoundationGateCapabilityKey key) =>
      Key('device_ledger_cap_${key.wire}');

  static Key stateTag(FoundationGateCapabilityKey key) =>
      Key('device_ledger_state_${key.wire}');

  static Key order(String id) => Key('device_ledger_order_$id');
}

/// The device's own account of what it can enforce, plus every order issued to it.
///
/// This panel exists because the promise families are sold is not "we recorded a rule" but "the
/// phone is holding it". A green switch on a plan proves nothing; a line saying which capability the
/// handset confirmed, when it said so, and from which app and system version does. Both halves are
/// read from the spine — the capability ledger and the command bus — and every number here traces
/// to a `reported_at` or a receipt. Nothing on this screen can show a state the server does not have.
///
/// It renders the seven honest states rather than hiding when there is nothing real to show: no
/// server, a child not linked to a server record, a device that has not reported, a refused write.
class DeviceCapabilityLedgerPanel extends StatefulWidget {
  const DeviceCapabilityLedgerPanel({
    super.key,
    required this.childId,
    required this.deviceLabel,
    this.deviceId,
    this.canEdit = true,
    this.authority,
  });

  final String childId;
  final String? deviceId;
  final String deviceLabel;
  final bool canEdit;

  /// Test seam. Unbound at runtime resolves to the application's authority; a panel with no
  /// authority at all says so rather than drawing a pretend ledger.
  final DeviceLedgerAuthority? authority;

  @override
  State<DeviceCapabilityLedgerPanel> createState() =>
      _DeviceCapabilityLedgerPanelState();
}

class _DeviceCapabilityLedgerPanelState extends State<DeviceCapabilityLedgerPanel> {
  DeviceLedgerReading? _reading;
  DeviceLedgerStatus _status = DeviceLedgerStatus.notConfigured;
  String? _note;
  bool _noteIsGood = false;

  /// The order the server just accepted, kept until the command list itself carries a row
  /// with the same id. Without this the screen would answer a successful write by showing
  /// nothing, which a guardian reads as the order having vanished.
  FoundationGateCommand? _justIssued;

  bool _loading = false;

  DeviceLedgerAuthority? get _authority =>
      widget.authority ?? DeviceLedgerAuthority.bound;

  /// An order can only be issued into a live session that names one real device: no session, a
  /// device that is not a server record, or a read in flight, and the button stays shut. Disabled
  /// is a fact here, not decoration - pressing it would ask the server for something it must
  /// refuse, which is the one thing this screen must not do to a guardian.
  bool get _canAskPhone =>
      !_loading &&
      _status == DeviceLedgerStatus.ready &&
      widget.deviceId != null &&
      _authority != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DeviceCapabilityLedgerPanel old) {
    super.didUpdateWidget(old);
    // This panel can be re-targeted at another child or another device without its screen being
    // built again. Whatever the last one showed - its rows, its in-flight order, its note - is not
    // information about this one, so it goes before the new read starts.
    if (old.childId != widget.childId ||
        old.deviceId != widget.deviceId ||
        old.canEdit != widget.canEdit) {
      _reading = null;
      _justIssued = null;
      _note = null;
      _noteIsGood = false;
      _status = DeviceLedgerStatus.notConfigured;
      _load();
    }
  }

  Future<void> _load() async {
    final authority = _authority;
    if (authority == null) {
      if (mounted) {
        setState(() => _status = DeviceLedgerStatus.notConfigured);
      }
      return;
    }
    if (_loading) return;
    if (mounted) setState(() => _loading = true);
    final answer = await authority.read(childId: widget.childId, deviceId: widget.deviceId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = answer.status;
      _reading = answer.value;
    });
  }

  /// Ask the spine to hand the stored policy to the phone again. The write goes through the
  /// authority, so the only thing this can claim is what the server answered.
  Future<void> _requestRefresh() async {
    final authority = _authority;
    if (authority == null || _loading) return;
    final deviceId = widget.deviceId;
    if (deviceId == null) return;
    setState(() {
      _loading = true;
      _note = null;
    });
    final answer = await authority.requestPolicyRefresh(
      childId: widget.childId,
      deviceId: deviceId,
      idempotencyKey: newFoundationGateIdempotencyKey(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _noteIsGood = answer.isReady;
      _note = _noteIsGood
          ? AppLocalizations.of(context).deviceLedgerRefreshSent
          : _refusalWord(answer.status, answer.refusal);
      if (answer.value != null) _justIssued = answer.value;
    });
    if (answer.isReady) await _load();
  }

  /// What to say when the order did not go through.
  ///
  /// The status decides the sentence, not a generic failure label: a server that never answered, a
  /// device that is not a server record and a device the server will not order about are three
  /// different facts, and a guardian who is told "the answer could not be read" when nobody replied
  /// will wait for a reply that is not coming.
  String _refusalWord(DeviceLedgerStatus status, DeviceLedgerRefusal refusal) {
    final l10n = AppLocalizations.of(context);
    if (status == DeviceLedgerStatus.refused) {
      return refusal == DeviceLedgerRefusal.deviceNotEligible
          ? l10n.deviceLedgerRefuseDevice
          : l10n.deviceLedgerRefuseOther;
    }
    return switch (status) {
      DeviceLedgerStatus.unreachable => l10n.deviceLedgerUnreachable,
      DeviceLedgerStatus.notConfigured => l10n.deviceLedgerNoSession,
      DeviceLedgerStatus.notLinked => l10n.deviceLedgerNoChild,
      DeviceLedgerStatus.accessDenied => l10n.deviceLedgerDenied,
      DeviceLedgerStatus.unreadable => l10n.deviceLedgerBadReply,
      DeviceLedgerStatus.ready => l10n.deviceLedgerRefuseOther,
      DeviceLedgerStatus.refused => l10n.deviceLedgerRefuseOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final reading = _reading;

    return Semantics(
      container: true,
      label: l10n.deviceLedgerTitle,
      child: Column(
        key: DeviceLedgerKeys.panel,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Headline(
            title: l10n.deviceLedgerTitle,
            subtitle: widget.deviceLabel,
            note: l10n.deviceLedgerHonestyLine,
            trailing: _loading
                ? KeyedSubtree(
                    key: DeviceLedgerKeys.busy,
                    child: Semantics(
                      label: l10n.deviceLedgerBusy,
                      child: SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.p600,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_status != DeviceLedgerStatus.ready)
            Padding(
              key: DeviceLedgerKeys.status,
              padding: const EdgeInsets.only(top: 8),
              child: BannerNote(message: _statusWord(l10n), variant: _statusVariant()),
            ),
          if (reading != null) ...[
            Padding(
              key: DeviceLedgerKeys.summary,
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.deviceLedgerSummary(reading.workingCount, reading.waitingCount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.ink2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _capabilitiesCard(context, l10n, colors, reading),
            const SizedBox(height: 10),
            _ordersCard(context, l10n, colors, reading),
            if (widget.canEdit) ...[
              const SizedBox(height: 10),
              _actionsCard(context, l10n, colors, reading),
            ],
          ],
          if (_note != null)
            Padding(
              key: DeviceLedgerKeys.note,
              padding: const EdgeInsets.only(top: 8),
              child: BannerNote(
                message: _note!,
                variant: _noteIsGood ? BannerVariant.t : BannerVariant.a,
              ),
            ),
        ],
      ),
    );
  }

  // ── capabilities ─────────────────────────────────────────────────────────

  Widget _capabilitiesCard(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
    DeviceLedgerReading reading,
  ) {
    final rows = reading.capabilities;
    return _LedgerCard(
      key: DeviceLedgerKeys.capabilitiesCard,
      title: l10n.deviceLedgerSubtitle,
      child: rows.isEmpty
          ? Text(
              key: DeviceLedgerKeys.empty,
              l10n.deviceLedgerNoReport,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.ink2,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Container(height: 1, color: colors.border.withValues(alpha: 0.5)),
                  _CapabilityRow(key: DeviceLedgerKeys.row(rows[i].key), row: rows[i]),
                ],
              ],
            ),
    );
  }

  // ── orders ───────────────────────────────────────────────────────────────

  Widget _ordersCard(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
    DeviceLedgerReading reading,
  ) {
    final issued = _justIssued;
    final known =
        issued != null && !reading.orders.any((c) => c.id == issued.id)
        ? <FoundationGateCommand>[issued, ...reading.orders]
        : reading.orders;
    final shown = known.take(8).toList(growable: false);
    return _LedgerCard(
      key: DeviceLedgerKeys.ordersCard,
      title: l10n.deviceLedgerCommandsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deviceLedgerCommandsHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.ink2,
            ),
          ),
          if (reading.ordersStatus != DeviceLedgerStatus.ready)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _ordersMissingWord(l10n, reading.ordersStatus),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.amberDeep,
                ),
              ),
            )
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.deviceLedgerCommandsEmpty,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.ink2,
                ),
              ),
            )
          else
            for (final order in shown)
              Padding(
                key: DeviceLedgerKeys.order(order.id),
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: _OrderRow(order: order),
              ),
          // A shortened list must say it is shortened. The server answers newest first and caps
          // what it sends; a parent who reads eight rows and no count learns a lesson that is not
          // true - that this is everything the device was ever told.
          if (known.length > shown.length)
            Padding(
              key: DeviceLedgerKeys.ordersCount,
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.deviceLedgerOrdersShown(shown.length, known.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.p600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Why the order list is empty or missing. Three sentences, because they mean three different
  /// things to act on. "No orders" is said only when the server answered that there are none.
  String _ordersMissingWord(AppLocalizations l10n, DeviceLedgerStatus status) =>
      switch (status) {
        DeviceLedgerStatus.accessDenied => l10n.deviceLedgerCommandsDenied,
        DeviceLedgerStatus.unreachable => l10n.deviceLedgerUnreachable,
        DeviceLedgerStatus.unreadable => l10n.deviceLedgerBadReply,
        DeviceLedgerStatus.notConfigured => l10n.deviceLedgerNoSession,
        DeviceLedgerStatus.notLinked => l10n.deviceLedgerNoChild,
        DeviceLedgerStatus.refused => l10n.deviceLedgerRefuseOther,
        DeviceLedgerStatus.ready => l10n.deviceLedgerCommandsEmpty,
      };

  // ── what the guardian can do from here ───────────────────────────────────

  Widget _actionsCard(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
    DeviceLedgerReading reading,
  ) {
    return _LedgerCard(
      title: l10n.deviceLedgerRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deviceLedgerRefreshNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PrimaryBtn(
                key: DeviceLedgerKeys.refreshCta,
                label: l10n.deviceLedgerAskRefresh,
                variant: PrimaryBtnVariant.sec,
                fullWidth: false,
                onPressed: _canAskPhone ? _requestRefresh : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            key: DeviceLedgerKeys.lockHint,
            reading.instantLockConfirmed
                ? l10n.deviceLedgerLockElsewhere
                : '${l10n.deviceLedgerLockElsewhere}\n${l10n.deviceLedgerActionWaiting}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.ink2,
            ),
          ),
        ],
      ),
    );
  }

  String _statusWord(AppLocalizations l10n) => switch (_status) {
    DeviceLedgerStatus.ready => l10n.deviceLedgerLoading,
    DeviceLedgerStatus.notConfigured => l10n.deviceLedgerNoSession,
    DeviceLedgerStatus.notLinked => l10n.deviceLedgerNoChild,
    DeviceLedgerStatus.accessDenied => l10n.deviceLedgerDenied,
    DeviceLedgerStatus.unreachable => l10n.deviceLedgerUnreachable,
    DeviceLedgerStatus.refused => l10n.deviceLedgerBusy,
    DeviceLedgerStatus.unreadable => l10n.deviceLedgerBadReply,
  };

  BannerVariant _statusVariant() => switch (_status) {
    DeviceLedgerStatus.ready => BannerVariant.p,
    DeviceLedgerStatus.accessDenied => BannerVariant.a,
    DeviceLedgerStatus.refused => BannerVariant.a,
    DeviceLedgerStatus.unreadable => BannerVariant.a,
    DeviceLedgerStatus.unreachable => BannerVariant.p,
    DeviceLedgerStatus.notConfigured => BannerVariant.p,
    DeviceLedgerStatus.notLinked => BannerVariant.p,
  };
}

/// The card frame, in this feature's own voice: a soft surface, a heading, and a Material under
/// the content so an ink response inside it never asserts.
class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AppCard(
        backgroundColor: Theme.of(context).extension<FamilyColors>()!.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.title,
    required this.subtitle,
    required this.note,
    required this.trailing,
  });

  final String title;
  final String subtitle;

  /// The one line that says where the numbers come from. It is not decoration: a family that
  /// reads a green tick must know it is the phone's own word, not a promise from us.
  final String note;

  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.ink2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.p600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}

/// One capability: what it is, what the phone said about it, and when it said so.
class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.row, super.key});

  final DeviceLedgerCapabilityRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final record = row.record;
    final name = switch (row.key) {
      FoundationGateCapabilityKey.usageMetering => l10n.deviceLedgerCapUsage,
      FoundationGateCapabilityKey.appInventory => l10n.deviceLedgerCapApps,
      FoundationGateCapabilityKey.appBlockOverlay => l10n.deviceLedgerCapBlock,
      FoundationGateCapabilityKey.accessibilityEnforcement =>
        l10n.deviceLedgerCapFollow,
      FoundationGateCapabilityKey.instantLock => l10n.deviceLedgerCapLock,
      FoundationGateCapabilityKey.webFilterVpn => l10n.deviceLedgerCapWeb,
      FoundationGateCapabilityKey.backgroundLocation => l10n.deviceLedgerCapPlace,
      FoundationGateCapabilityKey.bootPersistence => l10n.deviceLedgerCapRestart,
      FoundationGateCapabilityKey.pushDelivery => l10n.deviceLedgerCapAlerts,
      FoundationGateCapabilityKey.batteryReporting => l10n.deviceLedgerCapBattery,
      FoundationGateCapabilityKey.tamperSignals => l10n.deviceLedgerCapTamper,
    };
    final reported = _formatStamp(record.reportedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A Wrap, not a Row: at the largest text this app supports, the capability name and the
          // phone's verdict about it both have to fit. A Row would either clip the word or push the
          // chip away, and a clipped state word is a family acting on the wrong assumption.
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                name,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              DeviceCapabilityHonestyBadge(
                key: DeviceLedgerKeys.stateTag(row.key),
                state: _badgeStateFor(record.state),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 2,
            children: [
              Text(
                l10n.deviceLedgerLastReport(reported),
                style: textTheme.bodySmall?.copyWith(color: colors.ink2),
              ),
              if (row.confirmed && record.confirmedAt != null)
                Text(
                  l10n.deviceLedgerConfirmedSince(
                    _formatStamp(record.confirmedAt!),
                  ),
                  style: textTheme.bodySmall?.copyWith(color: colors.mintInk),
                ),
              if (record.appVersion != null)
                Text(
                  l10n.deviceLedgerFromApp(record.appVersion!),
                  style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                ),
              if (record.osVersion != null)
                Text(
                  l10n.deviceLedgerOnSystem(record.osVersion!),
                  style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One order: what it was, where it got to, the window it was valid for, and what came back.
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final FoundationGateCommand order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final receipt = order.receipt;
    final state = order.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_iconFor(state), size: 15, color: _colorFor(context, state)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${_typeWord(l10n)} · ${_stateWord(l10n, state)}',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l10n.deviceLedgerCommandWindow(
            _formatStamp(order.createdAt),
            _formatStamp(order.expiresAt),
          ),
          style: textTheme.bodySmall?.copyWith(color: colors.ink2),
        ),
        if (receipt != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.deviceLedgerReceiptLine(
                _receiptWord(l10n, receipt.receiptKind),
                _formatStamp(receipt.observedAtDevice),
              ),
              style: textTheme.bodySmall?.copyWith(color: colors.tealDeep),
            ),
          ),
        if (receipt == null && order.receivedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.deviceLedgerRepliedAt(_formatStamp(order.receivedAt!)),
              style: textTheme.bodySmall?.copyWith(color: colors.p600),
            ),
          ),
        if (order.failureReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.deviceLedgerReceiptFailure(order.failureReason!),
              style: textTheme.bodySmall?.copyWith(color: colors.amberDeep),
            ),
          ),
      ],
    );
  }

  String _typeWord(AppLocalizations l10n) => switch (order.commandType) {
    FoundationGateCommandType.lockNow => l10n.deviceLedgerTypeLock,
    FoundationGateCommandType.releaseLock => l10n.deviceLedgerTypeRelease,
    FoundationGateCommandType.refreshPolicy => l10n.deviceLedgerTypeRefresh,
  };

  String _stateWord(AppLocalizations l10n, FoundationGateCommandState state) =>
      switch (state) {
        FoundationGateCommandState.accepted => l10n.deviceLedgerCommandAccepted,
        FoundationGateCommandState.dispatched => l10n.deviceLedgerCommandDispatched,
        FoundationGateCommandState.received => l10n.deviceLedgerCommandReceived,
        FoundationGateCommandState.applied => l10n.deviceLedgerCommandApplied,
        FoundationGateCommandState.limited => l10n.deviceLedgerCommandLimited,
        FoundationGateCommandState.rejected => l10n.deviceLedgerCommandRejected,
        FoundationGateCommandState.expired => l10n.deviceLedgerCommandExpired,
        FoundationGateCommandState.failed => l10n.deviceLedgerCommandFailed,
      };

  String _receiptWord(
    AppLocalizations l10n,
    FoundationGateCommandReceiptKind kind,
  ) => switch (kind) {
    FoundationGateCommandReceiptKind.applied => l10n.deviceLedgerCommandApplied,
    FoundationGateCommandReceiptKind.limited => l10n.deviceLedgerCommandLimited,
    FoundationGateCommandReceiptKind.failed => l10n.deviceLedgerCommandClosed,
  };

  IconData _iconFor(FoundationGateCommandState state) => switch (state) {
    FoundationGateCommandState.accepted => Icons.hourglass_top_outlined,
    FoundationGateCommandState.dispatched => Icons.send_outlined,
    FoundationGateCommandState.received => Icons.download_for_offline_outlined,
    FoundationGateCommandState.applied => Icons.verified_outlined,
    FoundationGateCommandState.limited => Icons.error_outline,
    FoundationGateCommandState.rejected => Icons.block_outlined,
    FoundationGateCommandState.expired => Icons.timer_off_outlined,
    FoundationGateCommandState.failed => Icons.priority_high_rounded,
  };

  Color _colorFor(BuildContext context, FoundationGateCommandState state) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return switch (state) {
      FoundationGateCommandState.applied => colors.mintInk,
      FoundationGateCommandState.limited => colors.amberDeep,
      FoundationGateCommandState.rejected => colors.coral,
      FoundationGateCommandState.expired => colors.ink2,
      FoundationGateCommandState.failed => colors.coral,
      _ => colors.p600,
    };
  }
}

/// The six states the spine can report about a capability, in the words the shared badge owns.
///
/// The mapping lives here, beside the ledger, so the design system keeps no knowledge of spine
/// types: the badge knows how `confirmed` and `revoked` should look, and only this screen knows
/// that a ledger row is where a family reads them.
DeviceCapabilityHonestyState _badgeStateFor(
  FoundationGateCapabilityState state,
) => switch (state) {
  FoundationGateCapabilityState.confirmed =>
    DeviceCapabilityHonestyState.confirmed,
  FoundationGateCapabilityState.awaitingSetup =>
    DeviceCapabilityHonestyState.awaitingSetup,
  FoundationGateCapabilityState.permissionNeeded =>
    DeviceCapabilityHonestyState.permissionNeeded,
  FoundationGateCapabilityState.unsupported =>
    DeviceCapabilityHonestyState.unsupported,
  FoundationGateCapabilityState.revoked => DeviceCapabilityHonestyState.revoked,
  FoundationGateCapabilityState.unknown => DeviceCapabilityHonestyState.unknown,
};

/// `HH:mm · yyyy-MM-dd` in the device's own clock. No locale library and no fake relative time:
/// a guardian comparing two rows must be able to read the exact minute the phone said it.
String _formatStamp(DateTime at) {
  final local = at.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)} · '
      '${local.year}-${two(local.month)}-${two(local.day)}';
}
