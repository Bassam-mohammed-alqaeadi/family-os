import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/router.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/sys3_identity/sys3_identity_screens.dart';

void _log(String hypothesisId, String message, Map<String, Object?> data) {
  final payload = <String, Object?>{
    'sessionId': '296a8e',
    'hypothesisId': hypothesisId,
    'location': 'debug_sys3_route_probe_test.dart',
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'runId': data['runId'] ?? 'probe',
  };
  final line = jsonEncode(payload);
  // ignore: avoid_print
  print('AGENT_DEBUG $line');
  File(r'D:\special projects\family\debug-296a8e.log')
      .writeAsStringSync('$line\n', mode: FileMode.append);
}

void main() {
  test('H-A: stage1 needsFamilySelector is true', () {
    final rt = createStage1IdentityRuntime();
    _log('A', 'identity_probe', {
      'needsFamilySelector': rt.needsFamilySelector,
      'sessionExpired': rt.session.isExpiredAt(DateTime.now().toUtc()),
    });
    expect(rt.needsFamilySelector, isTrue);
  });

  test('POST-FIX: createAppRouter registers /sys3-family-select', () {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(roleListenable: role);
    final configs = router.configuration.routes;
    final paths = <String>[];
    for (final r in configs) {
      if (r is GoRoute) paths.add(r.path);
    }
    _log('A', 'router_paths_post_fix', {
      'hasSys3FamilySelect': paths.contains('/sys3-family-select'),
      'hasSys3SessionExpired': paths.contains('/sys3-session-expired'),
      'hasSys3AccountRecovery': paths.contains('/sys3-account-recovery'),
      'scrFat010Present': paths.contains('/scr-fat-010'),
      'routeCount': paths.length,
      'runId': 'post-fix',
    });
    expect(paths.contains('/sys3-family-select'), isTrue);
    expect(paths.contains('/sys3-session-expired'), isTrue);
    expect(paths.contains('/sys3-account-recovery'), isTrue);
    role.dispose();
    router.dispose();
  });

  testWidgets('POST-FIX: navigating to /sys3-family-select opens selector', (
    tester,
  ) async {
    final role = RoleController(AppRole.father);
    final runtime = createStage1IdentityRuntime();
    final router = createAppRouter(roleListenable: role);
    await tester.pumpWidget(
      CurrentIdentity(
        runtime: runtime,
        child: MaterialApp.router(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/sys3-family-select');
    await tester.pumpAndSettle();

    _log('A', 'nav_sys3_family_select_post_fix', {
      'uriAfter': router.state.uri.toString(),
      'runId': 'post-fix',
    });
    expect(router.state.uri.path, '/sys3-family-select');
    expect(find.byKey(Sys3Keys.familySelector), findsOneWidget);

    role.dispose();
    router.dispose();
  });
}
