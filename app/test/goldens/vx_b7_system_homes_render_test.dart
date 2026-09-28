import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/features/n02_day/alerts_hub_mock.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_screen.dart';
import 'package:family_os/features/n02_day/child_chats_mock.dart';
import 'package:family_os/features/n02_day/child_chats_repository.dart';
import 'package:family_os/features/n02_day/child_chats_screen.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/children_list_screen.dart';
import 'package:family_os/features/n02_day/conversations_list_mock.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';
import 'package:family_os/features/n02_day/conversations_list_screen.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n07_privacy/what_is_collected_screen.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';
import 'package:family_os/features/n12_devices/settings_hub_screen.dart';
import 'package:family_os/features/n14_studio/studio_board_repository.dart';
import 'package:family_os/features/n14_studio/studio_board_screen.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_screen.dart';

/// VX-B7 — system-home render smoke (Program §5 / §13).
///
/// Pumps each shell home at 360 & 412 dp, AR (RTL) & EN (LTR), font 1.0 & 1.3.
/// Asserts the screen mounts with no [FlutterError] overflow exceptions.
/// Binary goldens are optional Owner artifacts (see render/INDEX.md).
void main() {
  final cases = <_HomeCase>[
    _HomeCase(
      id: 'FAT-010',
      builder: (_) => const DayBoardScreen(),
    ),
    _HomeCase(
      id: 'FAT-012',
      builder: (_) => ChildrenListScreen(
        repository: InMemoryChildrenListRepository(),
        roleOverride: AppRole.father,
      ),
    ),
    _HomeCase(
      id: 'FAT-021',
      builder: (_) => ConversationsListScreen(
        repository: InMemoryConversationsListRepository(
          initial: ConversationsListMock.one,
        ),
        roleOverride: AppRole.father,
        onSos: () {},
      ),
    ),
    _HomeCase(
      id: 'FAT-025',
      wrapIdentity: true,
      builder: (_) => SettingsHubScreen(
        roleOverride: AppRole.father,
        onSos: () {},
        healthSeam: FakeDeviceHealthSeam.demo(),
      ),
    ),
    _HomeCase(
      id: 'FAT-019',
      builder: (_) => AlertsHubScreen(
        repository: InMemoryAlertsHubRepository(initial: AlertsHubMock.seeded),
        roleOverride: AppRole.father,
        onSos: () {},
      ),
    ),
    _HomeCase(
      id: 'FAT-040',
      wrapRole: AppRole.father,
      builder: (_) => StudioBoardScreen(
        repository: InMemoryStudioBoardRepository(),
        roleOverride: AppRole.father,
      ),
    ),
    _HomeCase(
      id: 'CHD-004',
      builder: (_) => ChildDayBoardScreen(showModeNotices: false),
    ),
    _HomeCase(
      id: 'CHD-012',
      wrapRole: AppRole.child,
      builder: (_) => ChildLearnHomeScreen(
        repository: InMemoryChildLearnHomeRepository(
          seed: childLearnHomeOneFixture(),
        ),
        roleOverride: AppRole.child,
        onSos: () {},
      ),
    ),
    _HomeCase(
      id: 'CHD-007',
      builder: (_) => ChildChatsScreen(
        repository: InMemoryChildChatsRepository(initial: ChildChatsMock.one),
        roleOverride: AppRole.child,
        onSos: () {},
      ),
    ),
    _HomeCase(
      id: 'CHD-010',
      wrapRole: AppRole.child,
      builder: (_) => WhatIsCollectedScreen(
        childId: ChildId('demo-child'),
        repository: InMemoryPrivacyCollectionRepository(),
      ),
    ),
  ];

  for (final home in cases) {
    for (final width in const [360.0, 412.0]) {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        for (final textScale in const [1.0, 1.3]) {
          final tag =
              '${home.id}_${width.toInt()}_${locale.languageCode}_f$textScale';
          testWidgets('render $tag', (tester) async {
            final errors = <FlutterErrorDetails>[];
            final old = FlutterError.onError;
            FlutterError.onError = (details) {
              errors.add(details);
              old?.call(details);
            };
            addTearDown(() => FlutterError.onError = old);

            await _pumpHome(
              tester,
              home: home,
              width: width,
              locale: locale,
              textScale: textScale,
            );

            final overflows = errors.where(
              (e) =>
                  e.exceptionAsString().contains('overflowed') ||
                  e.exceptionAsString().contains('RenderFlex'),
            );
            expect(
              overflows,
              isEmpty,
              reason: 'overflow on $tag: ${overflows.map((e) => e.exceptionAsString()).join(' | ')}',
            );
          });
        }
      }
    }
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required _HomeCase home,
  required double width,
  required Locale locale,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Widget child = home.builder(tester);
  if (home.wrapIdentity) {
    child = CurrentIdentity(
      runtime: createStage1IdentityRuntime(),
      child: child,
    );
  }
  if (home.wrapRole != null) {
    final role = RoleController(home.wrapRole!);
    addTearDown(role.dispose);
    child = CurrentRole(notifier: role, child: child);
  }

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 800),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        locale: locale,
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
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

final class _HomeCase {
  const _HomeCase({
    required this.id,
    required this.builder,
    this.wrapIdentity = false,
    this.wrapRole,
  });

  final String id;
  final Widget Function(WidgetTester tester) builder;
  final bool wrapIdentity;
  final AppRole? wrapRole;
}
