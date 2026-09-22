import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Family OS design tokens — extracted literally from handoff/06.
///
/// **Constitution:** `Color(0x…)` literals live ONLY in this file.
@immutable
class FamilyColors extends ThemeExtension<FamilyColors> {
  const FamilyColors({
    required this.p700,
    required this.p600,
    required this.p500,
    required this.p400,
    required this.p100,
    required this.p50,
    required this.mint,
    required this.mint100,
    required this.mintInk,
    required this.amber,
    required this.amber100,
    required this.amberInk,
    required this.amberDeep,
    required this.coral,
    required this.coral100,
    required this.sky,
    required this.teal,
    required this.teal600,
    required this.teal100,
    required this.tealDeep,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.border,
    required this.toastBg,
    required this.toastAction,
    required this.childBg,
  });

  final Color p700;
  final Color p600;
  final Color p500;
  final Color p400;
  final Color p100;
  final Color p50;
  final Color mint;
  final Color mint100;
  final Color mintInk;
  final Color amber;
  final Color amber100;
  final Color amberInk;
  final Color amberDeep;
  final Color coral;
  final Color coral100;
  /// Kid palette sky (design system «سماوي» / FAT-003 swatch 2).
  final Color sky;
  final Color teal;
  final Color teal600;
  final Color teal100;
  final Color tealDeep;
  final Color bg;
  final Color surface;
  final Color ink;
  final Color ink2;
  final Color border;
  final Color toastBg;
  final Color toastAction;
  final Color childBg;

