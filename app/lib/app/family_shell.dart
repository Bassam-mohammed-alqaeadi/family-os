import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/app/shell_config.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/components/hub_grid.dart';
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
}

/// Prototype-parity chrome: bottom [TabsBar], hub on tab roots, AI/SOS FABs.
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
    return _ShellChrome(
      path: _currentPath(),
      router: widget.router,
      child: widget.child,
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
    if (path == '/gallery') return child;

    final screenId = screenIdFromPath(path);
    if (screenId == null) return child;

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

    final tab = tabs[tabIndex];
    final onRoot = screenId == tab.rootScreenId;
    final showHub = onRoot && hubTilesForTab(tab.tabId).isNotEmpty;
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    // Bound the navigator child; hub+tabs are intrinsic. Material ancestors
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
                      if (showHub)
                        _HubStrip(
                          router: router,
                          tabId: tab.tabId,
                          isChild: isChild,
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
                    Positioned(
                      left: 16,
                      bottom: showHub ? 260 : 72,
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
                    Positioned(
                      left: 16,
                      bottom: showHub ? 260 : 72,
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

class _HubStrip extends StatelessWidget {
  const _HubStrip({
    required this.router,
    required this.tabId,
    required this.isChild,
  });

  final GoRouter router;
  final String tabId;
  final bool isChild;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final hubItems = hubTilesForTab(tabId);

    return Material(
      key: FamilyShellKeys.hub,
      color: colors.bg,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.shellMoreToolsHeading,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 8),
              HubGrid(
                items: [
                  for (final e in hubItems)
                    HubGridItem(
                      icon: e.icon,
                      label: e.name,
                      onTap: () => router.push(screenPath(e.screenId)),
                    ),
                ],
              ),
              if (!isChild && tabId == 'kids') ...[
                const SizedBox(height: 10),
                Text(
                  l10n.shellKidsPerChildNote,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: colors.ink2,
                  ),
                ),
              ],
              if (!isChild && tabId == 'settings') ...[
                const SizedBox(height: 12),
                Text(
                  l10n.shellSettingsOtherHeading,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                HubGrid(
                  items: [
                    HubGridItem(
                      icon: '🔄',
                      label: l10n.shellShortcutDeviceSwitch,
                      onTap: () => router.push(screenPath('SCR-SHR-008')),
                    ),
                    HubGridItem(
                      icon: '🤍',
                      label: l10n.shellShortcutAcceptInvite,
                      onTap: () => router.push(screenPath('SCR-FAT-009')),
                    ),
                    HubGridItem(
                      icon: '🚨',
                      label: l10n.shellShortcutSosAlert,
                      onTap: () => router.push(screenPath('SCR-FAT-018')),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
};
