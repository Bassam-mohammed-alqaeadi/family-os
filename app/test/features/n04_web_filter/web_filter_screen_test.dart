import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/policy/web_filter_policy_repository.dart';
import 'package:family_os/features/n04_web_filter/web_filter_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('widget-wf-child');

  testWidgets('toggle adults + save persists across reopen', (tester) async {
    final shared = <String, String>{};
    final repo = PrefsWebFilterPolicyRepository(
      MemoryWebFilterPrefsStore(shared),
    );

    // Seed with adults off so we can prove a real toggle persists.
    await repo.save(
      child,
      WebFilterPolicy(
        level: WebFilterLevel.open,
        categories: {
          for (final k in WebFilterCategories.known) k: false,
        },
      ),
    );

    await _pump(tester, repository: repo, childId: child, role: AppRole.father);

    final adultsOff = tester.widget<Switch>(
      find.byKey(const Key('web_filter_switch_adults')),
    );
    expect(adultsOff.value, isFalse);

    await tester.tap(find.byKey(const Key('web_filter_switch_adults')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('web_filter_save')));
    await tester.pump();
    expect(find.text('تم حفظ فلترة الإنترنت'), findsOneWidget);
    await _settleToast(tester);

    final repo2 = PrefsWebFilterPolicyRepository(
      MemoryWebFilterPrefsStore(shared),
    );
    await _pump(
      tester,
      repository: repo2,
      childId: child,
      role: AppRole.father,
    );
    final adultsOn = tester.widget<Switch>(
      find.byKey(const Key('web_filter_switch_adults')),
    );
    expect(adultsOn.value, isTrue);
  });

  testWidgets('child role is read-only', (tester) async {
    await _pump(
      tester,
      repository: InMemoryWebFilterPolicyRepository(),
      childId: child,
      role: AppRole.child,
    );

    final sw = tester.widget<Switch>(
      find.byKey(const Key('web_filter_switch_adults')),
    );
    expect(sw.onChanged, isNull);
    expect(find.byKey(const Key('web_filter_read_only')), findsOneWidget);
    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('web_filter_save')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('mother role is read-only', (tester) async {
    await _pump(
      tester,
      repository: InMemoryWebFilterPolicyRepository(),
      childId: child,
      role: AppRole.mother,
    );

    final sw = tester.widget<Switch>(
      find.byKey(const Key('web_filter_switch_adults')),
    );
    expect(sw.onChanged, isNull);
    expect(find.byKey(const Key('web_filter_read_only')), findsOneWidget);
    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('web_filter_save')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('category switches expose semantics labels', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await _pump(
        tester,
        repository: InMemoryWebFilterPolicyRepository(),
        childId: child,
        role: AppRole.father,
      );

      expect(
        tester
            .getSemantics(find.byKey(const Key('web_filter_switch_adults')))
            .label,
        contains('بالغين'),
      );
    } finally {
      handle.dispose();
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required WebFilterPolicyRepository repository,
  required ChildId childId,
  required AppRole role,
}) async {
  final roleCtrl = RoleController(role);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
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
        home: WebFilterScreen(
          childId: childId,
          repository: repository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _settleToast(WidgetTester tester) async {
  AppToast.dismiss();
  await tester.pump(const Duration(milliseconds: 2600));
}
