import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n02_day/request_inbox_screen.dart';
import 'package:family_os/features/n03_screen_time/time_expiry_screen.dart';
import 'package:family_os/features/n05_lock/instant_lock_screen.dart';

/// UI-014 — spine interactive CTAs: Semantics labels (ARB) for SOS / lock /
/// approve; icon-only edge covered (Rule 16).
void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('ar')}) {
    return MaterialApp(
      theme: buildFamilyTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  testWidgets(
    'AC1+AC2 AR: SOS / lock / approve announce ARB Semantics labels',
    (tester) async {
      final handle = tester.ensureSemantics();
      final child = ChildId('ui014-child');
      final pending = TimeRequest(
        id: 'tr-ui014',
        childId: child,
        requestedMinutes: 15,
        childReason: 'واجب',
      );
      final inbox = TimeRequestService(
        repository: InMemoryTimeRequestRepository([pending]),
        decisionBus: TimeRequestDecisionBus(),
      );
      addTearDown(inbox.dispose);

      const sosLabel = 'إرسال نداء الطوارئ SOS';
      const lockLabel = 'قفل جهاز الابن فوراً';
      const unlockLabel = 'فتح قفل جهاز الابن';
      const approveLabel = 'الموافقة على طلب الوقت الإضافي';
      const rejectLabel = 'رفض طلب الوقت الإضافي';
      const grantLabel = 'منح 15 دقيقة';
      const backLabel = 'رجوع من صندوق الطلبات';

      try {
        // --- SOS (primary + icon-only) ---
        await tester.pumpWidget(
          wrap(
            TimeExpiryScreen(
              childId: child,
              sosFire: MockSosFireService(),
              onSos: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<PrimaryBtn>(find.byKey(TimeExpiryKeys.sosCta))
              .semanticsLabel,
          sosLabel,
        );
        expect(find.bySemanticsLabel(sosLabel), findsWidgets);
        expect(
          tester
              .widget<IconButton>(find.byKey(TimeExpiryKeys.sosIconCta))
              .tooltip,
          sosLabel,
        );
        expect(find.byTooltip(sosLabel), findsOneWidget);

        // --- Instant lock ---
        await tester.pumpWidget(
          wrap(
            InstantLockScreen(
              childId: child,
              repository: InMemoryAntiTamperRepository(),
              lockService: DeviceLockService.inMemory(),
              roleOverride: AppRole.father,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<PrimaryBtn>(find.byKey(InstantLockKeys.lockButton))
              .semanticsLabel,
          lockLabel,
        );
        expect(
          tester
              .widget<PrimaryBtn>(find.byKey(InstantLockKeys.unlockButton))
              .semanticsLabel,
          unlockLabel,
        );
        expect(find.bySemanticsLabel(lockLabel), findsOneWidget);
        expect(find.bySemanticsLabel(unlockLabel), findsOneWidget);

        // --- Approve / grant (request inbox) ---
        await tester.pumpWidget(
          wrap(
            RequestInboxScreen(
              service: inbox,
              role: AppRole.father,
              onBack: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<PrimaryBtn>(
                find.byKey(RequestInboxKeys.approve(pending.id)),
              )
              .semanticsLabel,
          approveLabel,
        );
        expect(
          tester
              .widget<PrimaryBtn>(
                find.byKey(RequestInboxKeys.reject(pending.id)),
              )
              .semanticsLabel,
          rejectLabel,
        );
        expect(find.bySemanticsLabel(approveLabel), findsOneWidget);
        expect(find.bySemanticsLabel(rejectLabel), findsOneWidget);
        expect(find.bySemanticsLabel(grantLabel), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(find.byKey(RequestInboxKeys.backButton))
              .tooltip,
          backLabel,
        );
        expect(find.byTooltip(backLabel), findsOneWidget);
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets(
    'AC2 EN: screen reader labels for SOS / lock / approve',
    (tester) async {
      final handle = tester.ensureSemantics();
      final child = ChildId('ui014-en');
      final pending = TimeRequest(
        id: 'tr-en',
        childId: child,
        requestedMinutes: 30,
      );
      final inbox = TimeRequestService(
        repository: InMemoryTimeRequestRepository([pending]),
        decisionBus: TimeRequestDecisionBus(),
      );
      addTearDown(inbox.dispose);

      try {
        await tester.pumpWidget(
          wrap(
            TimeExpiryScreen(
              childId: child,
              sosFire: MockSosFireService(),
              onSos: () {},
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Send SOS emergency alert'),
          findsWidgets,
        );

        await tester.pumpWidget(
          wrap(
            InstantLockScreen(
              childId: child,
              repository: InMemoryAntiTamperRepository(),
              lockService: DeviceLockService.inMemory(),
              roleOverride: AppRole.father,
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Lock child device now'), findsOneWidget);

        await tester.pumpWidget(
          wrap(
            RequestInboxScreen(service: inbox, role: AppRole.father),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Approve extra-time request'),
          findsOneWidget,
        );
      } finally {
        handle.dispose();
      }
    },
  );
}
