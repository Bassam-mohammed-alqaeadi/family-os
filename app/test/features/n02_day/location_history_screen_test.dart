import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/location_history_mock.dart';
import 'package:family_os/features/n02_day/location_history_repository.dart';
import 'package:family_os/features/n02_day/location_history_screen.dart';

void main() {
  testWidgets('SCR-FAT-015 missing childId → empty', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          repository: InMemoryLocationHistoryRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenMap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationHistoryKeys.missingId), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.body), findsNothing);
    expect(find.byKey(LocationHistoryKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-015 unknown childId → not found', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          childId: 'missing_child',
          repository: InMemoryLocationHistoryRepository(
            byChildId: LocationHistoryMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenMap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationHistoryKeys.notFound), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.body), findsNothing);
    expect(find.byKey(LocationHistoryKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-015 empty trail → AppEmptyState', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          childId: 'child_empty',
          repository: InMemoryLocationHistoryRepository(
            byChildId: LocationHistoryMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenMap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationHistoryKeys.empty), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-015 thread + frequent + honesty + retention',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          childId: 'child_a',
          repository: InMemoryLocationHistoryRepository(
            byChildId: LocationHistoryMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenMap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationHistoryKeys.body), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.threadSection), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.day('day_today')), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.day('day_yesterday')), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.frequentSection), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.place('freq_school')), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.place('freq_cafe')), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.retentionNote), findsOneWidget);
    expect(find.textContaining('ابن ١'), findsWidgets);
  });

  testWidgets('SCR-FAT-015 open-map seam from missing id', (tester) async {
    var mapOpened = false;
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          repository: InMemoryLocationHistoryRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenMap: () => mapOpened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('فتح خريطة الموقع'));
    await tester.pumpAndSettle();
    expect(mapOpened, isTrue);
  });

  testWidgets('SCR-FAT-015 SOS seam fires on empty', (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          childId: 'child_empty',
          repository: InMemoryLocationHistoryRepository(
            byChildId: LocationHistoryMock.seeded,
          ),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LocationHistoryKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-015 load error → AppErrorState + SOS', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          childId: 'child_a',
          repository: InMemoryLocationHistoryRepository(failLoad: true),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationHistoryKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-015 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          childId: 'child_a',
          repository: InMemoryLocationHistoryRepository(
            byChildId: LocationHistoryMock.seeded,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationHistoryKeys.childLean), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-015 mother can view history', (tester) async {
    await tester.pumpWidget(
      _app(
        child: LocationHistoryScreen(
          childId: 'child_a',
          repository: InMemoryLocationHistoryRepository(
            byChildId: LocationHistoryMock.seeded,
          ),
          roleOverride: AppRole.mother,
          onSos: () {},
          onOpenMap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LocationHistoryKeys.body), findsOneWidget);
    expect(find.byKey(LocationHistoryKeys.childLean), findsNothing);
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
