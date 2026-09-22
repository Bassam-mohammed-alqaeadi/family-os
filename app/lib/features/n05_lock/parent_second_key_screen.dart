import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n05_lock/child_mode_lock_service.dart';

/// Widget keys for SCR-FAT-030 acceptance.
abstract final class ParentSecondKeyKeys {
  static const screen = Key('parent_second_key_screen');
  static const emptyInbox = Key('parent_second_key_empty');
  static const pendingCard = Key('parent_second_key_pending');
  static const attemptsLog = Key('parent_second_key_attempts');
  static const attemptsEmpty = Key('parent_second_key_attempts_empty');
  static const lockoutHint = Key('parent_second_key_lockout_hint');
  static const motherHint = Key('parent_second_key_mother_hint');
  static const childLean = Key('parent_second_key_child_lean');
  static const sosCta = Key('parent_second_key_sos');
  static const sosIconCta = Key('parent_second_key_sos_icon');
  static const backButton = Key('parent_second_key_back');

  static Key approve(String id) => Key('parent_second_key_approve_$id');
  static Key deny(String id) => Key('parent_second_key_deny_$id');
  static Key attemptRow(int index) => Key('parent_second_key_attempt_$index');
}

/// Temporary parent-mode window granted by the second key (prototype).
const Duration kParentSecondKeyWindow = Duration(minutes: 10);

/// SCR-FAT-030 — طلب فتح وضع الوالد (المفتاح الثاني).
///
/// Prototype FAT-030 · ADR-017 layer 3: father holds the second key. Lists
/// pending CHD-011 unlock requests + failed-attempt log. Allow = 10-minute
/// parent-mode window; deny keeps child locked. Mother sees inbox/log but
/// cannot decide (key stays with father). Child lean. P-4 SOS · Rule 12/23.
class ParentSecondKeyScreen extends StatefulWidget {
  const ParentSecondKeyScreen({
    super.key,
    this.lockService,
    this.sosFire,
    this.roleOverride,
    this.onBack,
    this.onSos,
    this.approveWindow = kParentSecondKeyWindow,
  });

  /// Rule 25 seam — null → [stage1ChildModeLockService].
  final ChildModeLockService? lockService;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  final VoidCallback? onBack;
  final VoidCallback? onSos;

  /// Duration of temporary parent-mode grant (prototype: 10 minutes).
  final Duration approveWindow;

  @override
  State<ParentSecondKeyScreen> createState() => _ParentSecondKeyScreenState();
}

