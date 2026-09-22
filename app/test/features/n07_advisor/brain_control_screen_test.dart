import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/policy/ai_stage_flags.dart';
import 'package:family_os/core/policy/ai_stage_flags_repository.dart';
import 'package:family_os/core/policy/ai_stage_id.dart';
import 'package:family_os/features/n07_advisor/brain_control_screen.dart';

void main() {
  testWidgets('flag off → CTA disabled / coming soon', (tester) async {
    final flags = MockRemoteAiStageFlags(
      initialServer: AiStageFlags.allOff(),
    );
    await tester.pumpWidget(
      _app(
        child: BrainControlScreen(
          flagsRepository: flags,
          advisor: const MockAdvisorRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(BrainControlKeys.servesBanner), findsOneWidget);
    expect(find.textContaining('يخدم'), findsWidgets);

    final analyzeCta = find.byKey(BrainControlKeys.stageCta(AiStageId.analyze));
    expect(analyzeCta, findsOneWidget);
    final btn = tester.widget<PrimaryBtn>(analyzeCta);
    expect(btn.onPressed, isNull, reason: 'flag-off CTA must not execute');
    expect(find.text('قريبًا'), findsWidgets);

    await tester.tap(analyzeCta);
    await tester.pumpAndSettle();
    expect(find.byKey(BrainControlKeys.suggestionsList), findsNothing);
  });

  testWidgets('flag on → suggestions list from mock advisor', (tester) async {
    final flags = MockRemoteAiStageFlags(
      initialServer: AiStageFlags.fromMap({
        AiStageId.suggest: true,
        AiStageId.analyze: false,
        AiStageId.coach: false,
      }),
    );
    await tester.pumpWidget(
      _app(
        child: BrainControlScreen(
          flagsRepository: flags,
          advisor: const MockAdvisorRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final suggestCta = find.byKey(BrainControlKeys.stageCta(AiStageId.suggest));
    expect(suggestCta, findsOneWidget);
    expect(tester.widget<PrimaryBtn>(suggestCta).onPressed, isNotNull);

    tester
        .state<BrainControlScreenState>(find.byType(BrainControlScreen))
        .openSuggestions(AiStageId.suggest);
    await tester.pumpAndSettle();

    expect(find.byKey(BrainControlKeys.suggestionsList), findsOneWidget);
    expect(find.textContaining('Bedtime'), findsOneWidget);
    expect(find.textContaining('يُطبَّق'), findsWidgets);
  });

  testWidgets('cannot locally unlock inference', (tester) async {
    final flags = MockRemoteAiStageFlags(
      initialServer: AiStageFlags.allOff(),
    );
    expect(
      () => flags.setLocalEnableInference(AiStageId.coach, enable: true),
      throwsA(isA<UnsupportedError>()),
    );

    await tester.pumpWidget(
      _app(
        child: BrainControlScreen(
          flagsRepository: flags,
          advisor: const MockAdvisorRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<PrimaryBtn>(find.byKey(BrainControlKeys.stageCta(AiStageId.coach)))
          .onPressed,
      isNull,
    );
  });

  testWidgets('SET-015 mother FULL → deny panel, zero stage CTAs', (
    tester,
  ) async {
    final flags = MockRemoteAiStageFlags(
      initialServer: AiStageFlags.fromMap({
        AiStageId.suggest: true,
        AiStageId.analyze: true,
        AiStageId.coach: true,
      }),
    );
    await tester.pumpWidget(
      _app(
        role: AppRole.mother,
        child: BrainControlScreen(
          flagsRepository: flags,
          advisor: const MockAdvisorRepository(),
          roleOverride: AppRole.mother,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(BrainControlKeys.denyPanel), findsOneWidget);
    expect(find.text('غير متاح'), findsOneWidget);
    expect(find.byKey(BrainControlKeys.servesBanner), findsNothing);
    for (final id in AiStageId.values) {
      expect(find.byKey(BrainControlKeys.stageCta(id)), findsNothing);
      expect(find.byKey(BrainControlKeys.stageRow(id)), findsNothing);
    }
  });

  testWidgets('SET-015 child → deny panel, zero stage CTAs', (tester) async {
    await tester.pumpWidget(
      _app(
        role: AppRole.child,
        child: BrainControlScreen(
          flagsRepository: MockRemoteAiStageFlags(
            initialServer: AiStageFlags.allOff(),
          ),
          advisor: const MockAdvisorRepository(),
          roleOverride: AppRole.child,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(BrainControlKeys.denyPanel), findsOneWidget);
    expect(find.text('غير متاح'), findsOneWidget);
    expect(find.byKey(BrainControlKeys.stageCta(AiStageId.analyze)), findsNothing);
  });

  testWidgets('SET-015 father → stages visible (SET-014 surface)', (
    tester,
  ) async {
    final flags = MockRemoteAiStageFlags(
      initialServer: AiStageFlags.fromMap({
        AiStageId.analyze: true,
        AiStageId.suggest: false,
        AiStageId.coach: false,
      }),
    );
    await tester.pumpWidget(
      _app(
        child: BrainControlScreen(
          flagsRepository: flags,
          advisor: const MockAdvisorRepository(),
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(BrainControlKeys.denyPanel), findsNothing);
    expect(find.byKey(BrainControlKeys.servesBanner), findsOneWidget);
    expect(
      find.byKey(BrainControlKeys.stageCta(AiStageId.analyze)),
      findsOneWidget,
    );
  });
}

Widget _app({required Widget child, AppRole role = AppRole.father}) {
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
