import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';

/// A finite shimmer skeleton. It animates once rather than looping forever,
/// keeping tests deterministic and avoiding needless GPU work on slow networks.
class PremiumRosterShimmer extends StatefulWidget {
  const PremiumRosterShimmer({super.key, this.cardCount = 3});

  final int cardCount;

  @override
  State<PremiumRosterShimmer> createState() => _PremiumRosterShimmerState();
}

class _PremiumRosterShimmerState extends State<PremiumRosterShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = Curves.easeInOut.transform(_controller.value);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.8 + (glow * 2.8), 0),
            end: Alignment(-0.8 + (glow * 2.8), 0),
            colors: [
              colors.border,
              colors.surface,
              colors.border,
            ],
            stops: const [0, 0.5, 1],
          ).createShader(bounds),
          child: child,
        );
      },
      child: Column(
        key: const Key('premium_roster_shimmer'),
        children: List.generate(
          widget.cardCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(radii.card),
              ),
              child: SizedBox(
                height: 94,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: colors.ink2,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FractionallySizedBox(
                              widthFactor: 0.58,
                              child: _ShimmerLine(
                                height: 14,
                                color: colors.ink2,
                              ),
                            ),
                            const SizedBox(height: 11),
                            FractionallySizedBox(
                              widthFactor: 0.34,
                              child: _ShimmerLine(
                                height: 10,
                                color: colors.ink2,
                              ),
                            ),
                          ],
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

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

/// Bounded, reusable confirmation moment for family creation and pairing.
class PremiumCelebrationPanel extends StatefulWidget {
  const PremiumCelebrationPanel({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.favorite_rounded,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  State<PremiumCelebrationPanel> createState() =>
      _PremiumCelebrationPanelState();
}

class _PremiumCelebrationPanelState extends State<PremiumCelebrationPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
    _scale = Tween<double>(begin: 0.76, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Center(
      child: FadeTransition(
        opacity: _controller,
        child: ScaleTransition(
          scale: _scale,
          child: Semantics(
            liveRegion: true,
            container: true,
            label: widget.title,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 150,
                    height: 136,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _Sparkle(
                          alignment: AlignmentDirectional.topStart,
                          color: colors.amber,
                          size: 28,
                        ),
                        _Sparkle(
                          alignment: AlignmentDirectional.topEnd,
                          color: colors.sky,
                          size: 22,
                        ),
                        _Sparkle(
                          alignment: AlignmentDirectional.bottomStart,
                          color: colors.coral,
                          size: 18,
                        ),
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.p700, colors.p500],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.p500.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: colors.surface,
                            size: 52,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    widget.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.ink2,
                      fontSize: 15,
                      height: 1.5,
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

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final AlignmentGeometry alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Icon(Icons.auto_awesome_rounded, color: color, size: size),
    );
  }
}
