import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

void main() {
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
  var _ownsRole = false;

  @override
  void initState() {
    super.initState();
    if (widget.roleController != null) {
      _role = widget.roleController!;
    } else {
      _role = RoleController(AppRole.father);
      _ownsRole = true;
    }
    _router = createAppRouter(roleListenable: _role);
  }

  @override
  void dispose() {
    if (_ownsRole) {
      _role.dispose();
    }
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurrentRole(
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
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
