import 'dart:async';

import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';

/// Lightweight child mirror for SET-003 P12 proof (not full SCR-CHD-004 board).
///
/// Watches [PolicySyncBus] so remaining minutes update in-session when the
/// parent saves a new cap — no cold restart required.
class ChildScreenTimeMirror extends StatefulWidget {
  const ChildScreenTimeMirror({
    super.key,
    required this.childId,
    this.syncBus,
    this.initialPolicy,
  });

  final ChildId childId;

  /// Rule 25 seam — null → [stage1PolicySyncBus].
  final PolicySyncBus? syncBus;

  /// Optional seed before first bus event (tests / hydrate from repo).
  final ScreenTimePolicy? initialPolicy;

  @override
  State<ChildScreenTimeMirror> createState() => _ChildScreenTimeMirrorState();
}

class _ChildScreenTimeMirrorState extends State<ChildScreenTimeMirror> {
  late final PolicySyncBus _bus;
  StreamSubscription<ChildPolicyMirror>? _sub;
  late ChildPolicyMirror _mirror;

  @override
  void initState() {
    super.initState();
    _bus = widget.syncBus ?? stage1PolicySyncBus;
    if (widget.initialPolicy != null) {
      _bus.hydrate(widget.childId, policy: widget.initialPolicy);
    }
    _mirror = _bus.mirrorOf(widget.childId);
    _sub = _bus.watch(widget.childId).listen((next) {
      if (!mounted) return;
      setState(() => _mirror = next);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final remaining = _mirror.remainingMinutes;
    final exhausted = _mirror.policy.isCapExhausted;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.childTimeMirrorTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              l10n.childTimeMirrorRemainingLabel,
              style: TextStyle(
                fontSize: 14,
                color: colors.ink2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              key: const Key('child_time_mirror_remaining'),
              l10n.childTimeMirrorRemainingMinutes(remaining),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            if (_mirror.sleepActiveNotice) ...[
              const SizedBox(height: 16),
              BannerNote(
                key: const Key('child_time_mirror_sleep_notice'),
                message: l10n.childTimeMirrorSleepNotice,
                variant: BannerVariant.t,
              ),
            ],
            if (exhausted) ...[
              const SizedBox(height: 16),
              BannerNote(
                key: const Key('child_time_mirror_exempt_banner'),
                message: l10n.childTimeMirrorExemptBanner,
                variant: BannerVariant.g,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
