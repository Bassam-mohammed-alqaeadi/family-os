import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/ai_safety_child_transparency_card.dart';
import 'package:family_os/core/design/components/ai_safety_ticket_review_panel.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/offline_ai_safety/offline_ai_safety.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/features/n07_privacy/what_is_collected_screen.dart';
import 'package:family_os/features/n08_platform/smart_alerts_repository.dart';
import 'package:family_os/features/n08_platform/smart_alerts_screen.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalOfflineAiSafetyStore store;
  late OfflineAiSafetyService service;
  final family = FamilyId('fam_ux');
  final child = ChildId('child_a');
  final now = DateTime.utc(2026, 9, 24, 16, 0);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    store = LocalOfflineAiSafetyStore(db);
    var seq = 0;
    service = OfflineAiSafetyService(
      store: store,
      familyId: family,
      clock: () => now,
      idFactory: () => 'ai_ux_${++seq}',
    );
    await service.applyModel(
      draft: const SignedModelManifest(
        modelId: 'safety_v1',
        version: '1.0.0',
        signature: 'sig_ux',
        policyVersion: 'pol_1',
      ),
      actor: const SafetyAiActor.father(),
    );
    await service.classifyCompleted(
      childId: child,
      text: 'msg [analysis:suspicious]',
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FAT-065 shows ticket panel with redacted preview + resolve',
      (tester) async {
    await tester.pumpWidget(
      _app(
        role: AppRole.father,
        child: SmartAlertsScreen(
          repository: InMemorySmartAlertsRepository(
            seed: smartAlertsEmptyFixture(),
          ),
          offlineAi: service,
          childId: child,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SmartAlertsKeys.fs007Banner), findsOneWidget);
    expect(find.byKey(AiSafetyTicketReviewKeys.panel), findsOneWidget);
    expect(find.byKey(AiSafetyTicketReviewKeys.noExecutorNote), findsOneWidget);
    expect(find.byKey(AiSafetyTicketReviewKeys.preview), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);

    await tester.ensureVisible(find.byKey(AiSafetyTicketReviewKeys.resolve));
    await tester.tap(find.byKey(AiSafetyTicketReviewKeys.resolve));
    await tester.pumpAndSettle();
    expect(find.byKey(AiSafetyTicketReviewKeys.empty), findsOneWidget);
  });

  testWidgets('Observer cannot review tickets', (tester) async {
    await tester.pumpWidget(
      _app(
        role: AppRole.mother,
        child: SmartAlertsScreen(
          repository: InMemorySmartAlertsRepository(
            seed: smartAlertsEmptyFixture(),
          ),
          offlineAi: service,
          childId: child,
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.observer,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AiSafetyTicketReviewKeys.panel), findsOneWidget);
    expect(find.byKey(AiSafetyTicketReviewKeys.resolve), findsNothing);
  });

  testWidgets('CHD-010 shows child on-device transparency card', (tester) async {
    final model = await service.activeModel();
    expect(model, isNotNull);
    expect(model!.mayExecute, isTrue);

    await tester.pumpWidget(
      _app(
        role: AppRole.child,
        child: WhatIsCollectedScreen(
          childId: child,
          repository: PrefsPrivacyCollectionRepository(
            MemoryPrivacyCollectionPrefsStore(),
          ),
          offlineAi: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(WhatIsCollectedKeys.list), findsOneWidget);
    expect(find.byType(AiSafetyChildTransparencyCard), findsOneWidget);
    expect(find.byKey(AiSafetyChildTransparencyKeys.card), findsOneWidget);
    expect(
      find.byKey(AiSafetyChildTransparencyKeys.onDeviceNote),
      findsOneWidget,
    );
    expect(find.byKey(AiSafetyChildTransparencyKeys.searchLine), findsOneWidget);
  });
}

Widget _app({required AppRole role, required Widget child}) {
  return CurrentRole(
    notifier: RoleController(role),
    child: MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
