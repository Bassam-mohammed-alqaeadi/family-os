import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/policy/time_engine.dart';
import 'package:family_os/core/policy/time_expiry_surface.dart';

/// Widget keys for SCR-CHD-021 / UI-011 acceptance.
abstract final class TimeExpiryKeys {
  static const screen = Key('time_expiry_screen');
  static const headline = Key('time_expiry_headline');
  static const exemptBanner = Key('time_expiry_exempt_banner');
  static const chatCta = Key('time_expiry_chat_cta');
  static const quranCta = Key('time_expiry_quran_cta');
  static const entertainmentLocked = Key('time_expiry_entertainment_locked');
  static const sosCta = Key('time_expiry_sos_cta');
  static const sosIconCta = Key('time_expiry_sos_icon_cta');
  static const lockState = Key('time_expiry_lock_state');
}

/// SCR-CHD-021 — انتهى الوقت — بلطف (UI-011 / Rules 9·11 / C-1 / S4).
///
/// Calm expiry: family chat & Quran CTAs stay enabled; entertainment is locked
/// via [TimeEngine] ([AppAccess.deniedCap]); SOS remains reachable.
class TimeExpiryScreen extends StatefulWidget {
  TimeExpiryScreen({
    super.key,
    ChildId? childId,
    ScreenTimePolicy? policy,
    this.chatAvailability,
    this.sosFire,
    this.onChat,
    this.onQuran,
    this.onSos,
    this.onEntertainment,
  })  : childId = childId ?? ChildId('demo-child'),
        policy = policy ?? TimeExpirySurface.exhaustedPolicy();

  final ChildId childId;

  /// TimeEngine lock inputs — Stage-1 default is an exhausted entertainment cap.
  final ScreenTimePolicy policy;

  /// C-1 seam — null → [stage1ChatAvailability].
  final ChatAvailability? chatAvailability;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test / navigation seams (null → go_router to CHD-007 / CHD-025 / CHD-005).
  final VoidCallback? onChat;
  final VoidCallback? onQuran;
  final VoidCallback? onSos;

  /// Must stay null / unused — entertainment is locked at expiry.
  final VoidCallback? onEntertainment;

  @override
  State<TimeExpiryScreen> createState() => _TimeExpiryScreenState();
}

class _TimeExpiryScreenState extends State<TimeExpiryScreen> {
  var _sosBusy = false;

  bool get _entertainmentExpired => widget.policy.isCapExhausted;

  AppAccess get _entertainmentAccess => TimeExpirySurface.entertainmentAccess(
        childId: widget.childId,
        policy: widget.policy,
      );

  bool get _chatEnabled =>
      TimeExpirySurface.chatUsable(availability: widget.chatAvailability) &&
      TimeExpirySurface.isReachable('chat', entertainmentExpired: _entertainmentExpired);

  bool get _quranEnabled {
    final access = TimeExpirySurface.quranAccess(
      childId: widget.childId,
      policy: widget.policy,
    );
    return access == AppAccess.allowed &&
        TimeExpirySurface.isReachable(
          'quran',
          entertainmentExpired: _entertainmentExpired,
        );
  }

  bool get _entertainmentLocked =>
      _entertainmentAccess != AppAccess.allowed ||
      !TimeExpirySurface.isReachable(
        'entertainment',
        entertainmentExpired: _entertainmentExpired,
      );

  bool get _sosEnabled => TimeExpirySurface.isReachable(
        'sos',
        entertainmentExpired: _entertainmentExpired,
      );

  void _openChat() {
    if (!_chatEnabled) return;
    if (widget.onChat != null) {
      widget.onChat!();
      return;
    }
    context.go(screenPath('SCR-CHD-007'));
  }

  void _openQuran() {
    if (!_quranEnabled) return;
    if (widget.onQuran != null) {
      widget.onQuran!();
      return;
    }
    context.go(screenPath('SCR-CHD-025'));
  }

  Future<void> _openSos() async {
    if (!_sosEnabled || _sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    final fire = widget.sosFire ?? stage1SosFireService;
    await fire.fire(childId: widget.childId.value);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.go(screenPath('SCR-CHD-005'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final entertainmentLocked = _entertainmentLocked;

    return Scaffold(
      key: TimeExpiryKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(l10n.timeExpiryTitle),
        actions: [
          // Icon-only SOS edge (UI-014/015 / Rule 16) — ≥48dp + ARB Semantics.
          IconButton(
            key: TimeExpiryKeys.sosIconCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _sosEnabled && !_sosBusy ? _openSos : null,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.sos, color: colors.coral),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Center(
              child: Text('🌙', style: TextStyle(fontSize: 52)),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.timeExpiryHeadline,
              key: TimeExpiryKeys.headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.timeExpiryBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.ink2,
                  ),
            ),
            const SizedBox(height: 16),
            BannerNote(
              key: TimeExpiryKeys.exemptBanner,
              message: l10n.timeExpiryExemptBanner,
              variant: BannerVariant.g,
            ),
            const SizedBox(height: 8),
            // Hidden lock-state probe for TimeEngine acceptance (AC2).
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 0,
                child: Text(
                  key: TimeExpiryKeys.lockState,
                  _entertainmentAccess.name,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.timeExpiryStillAvailable,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    _ExpiryCtaRow(
                      key: TimeExpiryKeys.chatCta,
                      icon: '💬',
                      title: l10n.timeExpiryChatCta,
                      subtitle: l10n.timeExpiryChatSubtitle,
                      enabled: _chatEnabled,
                      onTap: _chatEnabled ? _openChat : null,
                    ),
                    _ExpiryCtaRow(
                      key: TimeExpiryKeys.quranCta,
                      icon: '📖',
                      title: l10n.timeExpiryQuranCta,
                      subtitle: l10n.timeExpiryQuranSubtitle,
                      enabled: _quranEnabled,
                      onTap: _quranEnabled ? _openQuran : null,
                    ),
                    _ExpiryCtaRow(
                      key: TimeExpiryKeys.entertainmentLocked,
                      icon: '🎮',
                      title: l10n.timeExpiryEntertainmentLocked,
                      subtitle: l10n.timeExpiryEntertainmentSubtitle,
                      enabled: false,
                      locked: entertainmentLocked,
                      onTap: entertainmentLocked
                          ? null
                          : widget.onEntertainment,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryBtn(
              key: TimeExpiryKeys.sosCta,
              label: l10n.timeExpirySosCta,
              semanticsLabel: l10n.spineCtaSosSemantics,
              variant: PrimaryBtnVariant.coral,
              onPressed: _sosEnabled && !_sosBusy ? _openSos : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryCtaRow extends StatelessWidget {
  const _ExpiryCtaRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.locked = false,
    this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final interactive = enabled && onTap != null;

    return Semantics(
      button: true,
      enabled: interactive,
      label: title,
      child: Opacity(
        opacity: interactive ? 1 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (locked)
                    Icon(Icons.lock_outline, size: 20, color: colors.ink2)
                  else if (interactive)
                    Icon(Icons.chevron_left, size: 22, color: colors.ink2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
