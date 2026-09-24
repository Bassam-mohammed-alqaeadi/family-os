import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_screen.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('P12: father assign → child learn shows live assignment', (
    tester,
  ) async {
    final bus = InMemoryLearningAssignmentRepository();
    addTearDown(bus.dispose);
    final fatherRepo = InMemoryAttributionRewardRepository(assignments: bus);
    final childRepo = InMemoryChildLearnHomeRepository(assignments: bus);

    await _pumpAttribution(tester, repository: fatherRepo);
    await tester.ensureVisible(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpChildLearn(tester, repository: childRepo);
    expect(find.byKey(ChildLearnHomeKeys.challengeCard), findsOneWidget);
    expect(find.textContaining('Lesson your parent assigned'), findsOneWidget);
    expect(
      find.textContaining('Assigned just now by your parent'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpAttribution(
  WidgetTester tester, {
  required AttributionRewardRepository repository,
}) async {
  final roleCtrl = RoleController(AppRole.father);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AttributionRewardScreen(
          repository: repository,
          roleOverride: AppRole.father,
          motherLevel: MotherLevel.partner,
          onNavigate: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpChildLearn(
  WidgetTester tester, {
  required ChildLearnHomeRepository repository,
}) async {
  final roleCtrl = RoleController(AppRole.child);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ChildLearnHomeScreen(
          repository: repository,
          roleOverride: AppRole.child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
