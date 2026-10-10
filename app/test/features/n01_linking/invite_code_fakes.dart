import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_invite_code_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';

/// A scripted invite-code source for screen tests.
///
/// It records every call, so a test can prove that a refusal never produced a second write
/// and that a retry reused its idempotency key. It holds no rules of its own: whatever the
/// test scripts is what the "server" answered.
final class FakeInviteCodeSource implements FamilyInviteCodeSource {
  FakeInviteCodeSource({
    this.issueResult,
    this.revokeResult = const InviteCodeRevokeResult.revoked(),
    this.redeemResults = const [],
  });

  InviteCodeIssueResult? issueResult;
  InviteCodeRevokeResult revokeResult;
  List<InviteCodeRedeemResult> redeemResults;

  final List<({FamilyId familyId, String role, String key})> issued = [];
  final List<({FamilyId familyId, String inviteId})> revoked = [];
  final List<({String code, String key})> redeemed = [];

  static IssuedInviteCode sampleCode({
    String code = 'ABCDE-FGHJK',
    String inviteId = '11111111-1111-4111-8111-111111111111',
  }) => IssuedInviteCode(
    inviteId: inviteId,
    code: code,
    role: 'co_guardian',
    expiresAt: DateTime.utc(2030, 1, 2, 9),
  );

  @override
  Future<InviteCodeIssueResult> issue({
    required FamilyId familyId,
    required String role,
    required String idempotencyKey,
  }) async {
    issued.add((familyId: familyId, role: role, key: idempotencyKey));
    return issueResult ?? InviteCodeIssueResult.issued(sampleCode());
  }

  @override
  Future<InviteCodeRevokeResult> revoke({
    required FamilyId familyId,
    required String inviteId,
    required String idempotencyKey,
  }) async {
    revoked.add((familyId: familyId, inviteId: inviteId));
    return revokeResult;
  }

  @override
  Future<InviteCodeRedeemResult> redeem({
    required String code,
    required String idempotencyKey,
  }) async {
    redeemed.add((code: code, key: idempotencyKey));
    final index = redeemed.length - 1;
    if (redeemResults.isEmpty) {
      return const InviteCodeRedeemResult.failed(
        InviteCodeFailure.notRedeemable,
      );
    }
    return redeemResults[index < redeemResults.length
        ? index
        : redeemResults.length - 1];
  }

  @override
  void dispose() {}
}

/// A fixed identity snapshot, as the composed runtime would publish it.
final class StaticInviteIdentity extends ChangeNotifier
    implements IdentitySource {
  StaticInviteIdentity(this._value);

  final IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async => _value;
}

const String inviteTestFamilyUuid = '22222222-2222-4222-8222-222222222222';

/// A signed-in primary guardian with a selected server family.
IdentitySnapshot guardianSnapshot() => IdentitySnapshot(
  authority: IdentityAuthority.remoteAuthoritative,
  accountId: AccountId('acc_owner'),
  familyId: FamilyId(inviteTestFamilyUuid),
  isPrimaryOwner: true,
  role: AppRole.father,
);

/// Pumps [router] (or [home]) under an [AppScope] whose only invite-code capability is
/// [source], exactly as the product route composes it.
Future<AppRuntime> pumpWithInviteCodes(
  WidgetTester tester, {
  required FamilyInviteCodeSource source,
  IdentitySnapshot? identity,
  GoRouter? router,
  Widget? home,
  Locale locale = const Locale('ar'),
}) async {
  final runtime = AppRuntime(
    identity: StaticInviteIdentity(
      identity ?? const IdentitySnapshot.unavailable(),
    ),
    inviteCodes: source,
  );
  addTearDown(runtime.dispose);
  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  await tester.pumpWidget(
    AppScope(
      runtime: runtime,
      child: router != null
          ? MaterialApp.router(
              theme: buildFamilyTheme(),
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: delegates,
              routerConfig: router,
            )
          : MaterialApp(
              theme: buildFamilyTheme(),
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: delegates,
              home: home,
            ),
    ),
  );
  await tester.pumpAndSettle();
  return runtime;
}
