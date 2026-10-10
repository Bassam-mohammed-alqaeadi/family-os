import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/runtime/family_invite_code_source.dart';
import 'package:family_os/features/n01_linking/invite_mother_screen.dart';

import 'invite_code_fakes.dart';

/// SCR-FAT-008 — invites by code (owner decision 2026-10-10). The screen shows a code only
/// when the server issued one, and keeps nothing on the phone.
void main() {
  tearDown(AppToast.dismiss);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'before issuing: no code, no email field, no level picker, honest banner',
    (tester) async {
      final source = FakeInviteCodeSource();
      await pumpWithInviteCodes(
        tester,
        source: source,
        identity: guardianSnapshot(),
        home: const InviteMotherScreen(),
      );

      expect(find.byKey(const Key('invite_code_issue')), findsOneWidget);
      expect(find.byKey(const Key('invite_code_value')), findsNothing);
      expect(find.byKey(const Key('invite_mother_email')), findsNothing);
      expect(
        find.byKey(const Key('invite_mother_level_partner')),
        findsNothing,
      );
      expect(find.byKey(const Key('invite_code_honesty')), findsOneWidget);
      expect(find.textContaining('مرة واحدة فقط'), findsOneWidget);
      expect(find.textContaining('لم تُحفظ على الخادم'), findsOneWidget);
      expect(
        source.issued,
        isEmpty,
        reason: 'nothing is issued until the guardian asks',
      );
    },
  );

  testWidgets(
    'issue → the server\'s code is shown once, for the selected family, as co-guardian',
    (tester) async {
      final source = FakeInviteCodeSource();
      await pumpWithInviteCodes(
        tester,
        source: source,
        identity: guardianSnapshot(),
        home: const InviteMotherScreen(),
      );

      await tester.tap(find.byKey(const Key('invite_code_issue')));
      await tester.pumpAndSettle();

      expect(source.issued, hasLength(1));
      expect(source.issued.single.familyId.value, inviteTestFamilyUuid);
      expect(source.issued.single.role, 'co_guardian');
      expect(find.byKey(const Key('invite_code_value')), findsOneWidget);
      expect(find.text('ABCDE-FGHJK'), findsOneWidget);
      expect(find.byKey(const Key('invite_code_expiry')), findsOneWidget);
      expect(find.byKey(const Key('invite_code_issue')), findsNothing);
    },
  );

  testWidgets('copy puts exactly the code on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpWithInviteCodes(
      tester,
      source: FakeInviteCodeSource(),
      identity: guardianSnapshot(),
      home: const InviteMotherScreen(),
    );
    await tester.tap(find.byKey(const Key('invite_code_issue')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('invite_code_copy')));
    await tester.tap(find.byKey(const Key('invite_code_copy')));
    await tester.pump();
    expect(copied, 'ABCDE-FGHJK');
    await settle(tester);
  });

  testWidgets('revoke → the code disappears only after the server confirms', (
    tester,
  ) async {
    final source = FakeInviteCodeSource(
      revokeResult: const InviteCodeRevokeResult.failed(
        InviteCodeFailure.networkUnavailable,
      ),
    );
    await pumpWithInviteCodes(
      tester,
      source: source,
      identity: guardianSnapshot(),
      home: const InviteMotherScreen(),
    );
    await tester.tap(find.byKey(const Key('invite_code_issue')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('invite_code_revoke')));
    await tester.tap(find.byKey(const Key('invite_code_revoke')));
    await tester.pumpAndSettle();
    expect(
      source.revoked.single.inviteId,
      FakeInviteCodeSource.sampleCode().inviteId,
    );
    expect(
      find.text('ABCDE-FGHJK'),
      findsOneWidget,
      reason: 'a refused revoke keeps the code on screen',
    );
    expect(
      find.byKey(const Key('invite_code_error_networkUnavailable')),
      findsOneWidget,
    );

    source.revokeResult = const InviteCodeRevokeResult.revoked();
    await tester.ensureVisible(find.byKey(const Key('invite_code_revoke')));
    await tester.tap(find.byKey(const Key('invite_code_revoke')));
    await tester.pumpAndSettle();
    expect(find.text('ABCDE-FGHJK'), findsNothing);
    expect(find.byKey(const Key('invite_code_revoked')), findsOneWidget);
    expect(find.byKey(const Key('invite_code_issue')), findsOneWidget);
    await settle(tester);
  });

  for (final (failure, text) in [
    (InviteCodeFailure.limitReached, '٥ رموز مفتوحة'),
    (InviteCodeFailure.accessDenied, 'لوليّ الأمر الأساسي فقط'),
    (InviteCodeFailure.networkUnavailable, 'تعذّر الوصول إلى الخادم'),
    (InviteCodeFailure.unavailable, 'لم يُنشأ أي رمز'),
  ]) {
    testWidgets(
      'a refused issue says why (${failure.name}) and shows no code',
      (tester) async {
        final source = FakeInviteCodeSource(
          issueResult: InviteCodeIssueResult.failed(failure),
        );
        await pumpWithInviteCodes(
          tester,
          source: source,
          identity: guardianSnapshot(),
          home: const InviteMotherScreen(),
        );
        await tester.tap(find.byKey(const Key('invite_code_issue')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(Key('invite_code_error_${failure.name}')),
          findsOneWidget,
        );
        expect(find.textContaining(text), findsOneWidget);
        expect(find.byKey(const Key('invite_code_value')), findsNothing);
      },
    );
  }

  testWidgets(
    'a retry after a refusal is a new request (codes are never replayed)',
    (tester) async {
      final source = FakeInviteCodeSource(
        issueResult: const InviteCodeIssueResult.failed(
          InviteCodeFailure.networkUnavailable,
        ),
      );
      await pumpWithInviteCodes(
        tester,
        source: source,
        identity: guardianSnapshot(),
        home: const InviteMotherScreen(),
      );
      await tester.tap(find.byKey(const Key('invite_code_issue')));
      await tester.pumpAndSettle();
      source.issueResult = null;
      await tester.tap(find.byKey(const Key('invite_code_issue')));
      await tester.pumpAndSettle();
      expect(source.issued, hasLength(2));
      expect(source.issued[0].key, isNot(source.issued[1].key));
      expect(find.text('ABCDE-FGHJK'), findsOneWidget);
    },
  );

  testWidgets('without a server family the screen says so and calls nothing', (
    tester,
  ) async {
    final source = FakeInviteCodeSource();
    await pumpWithInviteCodes(
      tester,
      source: source,
      home: const InviteMotherScreen(),
    );
    await tester.tap(find.byKey(const Key('invite_code_issue')));
    await tester.pumpAndSettle();
    expect(source.issued, isEmpty);
    expect(
      find.byKey(const Key('invite_code_error_unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('done → family members (/scr-fat-027)', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-008',
      routes: [
        GoRoute(
          path: '/scr-fat-008',
          builder: (context, state) => const InviteMotherScreen(),
        ),
        GoRoute(
          path: '/scr-fat-027',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-027',
            title: 'أعضاء العائلة',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpWithInviteCodes(
      tester,
      source: FakeInviteCodeSource(),
      identity: guardianSnapshot(),
      router: router,
    );
    await tester.ensureVisible(find.byKey(const Key('invite_code_done')));
    await tester.tap(find.byKey(const Key('invite_code_done')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-027');
  });

  testWidgets('English locale renders the code flow', (tester) async {
    await pumpWithInviteCodes(
      tester,
      source: FakeInviteCodeSource(),
      identity: guardianSnapshot(),
      home: const InviteMotherScreen(),
      locale: const Locale('en'),
    );
    expect(find.text('Create invite code'), findsOneWidget);
    await tester.tap(find.byKey(const Key('invite_code_issue')));
    await tester.pumpAndSettle();
    expect(find.text('ABCDE-FGHJK'), findsOneWidget);
    expect(find.textContaining('single use'), findsOneWidget);
  });
}