class _ParentSecondKeyScreenState extends State<ParentSecondKeyScreen> {
  late ChildModeLockService _lock;
  late final SosFireService _sos;
  var _sosBusy = false;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.of(context);
  }

  bool get _isChild => _role == AppRole.child;
  bool get _isFather => _role == AppRole.father;
  bool get _canDecide => _isFather;

  @override
  void initState() {
    super.initState();
    _lock = widget.lockService ?? stage1ChildModeLockService;
    _sos = widget.sosFire ?? stage1SosFireService;
    _lock.addListener(_onLock);
    _lock.notifyBus.addListener(_onLock);
  }

  @override
  void didUpdateWidget(covariant ParentSecondKeyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockService != widget.lockService) {
      _lock.removeListener(_onLock);
      _lock.notifyBus.removeListener(_onLock);
      _lock = widget.lockService ?? stage1ChildModeLockService;
      _lock.addListener(_onLock);
      _lock.notifyBus.addListener(_onLock);
    }
  }

  @override
  void dispose() {
    _lock.removeListener(_onLock);
    _lock.notifyBus.removeListener(_onLock);
    super.dispose();
  }

  void _onLock() {
    if (mounted) setState(() {});
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    setState(() => _sosBusy = true);
    try {
      if (widget.onSos != null) {
        widget.onSos!();
        return;
      }
      await _sos.fire(childId: 'parent_local');
      if (!mounted) return;
      context.go(screenPath('SCR-CHD-005'));
    } finally {
      if (mounted) setState(() => _sosBusy = false);
    }
  }

  void _approve(ChildModeUnlockRequest request) {
    if (!_canDecide) return;
    _lock.approveSecondKey(window: widget.approveWindow);
    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      message: l10n.parentSecondKeyApprovedToast,
    );
  }

  void _deny(ChildModeUnlockRequest request) {
    if (!_canDecide) return;
    _lock.rejectSecondKey();
    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      message: l10n.parentSecondKeyDeniedToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ParentSecondKeyKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.parentSecondKeyTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        leading: widget.onBack == null
            ? null
            : IconButton(
                key: ParentSecondKeyKeys.backButton,
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
        actions: [
          IconButton(
            key: ParentSecondKeyKeys.sosIconCta,
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
      body: SafeArea(
        child: _isChild
            ? AppEmptyState(
                key: ParentSecondKeyKeys.childLean,
                title: l10n.parentSecondKeyChildLeanTitle,
                message: l10n.parentSecondKeyChildLeanMessage,
              )
            : _buildParentBody(context, l10n, colors),
      ),
    );
  }

  Widget _buildParentBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    final pending = _lock.awaitingSecondKeyRequests;
    final attempts = _lock.notifyBus.delivered.reversed.toList();
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending.isEmpty)
            AppEmptyState(
              key: ParentSecondKeyKeys.emptyInbox,
              title: l10n.parentSecondKeyEmptyTitle,
              message: l10n.parentSecondKeyEmptyMessage,
            )
          else
            for (final request in pending) ...[
              _PendingUnlockCard(
                request: request,
                canDecide: _canDecide,
                colors: colors,
                radii: radii,
                l10n: l10n,
                onApprove: () => _approve(request),
                onDeny: () => _deny(request),
              ),
              const SizedBox(height: 12),
            ],
          if (!_canDecide && !_isChild) ...[
            BannerNote(
              key: ParentSecondKeyKeys.motherHint,
              variant: BannerVariant.a,
              message: l10n.parentSecondKeyMotherHint,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.parentSecondKeyAttemptsTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (attempts.isEmpty)
            Text(
              key: ParentSecondKeyKeys.attemptsEmpty,
              l10n.parentSecondKeyAttemptsEmpty,
              style: TextStyle(fontSize: 13, color: colors.ink2),
            )
          else
            DecoratedBox(
              key: ParentSecondKeyKeys.attemptsLog,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < attempts.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: colors.border),
                    _AttemptRow(
                      key: ParentSecondKeyKeys.attemptRow(i),
                      event: attempts[i],
                      colors: colors,
                      l10n: l10n,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),
          BannerNote(
            key: ParentSecondKeyKeys.lockoutHint,
            variant: BannerVariant.p,
            message: l10n.parentSecondKeyLockoutHint,
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: ParentSecondKeyKeys.sosCta,
            label: l10n.parentSecondKeySosCta,
            semanticsLabel: l10n.spineCtaSosSemantics,
            variant: PrimaryBtnVariant.coral,
            onPressed: _sosBusy ? null : _openSos,
          ),
        ],
      ),
    );
  }
}

class _PendingUnlockCard extends StatelessWidget {
  const _PendingUnlockCard({
    required this.request,
    required this.canDecide,
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.onApprove,
    required this.onDeny,
  });

  final ChildModeUnlockRequest request;
  final bool canDecide;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ParentSecondKeyKeys.pendingCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.p400, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.parentSecondKeyPendingHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.parentSecondKeyPendingBody,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.parentSecondKeyPendingMeta,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colors.ink2,
              ),
            ),
            if (canDecide) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PrimaryBtn(
                      key: ParentSecondKeyKeys.deny(request.id),
                      label: l10n.parentSecondKeyDeny,
                      semanticsLabel: l10n.parentSecondKeyDenySemantics,
                      variant: PrimaryBtnVariant.coral,
                      onPressed: onDeny,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryBtn(
                      key: ParentSecondKeyKeys.approve(request.id),
                      label: l10n.parentSecondKeyApprove,
                      semanticsLabel: l10n.parentSecondKeyApproveSemantics,
                      variant: PrimaryBtnVariant.mint,
                      onPressed: onApprove,
                    ),
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

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({
    super.key,
    required this.event,
    required this.colors,
    required this.l10n,
  });

  final ChildModeUnlockNotifyEvent event;
  final FamilyColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final title = event.lockout
        ? l10n.parentSecondKeyAttemptLockout(event.attemptNumber)
        : l10n.parentSecondKeyAttemptFailed(
            event.attemptNumber,
            kChildModeLockMaxFailedAttempts,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.parentSecondKeyAttemptDevice,
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
