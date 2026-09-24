import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/components.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/adult_invite_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

abstract final class Sys3Keys {
  static const mockBanner = Key('sys3_mock_honesty');
  static const success = Key('sys3_success');
  static const error = Key('sys3_error');
  static const denied = Key('sys3_denied');
  static const sessionRestore = Key('sys3_session_restore');
  static const sessionExpired = Key('sys3_session_expired');
  static const logout = Key('sys3_logout');
  static const recovery = Key('sys3_account_recovery');
  static const deactivate = Key('sys3_account_deactivate');
  static const familySelector = Key('sys3_family_selector');
  static const removeAdult = Key('sys3_remove_adult');
  static const ownershipTransfer = Key('sys3_ownership_transfer');
  static const leaveFamily = Key('sys3_leave_family');
  static const inviteStatus = Key('sys3_invite_status');
  static const adultSessions = Key('sys3_adult_sessions');
  static const childSessions = Key('sys3_child_sessions');
  static const remoteEnd = Key('sys3_remote_end');
  static const revokeConfirm = Key('sys3_revoke_confirm');

  static Key family(String id) => Key('sys3_family_$id');
  static Key member(String id) => Key('sys3_member_$id');
  static Key session(String id) => Key('sys3_session_$id');
  static Key enrollment(String id) => Key('sys3_enrollment_$id');
  static Key inviteState(InviteLifecycleState state) =>
      Key('sys3_invite_${state.name}');
}

IdentityRuntime _runtime(BuildContext context) => CurrentIdentity.of(context);

class _Sys3Page extends StatelessWidget {
  const _Sys3Page({
    required this.screenKey,
    required this.title,
    required this.body,
    required this.children,
  });

  final Key screenKey;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: screenKey,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          title,
          style: TextStyle(
            color: colors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              body,
              style: TextStyle(
                color: colors.ink2,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            BannerNote(
              key: Sys3Keys.mockBanner,
              message: AppLocalizations.of(context).sys3MockHonesty,
              variant: BannerVariant.a,
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _result(
  AppLocalizations l10n, {
  required bool success,
  bool denied = false,
  String? message,
}) {
  if (denied) {
    return AppEmptyState(
      key: Sys3Keys.denied,
      title: l10n.sys3DeniedTitle,
      message: message ?? l10n.sys3DeniedBody,
    );
  }
  return AppEmptyState(
    key: success ? Sys3Keys.success : Sys3Keys.error,
    title: success ? l10n.sys3SuccessTitle : l10n.sys3ErrorTitle,
    message: message ?? (success ? l10n.sys3SuccessBody : l10n.sys3ErrorBody),
  );
}

class SessionRestoreScreen extends StatefulWidget {
  const SessionRestoreScreen({super.key, this.onRestored});
  final VoidCallback? onRestored;

  @override
  State<SessionRestoreScreen> createState() => _SessionRestoreScreenState();
}

class _SessionRestoreScreenState extends State<SessionRestoreScreen> {
  bool? _restored;

  void _restore() {
    final runtime = _runtime(context);
    final ok = runtime.restoreSession(runtime.activeSessionId);
    setState(() => _restored = ok);
    if (ok) widget.onRestored?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Sys3Page(
      screenKey: Sys3Keys.sessionRestore,
      title: l10n.sys3SessionRestoreTitle,
      body: l10n.sys3SessionRestoreBody,
      children: [
        if (_restored != null) _result(l10n, success: _restored!),
        if (_restored == null)
          PrimaryBtn(
            key: const Key('sys3_restore_action'),
            label: l10n.sys3SessionRestoreAction,
            onPressed: _restore,
          ),
      ],
    );
  }
}

class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Sys3Page(
      screenKey: Sys3Keys.sessionExpired,
      title: l10n.sys3SessionExpiredTitle,
      body: l10n.sys3SessionExpiredBody,
      children: [
        PrimaryBtn(
          key: const Key('sys3_expired_restore'),
          label: l10n.sys3SessionRestoreAction,
          onPressed: () => context.push('/sys3-session-restore'),
        ),
        const SizedBox(height: 8),
        PrimaryBtn(
          key: const Key('sys3_expired_login'),
          label: l10n.sys3SignInAgain,
          variant: PrimaryBtnVariant.ghost,
          onPressed: () => context.go('/scr-shr-003'),
        ),
      ],
    );
  }
}

class LogoutConfirmScreen extends StatefulWidget {
  const LogoutConfirmScreen({super.key});

  @override
  State<LogoutConfirmScreen> createState() => _LogoutConfirmScreenState();
}

class _LogoutConfirmScreenState extends State<LogoutConfirmScreen> {
  bool? _done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Sys3Page(
      screenKey: Sys3Keys.logout,
      title: l10n.sys3LogoutTitle,
      body: l10n.sys3LogoutBody,
      children: [
        if (_done != null)
          _result(l10n, success: _done!)
        else
          PrimaryBtn(
            key: const Key('sys3_logout_action'),
            label: l10n.sys3LogoutAction,
            onPressed: () {
              final ok = _runtime(context).logoutCurrentSession();
              setState(() => _done = ok);
            },
          ),
      ],
    );
  }
}

class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  final _email = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Sys3Page(
      screenKey: Sys3Keys.recovery,
      title: l10n.sys3RecoveryTitle,
      body: l10n.sys3RecoveryBody,
      children: [
        if (_done)
          _result(l10n, success: true, message: l10n.sys3RecoverySuccess)
        else ...[
          Semantics(
            textField: true,
            label: l10n.loginEmailLabel,
            child: TextField(
              key: const Key('sys3_recovery_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.loginEmailLabel),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: const Key('sys3_recovery_action'),
            label: l10n.sys3RecoveryAction,
            onPressed: () => setState(() => _done = true),
          ),
        ],
      ],
    );
  }
}

class AccountDeactivateScreen extends StatefulWidget {
  const AccountDeactivateScreen({super.key});

