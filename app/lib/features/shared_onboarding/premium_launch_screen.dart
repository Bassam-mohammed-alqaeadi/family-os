import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/launch_language_switcher.dart';

/// A short, finite launch scene shown only to signed-out users.
///
/// Every animation completes, which respects test determinism and avoids a
/// battery-consuming loop while still giving the brand a premium entrance.
class PremiumLaunchScreen extends StatefulWidget {
  const PremiumLaunchScreen({super.key});

  @override
  State<PremiumLaunchScreen> createState() => _PremiumLaunchScreenState();
}

class _PremiumLaunchScreenState extends State<PremiumLaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.72, curve: Curves.easeOut),
    );
    _controller.addStatusListener(_onAnimationStatus);
    _controller.forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    context.go('/scr-shr-001');
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [colors.p700, colors.p500, colors.teal600],
            ),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: -70,
                start: -60,
                child: _AmbientOrb(
                  size: 210,
                  color: colors.surface.withValues(alpha: 0.12),
                ),
              ),
              PositionedDirectional(
                bottom: -110,
                end: -55,
                child: _AmbientOrb(
                  size: 280,
                  color: colors.mint.withValues(alpha: 0.2),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                  child: Column(
                    children: [
                      const Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: LaunchLanguageSwitcher(),
                      ),
                      Expanded(
                        child: Center(
                          child: FadeTransition(
                            opacity: _contentOpacity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ScaleTransition(
                                  scale: _logoScale,
                                  child: _FamilyMark(colors: colors),
                                ),
                                const SizedBox(height: 26),
                                Text(
                                  l10n.appTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.surface,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 330,
                                  ),
                                  child: Text(
                                    l10n.welcomeSlide0Body,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.surface.withValues(
                                        alpha: 0.84,
                                      ),
                                      fontSize: 15,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: _contentOpacity,
                        child: _LaunchProgress(colors: colors),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyMark extends StatelessWidget {
  const _FamilyMark({required this.colors});

  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).appTitle,
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.18),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 72, color: colors.p600),
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Icon(Icons.favorite_rounded, size: 31, color: colors.mint),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _LaunchProgress extends StatelessWidget {
  const _LaunchProgress({required this.colors});

  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        width: 84,
        height: 4,
        child: LinearProgressIndicator(
          value: 1,
          backgroundColor: colors.surface.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(colors.surface),
        ),
      ),
    );
  }
}
