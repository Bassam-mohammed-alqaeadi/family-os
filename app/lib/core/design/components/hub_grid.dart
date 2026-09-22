import 'package:flutter/material.dart';

import '../tokens.dart';

/// One hub tile (prototype `.tcard`).
class HubGridItem {
  const HubGridItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
}

/// 3-column hub grid matching prototype `.tgrid` / `.tcard`.
class HubGrid extends StatelessWidget {
  const HubGrid({super.key, required this.items});

  final List<HubGridItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final tileWidth = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: tileWidth,
                child: _HubTile(item: items[i], index: i),
              ),
          ],
        );
      },
    );
  }
}

class _HubTile extends StatefulWidget {
  const _HubTile({required this.item, required this.index});

  final HubGridItem item;
  final int index;

  @override
  State<_HubTile> createState() => _HubTileState();
}

class _HubTileState extends State<_HubTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Semantics(
      button: true,
      label: widget.item.label,
      child: AnimatedScale(
        scale: _pressed ? 0.978 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.item.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(radii.tcard),
            child: Ink(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.tcard),
                border: Border.all(color: colors.border, width: 1.5),
                boxShadow: _pressed ? [shadows.shCard] : null,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.p50,
                          borderRadius: BorderRadius.circular(radii.tcardIcon),
                        ),
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: Center(
                            child: Text(
                              widget.item.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.item.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
