import 'dart:async';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/family_child_context_source.dart';
import 'package:family_os/features/n02_day/remote_child_context_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';

void main() {
  testWidgets('renders loading then only server-confirmed primary-guardian facts', (
    tester,
  ) async {
    final completer = Completer<FamilyChildContextResult>();
    final source = _Source(() => completer.future);
    var paired = false;
    await tester.pumpWidget(
      _host(
        source: source,
        onPairDevice: () => paired = true,
      ),
    );

    expect(find.byKey(RemoteChildContextKeys.loading), findsOneWidget);
    completer.complete(_ready(FamilyChildContextRole.primaryGuardian));
    await tester.pump();

    expect(find.byKey(RemoteChildContextKeys.ready), findsOneWidget);
    expect(find.text('Amani'), findsOneWidget);
    expect(find.text('Age 8 years'), findsOneWidget);
    expect(find.text('No device linked yet'), findsOneWidget);
    expect(find.text('Linked devices: 0'), findsOneWidget);
    expect(find.byKey(RemoteChildContextKeys.pairDevice), findsOneWidget);
    expect(find.textContaining('Battery'), findsNothing);
    expect(find.textContaining('Location'), findsNothing);
    expect(find.textContaining('health'), findsNothing);
    expect(find.textContaining('policy'), findsNothing);
    expect(find.textContaining('tools'), findsNothing);

    await tester.tap(find.byKey(RemoteChildContextKeys.pairDevice));
    expect(paired, isTrue);
  });

  testWidgets('co-guardian gets honest read-only presentation without pairing CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        source: _Source(
          () async => _ready(FamilyChildContextRole.coGuardian),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(RemoteChildContextKeys.readOnly), findsOneWidget);
    expect(find.byKey(RemoteChildContextKeys.pairDevice), findsNothing);
    expect(find.textContaining('owner permission'), findsOneWidget);
  });

  testWidgets('renders distinct denial, not-found, session and recovery states', (
    tester,
  ) async {
    final cases = <FamilyChildContextFailure, String>{
      FamilyChildContextFailure.accessDenied: 'Access denied',
      FamilyChildContextFailure.notFound: 'Child not found',
      FamilyChildContextFailure.sessionInvalid: 'Session ended',
      FamilyChildContextFailure.networkUnavailable: 'No connection',
      FamilyChildContextFailure.serviceUnavailable:
          'Service temporarily unavailable',
      FamilyChildContextFailure.invalidResponse:
          'Information could not be verified',
      FamilyChildContextFailure.unavailable: 'Child profile unavailable',
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(
        _host(
          source: _Source(
            () async => FamilyChildContextResult.failed(entry.key),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(RemoteChildContextKeys.error), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('retry replaces an unavailable state with a fresh server context', (
    tester,
  ) async {
    var attempt = 0;
    final source = _Source(() async {
      attempt += 1;
      return attempt == 1
          ? const FamilyChildContextResult.failed(
              FamilyChildContextFailure.networkUnavailable,
            )
          : _ready(FamilyChildContextRole.primaryGuardian);
    });
    await tester.pumpWidget(_host(source: source));
    await tester.pump();
    expect(find.text('No connection'), findsOneWidget);

    await tester.tap(find.byKey(RemoteChildContextKeys.retry));
    await tester.pump();
    expect(find.text('Amani'), findsOneWidget);
    expect(source.calls, 2);
  });

  testWidgets('Arabic locale uses RTL-aware Arabic truth and recovery copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        locale: const Locale('ar'),
        source: _Source(
          () async => const FamilyChildContextResult.failed(
            FamilyChildContextFailure.networkUnavailable,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('لا يوجد اتصال'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(
      tester.widget<Directionality>(find.byType(Directionality).first).textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('missing child id fails closed without calling the source', (
    tester,
  ) async {
    final source = _Source(
      () async => _ready(FamilyChildContextRole.primaryGuardian),
    );
    await tester.pumpWidget(_host(source: source, childId: null));
    await tester.pump();

    expect(find.text('Child not found'), findsOneWidget);
    expect(source.calls, 0);
  });
}

Widget _host({
  required FamilyChildContextSource source,
  String? childId = _childId,
  Locale locale = const Locale('en'),
  VoidCallback? onPairDevice,
}) => MaterialApp(
  locale: locale,
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  home: RemoteChildContextScreen(
    childId: childId,
    source: source,
    familyIdOverride: FamilyId(_familyId),
    onBack: () {},
    onPairDevice: onPairDevice,
  ),
);

FamilyChildContextResult _ready(FamilyChildContextRole role) {
  final scopes = role == FamilyChildContextRole.primaryGuardian
      ? {
          FamilyChildPermissionScope.read,
          FamilyChildPermissionScope.createDevicePairing,
        }
      : {FamilyChildPermissionScope.read};
  final now = DateTime.now().toUtc();
  return FamilyChildContextResult.ready(
    FamilyChildContext(
      familyId: FamilyId(_familyId),
      childId: ChildId(_childId),
      displayName: 'Amani',
      ageYears: 8,
      avatarEmoji: '🦁',
      themeColor: 'purple',
      version: 2,
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now.subtract(const Duration(days: 1)),
      deviceState: FamilyChildDeviceSetupState.notLinked,
      deviceCount: 0,
      observedAt: now,
      permissionSnapshot: PermissionSnapshotV1(
        policyVersion: 3,
        role: role,
        scopes: scopes,
        observedAt: now,
        expiresAt: now.add(const Duration(minutes: 5)),
      ),
    ),
  );
}

final class _Source implements FamilyChildContextSource {
  _Source(this.loadResult);

  final Future<FamilyChildContextResult> Function() loadResult;
  var calls = 0;

  @override
  Future<FamilyChildContextResult> load({
    required FamilyId familyId,
    required ChildId childId,
  }) {
    calls += 1;
    return loadResult();
  }

  @override
  void dispose() {}
}
