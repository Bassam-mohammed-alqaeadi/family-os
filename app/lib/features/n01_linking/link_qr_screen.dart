import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Default pairing_token window (prototype `startQR` / data contracts).
const int kLinkQrDefaultSeconds = 299;

/// Mock pairing token: `pair_` + 8 hex chars.
String generateMockPairToken([Random? random]) {
  final r = random ?? Random();
  final hex = List.generate(
    8,
    (_) => r.nextInt(16).toRadixString(16),
  ).join();
  return 'pair_$hex';
}

/// Formats remaining seconds as `m:ss` (Eastern digits when [eastern] is true).
String formatLinkQrCountdown(int totalSeconds, {required bool eastern}) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = safe ~/ 60;
  final seconds = safe % 60;
  final raw = '$minutes:${seconds.toString().padLeft(2, '0')}';
  if (!eastern) return raw;
  return raw.split('').map((ch) {
    const western = '0123456789';
    const easternDigits = '٠١٢٣٤٥٦٧٨٩';
    final i = western.indexOf(ch);
    return i < 0 ? ch : easternDigits[i];
  }).join();
}

/// SCR-FAT-004 — رمز الربط QR (bare parent onboarding, mock-first).
///
/// Parametric / Rule 23: no default child name in UI — «جهازه» / «ابنه» wording.
/// Mock QR only — no camera / QR package / backend.
class LinkQrScreen extends StatefulWidget {
  const LinkQrScreen({
    super.key,
    this.initialSeconds = kLinkQrDefaultSeconds,
    this.tickInterval = const Duration(seconds: 1),
    this.onContinue,
    this.onTrial,
    this.mockToken,
  });

  /// Test seam — remaining seconds at first paint (prototype starts at 299).
  final int initialSeconds;

  /// Test seam — countdown tick period (default 1s).
  final Duration tickInterval;

  /// Test seam — when null, navigates to `/scr-fat-005`.
  final VoidCallback? onContinue;

  /// Test seam — when null, navigates to `/scr-fat-007`.
  final VoidCallback? onTrial;

  /// Optional stable token for tests; otherwise generated on init / renew.
  final String? mockToken;

  @override
  State<LinkQrScreen> createState() => _LinkQrScreenState();
}

class _LinkQrScreenState extends State<LinkQrScreen> {
  late int _secondsLeft;
  late String _token;
  Timer? _timer;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _token = widget.mockToken ?? generateMockPairToken();
    _secondsLeft = widget.initialSeconds;
    _expired = _secondsLeft <= 0;
    if (!_expired) {
      _startTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.tickInterval, (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft <= 1) {
          _secondsLeft = 0;
          _expired = true;
          _timer?.cancel();
          _timer = null;
        } else {
          _secondsLeft -= 1;
        }
      });
    });
  }

  void _continue() {
    if (_expired) return;
    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }
    context.go('/scr-fat-005');
  }

  void _trial() {
    if (widget.onTrial != null) {
      widget.onTrial!();
      return;
    }
    context.go('/scr-fat-007');
  }

  void _renew(AppLocalizations l10n) {
    setState(() {
      _token = generateMockPairToken();
      _secondsLeft = kLinkQrDefaultSeconds;
      _expired = false;
    });
    _startTicker();
    AppToast.show(context, message: l10n.linkQrRenewToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final shadows = Theme.of(context).extension<FamilyShadows>()!;
    final eastern = l10n.localeName.startsWith('ar');
    final warning = _secondsLeft < 60 && !_expired;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.linkQrTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.linkQrStep,
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
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                  height: 1.55,
                ),
                children: [
                  TextSpan(text: l10n.linkQrInstructionPrefix),
                  TextSpan(
                    text: l10n.linkQrInstructionBold,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
              key: const Key('link_qr_instruction'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Center(
              child: Semantics(
                label: l10n.linkQrSemantics,
                image: true,
                child: DecoratedBox(
                  key: const Key('link_qr_visual'),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.surface, width: 10),
                    boxShadow: [shadows.shCard],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radii.tcardIcon),
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(170, 170),
                            painter: _MockQrPainter(
                              moduleColor: colors.ink,
                              bgColor: colors.surface,
                              seed: _token.hashCode,
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const ExcludeSemantics(
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: Text(
                                    '🦁',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_expired)
              Text(
                l10n.linkQrExpired,
                key: const Key('link_qr_expired'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: colors.coral,
                ),
              )
            else
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: warning ? colors.coral : colors.ink2,
                  ),
                  children: [
                    TextSpan(text: l10n.linkQrTimerLead),
                    TextSpan(
                      text: formatLinkQrCountdown(
                        _secondsLeft,
                        eastern: eastern,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: l10n.linkQrTimerTrail),
                  ],
                ),
                key: const Key('link_qr_timer'),
                textAlign: TextAlign.center,
              ),
            // Keep token off UI chrome; available for tests / future wire-up.
            Opacity(
              opacity: 0,
              child: Text(_token, key: const Key('link_qr_token')),
            ),
            const SizedBox(height: 14),
            PrimaryBtn(
              key: const Key('link_qr_continue'),
              label: l10n.linkQrContinue,
              onPressed: _expired ? null : _continue,
            ),
            const SizedBox(height: 10),
            PrimaryBtn(
              key: const Key('link_qr_renew'),
              label: l10n.linkQrRenew,
              variant: _expired
                  ? PrimaryBtnVariant.primary
                  : PrimaryBtnVariant.sec,
              onPressed: () => _renew(l10n),
            ),
            const SizedBox(height: 10),
            PrimaryBtn(
              key: const Key('link_qr_trial'),
              label: l10n.linkQrTrial,
              variant: PrimaryBtnVariant.ghost,
              onPressed: _trial,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fake QR module grid (no real encoding).
class _MockQrPainter extends CustomPainter {
  _MockQrPainter({
    required this.moduleColor,
    required this.bgColor,
    required this.seed,
  });

  final Color moduleColor;
  final Color bgColor;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = bgColor;
    canvas.drawRect(Offset.zero & size, bg);

    const modules = 21;
    final cell = size.width / modules;
    final paint = Paint()..color = moduleColor;
    final rng = Random(seed);

    for (var y = 0; y < modules; y++) {
      for (var x = 0; x < modules; x++) {
        final inFinder = _inFinderPattern(x, y, modules);
        final filled = inFinder || rng.nextBool();
        if (!filled) continue;
        // Clear center logo pocket.
        if (x >= 8 && x <= 12 && y >= 8 && y <= 12) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  bool _inFinderPattern(int x, int y, int n) {
    bool corner(int ox, int oy) {
      final dx = x - ox;
      final dy = y - oy;
      if (dx < 0 || dy < 0 || dx > 6 || dy > 6) return false;
      if (dx == 0 || dy == 0 || dx == 6 || dy == 6) return true;
      if (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4) return true;
      return false;
    }

    return corner(0, 0) || corner(n - 7, 0) || corner(0, n - 7);
  }

  @override
  bool shouldRepaint(covariant _MockQrPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.moduleColor != moduleColor ||
        oldDelegate.bgColor != bgColor;
  }
}
