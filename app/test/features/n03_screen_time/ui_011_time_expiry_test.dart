import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/policy/time_engine.dart';
import 'package:family_os/core/policy/time_expiry_surface.dart';
import 'package:family_os/features/n03_screen_time/time_expiry_screen.dart';

/// UI-011 — SCR-CHD-021 time expiry: chat+Quran open; entertainment locked; SOS
/// reachable (Rules 9/11 · C-1 · S4 walkthrough step).
void main() {
  final child = ChildId('ui011-child');

  group('UI-011 TimeExpirySurface / TimeEngine', () {
    test('entertainment deniedCap when daily cap exhausted', () {
      final policy = TimeExpirySurface.exhaustedPolicy();
      expect(policy.isCapExhausted, isTrue);
      expect(
        TimeExpirySurface.entertainmentAccess(childId: child, policy: policy),
        AppAccess.deniedCap,
      );
      expect(
        TimeEngine.canUse(
          TimeContext(
            childId: child,
            dailyLimitExhausted: true,
            earnedBalance: Minutes.zero,
          ),
        ),
        isFalse,
      );
    });

    test('quran allowed (non-countable) while entertainment expired', () {
      final policy = TimeExpirySurface.exhaustedPolicy();
      expect(
        TimeExpirySurface.quranAccess(childId: child, policy: policy),
        AppAccess.allowed,
      );
    });

    test('chat usable + exempt surfaces reachable at expiry', () {
      expect(TimeExpirySurface.chatUsable(), isTrue);
      expect(
        TimeExpirySurface.isReachable('chat', entertainmentExpired: true),
        isTrue,
      );
      expect(
        TimeExpirySurface.isReachable('quran', entertainmentExpired: true),
        isTrue,
      );
      expect(
        TimeExpirySurface.isReachable('sos', entertainmentExpired: true),
        isTrue,
      );
      expect(
        TimeExpirySurface.isReachable(
          'entertainment',
          entertainmentExpired: true,
        ),
        isFalse,
      );
    });
  });

  group('UI-011 SCR-CHD-021 widget', () {
    testWidgets('AC1: Chat & Quran CTAs visible and enabled (AR)',
        (tester) async {
      var chatTaps = 0;
      var quranTaps = 0;

      await _pump(
        tester,
        childId: child,
        locale: const Locale('ar'),
        onChat: () => chatTaps++,
        onQuran: () => quranTaps++,
      );

      expect(find.byKey(TimeExpiryKeys.chatCta), findsOneWidget);
      expect(find.byKey(TimeExpiryKeys.quranCta), findsOneWidget);
      expect(find.text('محادثة العائلة'), findsOneWidget);
      expect(find.text('ورْد القرآن والتعلّم'), findsOneWidget);
      expect(
        find.text(
          'محادثة العائلة والقرآن يبقيان متاحين. نداء الطوارئ (SOS) يصل دائماً.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(TimeExpiryKeys.chatCta));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TimeExpiryKeys.quranCta));
      await tester.pumpAndSettle();

      expect(chatTaps, 1);
      expect(quranTaps, 1);
    });

    testWidgets('AC1: Chat & Quran CTAs visible and enabled (EN)',
        (tester) async {
      await _pump(
        tester,
        childId: child,
        locale: const Locale('en'),
      );

      expect(find.text('Family chat'), findsOneWidget);
      expect(find.text('Quran & learning'), findsOneWidget);
      expect(
        find.text(
          'Family chat and Quran stay open. SOS is always reachable.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC2: entertainment locked; TimeEngine deniedCap',
        (tester) async {
      var entertainmentTaps = 0;

      await _pump(
        tester,
        childId: child,
        onEntertainment: () => entertainmentTaps++,
      );

      expect(find.byKey(TimeExpiryKeys.entertainmentLocked), findsOneWidget);
      expect(find.text('الألعاب والترفيه'), findsOneWidget);

      final lockProbe = tester.widget<Text>(
        find.byKey(TimeExpiryKeys.lockState),
      );
      expect(lockProbe.data, AppAccess.deniedCap.name);

      await tester.tap(find.byKey(TimeExpiryKeys.entertainmentLocked));
      await tester.pumpAndSettle();
      expect(entertainmentTaps, 0);

      final ink = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(TimeExpiryKeys.entertainmentLocked),
          matching: find.byType(InkWell),
        ),
      );
      expect(ink.onTap, isNull);
    });

    testWidgets(
      'AC3: S4 walkthrough — chat+Quran never lock; SOS fires at expiry',
      (tester) async {
        final sos = MockSosFireService();
        var chatTaps = 0;
        var quranTaps = 0;
        var sosTaps = 0;

        await _pump(
          tester,
          childId: child,
          sosFire: sos,
          onChat: () => chatTaps++,
          onQuran: () => quranTaps++,
          onSos: () => sosTaps++,
        );

        // S4 step: CHD-021 — family chat & Quran never lock.
        expect(find.byKey(TimeExpiryKeys.chatCta), findsOneWidget);
        expect(find.byKey(TimeExpiryKeys.quranCta), findsOneWidget);
        expect(find.byKey(TimeExpiryKeys.entertainmentLocked), findsOneWidget);
        expect(find.byKey(TimeExpiryKeys.sosCta), findsOneWidget);

        await tester.tap(find.byKey(TimeExpiryKeys.chatCta));
        await tester.tap(find.byKey(TimeExpiryKeys.quranCta));
        await tester.pumpAndSettle();
        expect(chatTaps, 1);
        expect(quranTaps, 1);

        // Entertainment stays locked while exempts work.
        await tester.tap(find.byKey(TimeExpiryKeys.entertainmentLocked));
        await tester.pumpAndSettle();

        final sosBtn = tester.widget<PrimaryBtn>(
          find.byKey(TimeExpiryKeys.sosCta),
        );
        expect(sosBtn.onPressed, isNotNull);

        await tester.tap(find.byKey(TimeExpiryKeys.sosCta));
        await tester.pumpAndSettle();
        expect(sosTaps, 1);

        // SOS fire path also works under expired policy (P-4 companion).
        final result = await sos.fire(childId: child.value);
        expect(result.fired, isTrue);
        expect(sos.fireCount, 1);

        expect(
          TimeExpirySurface.chatUsable(
            availability: const AlwaysOnChatAvailability(),
          ),
          isTrue,
        );
        expect(
          TimeExpirySurface.entertainmentAccess(
            childId: child,
            policy: TimeExpirySurface.exhaustedPolicy(),
          ),
          AppAccess.deniedCap,
        );
      },
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ChildId childId,
  Locale locale = const Locale('ar'),
  ChatAvailability? chatAvailability,
  SosFireService? sosFire,
  VoidCallback? onChat,
  VoidCallback? onQuran,
  VoidCallback? onSos,
  VoidCallback? onEntertainment,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: TimeExpiryScreen(
        childId: childId,
        policy: TimeExpirySurface.exhaustedPolicy(),
        chatAvailability: chatAvailability,
        sosFire: sosFire,
        onChat: onChat,
        onQuran: onQuran,
        onSos: onSos,
        onEntertainment: onEntertainment,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