  /// Prototype palette (handoff/06 + F0-B additive inks).
  static const FamilyColors defaults = FamilyColors(
    p700: Color(0xFF5B3FD0),
    p600: Color(0xFF6C4BD8),
    p500: Color(0xFF7C5CE6),
    p400: Color(0xFF8B6FF0),
    p100: Color(0xFFEDE7FF),
    p50: Color(0xFFF6F3FF),
    mint: Color(0xFF00D9A3),
    mint100: Color(0xFFD4FBF0),
    mintInk: Color(0xFF00795B),
    amber: Color(0xFFFFB547),
    amber100: Color(0xFFFFF4DE),
    amberInk: Color(0xFF9A6A12),
    amberDeep: Color(0xFF7A5510),
    coral: Color(0xFFFF5A5F),
    coral100: Color(0xFFFFE7E8),
    sky: Color(0xFF4FC3F7),
    teal: Color(0xFF4DD0C7),
    teal600: Color(0xFF26B3A9),
    teal100: Color(0xFFDFF7F5),
    tealDeep: Color(0xFF0F7A72),
    bg: Color(0xFFF5F6FA),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1A1D2E),
    ink2: Color(0xFF8A8FA3),
    border: Color(0xFFEDEEF5),
    toastBg: Color(0xFF22253C),
    toastAction: Color(0xFF9EE8FF),
    childBg: Color(0xFFF2FAF9),
  );

  /// Named swatches for the component gallery (token id → color → hex label).
  List<({String name, Color color, String hex})> get swatches => [
    (name: 'p700', color: p700, hex: '#5B3FD0'),
    (name: 'p600', color: p600, hex: '#6C4BD8'),
    (name: 'p500', color: p500, hex: '#7C5CE6'),
    (name: 'p400', color: p400, hex: '#8B6FF0'),
    (name: 'p100', color: p100, hex: '#EDE7FF'),
    (name: 'p50', color: p50, hex: '#F6F3FF'),
    (name: 'mint', color: mint, hex: '#00D9A3'),
    (name: 'mint100', color: mint100, hex: '#D4FBF0'),
    (name: 'mintInk', color: mintInk, hex: '#00795B'),
    (name: 'amber', color: amber, hex: '#FFB547'),
    (name: 'amber100', color: amber100, hex: '#FFF4DE'),
    (name: 'amberInk', color: amberInk, hex: '#9A6A12'),
    (name: 'amberDeep', color: amberDeep, hex: '#7A5510'),
    (name: 'coral', color: coral, hex: '#FF5A5F'),
    (name: 'coral100', color: coral100, hex: '#FFE7E8'),
    (name: 'sky', color: sky, hex: '#4FC3F7'),
    (name: 'teal', color: teal, hex: '#4DD0C7'),
    (name: 'teal600', color: teal600, hex: '#26B3A9'),
    (name: 'teal100', color: teal100, hex: '#DFF7F5'),
    (name: 'tealDeep', color: tealDeep, hex: '#0F7A72'),
    (name: 'bg', color: bg, hex: '#F5F6FA'),
    (name: 'surface', color: surface, hex: '#FFFFFF'),
    (name: 'ink', color: ink, hex: '#1A1D2E'),
    (name: 'ink2', color: ink2, hex: '#8A8FA3'),
    (name: 'border', color: border, hex: '#EDEEF5'),
    (name: 'toastBg', color: toastBg, hex: '#22253C'),
    (name: 'toastAction', color: toastAction, hex: '#9EE8FF'),
    (name: 'childBg', color: childBg, hex: '#F2FAF9'),
  ];

  @override
  FamilyColors copyWith({
    Color? p700,
    Color? p600,
    Color? p500,
    Color? p400,
    Color? p100,
    Color? p50,
    Color? mint,
    Color? mint100,
    Color? mintInk,
    Color? amber,
    Color? amber100,
    Color? amberInk,
    Color? amberDeep,
    Color? coral,
    Color? coral100,
    Color? sky,
    Color? teal,
    Color? teal600,
    Color? teal100,
    Color? tealDeep,
    Color? bg,
    Color? surface,
    Color? ink,
    Color? ink2,
    Color? border,
    Color? toastBg,
    Color? toastAction,
    Color? childBg,
  }) {
    return FamilyColors(
      p700: p700 ?? this.p700,
      p600: p600 ?? this.p600,
      p500: p500 ?? this.p500,
      p400: p400 ?? this.p400,
      p100: p100 ?? this.p100,
      p50: p50 ?? this.p50,
      mint: mint ?? this.mint,
      mint100: mint100 ?? this.mint100,
      mintInk: mintInk ?? this.mintInk,
      amber: amber ?? this.amber,
      amber100: amber100 ?? this.amber100,
      amberInk: amberInk ?? this.amberInk,
      amberDeep: amberDeep ?? this.amberDeep,
      coral: coral ?? this.coral,
      coral100: coral100 ?? this.coral100,
      sky: sky ?? this.sky,
      teal: teal ?? this.teal,
      teal600: teal600 ?? this.teal600,
      teal100: teal100 ?? this.teal100,
      tealDeep: tealDeep ?? this.tealDeep,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      border: border ?? this.border,
      toastBg: toastBg ?? this.toastBg,
      toastAction: toastAction ?? this.toastAction,
      childBg: childBg ?? this.childBg,
    );
  }

  @override
  FamilyColors lerp(ThemeExtension<FamilyColors>? other, double t) {
    if (other is! FamilyColors) {
      return this;
    }
    return FamilyColors(
      p700: Color.lerp(p700, other.p700, t)!,
      p600: Color.lerp(p600, other.p600, t)!,
      p500: Color.lerp(p500, other.p500, t)!,
      p400: Color.lerp(p400, other.p400, t)!,
      p100: Color.lerp(p100, other.p100, t)!,
      p50: Color.lerp(p50, other.p50, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mint100: Color.lerp(mint100, other.mint100, t)!,
      mintInk: Color.lerp(mintInk, other.mintInk, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amber100: Color.lerp(amber100, other.amber100, t)!,
      amberInk: Color.lerp(amberInk, other.amberInk, t)!,
      amberDeep: Color.lerp(amberDeep, other.amberDeep, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coral100: Color.lerp(coral100, other.coral100, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      teal600: Color.lerp(teal600, other.teal600, t)!,
      teal100: Color.lerp(teal100, other.teal100, t)!,
      tealDeep: Color.lerp(tealDeep, other.tealDeep, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      border: Color.lerp(border, other.border, t)!,
      toastBg: Color.lerp(toastBg, other.toastBg, t)!,
      toastAction: Color.lerp(toastAction, other.toastAction, t)!,
      childBg: Color.lerp(childBg, other.childBg, t)!,
    );
  }
}

@immutable
class FamilyShadows extends ThemeExtension<FamilyShadows> {
  const FamilyShadows({
    required this.shCard,
    required this.shFloat,
    required this.shBrand,
    required this.shCoral,
    required this.shTeal,
    required this.shMint,
  });

  final BoxShadow shCard;
  final BoxShadow shFloat;
  final BoxShadow shBrand;
  final BoxShadow shCoral;
  final BoxShadow shTeal;
  final BoxShadow shMint;

  static FamilyShadows defaultsFor(FamilyColors colors) {
    return FamilyShadows(
      shCard: BoxShadow(
        offset: const Offset(0, 2),
        blurRadius: 12,
        color: colors.ink.withValues(alpha: 0.05),
      ),
      shFloat: BoxShadow(
        offset: const Offset(0, 8),
        blurRadius: 28,
        color: colors.ink.withValues(alpha: 0.08),
      ),
      shBrand: BoxShadow(
        offset: const Offset(0, 8),
        blurRadius: 24,
        color: colors.p500.withValues(alpha: 0.28),
      ),
      shCoral: BoxShadow(
        offset: const Offset(0, 8),
        blurRadius: 24,
        color: colors.coral.withValues(alpha: 0.35),
      ),
      shTeal: BoxShadow(
        offset: const Offset(0, 8),
        blurRadius: 24,
        color: colors.teal600.withValues(alpha: 0.35),
      ),
      shMint: BoxShadow(
        offset: const Offset(0, 8),
        blurRadius: 24,
        color: colors.mint.withValues(alpha: 0.3),
      ),
    );
  }

  List<({String name, BoxShadow shadow})> get samples => [
    (name: 'shCard', shadow: shCard),
    (name: 'shFloat', shadow: shFloat),
    (name: 'shBrand', shadow: shBrand),
    (name: 'shCoral', shadow: shCoral),
    (name: 'shTeal', shadow: shTeal),
    (name: 'shMint', shadow: shMint),
  ];

  @override
  FamilyShadows copyWith({
    BoxShadow? shCard,
    BoxShadow? shFloat,
    BoxShadow? shBrand,
    BoxShadow? shCoral,
    BoxShadow? shTeal,
    BoxShadow? shMint,
  }) {
    return FamilyShadows(
      shCard: shCard ?? this.shCard,
      shFloat: shFloat ?? this.shFloat,
      shBrand: shBrand ?? this.shBrand,
      shCoral: shCoral ?? this.shCoral,
      shTeal: shTeal ?? this.shTeal,
      shMint: shMint ?? this.shMint,
    );
  }

  @override
  FamilyShadows lerp(ThemeExtension<FamilyShadows>? other, double t) {
    if (other is! FamilyShadows) {
      return this;
    }
    return FamilyShadows(
      shCard: BoxShadow.lerp(shCard, other.shCard, t)!,
      shFloat: BoxShadow.lerp(shFloat, other.shFloat, t)!,
      shBrand: BoxShadow.lerp(shBrand, other.shBrand, t)!,
      shCoral: BoxShadow.lerp(shCoral, other.shCoral, t)!,
      shTeal: BoxShadow.lerp(shTeal, other.shTeal, t)!,
      shMint: BoxShadow.lerp(shMint, other.shMint, t)!,
    );
  }
}

@immutable
class FamilyRadii extends ThemeExtension<FamilyRadii> {
  const FamilyRadii({
    required this.btn,
    required this.card,
    required this.cardChild,
    required this.banner,
    required this.input,
    required this.pill,
    required this.sheetTop,
    required this.tcard,
    required this.tcardIcon,
  });

  final double btn;
  final double card;
  final double cardChild;
  final double banner;
  final double input;
  final double pill;
  final double sheetTop;
  final double tcard;
  final double tcardIcon;

  static const FamilyRadii defaults = FamilyRadii(
    btn: 16,
    card: 20,
    cardChild: 24,
    banner: 16,
    input: 14,
    pill: 99,
    sheetTop: 24,
    tcard: 16,
    tcardIcon: 12,
  );

  List<({String name, double value})> get chips => [
    (name: 'btn', value: btn),
    (name: 'card', value: card),
    (name: 'cardChild', value: cardChild),
    (name: 'banner', value: banner),
    (name: 'input', value: input),
    (name: 'pill', value: pill),
    (name: 'sheetTop', value: sheetTop),
    (name: 'tcard', value: tcard),
    (name: 'tcardIcon', value: tcardIcon),
  ];

  @override
  FamilyRadii copyWith({
    double? btn,
    double? card,
    double? cardChild,
    double? banner,
    double? input,
    double? pill,
    double? sheetTop,
    double? tcard,
    double? tcardIcon,
  }) {
    return FamilyRadii(
      btn: btn ?? this.btn,
      card: card ?? this.card,
      cardChild: cardChild ?? this.cardChild,
      banner: banner ?? this.banner,
      input: input ?? this.input,
      pill: pill ?? this.pill,
      sheetTop: sheetTop ?? this.sheetTop,
      tcard: tcard ?? this.tcard,
      tcardIcon: tcardIcon ?? this.tcardIcon,
    );
  }

  @override
  FamilyRadii lerp(ThemeExtension<FamilyRadii>? other, double t) {
    if (other is! FamilyRadii) {
      return this;
    }
    return FamilyRadii(
      btn: lerpDouble(btn, other.btn, t)!,
      card: lerpDouble(card, other.card, t)!,
      cardChild: lerpDouble(cardChild, other.cardChild, t)!,
      banner: lerpDouble(banner, other.banner, t)!,
      input: lerpDouble(input, other.input, t)!,
      pill: lerpDouble(pill, other.pill, t)!,
      sheetTop: lerpDouble(sheetTop, other.sheetTop, t)!,
      tcard: lerpDouble(tcard, other.tcard, t)!,
      tcardIcon: lerpDouble(tcardIcon, other.tcardIcon, t)!,
    );
  }
}

@immutable
class FamilyGradients extends ThemeExtension<FamilyGradients> {
  const FamilyGradients({
    required this.grad,
    required this.gradTeal,
    required this.gradCoral,
    required this.gradMint,
  });

  final LinearGradient grad;
  final LinearGradient gradTeal;
  final LinearGradient gradCoral;
  final LinearGradient gradMint;

  /// 135° prototype gradients (handoff/06 + F0-B coral + mint `.btn.mint`).
  static const FamilyGradients defaults = FamilyGradients(
    grad: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B6FF0), Color(0xFF6C4BD8)],
    ),
    gradTeal: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5FDDD4), Color(0xFF26B3A9)],
    ),
    gradCoral: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF7A7E), Color(0xFFF0464C)],
    ),
    gradMint: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2BE3B5), Color(0xFF00B98B)],
    ),
  );

  List<({String name, LinearGradient gradient})> get strips => [
    (name: 'grad', gradient: grad),
    (name: 'gradTeal', gradient: gradTeal),
    (name: 'gradCoral', gradient: gradCoral),
    (name: 'gradMint', gradient: gradMint),
  ];

  @override
  FamilyGradients copyWith({
    LinearGradient? grad,
    LinearGradient? gradTeal,
    LinearGradient? gradCoral,
    LinearGradient? gradMint,
  }) {
    return FamilyGradients(
      grad: grad ?? this.grad,
      gradTeal: gradTeal ?? this.gradTeal,
      gradCoral: gradCoral ?? this.gradCoral,
      gradMint: gradMint ?? this.gradMint,
    );
  }

  @override
  FamilyGradients lerp(ThemeExtension<FamilyGradients>? other, double t) {
    if (other is! FamilyGradients) {
      return this;
    }
    return FamilyGradients(
      grad: LinearGradient.lerp(grad, other.grad, t)!,
      gradTeal: LinearGradient.lerp(gradTeal, other.gradTeal, t)!,
      gradCoral: LinearGradient.lerp(gradCoral, other.gradCoral, t)!,
      gradMint: LinearGradient.lerp(gradMint, other.gradMint, t)!,
    );
  }
}

