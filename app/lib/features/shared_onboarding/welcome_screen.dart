import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/launch_language_switcher.dart';

/// SCR-SHR-001 — premium Safety · Education · Fun onboarding carousel.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onStart, this.onLogin});

  final VoidCallback? onStart;
  final VoidCallback? onLogin;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.onStart case final callback?) {
      callback();
      return;
    }
    context.push('/scr-shr-002');
  }

  void _login() {
    if (widget.onLogin case final callback?) {
      callback();
      return;
    }
    context.push('/scr-shr-003');
  }

  void _advance() {
    final next = (_page + 1).clamp(0, 2);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final slides = [
      (
        emoji: l10n.welcomeSlide0Emoji,
        title: l10n.welcomeSlide0Title,
        body: l10n.welcomeSlide0Body,
        icon: Icons.celebration_rounded,
        accent: colors.amber,
        accentSoft: colors.amber100,
      ),
      (
        emoji: l10n.welcomeSlide1Emoji,
        title: l10n.welcomeSlide1Title,
        body: l10n.welcomeSlide1Body,
        icon: Icons.shield_rounded,
        accent: colors.mint,
        accentSoft: colors.mint100,
      ),
      (
        emoji: l10n.welcomeSlide2Emoji,
        title: l10n.welcomeSlide2Title,
        body: l10n.welcomeSlide2Body,
        icon: Icons.auto_stories_rounded,
        accent: colors.sky,
        accentSoft: colors.teal100,
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.p50, colors.bg, colors.childBg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    _BrandPill(colors: colors),
                    const Spacer(),
                    const LaunchLanguageSwitcher(),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: PageView.builder(
                    key: const Key('welcome_page_view'),
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return _WelcomeSlide(
                        key: Key('welcome_page_$index'),
                        emoji: slide.emoji,
                        title: slide.title,
                        body: slide.body,
                        icon: slide.icon,
                        accent: slide.accent,
                        accentSoft: slide.accentSoft,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: l10n.welcomeDotsSemantics,
                  hint: _page < slides.length - 1
                      ? l10n.welcomeDotsHint
                      : l10n.welcomeDotsDone,
                  child: GestureDetector(
                    key: const Key('welcome_dots'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _page < slides.length - 1 ? _advance : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          slides.length,
                          (index) => AnimatedContainer(
                            key: Key('welcome_dot_$index'),
                            duration: const Duration(milliseconds: 220),
                            width: index == _page ? 28 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == _page
                                  ? colors.p600
                                  : colors.border,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                PrimaryBtn(
                  key: const Key('welcome_start'),
                  label: l10n.welcomeStartCta,
                  onPressed: _start,
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('welcome_login'),
                    onPressed: _login,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.p700,
                      side: BorderSide(color: colors.p100, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      l10n.welcomeLoginCta,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  l10n.welcomeLegal,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.ink2,
                    fontSize: 11,
                    height: 1.35,
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

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.colors});

  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colors.p700, colors.p500]),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.favorite_rounded, color: colors.surface, size: 19),
        ),
      ],
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.accentSoft,
  });

  final String emoji;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card + 8),
              border: Border.all(color: colors.border),
              boxShadow: [shadows.shCard],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 146,
                        height: 146,
                        decoration: BoxDecoration(
                          color: accentSoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(emoji, style: const TextStyle(fontSize: 76)),
                      PositionedDirectional(
                        end: -2,
                        bottom: 4,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 4),
                          ),
                          child: Icon(icon, color: colors.surface, size: 25),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.ink2,
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
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
