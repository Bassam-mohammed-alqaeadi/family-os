import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// SCR-FAT-006 — نجاح الربط (bare parent onboarding, mock-first).
///
/// Wave-1: celebration + mini map first value → day board.
/// Parametric / Rule 23: no default child name — «ابنك» / constructor display name.
///
/// Honesty: when IdentityRuntime has no active enrolled device for the active
/// family, this screen is a **legacy prototype celebration** — not managed
/// enrollment success. Managed pairing returns to FAT-013 while pairing-pending.
class LinkSuccessScreen extends StatefulWidget {
  const LinkSuccessScreen({
    super.key,
    this.childDisplayName = '',
    this.onAddNext,
    this.onDayBoard,
  });

  /// Injected mock display name; empty → generic «ابنك» hero (ARB).
  final String childDisplayName;

  /// Test seams — when null, navigates to FAT-003 / FAT-010.
  final VoidCallback? onAddNext;
  final VoidCallback? onDayBoard;

  @override
  State<LinkSuccessScreen> createState() => _LinkSuccessScreenState();
}

class _LinkSuccessScreenState extends State<LinkSuccessScreen> {
  bool _templateApplied = false;

  String get _resolvedName {
    final raw = widget.childDisplayName.trim();
    return raw.isEmpty ? '' : raw;
  }

  bool _hasManagedEnrollment(BuildContext context) {
    final runtime = CurrentIdentity.maybeOf(context);
    if (runtime == null) return false;
    final familyId = runtime.activeFamilyId;
    return runtime.enrollments.any(
      (enrollment) =>
          enrollment.familyId == familyId &&
          enrollment.state == EnrollmentState.enrolled,
    );
  }

  void _addNext(BuildContext context, AppLocalizations l10n) {
    AppToast.show(context, message: l10n.linkSuccessAddNextToast);
    if (widget.onAddNext != null) {
      widget.onAddNext!();
      return;
    }
    context.go('/scr-fat-003');
  }

  void _dayBoard(BuildContext context) {
    if (widget.onDayBoard != null) {
      widget.onDayBoard!();
      return;
    }
    context.go('/scr-fat-010');
  }

  void _applyTemplate(BuildContext context, AppLocalizations l10n) {
    setState(() => _templateApplied = true);
    AppToast.show(context, message: l10n.linkSuccessApplyToast);
  }

  void _manualAdjust(BuildContext context, AppLocalizations l10n) {
    AppToast.show(context, message: l10n.linkSuccessManualToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final managedEnrollment = _hasManagedEnrollment(context);

    // Prefer fixed hero; optional injected name only for tests — never a person default.
    final heroTitle = !managedEnrollment
        ? l10n.pairingVerificationMessage
        : (_resolvedName.isEmpty
              ? l10n.linkSuccessHeroTitle
              : l10n.linkSuccessHeroTitleNamed(_resolvedName));

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.linkSuccessTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.linkSuccessStep,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            if (!managedEnrollment) ...[
              BannerNote(
                key: const Key('link_success_legacy_honesty'),
                message: l10n.sys3MockHonesty,
                variant: BannerVariant.a,
              ),
              const SizedBox(height: 10),
            ],
            Text(
              '🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 56, color: colors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              key: Key(
                managedEnrollment
                    ? 'link_success_managed_hero'
                    : 'link_success_legacy_hero',
              ),
              heroTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.ink,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.linkSuccessFirstFruit,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              label: l10n.linkSuccessMapSemantics,
              image: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radii.banner),
                child: SizedBox(
                  key: const Key('link_success_mini_map'),
                  height: 170,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            painter: _MiniMapPainter(colors: colors),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 52,
                        right: 140,
                        child: ExcludeSemantics(
                          child: _MapPin(
                            emoji: '🦁',
                            gradient: gradients.grad,
                            shadow: shadows.shBrand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              key: const Key('link_success_location_card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.linkSuccessLocationTitle,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.linkSuccessLocationMeta,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              key: const Key('link_success_template_card'),
              borderColor: colors.teal,
              borderWidth: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.linkSuccessTemplateTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.linkSuccessTemplateBody,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_templateApplied) ...[
                    BannerNote(
                      key: const Key('link_success_template_applied'),
                      message: l10n.linkSuccessTemplateApplied,
                      variant: BannerVariant.g,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        key: const Key('link_success_template_undo'),
                        onPressed: () =>
                            setState(() => _templateApplied = false),
                        child: Text(
                          l10n.linkSuccessTemplateUndo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.mintInk,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    PrimaryBtn(
                      key: const Key('link_success_apply_template'),
                      label: l10n.linkSuccessApplyTemplate,
                      variant: PrimaryBtnVariant.teal,
                      onPressed: () => _applyTemplate(context, l10n),
                    ),
                    const SizedBox(height: 8),
                    PrimaryBtn(
                      key: const Key('link_success_manual'),
                      label: l10n.linkSuccessManual,
                      variant: PrimaryBtnVariant.ghost,
                      onPressed: () => _manualAdjust(context, l10n),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              key: const Key('link_success_next_child_card'),
              backgroundColor: colors.p50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.linkSuccessNextChildTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.linkSuccessNextChildBody,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryBtn(
                    key: const Key('link_success_add_next'),
                    label: l10n.linkSuccessAddNext,
                    onPressed: () => _addNext(context, l10n),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryBtn(
              key: const Key('link_success_day_board'),
              label: l10n.linkSuccessDayBoard,
              variant: PrimaryBtnVariant.mint,
              onPressed: () => _dayBoard(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.emoji,
    required this.gradient,
    required this.shadow,
  });

  final String emoji;
  final LinearGradient gradient;
  final BoxShadow shadow;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.785398, // -45°
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(19),
            topRight: Radius.circular(19),
            bottomLeft: Radius.circular(19),
            bottomRight: Radius.circular(2),
          ),
          boxShadow: [shadow],
        ),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Transform.rotate(
              angle: 0.785398,
              child: Text(emoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mock map-scape using [FamilyColors] only — no map SDK.
class _MiniMapPainter extends CustomPainter {
  _MiniMapPainter({required this.colors});

  final FamilyColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()..color = colors.childBg;
    canvas.drawRect(Offset.zero & size, ground);

    final building = Paint()..color = colors.border;
    final park = Paint()..color = colors.mint100;
    final school = Paint()..color = colors.teal100;
    final road = Paint()..color = colors.surface;
    final dash = Paint()
      ..color = colors.amber
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Blocks
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.04,
          size.height * 0.06,
          size.width * 0.3,
          size.height * 0.32,
        ),
        const Radius.circular(6),
      ),
      building,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.46,
          size.height * 0.05,
          size.width * 0.26,
          size.height * 0.33,
        ),
        const Radius.circular(6),
      ),
      building,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.8,
          size.height * 0.04,
          size.width * 0.16,
          size.height * 0.34,
        ),
        const Radius.circular(6),
      ),
      school,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.05,
          size.height * 0.58,
          size.width * 0.24,
          size.height * 0.34,
        ),
        const Radius.circular(10),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.46,
          size.height * 0.57,
          size.width * 0.26,
          size.height * 0.36,
        ),
        const Radius.circular(6),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.78,
          size.height * 0.58,
          size.width * 0.18,
          size.height * 0.34,
        ),
        const Radius.circular(6),
      ),
      building,
    );

    // Roads
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.12),
      road,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.38, 0, size.width * 0.06, size.height),
      road,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.48),
      Offset(size.width, size.height * 0.48),
      dash,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
