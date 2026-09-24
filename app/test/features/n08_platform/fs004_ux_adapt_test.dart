import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/components/screen_camera_parent_panel.dart';
import 'package:family_os/core/design/components/screen_camera_transparency_card.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/privacy_collection_repository.dart';
import 'package:family_os/core/screen_camera/screen_camera.dart';
import 'package:family_os/features/n07_privacy/what_is_collected_screen.dart';
import 'package:family_os/features/n08_platform/smart_alerts_repository.dart';
import 'package:family_os/features/n08_platform/smart_alerts_screen.dart';

void main() {
  late MemoryLocalDatabase db;
  late ScreenCameraService service;
  final family = FamilyId('fam_ux');
  final child = ChildId('demo-child');
  final now = DateTime.utc(2026, 9, 24, 21);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    final store = LocalScreenCameraStore(db, clock: () => now);
    service = ScreenCameraService(
      documents: store,
      familyId: family,
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FAT-065 binds SC panel; monitor writes domain; planes MOCK-REMOTE', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        role: AppRole.father,
        child: SmartAlertsScreen(
          repository: InMemorySmartAlertsRepository(
            seed: smartAlertsPrototypeFixture(),
          ),
          screenCamera: service,
          childId: child,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SmartAlertsKeys.scPolicyBanner), findsOneWidget);
    expect(find.byKey(ScreenCameraParentPanelKeys.panel), findsOneWidget);
    expect(find.byType(CapabilityHonestyBadge), findsWidgets);
    // Screenshot tool moved into FS-004 panel (no duplicate store UI).
    expect(find.byKey(SmartAlertsKeys.toolSwitch('screenshot')), findsNothing);

    await tester.ensureVisible(
      find.byKey(ScreenCameraParentPanelKeys.monitorSwitch),
    );
    await tester.tap(find.byKey(ScreenCameraParentPanelKeys.monitorSwitch));
    await tester.pumpAndSettle();

    final doc = await service.loadEffective(child);
    expect(doc.monitorScreenshots, isTrue);
    expect(find.byKey(ScreenCameraChildPreview.previewKey), findsOneWidget);

    // Honesty: no claimable enforcement on MOCK-REMOTE.
    final eval = ScreenCameraEngine.evaluate(
      doc.copyWith(preventCameraOs: true, preventCapture: true),
    );
    expect(eval.claimableEnforcement, isFalse);
  });

  testWidgets('Partner cannot configure SC panel', (tester) async {
    await service.setScreenshotMonitoring(
      childId: child,
      enabled: true,
      actor: const ScreenCameraActor.father(),
    );
    await tester.pumpWidget(
      _app(
        role: AppRole.mother,
        child: SmartAlertsScreen(
          repository: InMemorySmartAlertsRepository(
            seed: smartAlertsPrototypeFixture(),
          ),
          screenCamera: service,
          childId: child,
          roleOverride: AppRole.mother,
          motherLevel: MotherLevel.partner,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(
      find.byKey(ScreenCameraParentPanelKeys.monitorSwitch),
    );
    expect(tile.onChanged, isNull);
  });

  testWidgets('CHD-010 shows child transparency when monitoring on', (
    tester,
  ) async {
    await service.setScreenshotMonitoring(
      childId: child,
      enabled: true,
      actor: const ScreenCameraActor.father(),
    );
    await service.setCameraOsPrevent(
      childId: child,
      enabled: true,
      actor: const ScreenCameraActor.father(),
    );

    await tester.pumpWidget(
      _app(
        role: AppRole.child,
        child: WhatIsCollectedScreen(
          childId: child,
          repository: PrefsPrivacyCollectionRepository(
            MemoryPrivacyCollectionPrefsStore(),
          ),
          screenCamera: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ScreenCameraTransparencyKeys.card), findsOneWidget);
    expect(
      find.byKey(ScreenCameraTransparencyKeys.monitorNotice),
      findsOneWidget,
    );
    expect(find.byKey(ScreenCameraTransparencyKeys.cameraLine), findsOneWidget);
  });

  testWidgets('child transparency hidden when idle', (tester) async {
    // Defaults: protect may be true on familyDefaults — save explicit idle.
    await service.saveChildPolicy(
      childId: child,
      draft: ScreenCameraDocument(
        familyId: family,
        scopeKind: ScreenCameraScopeKind.childOverride,
        childId: child,
        preventCameraOs: false,
        preventCapture: false,
        monitorScreenshots: false,
        protectSensitiveSurfaces: false,
      ),
      actor: const ScreenCameraActor.father(),
    );

    await tester.pumpWidget(
      _app(
        role: AppRole.child,
        child: WhatIsCollectedScreen(
          childId: child,
          repository: PrefsPrivacyCollectionRepository(
            MemoryPrivacyCollectionPrefsStore(),
          ),
          screenCamera: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ScreenCameraTransparencyKeys.hidden), findsOneWidget);
    expect(find.byKey(ScreenCameraTransparencyKeys.card), findsNothing);
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
