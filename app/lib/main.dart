import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:family_os/app/family_shell.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phase 1.5 — shared FS SQLite session (Memory fallback is honest DEGRADED).
  await FsSessionKernel.ensureOpen(preferSqlite: true);
  // #region agent log
  try {
    final rt = stage1IdentityRuntime;
    final payload = <String, Object?>{
      'sessionId': '296a8e',
      'hypothesisId': 'A',
      'location': 'main.dart:boot',
      'message': 'identity_boot_flags',
      'data': {
        'needsFamilySelector': rt.needsFamilySelector,
        'sessionExpired': rt.session.isExpiredAt(DateTime.now().toUtc()),
        'sessionRevoked': rt.session.isRevoked,
        'membershipCountHint': rt.needsFamilySelector ? 'gt1' : 'le1',
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'runId': 'pre-fix',
    };
    final line =
        '{"sessionId":"296a8e","hypothesisId":"A","location":"main.dart:boot","message":"identity_boot_flags","data":{"needsFamilySelector":${rt.needsFamilySelector},"sessionExpired":${rt.session.isExpiredAt(DateTime.now().toUtc())}},"timestamp":${DateTime.now().millisecondsSinceEpoch},"runId":"pre-fix"}';
    debugPrint('AGENT_DEBUG $line');
    // ignore: unused_local_variable
    final _ = payload;
    File(
      r'D:\special projects\family\debug-296a8e.log',
    ).writeAsStringSync('$line\n', mode: FileMode.append);
  } catch (_) {}
  // #endregion
  runApp(const FamilyOsApp());
}

/// Family OS root — Arabic-first RTL, IBM Plex Sans Arabic, go_router.
class FamilyOsApp extends StatefulWidget {
  const FamilyOsApp({super.key, this.roleController});

  /// Optional override for tests / gallery role switching.
  final RoleController? roleController;

  @override
  State<FamilyOsApp> createState() => _FamilyOsAppState();
}

class _FamilyOsAppState extends State<FamilyOsApp> {
  late final RoleController _role;
  late final GoRouter _router;
  late final IdentityRuntime _identity;
  var _ownsRole = false;

  @override
  void initState() {
    super.initState();
    _identity = stage1IdentityRuntime;
    if (widget.roleController != null) {
      _role = widget.roleController!;
    } else {
      _role = RoleController(AppRole.father);
      _ownsRole = true;
    }
    _role.addListener(_syncLegacyRoleFallback);
    _syncLegacyRoleFallback();
    _router = createAppRouter(roleListenable: _role);
  }

  void _syncLegacyRoleFallback() {
    // Temporary bridge: role picker remains for stage-1 compatibility only.
    _identity.setLegacyRoleFallback(_role.value);
  }

  @override
  void dispose() {
    _role.removeListener(_syncLegacyRoleFallback);
    if (_ownsRole) {
      _role.dispose();
    }
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurrentIdentity(
      runtime: _identity,
      child: CurrentRole(
        notifier: _role,
        child: MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
          builder: (context, child) => FamilyShellHost(
            router: _router,
            child: child ?? const SizedBox.shrink(),
          ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
