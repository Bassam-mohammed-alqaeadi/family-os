import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_os/core/design/tokens.dart';

void main() {
  group('FamilyColors.defaults', () {
    test('matches handoff/06 hex values plus F0-B additives', () {
      const c = FamilyColors.defaults;
      expect(c.p700, const Color(0xFF5B3FD0));
      expect(c.p600, const Color(0xFF6C4BD8));
      expect(c.p500, const Color(0xFF7C5CE6));
      expect(c.p400, const Color(0xFF8B6FF0));
      expect(c.p100, const Color(0xFFEDE7FF));
      expect(c.p50, const Color(0xFFF6F3FF));
      expect(c.mint, const Color(0xFF00D9A3));
      expect(c.mintInk, const Color(0xFF00795B));
      expect(c.coral, const Color(0xFFFF5A5F));
      expect(c.sky, const Color(0xFF4FC3F7));
      expect(c.teal600, const Color(0xFF26B3A9));
      expect(c.amberInk, const Color(0xFF9A6A12));
      expect(c.amberDeep, const Color(0xFF7A5510));
      expect(c.tealDeep, const Color(0xFF0F7A72));
      expect(c.toastBg, const Color(0xFF22253C));
      expect(c.toastAction, const Color(0xFF9EE8FF));
      expect(c.childBg, const Color(0xFFF2FAF9));
      expect(c.bg, const Color(0xFFF5F6FA));
      expect(c.surface, const Color(0xFFFFFFFF));
      expect(c.ink, const Color(0xFF1A1D2E));
      expect(c.ink2, const Color(0xFF8A8FA3));
      expect(c.border, const Color(0xFFEDEEF5));
    });
  });

  group('FamilyRadii.defaults', () {
    test('matches component radii including F0-B', () {
      const r = FamilyRadii.defaults;
      expect(r.btn, 16);
      expect(r.card, 20);
      expect(r.cardChild, 24);
      expect(r.banner, 16);
      expect(r.input, 14);
      expect(r.pill, 99);
      expect(r.sheetTop, 24);
      expect(r.tcard, 16);
      expect(r.tcardIcon, 12);
    });
  });

  group('FamilyGradients / FamilyShadows additives', () {
    test('gradCoral and shTeal match planner', () {
      const g = FamilyGradients.defaults;
      expect(g.gradCoral.colors.first, const Color(0xFFFF7A7E));
      expect(g.gradCoral.colors.last, const Color(0xFFF0464C));

      final shadows = FamilyShadows.defaultsFor(FamilyColors.defaults);
      expect(shadows.shTeal.offset, const Offset(0, 8));
      expect(shadows.shTeal.blurRadius, 24);
      expect(
        shadows.shTeal.color,
        FamilyColors.defaults.teal600.withValues(alpha: 0.35),
      );
    });
  });

  testWidgets('Theme extensions resolve from buildFamilyTheme', (tester) async {
    late ThemeData theme;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        home: Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final colors = theme.extension<FamilyColors>();
    final shadows = theme.extension<FamilyShadows>();
    final radii = theme.extension<FamilyRadii>();
    final gradients = theme.extension<FamilyGradients>();

    expect(colors, isNotNull);
    expect(shadows, isNotNull);
    expect(radii, isNotNull);
    expect(gradients, isNotNull);
    expect(colors!.p500, const Color(0xFF7C5CE6));
    expect(colors.mintInk, const Color(0xFF00795B));
    expect(radii!.card, 20);
    expect(radii.cardChild, 24);
    expect(gradients!.grad.colors.first, const Color(0xFF8B6FF0));
    expect(gradients.gradCoral.colors.first, const Color(0xFFFF7A7E));
    expect(shadows!.shTeal.blurRadius, 24);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF5F6FA));
    expect(theme.textTheme.titleMedium?.fontSize, 15);
    expect(theme.textTheme.bodyMedium?.fontSize, 13.5);
    expect(theme.textTheme.bodySmall?.fontSize, 12);
  });
}
