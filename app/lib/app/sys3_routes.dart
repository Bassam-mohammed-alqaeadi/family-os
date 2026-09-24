import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/features/sys3_identity/sys3_identity_screens.dart';

/// System #3 identity / session routes (not in screens.csv — survive outside
/// SCR-* catalog). Wired from login, settings hub, family members, profile.
List<RouteBase> get sys3IdentityRoutes => [
  GoRoute(
    path: '/sys3-session-restore',
    name: 'sys3-session-restore',
    builder: (context, state) => const SessionRestoreScreen(),
  ),
  GoRoute(
    path: '/sys3-session-expired',
    name: 'sys3-session-expired',
    builder: (context, state) => const SessionExpiredScreen(),
  ),
  GoRoute(
    path: '/sys3-logout',
    name: 'sys3-logout',
    builder: (context, state) => const LogoutConfirmScreen(),
  ),
  GoRoute(
    path: '/sys3-account-recovery',
    name: 'sys3-account-recovery',
    builder: (context, state) => const AccountRecoveryScreen(),
  ),
  GoRoute(
    path: '/sys3-account-deactivate',
    name: 'sys3-account-deactivate',
    builder: (context, state) => const AccountDeactivateScreen(),
  ),
  GoRoute(
    path: '/sys3-family-select',
    name: 'sys3-family-select',
    builder: (context, state) => const FamilySelectorScreen(),
  ),
  GoRoute(
    path: '/sys3-remove-adult',
    name: 'sys3-remove-adult',
    builder: (context, state) => RemoveAdultScreen(
      memberId: state.uri.queryParameters['memberId'],
    ),
  ),
  GoRoute(
    path: '/sys3-ownership-transfer',
    name: 'sys3-ownership-transfer',
    builder: (context, state) => const OwnershipTransferScreen(),
  ),
  GoRoute(
    path: '/sys3-leave-family',
    name: 'sys3-leave-family',
    builder: (context, state) => const LeaveFamilyConfirmScreen(),
  ),
  GoRoute(
    path: '/sys3-invite-status',
    name: 'sys3-invite-status',
    builder: (context, state) => InviteStatusScreen(
      inviteTokenId: state.uri.queryParameters['inviteTokenId'],
    ),
  ),
  GoRoute(
    path: '/sys3-adult-sessions',
    name: 'sys3-adult-sessions',
    builder: (context, state) => const AdultSessionsScreen(),
  ),
  GoRoute(
    path: '/sys3-child-sessions',
    name: 'sys3-child-sessions',
    builder: (context, state) => const ChildSessionsScreen(),
  ),
  GoRoute(
    path: '/sys3-remote-end',
    name: 'sys3-remote-end',
    builder: (context, state) => RemoteEndChildSessionScreen(
      enrollmentId: state.uri.queryParameters['enrollmentId'],
      childId: state.uri.queryParameters['childId'],
    ),
  ),
  GoRoute(
    path: '/sys3-revoke-confirm',
    name: 'sys3-revoke-confirm',
    builder: (context, state) => RevokeConfirmScreen(
      kind: state.uri.queryParameters['kind'],
      id: state.uri.queryParameters['id'],
    ),
  ),
];
