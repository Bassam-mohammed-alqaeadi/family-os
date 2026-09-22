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