  @override
  State<AccountDeactivateScreen> createState() =>
      _AccountDeactivateScreenState();
}

class _AccountDeactivateScreenState extends State<AccountDeactivateScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Sys3Page(
      screenKey: Sys3Keys.deactivate,
      title: l10n.sys3DeactivateTitle,
      body: l10n.sys3DeactivateBody,
      children: [
        if (_done)
          _result(l10n, success: true, message: l10n.sys3DeactivateSuccess)
        else
          PrimaryBtn(
            key: const Key('sys3_deactivate_action'),
            label: l10n.sys3DeactivateAction,
            onPressed: () {
              _runtime(context).deactivateAccount();
              setState(() => _done = true);
            },
          ),
      ],
    );
  }
}

class FamilySelectorScreen extends StatefulWidget {
  const FamilySelectorScreen({super.key, this.onSelected});
  final ValueChanged<FamilyId>? onSelected;

  @override
  State<FamilySelectorScreen> createState() => _FamilySelectorScreenState();
}

class _FamilySelectorScreenState extends State<FamilySelectorScreen> {
  bool _autoScheduled = false;

  void _complete(FamilyId id) {
    final runtime = _runtime(context);
    runtime.switchActiveFamily(id);
    if (widget.onSelected != null) {
      widget.onSelected!(id);
      return;
    }
    context.go('/scr-fat-010');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoScheduled) return;
    final memberships = _runtime(
      context,
    ).membershipsForAccount(_runtime(context).account.id);
    if (memberships.length != 1) return;
    _autoScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _complete(memberships.single.familyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runtime = _runtime(context);
    final memberships = runtime.membershipsForAccount(runtime.account.id);
    return _Sys3Page(
      screenKey: Sys3Keys.familySelector,
      title: l10n.sys3FamilySelectTitle,
      body: memberships.length <= 1
          ? l10n.sys3FamilySingle
          : l10n.sys3FamilySelectBody,
      children: [
        if (memberships.isEmpty)
          AppEmptyState(
            title: l10n.sys3FamilySelectTitle,
            message: l10n.sys3SessionsEmpty,
          )
        else
          for (final membership in memberships)
            ListTile(
              key: Sys3Keys.family(membership.familyId.value),
              minTileHeight: 48,
              title: Text(
                runtime.families
                    .firstWhere((family) => family.id == membership.familyId)
                    .name,
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _complete(membership.familyId),
            ),
      ],
    );
  }
}

class RemoveAdultScreen extends StatefulWidget {
  const RemoveAdultScreen({super.key, this.memberId});
  final String? memberId;

