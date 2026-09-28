import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/conversation_screen.dart';

/// CE-B0 / Q-CEX-001 — ticks must not imply remote delivered/read.
void main() {
  test('outbound default status is local sent', () {
    const msg = ConversationMessage(
      id: 'm1',
      body: 'hi',
      timeLabel: 'now',
      isMine: true,
    );
    expect(msg.status, ConversationDeliveryStatus.sent);
  });

  testWidgets('SCR-FAT-022 never renders double-check for legacy statuses',
      (tester) async {
    final repo = InMemoryConversationRepository(
      initial: [
        const ConversationDetail(
          chatWith: 'family',
          title: 'Family',
          subtitle: 'local',
          emoji: '🏠',
          messages: [
            ConversationMessage(
              id: 'a',
              body: 'legacy delivered',
              timeLabel: '1',
              isMine: true,
              status: ConversationDeliveryStatus.delivered,
            ),
            ConversationMessage(
              id: 'b',
              body: 'legacy read',
              timeLabel: '2',
              isMine: true,
              status: ConversationDeliveryStatus.read,
            ),
            ConversationMessage(
              id: 'c',
              body: 'local sent',
              timeLabel: '3',
              isMine: true,
              status: ConversationDeliveryStatus.sent,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConversationScreen(
          chatWith: 'family',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.body), findsOneWidget);
    expect(find.textContaining('✓✓'), findsNothing);
    expect(find.textContaining('✓'), findsWidgets);
  });
}
