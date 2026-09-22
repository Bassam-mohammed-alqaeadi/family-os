import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// SCR-SHR-001 — شاشة الترحيب (bare shared onboarding entry).
///
/// Three value slides + dots + start/login. No data collection before choice.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onStart, this.onLogin});

  /// Test seam — when null, navigates to `/scr-shr-002`.
  final VoidCallback? onStart;

  /// Test seam — when null, navigates to `/scr-shr-003`.
  final VoidCallback? onLogin;

  static const int slideCount = 3;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;
  int _index = 0;

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

  void _goTo(int i) {
    final next = i % WelcomeScreen.slideCount;
    setState(() => _index = next);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _advanceFromDots() {
    _goTo(_index + 1);
  }

  void _onStart() {
    if (widget.onStart != null) {
      widget.onStart!();
      return;
    }
    context.go('/scr-shr-002');
  }

  void _onLogin() {
    if (widget.onLogin != null) {
      widget.onLogin!();
      return;
    }
    context.go('/scr-shr-003');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final slides = _slides(l10n);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Semantics(
          container: true,
          label: l10n.welcomeSlide0Title,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: WelcomeScreen.slideCount,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final slide = slides[i];
                    return Semantics(
                      label: l10n.welcomeSlideSemantics(
                        i + 1,
                        WelcomeScreen.slideCount,
                      ),
                      child: _WelcomeSlide(
                        emoji: slide.emoji,
                        title: slide.title,
                        body: slide.body,
                        mutedColor: colors.ink2,
                        inkColor: colors.ink,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Semantics(
                      button: true,
                      label: l10n.welcomeDotsSemantics,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('welcome_dots'),
                          onTap: _advanceFromDots,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var d = 0;
                                    d < WelcomeScreen.slideCount;
                                    d++)
                                  _Dot(
                                    key: Key('welcome_dot_$d'),
                                    active: d == _index,
                                    activeColor: colors.p500,
                                    idleColor: colors.border,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _index < WelcomeScreen.slideCount - 1
                          ? l10n.welcomeDotsHint
                          : l10n.welcomeDotsDone,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.ink2.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryBtn(
                      key: const Key('welcome_start'),
                      label: l10n.welcomeStartCta,
                      onPressed: _onStart,
                    ),
                    const SizedBox(height: 8),
                    PrimaryBtn(
                      key: const Key('welcome_login'),
                      label: l10n.welcomeLoginCta,
                      variant: PrimaryBtnVariant.ghost,
                      onPressed: _onLogin,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.welcomeLegal,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: colors.ink2),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_SlideCopy> _slides(AppLocalizations l10n) => [
    _SlideCopy(
      emoji: l10n.welcomeSlide0Emoji,
      title: l10n.welcomeSlide0Title,
      body: l10n.welcomeSlide0Body,
    ),
    _SlideCopy(
      emoji: l10n.welcomeSlide1Emoji,
      title: l10n.welcomeSlide1Title,
      body: l10n.welcomeSlide1Body,
    ),
    _SlideCopy(
      emoji: l10n.welcomeSlide2Emoji,
      title: l10n.welcomeSlide2Title,
      body: l10n.welcomeSlide2Body,
    ),
  ];
}

class _SlideCopy {
  const _SlideCopy({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({
    required this.emoji,
    required this.title,
    required this.body,
    required this.mutedColor,
    required this.inkColor,
  });

  final String emoji;
  final String title;
  final String body;
  final Color mutedColor;
  final Color inkColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 70)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: inkColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: mutedColor, height: 1.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    super.key,
    required this.active,
    required this.activeColor,
    required this.idleColor,
  });

  final bool active;
  final Color activeColor;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? activeColor : idleColor,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