  @override
  State<RemoveAdultScreen> createState() => _RemoveAdultScreenState();
}

class _RemoveAdultScreenState extends State<RemoveAdultScreen> {
  bool? _resultValue;

  void _remove() {
    final runtime = _runtime(context);
    final auth = resolveAuthorizationContext(context);
    if (!auth.isPrimaryOwner) {
      setState(() => _resultValue = false);
      return;
    }
    final raw = widget.memberId?.trim();
    final ok =
        raw != null &&
        raw.isNotEmpty &&
        runtime.removeAdultMember(
          familyId: runtime.activeFamilyId,
          targetMemberId: MemberId(raw),
        );
    setState(() => _resultValue = ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = resolveAuthorizationContext(context);
    return _Sys3Page(
      screenKey: Sys3Keys.removeAdult,
      title: l10n.sys3RemoveAdultTitle,
      body: l10n.sys3RemoveAdultBody,
      children: [
        if (!auth.isPrimaryOwner)
          _result(l10n, success: false, denied: true)
        else if (_resultValue != null)
          _result(l10n, success: _resultValue!)
        else
          PrimaryBtn(
            key: const Key('sys3_remove_adult_action'),
            label: l10n.sys3RemoveAdultAction,
            onPressed: _remove,
          ),
      ],
    );
  }
}

class OwnershipTransferScreen extends StatefulWidget {
  const OwnershipTransferScreen({super.key});

