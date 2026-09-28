import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/audit_population.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/app/shell_config.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/components/tabs_bar.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Widget keys for PRT-2 / PRT-2.1 shell acceptance.
abstract final class FamilyShellKeys {
  static const host = Key('family_shell_host');
  static const tabs = Key('family_shell_tabs');
  static const hub = Key('family_shell_hub');
  static const aiFab = Key('family_shell_ai_fab');
  static const sosFab = Key('family_shell_sos_fab');
  static const devRoleSwitch = Key('family_shell_dev_role_switch');
  static const devRoleChild = Key('family_shell_dev_role_child');
  static const devRoleMother = Key('family_shell_dev_role_mother');
  static const devRoleFather = Key('family_shell_dev_role_father');
}

/// Prototype-parity chrome: bottom [TabsBar], AI/SOS FABs.
///
/// «More tools» scrolls inside each tab root ([ShellTabMoreTools]), not pinned
/// above the tab bar.
///
/// Lives in [MaterialApp.builder] (above [GoRouterState]), so path is read from
/// [GoRouter.state] / [GoRouter.routeInformationProvider]. Listens to both
/// delegate + provider; rebuilds are post-frame so `context.go()` after login
/// never triggers setState-during-build.
///
/// StatefulShellRoute.indexedStack deferred (PRT-2.1) — full router regen of
/// ~129 routes is high-risk; this host keeps RoleGuard + flat routes intact.
class FamilyShellHost extends StatefulWidget {
  const FamilyShellHost({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<FamilyShellHost> createState() => _FamilyShellHostState();
}

class _FamilyShellHostState extends State<FamilyShellHost> {
  late final Listenable _routeListenable;

  @override
  void initState() {
    super.initState();
    _routeListenable = Listenable.merge([
      widget.router.routerDelegate,
      widget.router.routeInformationProvider,
    ]);
    _routeListenable.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _routeListenable.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    // Delegate notifies during Router restore/build — defer setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// Prefer matched [GoRouter.state]; fall back to URI provider.
  String _currentPath() {
    try {
      return widget.router.state.uri.path;
    } on Object {
      return widget.router.routeInformationProvider.value.uri.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _currentPath();
    final chrome = _ShellChrome(
      path: path,
      router: widget.router,
      child: widget.child,
    );
    // Dev/gallery catalog — no role switch overlay.
    if (path == '/gallery' || path == '/dev-screens') return chrome;
    // Hot-reload phone workflow: jump Father Today ↔ Child / Mother homes.
    if (!kDebugMode) return chrome;

    return Stack(
      fit: StackFit.expand,
      children: [
        chrome,
        Positioned(
          top: MediaQuery.paddingOf(context).top + 6,
          left: 10,
          right: 10,
          child: _DevRoleSwitchBar(router: widget.router),
        ),
      ],
    );
  }
}

/// Debug-only role jump chips (Owner live-phone polish workflow).
class _DevRoleSwitchBar extends StatelessWidget {
  const _DevRoleSwitchBar({required this.router});

  final GoRouter router;

  void _switch(BuildContext context, AppRole role) {
    final notifier = CurrentRole.maybeNotifierOf(context);
    if (notifier != null) {
      notifier.value = role;
    }
    router.go(roleHomePath(role));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final role = CurrentRole.of(context);

    Widget chip({
      required Key key,
      required String label,
      required AppRole target,
      required Color fill,
      required Color ink,
    }) {
      final selected = role == target;
      return Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: key,
            onTap: () => _switch(context, target),
            borderRadius: BorderRadius.circular(radii.pill),
            child: Ink(
              decoration: BoxDecoration(
                color: selected ? fill : colors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(radii.pill),
                border: Border.all(
                  color: selected ? fill : colors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? ink : colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      key: FamilyShellKeys.devRoleSwitch,
      color: Colors.transparent,
      elevation: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(radii.pill),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: chip(
                  key: FamilyShellKeys.devRoleChild,
                  label: l10n.devRoleSwitchChild,
                  target: AppRole.child,
                  fill: colors.sky,
                  ink: colors.ink,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: chip(
                  key: FamilyShellKeys.devRoleMother,
                  label: l10n.devRoleSwitchMother,
                  target: AppRole.mother,
                  fill: colors.amber,
                  ink: colors.amberDeep,
                ),
              ),
              if (role != AppRole.father) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: chip(
                    key: FamilyShellKeys.devRoleFather,
                    label: l10n.devRoleSwitchFather,
                    target: AppRole.father,
                    fill: colors.p500,
                    ink: colors.surface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellChrome extends StatelessWidget {
  const _ShellChrome({
    required this.path,
    required this.router,
    required this.child,
  });

  final String path;
  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Design token gallery + QA SCR catalog — no shell chrome.
    if (path == '/gallery' || path == '/dev-screens') return child;

    final screenId = screenIdFromPath(path);
    if (screenId == null) return child;

    if (auditHostActive) {
      return _AuditVisionHost(router: router, screenId: screenId, child: child);
    }

    final role = CurrentRole.of(context);
    final isChild = role == AppRole.child;
    final tabs = isChild ? childShellTabs : parentShellTabs;
    final tabless = isChild ? childTablessScreenIds : parentTablessScreenIds;

    if (tabless.contains(screenId)) {
      return KeyedSubtree(key: FamilyShellKeys.host, child: child);
    }

    final tabIndex = indexOfTabContaining(tabs, screenId);
    if (tabIndex < 0) {
      return KeyedSubtree(key: FamilyShellKeys.host, child: child);
    }

    // More tools scrolls inside each tab root (FAT-010 pattern) — not pinned.
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    // Bound the navigator child; tabs are intrinsic. Material ancestors
    // TabsBar ink/theme; SafeArea keeps chrome above system nav (no overflow).
    return FamilyUiModeScope(
      mode: isChild ? FamilyUiMode.child : FamilyUiMode.parent,
      child: KeyedSubtree(
        key: FamilyShellKeys.host,
        child: SizedBox.expand(
          child: Material(
            color: colors.bg,
            child: SafeArea(
              top: false,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: MediaQuery.removePadding(
                          context: context,
                          removeBottom: true,
                          child: child,
                        ),
                      ),
                      TabsBar(
                        key: FamilyShellKeys.tabs,
                        role: isChild ? TabsBarRole.child : TabsBarRole.parent,
                        selectedIndex: tabIndex,
                        items: [
                          for (final t in tabs)
                            TabsBarItem(
                              icon: t.icon,
                              label: shellTabLabel(l10n, t.arbLabelKey),
                            ),
                        ],
                        onChanged: (i) {
                          router.go(screenPath(tabs[i].rootScreenId));
                        },
                      ),
                    ],
                  ),
                  if (!isChild && screenId != 'SCR-FAT-074')
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      end: 16,
                      bottom: 72,
                      child: Semantics(
                        button: true,
                        label: l10n.shellAiFabSemantics,
                        child: FloatingActionButton(
                          key: FamilyShellKeys.aiFab,
                          heroTag: 'family_shell_ai',
                          backgroundColor: colors.p600,
                          foregroundColor: colors.surface,
                          onPressed: () =>
                              router.push(screenPath('SCR-FAT-074')),
                          child: const Text(
                            '✨',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  if (isChild &&
                      screenId != 'SCR-CHD-005' &&
                      screenId != 'SCR-CHD-006')
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      end: 16,
                      bottom: 72,
                      child: Semantics(
                        button: true,
                        label: l10n.shellSosFabSemantics,
                        child: FloatingActionButton(
                          key: FamilyShellKeys.sosFab,
                          heroTag: 'family_shell_sos',
                          backgroundColor: colors.coral,
                          foregroundColor: colors.surface,
                          onPressed: () =>
                              router.push(screenPath('SCR-CHD-005')),
                          child: const Text(
                            '🆘',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Audit cold-open host. No bottom nav. The SOS control is the child's,
/// so the father board does not get a floating emergency button.
class _AuditVisionHost extends StatelessWidget {
  const _AuditVisionHost({
    required this.router,
    required this.screenId,
    required this.child,
  });

  final GoRouter router;
  final String screenId;
  final Widget child;

  static const double _gutter = 88;

  @override
  Widget build(BuildContext context) {
    final role = CurrentRole.of(context);
    final showSos =
        role == AppRole.child &&
        screenId != 'SCR-CHD-005' &&
        screenId != 'SCR-CHD-006';
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return KeyedSubtree(
      key: FamilyShellKeys.host,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: showSos ? _gutter : 0),
            child: child,
          ),
          if (showSos)
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 16,
              bottom: 16,
              child: Semantics(
                button: true,
                label: l10n.shellSosFabSemantics,
                child: FloatingActionButton(
                  key: FamilyShellKeys.sosFab,
                  heroTag: 'family_shell_sos_audit',
                  backgroundColor: colors.coral,
                  foregroundColor: colors.surface,
                  onPressed: () => router.push(screenPath('SCR-CHD-005')),
                  child: const Text('🆘', style: TextStyle(fontSize: 22)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `/scr-fat-010` → `SCR-FAT-010`.
String? screenIdFromPath(String path) {
  if (!path.startsWith('/scr-')) return null;
  final raw = path.substring(1);
  final parts = raw.split('-');
  if (parts.length < 3) return null;
  final kind = parts[1].toUpperCase();
  final num = parts.sublist(2).join('-').toUpperCase();
  return 'SCR-$kind-$num';
}

int indexOfTabContaining(List<ShellTab> tabs, String screenId) {
  for (var i = 0; i < tabs.length; i++) {
    if (tabs[i].screenIds.contains(screenId)) return i;
  }
  return -1;
}

/// Hub tiles for a tab root — mirrors HTML `hub(tab)` filters.
List<HubEntry> hubTilesForTab(String tabId) {
  final rootByTab = {
    for (final t in [...parentShellTabs, ...childShellTabs])
      t.tabId: t.rootScreenId,
  };
  final rootId = rootByTab[tabId];
  final all = hubIndex[tabId] ?? const <HubEntry>[];
  var items = all
      .where(
        (e) => e.screenId != rootId && !_noHubScreenIds.contains(e.screenId),
      )
      .toList();
  if (tabId == 'kids') {
    items = items
        .where((e) => !_perChildScreenIds.contains(e.screenId))
        .toList();
  }
  return items;
}

String shellTabLabel(AppLocalizations l10n, String arbKey) {
  return switch (arbKey) {
    'tabParentToday' => l10n.tabParentToday,
    'tabParentKids' => l10n.tabParentKids,
    'tabParentFamily' => l10n.tabParentFamily,
    'tabParentStudio' => l10n.tabParentStudio,
    'tabParentSettings' => l10n.tabParentSettings,
    'tabChildMyDay' => l10n.tabChildMyDay,
    'tabChildLearn' => l10n.tabChildLearn,
    'tabChildFamily' => l10n.tabChildFamily,
    'tabChildMe' => l10n.tabChildMe,
    _ => arbKey,
  };
}

/// Prototype `noHub:true` screens (not listed on tab hubs).
const Set<String> _noHubScreenIds = {
  'SCR-FAT-015',
  'SCR-FAT-020',
  // VX-B4 · G-08 — device detail needs a device; open from FAT-025 list.
  'SCR-FAT-026',
  'SCR-FAT-063',
  'SCR-FAT-064',
  'SCR-FAT-068',
  'SCR-FAT-070',
  'SCR-FAT-071',
  'SCR-FAT-074',
  'SCR-FAT-077',
  'SCR-FAT-080',
  'SCR-FAT-081',
  'SCR-FAT-083',
  'SCR-CHD-030',
};

/// Prototype `PERCHILD` — open from child profile tools, not kids hub.
const Set<String> _perChildScreenIds = {
  'SCR-FAT-013',
  // VX-B4 · G-08 — location / zones / media need active child context.
  'SCR-FAT-014',
  'SCR-FAT-016',
  'SCR-FAT-017',
  'SCR-FAT-032',
  'SCR-FAT-033',
  'SCR-FAT-034',
  'SCR-FAT-035',
  'SCR-FAT-036',
  'SCR-FAT-037',
  'SCR-FAT-038',
  'SCR-FAT-051',
  'SCR-FAT-065',
  'SCR-FAT-066',
  'SCR-FAT-067',
  'SCR-FAT-069',
  'SCR-FAT-072',
  'SCR-FAT-085',
};
