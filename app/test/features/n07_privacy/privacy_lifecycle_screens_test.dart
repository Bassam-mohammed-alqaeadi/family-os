import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/advisor_memory_store.dart';
import 'package:family_os/core/policy/chat_mock_store.dart';
import 'package:family_os/core/policy/family_data_lifecycle.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart' show AuditAppend;
import 'package:family_os/features/n07_privacy/audit_log_panel.dart';
import 'package:family_os/features/n07_privacy/privacy_data_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('demo-child');

  Future<void> tapKey(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  FamilyDataLifecycleService seededLifecycle({
    AuditAppend? audit,
    List<AdvisorMemoryNote>? memory,
    List<ChatMockMessage>? chat,
    DateTime Function()? clock,
  }) {
    final a = audit ?? (AuditAppend()..add('preexisting_audit'));
    return FamilyDataLifecycleService(
      memory: MemoryAdvisorMemoryStore(
        memory ??
            [
              AdvisorMemoryNote(
                id: 'm1',
                text: 'note',
                createdAt: DateTime.utc(2026, 9, 1),
              ),
            ],
      ),
      chat: MemoryChatMockStore(
        chat ??
            [
              ChatMockMessage(
                id: 'c1',
                body: 'chat stays',
                createdAt: DateTime.utc(2026, 9, 2),
              ),
            ],
      ),
      audit: a,
      clock: clock ?? () => DateTime.utc(2026, 9, 20, 12),
      idFactory: () => 'wipe-ui-1',
    );
  }

  testWidgets(
    'forget leaves audit + chat intact; memory cleared',
    (tester) async {
      final lifecycle = seededLifecycle();
      await tester.pumpWidget(
        _app(
          role: AppRole.father,
          child: PrivacyDataScreen(
            childId: child,
            repository: InMemoryPrivacyCollectionRepository(),
            lifecycle: lifecycle,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(PrivacyDataKeys.forgetButton), findsOneWidget);
      expect(find.byKey(AuditLogPanelKeys.panel), findsOneWidget);
      // Forget must not live on the audit panel.
      expect(
        find.descendant(
          of: find.byKey(AuditLogPanelKeys.panel),
          matching: find.byKey(PrivacyDataKeys.forgetButton),
        ),
        findsNothing,
      );

      await tapKey(tester, PrivacyDataKeys.forgetButton);
      expect(find.byKey(PrivacyDataKeys.forgetConfirmDialog), findsOneWidget);
      await tapKey(tester, PrivacyDataKeys.forgetConfirmAction);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(lifecycle.memory.notes, isEmpty);
      expect(lifecycle.chat.messages, isNotEmpty);
      expect(lifecycle.audit.entries, contains('preexisting_audit'));
    },
  );

  testWidgets(
    'wipe requires two steps; shows 7-day window; audit has wipe-request',
    (tester) async {
      final lifecycle = seededLifecycle();
      await tester.pumpWidget(
        _app(
          role: AppRole.father,
          child: PrivacyDataScreen(
            childId: child,
            repository: InMemoryPrivacyCollectionRepository(),
            lifecycle: lifecycle,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapKey(tester, PrivacyDataKeys.wipeButton);
      expect(find.byKey(PrivacyDataKeys.wipeStep1Dialog), findsOneWidget);
      // Still no pending until step 2.
      expect(lifecycle.pendingWipe, isNull);

      await tapKey(tester, PrivacyDataKeys.wipeStep1Continue);
      expect(find.byKey(PrivacyDataKeys.wipeStep2Dialog), findsOneWidget);

      await tester.enterText(
        find.byKey(PrivacyDataKeys.wipeStep2Field),
        'مسح',
      );
      await tester.pumpAndSettle();
      await tapKey(tester, PrivacyDataKeys.wipeStep2Action);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(lifecycle.pendingWipe, isNotNull);
      expect(
        lifecycle.pendingWipe!.pendingUntil,
        DateTime.utc(2026, 9, 27, 12),
      );
      expect(find.byKey(PrivacyDataKeys.wipePendingBanner), findsOneWidget);
      expect(
        find.textContaining('٧ أيام'),
        findsWidgets,
      );
      expect(
        lifecycle.audit.entries
            .any((e) => e.contains('FAMILY_WIPE_REQUESTED')),
        isTrue,
      );
      expect(lifecycle.audit.entries.first, 'preexisting_audit');
    },
  );

  testWidgets('cancel wipe within window works', (tester) async {
    final lifecycle = seededLifecycle();
    await tester.pumpWidget(
      _app(
        role: AppRole.father,
        child: PrivacyDataScreen(
          childId: child,
          repository: InMemoryPrivacyCollectionRepository(),
          lifecycle: lifecycle,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tapKey(tester, PrivacyDataKeys.wipeButton);
    await tapKey(tester, PrivacyDataKeys.wipeStep1Continue);
    await tester.enterText(find.byKey(PrivacyDataKeys.wipeStep2Field), 'مسح');
    await tester.pumpAndSettle();
    await tapKey(tester, PrivacyDataKeys.wipeStep2Action);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byKey(PrivacyDataKeys.wipeCancelButton), findsOneWidget);
    await tapKey(tester, PrivacyDataKeys.wipeCancelButton);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(lifecycle.pendingWipe, isNull);
    expect(
      lifecycle.audit.entries.any((e) => e.contains('FAMILY_WIPE_CANCELLED')),
      isTrue,
    );
    expect(find.byKey(PrivacyDataKeys.wipePendingBanner), findsNothing);
  });

  testWidgets('mother denied — no forget/wipe buttons', (tester) async {
    final lifecycle = seededLifecycle();
    await tester.pumpWidget(
      _app(
        role: AppRole.mother,
        child: PrivacyDataScreen(
          childId: child,
          repository: InMemoryPrivacyCollectionRepository(),
          lifecycle: lifecycle,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(PrivacyDataKeys.forgetButton), findsNothing);
    expect(find.byKey(PrivacyDataKeys.wipeButton), findsNothing);
    expect(find.byKey(AuditLogPanelKeys.panel), findsOneWidget);
  });

  testWidgets('AuditLogPanel has no forget button', (tester) async {
    final audit = AuditAppend()..add('entry-a');
    await tester.pumpWidget(
      _app(
        role: AppRole.father,
        child: Scaffold(
          body: AuditLogPanel(audit: audit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AuditLogPanelKeys.panel), findsOneWidget);
    expect(find.byKey(PrivacyDataKeys.forgetButton), findsNothing);
    expect(find.textContaining('entry-a'), findsOneWidget);
  });
}

Widget _app({required AppRole role, required Widget child}) {
  final roleCtrl = RoleController(role);
  return CurrentRole(
    notifier: roleCtrl,
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFamilyTheme(),
      home: child,
    ),
  );
}