  @override
  State<OwnershipTransferScreen> createState() =>
      _OwnershipTransferScreenState();
}

class _OwnershipTransferScreenState extends State<OwnershipTransferScreen> {
  MemberId? _selected;
  OwnershipTransferResult? _resultValue;
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final runtime = _runtime(context);
    final candidates = runtime
        .adultMembershipsForFamily(runtime.activeFamilyId)
        .where((member) => !member.isPrimaryOwner)
        .toList(growable: false);
    _selected = candidates.isEmpty ? null : candidates.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runtime = _runtime(context);
    final auth = resolveAuthorizationContext(context);
    final candidates = runtime
        .adultMembershipsForFamily(runtime.activeFamilyId)
        .where((member) => !member.isPrimaryOwner)
        .toList(growable: false);
    return _Sys3Page(
      screenKey: Sys3Keys.ownershipTransfer,
      title: l10n.sys3TransferTitle,
      body: l10n.sys3TransferBody,
      children: [
        if (_resultValue != null)
          _result(
            l10n,
            success: _resultValue == OwnershipTransferResult.success,
            denied: _resultValue == OwnershipTransferResult.denied,
          )
        else if (!auth.isPrimaryOwner)
          _result(l10n, success: false, denied: true)
        else if (candidates.isEmpty)
          AppEmptyState(
            title: l10n.sys3TransferTitle,
            message: l10n.sys3SessionsEmpty,
          )
        else ...[
          for (final candidate in candidates)
            ListTile(
              key: Sys3Keys.member(candidate.id.value),
              minTileHeight: 48,
              selected: _selected == candidate.id,
              title: Text(l10n.sys3MemberLabel(candidate.id.value)),
              trailing: Icon(
                _selected == candidate.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              onTap: () => setState(() => _selected = candidate.id),
            ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: const Key('sys3_transfer_action'),
            label: l10n.sys3TransferAction,
            onPressed: _selected == null
                ? null
                : () => setState(
                    () => _resultValue = runtime.transferOwnership(
                      familyId: runtime.activeFamilyId,
                      toMemberId: _selected!,
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class LeaveFamilyConfirmScreen extends StatefulWidget {
  const LeaveFamilyConfirmScreen({super.key});

  @override
  State<LeaveFamilyConfirmScreen> createState() =>
      _LeaveFamilyConfirmScreenState();
}

class _LeaveFamilyConfirmScreenState extends State<LeaveFamilyConfirmScreen> {
  bool? _done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runtime = _runtime(context);
    final canLeave = resolveAuthorizationContext(context).canLeaveFamily;
    return _Sys3Page(
      screenKey: Sys3Keys.leaveFamily,
      title: l10n.sys3LeaveTitle,
      body: l10n.sys3LeaveBody,
      children: [
        if (!canLeave)
          _result(l10n, success: false, denied: true)
        else if (_done != null)
          _result(l10n, success: _done!)
        else
          PrimaryBtn(
            key: const Key('sys3_leave_action'),
            label: l10n.sys3LeaveAction,
            onPressed: () => setState(
              () => _done = runtime.leaveFamily(
                accountId: runtime.account.id,
                familyId: runtime.activeFamilyId,
              ),
            ),
          ),
      ],
    );
  }
}

class InviteStatusScreen extends StatefulWidget {
  const InviteStatusScreen({super.key, this.inviteTokenId, this.repository});

  final String? inviteTokenId;
  final AdultInviteRepository? repository;

  @override
  State<InviteStatusScreen> createState() => _InviteStatusScreenState();
}

class _InviteStatusScreenState extends State<InviteStatusScreen> {
  late final TextEditingController _token;
  AdultInvite? _invite;
  bool _lookedUp = false;

  @override
  void initState() {
    super.initState();
    _token = TextEditingController(text: widget.inviteTokenId ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  void _lookup() {
    final raw = _token.text.trim();
    setState(() {
      _lookedUp = raw.isNotEmpty;
      _invite = raw.isEmpty
          ? null
          : (widget.repository ?? stage1AdultInviteRepository).findByToken(
              InviteTokenId(raw),
            );
    });
  }

  String _stateLabel(AppLocalizations l10n, InviteLifecycleState state) {
    return switch (state) {
      InviteLifecycleState.created => l10n.inviteLifecyclePending,
      InviteLifecycleState.active => l10n.inviteLifecycleActive,
      InviteLifecycleState.accepted => l10n.inviteLifecycleAccepted,
      InviteLifecycleState.expired => l10n.inviteLifecycleExpired,
      InviteLifecycleState.revoked => l10n.inviteLifecycleRevoked,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _invite?.stateAt(DateTime.now().toUtc());
    return _Sys3Page(
      screenKey: Sys3Keys.inviteStatus,
      title: l10n.sys3InviteStatusTitle,
      body: l10n.sys3InviteStatusBody,
      children: [
        Semantics(
          textField: true,
          label: l10n.sys3InviteTokenLabel,
          child: TextField(
            key: const Key('sys3_invite_token'),
            controller: _token,
            decoration: InputDecoration(labelText: l10n.sys3InviteTokenLabel),
          ),
        ),
        const SizedBox(height: 10),
        PrimaryBtn(
          key: const Key('sys3_invite_lookup'),
          label: l10n.sys3InviteLookupAction,
          onPressed: _lookup,
        ),
        const SizedBox(height: 12),
        if (_lookedUp && _invite == null)
          AppEmptyState(
            key: Sys3Keys.error,
            title: l10n.sys3InviteStatusTitle,
            message: l10n.sys3InviteUnknown,
          )
        else if (state != null)
          Tag(
            key: Sys3Keys.inviteState(state),
            label: _stateLabel(l10n, state),
            variant: state == InviteLifecycleState.accepted
                ? TagVariant.g
                : TagVariant.a,
          ),
      ],
    );
  }
}

class AdultSessionsScreen extends StatelessWidget {
  const AdultSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runtime = _runtime(context);
    final sessions = runtime.adultSessions;
    return _Sys3Page(
      screenKey: Sys3Keys.adultSessions,
      title: l10n.sys3AdultSessionsTitle,
      body: l10n.sys3MockHonesty,
      children: [
        if (sessions.isEmpty)
          AppEmptyState(
            title: l10n.sys3AdultSessionsTitle,
            message: l10n.sys3SessionsEmpty,
          )
        else
          for (final session in sessions)
            ListTile(
              key: Sys3Keys.session(session.id.value),
              minTileHeight: 48,
              title: Text(l10n.sys3SessionLabel(session.id.value)),
              trailing: TextButton(
                key: Key('sys3_revoke_session_${session.id.value}'),
                onPressed: session.isRevoked
                    ? null
                    : () => context.push(
                        '/sys3-revoke-confirm?kind=session&id=${Uri.encodeComponent(session.id.value)}',
                      ),
                child: Text(l10n.sys3RevokeAction),
              ),
            ),
      ],
    );
  }
}

class ChildSessionsScreen extends StatelessWidget {
  const ChildSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final runtime = _runtime(context);
    final enrollments = runtime.enrollments
        .where(
          (enrollment) =>
              enrollment.familyId == runtime.activeFamilyId &&
              enrollment.isActive,
        )
        .toList(growable: false);
    return _Sys3Page(
      screenKey: Sys3Keys.childSessions,
      title: l10n.sys3ChildSessionsTitle,
      body: l10n.sys3MockHonesty,
      children: [
        if (enrollments.isEmpty)
          AppEmptyState(
            title: l10n.sys3ChildSessionsTitle,
            message: l10n.sys3SessionsEmpty,
          )
        else
          for (final enrollment in enrollments)
            ListTile(
              key: Sys3Keys.enrollment(enrollment.id.value),
              minTileHeight: 48,
              title: Text(l10n.sys3EnrollmentLabel(enrollment.id.value)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push(
                '/sys3-remote-end?enrollmentId=${Uri.encodeComponent(enrollment.id.value)}&childId=${Uri.encodeComponent(enrollment.childId.value)}',
              ),
            ),
      ],
    );
  }
}

class RemoteEndChildSessionScreen extends StatefulWidget {
  const RemoteEndChildSessionScreen({
    super.key,
    this.enrollmentId,
    this.childId,
  });

  final String? enrollmentId;
  final String? childId;

  @override
  State<RemoteEndChildSessionScreen> createState() =>
      _RemoteEndChildSessionScreenState();
}

class _RemoteEndChildSessionScreenState
    extends State<RemoteEndChildSessionScreen> {
  bool? _done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = resolveAuthorizationContext(context);
    return _Sys3Page(
      screenKey: Sys3Keys.remoteEnd,
      title: l10n.sys3RemoteEndTitle,
      body: l10n.sys3RemoteEndBody,
      children: [
        if (!auth.isPrimaryOwner)
          _result(l10n, success: false, denied: true)
        else if (_done != null)
          _result(l10n, success: _done!)
        else
          PrimaryBtn(
            key: const Key('sys3_remote_end_action'),
            label: l10n.sys3RemoteEndAction,
            onPressed: () {
              final id = widget.enrollmentId?.trim();
              final ok =
                  id != null &&
                  id.isNotEmpty &&
                  _runtime(context).endChildSessionRemotely(EnrollmentId(id));
              setState(() => _done = ok);
            },
          ),
      ],
    );
  }
}

class RevokeConfirmScreen extends StatefulWidget {
  const RevokeConfirmScreen({super.key, this.kind, this.id});
  final String? kind;
  final String? id;

  @override
  State<RevokeConfirmScreen> createState() => _RevokeConfirmScreenState();
}

class _RevokeConfirmScreenState extends State<RevokeConfirmScreen> {
  bool? _done;

  void _revoke() {
    final runtime = _runtime(context);
    final raw = widget.id?.trim();
    if (raw == null || raw.isEmpty) {
      setState(() => _done = false);
      return;
    }
    if (widget.kind == 'enrollment') {
      if (!resolveAuthorizationContext(context).isPrimaryOwner) {
        setState(() => _done = false);
        return;
      }
      runtime.revokeEnrollment(EnrollmentId(raw));
      setState(() => _done = true);
      return;
    }
    setState(() => _done = runtime.revokeSession(SessionId(raw)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Sys3Page(
      screenKey: Sys3Keys.revokeConfirm,
      title: l10n.sys3RevokeTitle,
      body: l10n.sys3RevokeBody,
      children: [
        if (_done != null)
          _result(l10n, success: _done!)
        else
          PrimaryBtn(
            key: const Key('sys3_revoke_action'),
            label: l10n.sys3RevokeAction,
            onPressed: _revoke,
          ),
      ],
    );
  }
}
