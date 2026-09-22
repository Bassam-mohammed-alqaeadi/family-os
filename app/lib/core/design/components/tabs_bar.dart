import 'package:flutter/material.dart';

import '../tokens.dart';
import 'family_ui_mode.dart';

enum TabsBarRole { parent, child }

/// One tabs item (icon glyph + localized label).
class TabsBarItem {
  const TabsBarItem({required this.icon, required this.label});

  final String icon;
  final String label;
}

/// Bottom tabs chrome matching prototype `.tabs` (parent 5 / child 4).
class TabsBar extends StatelessWidget {
  const TabsBar({
    super.key,
    required this.role,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final TabsBarRole role;
  final List<TabsBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final expected = role == TabsBarRole.parent ? 5 : 4;
    assert(
      items.length == expected,
      'TabsBar $role expects $expected items, got ${items.length}',
    );

    final useChildAccent =
        role == TabsBarRole.child ||
        FamilyUiModeScope.of(context) == FamilyUiMode.child;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _TabButton(
                  item: items[i],
                  selected: i == selectedIndex,
                  useChildAccent: useChildAccent && role == TabsBarRole.child,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.useChildAccent,
    required this.onTap,
  });

  final TabsBarItem item;
  final bool selected;
  final bool useChildAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final fg = !selected
        ? colors.ink2
        : (useChildAccent ? colors.teal600 : colors.p600);
    final well = !selected
        ? null
        : (useChildAccent ? colors.teal100 : colors.p100);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: well,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 30,
                    child: Center(
                      child: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
