import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/collection_scope.dart';
import 'package:family_os/core/policy/privacy_collection_policy.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/policy/privacy_collection_sync_bus.dart';
import 'package:family_os/features/n07_privacy/privacy_data_screen.dart';
import 'package:family_os/features/n07_privacy/what_is_collected_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  final child = ChildId('demo-child');

  testWidgets(
    'location off → child list loses location line after sync (P12 same session)',
    (tester) async {
      final store = MemoryPrivacyCollectionPrefsStore();
      final repo = PrefsPrivacyCollectionRepository(store);
      final bus = PrivacyCollectionSyncBus();

      await tester.pumpWidget(
        _app(
          role: AppRole.child,
          child: WhatIsCollectedScreen(
            childId: child,
            repository: repo,
            syncBus: bus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(WhatIsCollectedKeys.scopeLine(CollectionScope.location)),
        findsOneWidget,
      );
      final childState = tester.state(find.byType(WhatIsCollectedScreen));

      // Father save on shared repo + bus (same isolate — no child cold restart).
      final next = PrivacyCollectionPolicy.defaults(childId: child.value)
          .withScope(CollectionScope.location, false)
          .copyWith(updatedAt: DateTime.utc(2026, 9, 20, 21));
      final write = await repo.save(next, actor: AppRole.father);
      expect(write, isA<PrivacyCollectionWriteOk>());
      bus.publish((write as PrivacyCollectionWriteOk).policy);
      await tester.pumpAndSettle();

      expect(
        find.byKey(WhatIsCollectedKeys.scopeLine(CollectionScope.location)),
        findsNothing,
      );
      expect(
        find.byKey(WhatIsCollectedKeys.scopeLine(CollectionScope.screenTime)),
        findsOneWidget,
      );
      expect(
        identical(childState, tester.state(find.byType(WhatIsCollectedScreen))),
        isTrue,
      );
    },
  );

  testWidgets('child widgets have no Switch editors', (tester) async {
    final repo = InMemoryPrivacyCollectionRepository();
    await tester.pumpWidget(
      _app(
        role: AppRole.child,
        child: WhatIsCollectedScreen(
          childId: child,
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('father persist across reopen', (tester) async {
    final store = MemoryPrivacyCollectionPrefsStore();
    final repo = PrefsPrivacyCollectionRepository(store);
    final bus = PrivacyCollectionSyncBus();

    await tester.pumpWidget(
      _app(
        role: AppRole.father,
        child: PrivacyDataScreen(
          childId: child,
          repository: repo,
          syncBus: bus,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(PrivacyDataKeys.scopeSwitch(CollectionScope.location)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PrivacyDataKeys.save));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Simulate reopen with fresh screen + same store.
    await tester.pumpWidget(
      _app(
        role: AppRole.father,
        child: PrivacyDataScreen(
          childId: child,
          repository: PrefsPrivacyCollectionRepository(store),
          syncBus: PrivacyCollectionSyncBus(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(
      find.byKey(PrivacyDataKeys.scopeSwitch(CollectionScope.location)),
    );
    expect(tile.value, isFalse);
  });

  testWidgets('mother sees read-only — no save, switches disabled',
      (tester) async {
    final repo = InMemoryPrivacyCollectionRepository();
    await tester.pumpWidget(
      _app(
        role: AppRole.mother,
        child: PrivacyDataScreen(
          childId: child,
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(PrivacyDataKeys.readOnlyBanner), findsOneWidget);
    expect(find.byKey(PrivacyDataKeys.save), findsNothing);

    final tile = tester.widget<SwitchListTile>(
      find.byKey(PrivacyDataKeys.scopeSwitch(CollectionScope.location)),
    );
    expect(tile.onChanged, isNull);
  });

  testWidgets('retention note visible on father privacy screen',
      (tester) async {
    await tester.pumpWidget(
      _app(
        role: AppRole.father,
        child: PrivacyDataScreen(
          childId: child,
          repository: InMemoryPrivacyCollectionRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(PrivacyDataKeys.retentionBanner), findsOneWidget);
    expect(
      find.textContaining('الاحتفاظ ≠ الجمع'),
      findsOneWidget,
    );
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