/// Material 3 [ThemeData] wired to Family OS tokens + IBM Plex Sans Arabic.
ThemeData buildFamilyTheme() {
  const colors = FamilyColors.defaults;
  final shadows = FamilyShadows.defaultsFor(colors);
  const radii = FamilyRadii.defaults;
  const gradients = FamilyGradients.defaults;

  const fontFamily = 'IBMPlexSansArabic';

  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: colors.p500,
    onPrimary: colors.surface,
    secondary: colors.teal,
    onSecondary: colors.ink,
    error: colors.coral,
    onError: colors.surface,
    surface: colors.surface,
    onSurface: colors.ink,
    onSurfaceVariant: colors.ink2,
    outline: colors.border,
    outlineVariant: colors.border,
    surfaceContainerHighest: colors.p50,
  );

  final textTheme = TextTheme(
    // h3 ≈ 15 · body ≈ 13.5 · small ≈ 12 (handoff/06); weights 400/700/800
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: colors.ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: colors.ink,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: colors.ink2,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13.5,
      fontWeight: FontWeight.w800,
      height: 1.3,
      color: colors.ink,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.bg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    // UI-015 / Rule 16 — Material controls expand to ≥48dp tap targets.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleMedium,
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(48, 48)),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    chipTheme: const ChipThemeData(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    dividerColor: colors.border,
    extensions: <ThemeExtension<dynamic>>[colors, shadows, radii, gradients],
  );
}
