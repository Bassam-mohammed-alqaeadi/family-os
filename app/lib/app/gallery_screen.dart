import 'package:flutter/material.dart';
import 'package:family_os/core/design/components/components.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Design-token + component gallery — parent/child UI modes.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  FamilyUiMode _mode = FamilyUiMode.parent;
  int _parentTab = 0;
  int _childTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<FamilyColors>()!;
    final shadows = theme.extension<FamilyShadows>()!;
    final radii = theme.extension<FamilyRadii>()!;
    final gradients = theme.extension<FamilyGradients>()!;
    final scaffoldBg = _mode == FamilyUiMode.child ? colors.childBg : colors.bg;

    return FamilyUiModeScope(
      mode: _mode,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(title: Text(l10n.galleryTitle)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.appTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.galleryHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.ink2,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryColors),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final swatch in colors.swatches)
                      _ColorTile(
                        name: swatch.name,
                        color: swatch.color,
                        hex: swatch.hex,
                        ink: colors.ink,
                        ink2: colors.ink2,
                        border: colors.border,
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryShadows),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final sample in shadows.samples)
                      _ShadowSample(
                        name: sample.name,
                        shadow: sample.shadow,
                        surface: colors.surface,
                        ink: colors.ink,
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryGradients),
                const SizedBox(height: 12),
                for (final strip in gradients.strips) ...[
                  _GradientStrip(
                    name: strip.name,
                    gradient: strip.gradient,
                    ink: colors.ink,
                    radius: radii.banner,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                _SectionHeader(label: l10n.galleryRadii),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final chip in radii.chips)
                      _RadiusChip(
                        name: chip.name,
                        value: chip.value,
                        border: colors.border,
                        ink: colors.ink,
                        ink2: colors.ink2,
                        accent: colors.p100,
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryTypography),
                const SizedBox(height: 12),
                Text(
                  'IBM Plex Sans Arabic · 400',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'IBM Plex Sans Arabic · 700',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'IBM Plex Sans Arabic · 800',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryUiMode),
                const SizedBox(height: 12),
                SegmentedButton<FamilyUiMode>(
                  segments: [
                    ButtonSegment(
                      value: FamilyUiMode.parent,
                      label: Text(l10n.galleryModeParent),
                    ),
                    ButtonSegment(
                      value: FamilyUiMode.child,
                      label: Text(l10n.galleryModeChild),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) {
                    setState(() => _mode = s.first);
                  },
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryButtons),
                const SizedBox(height: 12),
                PrimaryBtn(
                  key: const ValueKey('gallery_btn_primary'),
                  label: l10n.galleryBtnPrimary,
                  variant: PrimaryBtnVariant.primary,
                  onPressed: () =>
                      AppToast.show(context, message: l10n.galleryToastMessage),
                ),
                const SizedBox(height: 10),
                PrimaryBtn(
                  key: const ValueKey('gallery_btn_teal'),
                  label: l10n.galleryBtnTeal,
                  variant: PrimaryBtnVariant.teal,
                  onPressed: () =>
                      AppToast.show(context, message: l10n.galleryToastMessage),
                ),
                const SizedBox(height: 10),
                PrimaryBtn(
                  key: const ValueKey('gallery_btn_sec'),
                  label: l10n.galleryBtnSec,
                  variant: PrimaryBtnVariant.sec,
                  onPressed: () =>
                      AppToast.show(context, message: l10n.galleryToastMessage),
                ),
                const SizedBox(height: 10),
                PrimaryBtn(
                  key: const ValueKey('gallery_btn_ghost'),
                  label: l10n.galleryBtnGhost,
                  variant: PrimaryBtnVariant.ghost,
                  onPressed: () =>
                      AppToast.show(context, message: l10n.galleryToastMessage),
                ),
                const SizedBox(height: 10),
                PrimaryBtn(
                  key: const ValueKey('gallery_btn_coral'),
                  label: l10n.galleryBtnCoral,
                  variant: PrimaryBtnVariant.coral,
                  onPressed: () =>
                      AppToast.show(context, message: l10n.galleryToastMessage),
                ),
                const SizedBox(height: 10),
                PrimaryBtn(
                  key: const ValueKey('gallery_btn_disabled'),
                  label: l10n.galleryBtnDisabled,
                  onPressed: null,
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryCards),
                const SizedBox(height: 12),
                AppCard(
                  title: l10n.galleryCardTitle,
                  linkLabel: l10n.galleryCardLink,
                  onLinkTap: () =>
                      AppToast.show(context, message: l10n.galleryToastMessage),
                  child: Text(
                    l10n.galleryCardBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryRows),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      RowTile(
                        leading: const Text(
                          '☀️',
                          style: TextStyle(fontSize: 22),
                        ),
                        title: l10n.galleryRowTitle1,
                        subtitle: l10n.galleryRowSub1,
                        trailing: Tag(
                          label: l10n.galleryTagG,
                          variant: TagVariant.g,
                        ),
                        onTap: () => AppToast.show(
                          context,
                          message: l10n.galleryToastMessage,
                        ),
                      ),
                      RowTile(
                        leading: const Text(
                          '💬',
                          style: TextStyle(fontSize: 22),
                        ),
                        title: l10n.galleryRowTitle2,
                        subtitle: l10n.galleryRowSub2,
                        trailing: Icon(Icons.chevron_left, color: colors.ink2),
                        onTap: () => AppToast.show(
                          context,
                          message: l10n.galleryToastMessage,
                        ),
                      ),
                      RowTile(
                        leading: const Text(
                          '📚',
                          style: TextStyle(fontSize: 22),
                        ),
                        title: l10n.galleryRowTitle3,
                        subtitle: l10n.galleryRowSub3,
                        trailing: Tag(
                          label: l10n.galleryTagA,
                          variant: TagVariant.a,
                        ),
                        showDivider: false,
                        onTap: () => AppToast.show(
                          context,
                          message: l10n.galleryToastMessage,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryTags),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tag(label: l10n.galleryTagG, variant: TagVariant.g),
                    Tag(label: l10n.galleryTagT, variant: TagVariant.t),
                    Tag(label: l10n.galleryTagP, variant: TagVariant.p),
                    Tag(label: l10n.galleryTagA, variant: TagVariant.a),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryBanners),
                const SizedBox(height: 12),
                BannerNote(
                  message: l10n.galleryBannerT,
                  variant: BannerVariant.t,
                ),
                const SizedBox(height: 10),
                BannerNote(
                  message: l10n.galleryBannerP,
                  variant: BannerVariant.p,
                ),
                const SizedBox(height: 10),
                BannerNote(
                  message: l10n.galleryBannerA,
                  variant: BannerVariant.a,
                ),
                const SizedBox(height: 10),
                BannerNote(
                  message: l10n.galleryBannerG,
                  variant: BannerVariant.g,
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryProgress),
                const SizedBox(height: 12),
                const ProgressBar(
                  key: ValueKey('gallery_prog_mint'),
                  value: 0.45,
                ),
                const SizedBox(height: 12),
                const ProgressBar(
                  key: ValueKey('gallery_prog_pu'),
                  value: 0.70,
                  variant: ProgressBarVariant.pu,
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.gallerySheet),
                const SizedBox(height: 12),
                PrimaryBtn(
                  key: const ValueKey('gallery_open_sheet'),
                  label: l10n.galleryOpenSheet,
                  variant: PrimaryBtnVariant.sec,
                  onPressed: () {
                    BottomSheetHost.show<void>(
                      context,
                      semanticLabel: l10n.gallerySheetTitle,
                      builder: (sheetContext) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.gallerySheetTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PrimaryBtn(
                              key: const ValueKey('gallery_sheet_close'),
                              label: l10n.gallerySheetClose,
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryToast),
                const SizedBox(height: 12),
                PrimaryBtn(
                  key: const ValueKey('gallery_show_toast'),
                  label: l10n.galleryShowToast,
                  variant: PrimaryBtnVariant.ghost,
                  onPressed: () {
                    AppToast.show(
                      context,
                      message: l10n.galleryToastMessage,
                      actionLabel: l10n.galleryToastAction,
                      onAction: () {
                        AppToast.show(
                          context,
                          message: l10n.galleryToastUndone,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryTabs),
                const SizedBox(height: 12),
                TabsBar(
                  key: const ValueKey('gallery_tabs_parent'),
                  role: TabsBarRole.parent,
                  selectedIndex: _parentTab,
                  onChanged: (i) => setState(() => _parentTab = i),
                  items: [
                    TabsBarItem(icon: '🏠', label: l10n.tabParentToday),
                    TabsBarItem(icon: '👦', label: l10n.tabParentKids),
                    TabsBarItem(icon: '💬', label: l10n.tabParentFamily),
                    TabsBarItem(icon: '📚', label: l10n.tabParentStudio),
                    TabsBarItem(icon: '⚙️', label: l10n.tabParentSettings),
                  ],
                ),
                const SizedBox(height: 12),
                TabsBar(
                  key: const ValueKey('gallery_tabs_child'),
                  role: TabsBarRole.child,
                  selectedIndex: _childTab,
                  onChanged: (i) => setState(() => _childTab = i),
                  items: [
                    TabsBarItem(icon: '🏠', label: l10n.tabChildMyDay),
                    TabsBarItem(icon: '📚', label: l10n.tabChildLearn),
                    TabsBarItem(icon: '💬', label: l10n.tabChildFamily),
                    TabsBarItem(icon: '👤', label: l10n.tabChildMe),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(label: l10n.galleryHub),
                const SizedBox(height: 12),
                HubGrid(
                  items: [
                    HubGridItem(
                      icon: '✅',
                      label: l10n.galleryHubItem1,
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.galleryToastMessage,
                      ),
                    ),
                    HubGridItem(
                      icon: '⏱',
                      label: l10n.galleryHubItem2,
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.galleryToastMessage,
                      ),
                    ),
                    HubGridItem(
                      icon: '⚡',
                      label: l10n.galleryHubItem3,
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.galleryToastMessage,
                      ),
                    ),
                    HubGridItem(
                      icon: '📊',
                      label: l10n.galleryHubItem4,
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.galleryToastMessage,
                      ),
                    ),
                    HubGridItem(
                      icon: '📱',
                      label: l10n.galleryHubItem5,
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.galleryToastMessage,
                      ),
                    ),
                    HubGridItem(
                      icon: '✨',
                      label: l10n.galleryHubItem6,
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.galleryToastMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(label, style: theme.textTheme.titleMedium),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.name,
    required this.color,
    required this.hex,
    required this.ink,
    required this.ink2,
    required this.border,
  });

  final String name;
  final Color color;
  final String hex;
  final Color ink;
  final Color ink2;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name $hex',
      child: SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: const SizedBox(height: 48),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            Text(
              hex,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShadowSample extends StatelessWidget {
  const _ShadowSample({
    required this.name,
    required this.shadow,
    required this.surface,
    required this.ink,
  });

  final String name;
  final BoxShadow shadow;
  final Color surface;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [shadow],
            ),
            child: const SizedBox(width: 72, height: 56),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientStrip extends StatelessWidget {
  const _GradientStrip({
    required this.name,
    required this.gradient,
    required this.ink,
    required this.radius,
  });

  final String name;
  final LinearGradient gradient;
  final Color ink;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: const SizedBox(height: 40),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip({
    required this.name,
    required this.value,
    required this.border,
    required this.ink,
    required this.ink2,
    required this.accent,
  });

  final String name;
  final double value;
  final Color border;
  final Color ink;
  final Color ink2;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final r = value.clamp(0, 28).toDouble();
    return Semantics(
      label: '$name $value',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              Text(
                value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
