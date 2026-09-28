import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/family_shell.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/hub_grid.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// In-scroll «More tools» block for shell tab roots (FAT-010 pattern).
///
/// Hub tiles scroll with page content — not pinned above [TabsBar].
class ShellTabMoreTools extends StatelessWidget {
  const ShellTabMoreTools({super.key, required this.tabId, this.onOpen});

  final String tabId;

  /// Test seam — when null, pushes [screenPath] via go_router.
  final void Function(String screenId)? onOpen;

  void _open(BuildContext context, String screenId) {
    if (onOpen != null) {
      onOpen!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final isChild =
        (CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father) ==
        AppRole.child;
    final hubItems = hubTilesForTab(tabId);
    final showKidsNote = !isChild && tabId == 'kids';
    final showSettingsOther = !isChild && tabId == 'settings';

    // Kids may have zero hub tiles (all PERCHILD) but still shows the note.
    if (hubItems.isEmpty && !showSettingsOther && !showKidsNote) {
      return const SizedBox.shrink();
    }

    return Padding(
      key: FamilyShellKeys.hub,
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.shellMoreToolsHeading,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          if (hubItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            HubGrid(
              items: [
                for (final e in hubItems)
                  HubGridItem(
                    icon: e.icon,
                    label: e.name,
                    onTap: () => _open(context, e.screenId),
                  ),
              ],
            ),
          ],
          if (showKidsNote) ...[
            const SizedBox(height: 10),
            Text(
              l10n.shellKidsPerChildNote,
              style: TextStyle(fontSize: 12, height: 1.4, color: colors.ink2),
            ),
          ],
          if (showSettingsOther) ...[
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
                  onTap: () => _open(context, 'SCR-SHR-008'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
