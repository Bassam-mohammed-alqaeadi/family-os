import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_conversation_mock.dart';
import 'package:family_os/features/n02_day/child_conversation_screen.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';

void main() {
  testWidgets('SCR-CHD-008 father thread + never-lock + incoming', (
    tester,
  ) async {
    await _pump(
      tester,
      chatWith: 'father',
      repo: InMemoryConversationRepository(initial: ChildConversationMock.all),
    );
    await tester.pump();

    expect(find.byKey(ChildConversationKeys.body), findsOneWidget);
    expect(find.byKey(ChildConversationKeys.neverLockBanner), findsOneWidget);
    expect(find.byKey(ChildConversationKeys.incomingCall), findsOneWidget);
    expect(find.byKey(ChildConversationKeys.bubble('cf1')), findsOneWidget);
  });

  testWidgets('SCR-CHD-008 answer hides incoming card', (tester) async {
    var answered = false;
    await _pump(
      tester,
      chatWith: 'father',
      repo: InMemoryConversationRepository(initial: ChildConversationMock.all),
      onAnswer: () => answered = true,
    );
    await tester.pump();
    await tester.tap(find.byKey(ChildConversationKeys.answerCall));
    await tester.pump();

    expect(answered, isTrue);
    expect(find.byKey(ChildConversationKeys.incomingCall), findsNothing);
  });

  testWidgets('SCR-CHD-008 send appends mine bubble', (tester) async {
    await _pump(
      tester,
      chatWith: 'father',
      repo: InMemoryConversationRepository(initial: ChildConversationMock.all),
    );
    await tester.pump();
    await tester.enterText(find.byKey(ChildConversationKeys.input), 'هلا');
    await tester.tap(find.byKey(ChildConversationKeys.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('هلا'), findsOneWidget);
  });

  testWidgets('SCR-CHD-008 parent lean', (tester) async {
    await _pump(
      tester,
      chatWith: 'father',
      role: AppRole.father,
      repo: InMemoryConversationRepository(initial: ChildConversationMock.all),
    );
    await tester.pump();
    expect(find.byKey(ChildConversationKeys.parentLean), findsOneWidget);
    expect(find.byKey(ChildConversationKeys.body), findsNothing);
  });

  testWidgets('SCR-CHD-008 missing peer', (tester) async {
    await _pump(tester, chatWith: null, repo: InMemoryConversationRepository());
    await tester.pump();
    expect(find.byKey(ChildConversationKeys.missingPeer), findsOneWidget);
  });

  testWidgets('SCR-CHD-008 no presence, no typing, no e2e badge',
      (tester) async {
    await _pump(
      tester,
      chatWith: 'father',
      repo: InMemoryConversationRepository(initial: ChildConversationMock.all),
    );
    await tester.pump();

    expect(find.textContaining('متصل'), findsNothing);
    expect(find.textContaining('يكتب'), findsNothing);
    expect(find.textContaining('مشفّرة'), findsNothing);
  });

  testWidgets('SCR-CHD-008 own read message shows ✓✓', (tester) async {
    await _pump(
      tester,
      chatWith: 'father',
      repo: InMemoryConversationRepository(initial: ChildConversationMock.all),
    );
    await tester.pump();

    expect(find.text('✓✓'), findsWidgets);
  });

  testWidgets('SCR-CHD-008 settings sheet mutes this chat (mandatory receipts)',
      (tester) async {
    final repo = InMemoryConversationRepository(initial: ChildConversationMock.all);
    await _pump(tester, chatWith: 'father', repo: repo);
    await tester.pump();

    await tester.tap(find.byKey(ChildConversationKeys.settingsTag));
    await tester.pumpAndSettle();
    // A parent thread → receipts mandatory, no toggle.
    await tester.ensureVisible(find.byKey(const Key('chat_receipts_mandatory')));
    expect(find.byKey(const Key('chat_receipts_mandatory')), findsOneWidget);
    expect(find.byKey(const Key('chat_receipts_switch')), findsNothing);

    await tester.tap(find.byKey(const Key('chat_mute_8h')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_settings_done')));
    await tester.pumpAndSettle();

    final loaded = await repo.load('father');
    expect(loaded!.muted, isTrue);
    expect(loaded.mutedUntil, isNotNull);
  });

  testWidgets('SCR-CHD-008 family pinned bar renders', (tester) async {
    await _pump(
      tester,
      chatWith: 'family',
      repo: InMemoryConversationRepository(initial: ChildConversationMock.all),
    );
    await tester.pump();

    expect(find.byKey(ChildConversationKeys.pinnedBar), findsOneWidget);
  });

  test('SCR-CHD-008 mock has no planted names', () {
    for (final t in ChildConversationMock.all) {
      expect(t.title.toLowerCase().contains('عبدالله'), isFalse);
      expect(t.title.toLowerCase().contains('خالد'), isFalse);
      for (final m in t.messages) {
        expect(m.body.contains('فهد'), isFalse);
      }
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ConversationRepository repo,
  String? chatWith,
  AppRole role = AppRole.child,
  VoidCallback? onAnswer,
}) async {
  final controller = RoleController(role);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: controller,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ChildConversationScreen(
          chatWith: chatWith,
          repository: repo,
          roleOverride: role,
          onAnswerCall: onAnswer,
        ),
      ),
    ),
  );
}
