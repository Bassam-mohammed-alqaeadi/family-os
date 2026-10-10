import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/family_ui_mode.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/foundation_gate/native_child_telemetry_bridge.dart';

/// The disclosure text version the consent act records.
///
/// A consent is evidence of agreement to *this* text; changing the disclosure
/// copy materially means changing this version and re-asking.
const String kChildLocationConsentTextVersion = '2026-10-10';

/// Widget keys for SCR-CHD-003 acceptance.
abstract final class TransparencyConsentKeys {
  static const screen = Key('transparency_consent_screen');
  static const honestyBanner = Key('transparency_consent_honesty_banner');
  static const sharedCard = Key('transparency_consent_shared_card');
  static const neverCard = Key('transparency_consent_never_card');
  static const advisorCard = Key('transparency_consent_advisor_card');
  static const acceptCta = Key('transparency_consent_accept');
  static const parentLean = Key('transparency_consent_parent_lean');
  static const recordingBanner = Key('transparency_consent_recording');
  static const errorBanner = Key('transparency_consent_error');
}

/// SCR-CHD-003 — إقرار الشفافية.
///
/// The one-time prominent disclosure Play requires: it stands BEFORE the
/// permission asks (the pairing screen no longer asks ahead of it), and its
/// accept action is the consent the server records (who, when, which text).
/// Age-appropriate honesty (care ≠ spy). Prototype CHD-003 · SET-012 · Rule 12/23.
class TransparencyConsentScreen extends StatefulWidget {
  const TransparencyConsentScreen({
    super.key,
    this.roleOverride,
    this.onAccept,
    this.recordConsent,
    this.runNativeFlow = true,
  });

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Test seam — when null, navigates to `/scr-chd-004`.
  final VoidCallback? onAccept;

  /// Test seam — records the disclosure-consent act on the server. Null → the
  /// real recording, through the paired-device credential the native layer
  /// holds. Returns true only after the server confirmed (or already held) the
  /// consent.
  final Future<bool> Function()? recordConsent;

  /// Test seam — when false, the accept act performs no native calls at all
  /// (no permission ask, no service start). Defaults to true; widget tests set
  /// it false because the platform channels are unbound there.
  final bool runNativeFlow;

  @override
  State<TransparencyConsentScreen> createState() =>
      _TransparencyConsentScreenState();
}

class _TransparencyConsentScreenState extends State<TransparencyConsentScreen> {
  bool _recording = false;
  bool _failed = false;

  AppRole _role(BuildContext context) =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.child;

  /// The real recording: the native layer posts with the credential it holds.
  ///
  /// `409 consent_already_granted` is success — the consent exists; a second
  /// act would not make it more true. An unavailable bridge (no paired session
  /// on this phone) is not a failure to hide behind: the disclosure act stands
  /// locally, and nothing claims a server record.
  Future<bool> _recordConsentOnServer() async {
    final answer = await NativeChildTelemetryBridge.recordConsent(
      capability: 'location',
      textVersion: kChildLocationConsentTextVersion,
      idempotencyKey: 'chd003-consent-${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!answer.available) return true;
    return answer.statusCode == 201 ||
        answer.statusCode == 200 ||
        answer.statusCode == 409;
  }

  Future<void> _accept(BuildContext context) async {
    final notifier = CurrentRole.maybeNotifierOf(context);
    if (notifier != null && notifier.value != AppRole.child) {
      notifier.value = AppRole.child;
    }
    if (_role(context) == AppRole.child) {
      setState(() {
        _recording = true;
        _failed = false;
      });
      final recorded = await (widget.recordConsent ?? _recordConsentOnServer)();
      if (!mounted) return;
      if (!recorded) {
        // Honest refusal: the consent is not recorded, so the journey does not
        // pretend it is. The button is the retry.
        setState(() {
          _recording = false;
          _failed = true;
        });
        return;
      }
      if (widget.runNativeFlow) {
        // The disclosure has been made and agreed to — only now may the system
        // permission dialogs appear (Play: disclosure BEFORE the asks), and
        // only now may the always-on service start from the stored pairing.
        await NativeChildTelemetryBridge.requestLocationPermissions();
        if (!mounted) return;
        await NativeChildTelemetryBridge.startConfigured();
        if (!mounted) return;
      }
      setState(() => _recording = false);
    }
    if (widget.onAccept != null) {
      widget.onAccept!();
      return;
    }
    if (!mounted) return;
    context.go('/scr-chd-004');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final role = _role(context);

    return FamilyUiModeScope(
      mode: FamilyUiMode.child,
      child: Scaffold(
        key: TransparencyConsentKeys.screen,
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.transparencyConsentTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              Text(
                l10n.transparencyConsentSubtitle,
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
          child: role == AppRole.child
              ? _ConsentBody(
                  l10n: l10n,
                  colors: colors,
                  recording: _recording,
                  failed: _failed,
                  onAccept: () => _accept(context),
                )
              : AppEmptyState(
                  key: TransparencyConsentKeys.parentLean,
                  title: l10n.transparencyConsentParentLeanTitle,
                  message: l10n.transparencyConsentParentLeanMessage,
                ),
        ),
      ),
    );
  }
}

class _ConsentBody extends StatelessWidget {
  const _ConsentBody({
    required this.l10n,
    required this.colors,
    required this.recording,
    required this.failed,
    required this.onAccept,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final bool recording;
  final bool failed;
  final Future<void> Function() onAccept;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BannerNote(
                  key: TransparencyConsentKeys.honestyBanner,
                  variant: BannerVariant.t,
                  leading: Text(
                    '🤝',
                    style: TextStyle(fontSize: 18, color: colors.ink),
                  ),
                  message: l10n.transparencyConsentHonestyBanner,
                ),
                if (recording) ...[
                  const SizedBox(height: 12),
                  BannerNote(
                    key: TransparencyConsentKeys.recordingBanner,
                    variant: BannerVariant.t,
                    message: l10n.transparencyConsentRecording,
                  ),
                ],
                if (failed) ...[
                  const SizedBox(height: 12),
                  BannerNote(
                    key: TransparencyConsentKeys.errorBanner,
                    variant: BannerVariant.warn,
                    message: l10n.transparencyConsentError,
                  ),
                ],
                const SizedBox(height: 12),
                AppCard(
                  key: TransparencyConsentKeys.sharedCard,
                  title: l10n.transparencyConsentSharedTitle,
                  child: Column(
                    children: [
                      RowTile(
                        leading: Text(
                          '📍',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentSharedLocationTitle,
                        subtitle: l10n.transparencyConsentSharedLocationBody,
                        showDivider: true,
                      ),
                      RowTile(
                        leading: Text(
                          '⏱',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentSharedScreenTimeTitle,
                        subtitle: l10n.transparencyConsentSharedScreenTimeBody,
                        showDivider: true,
                      ),
                      RowTile(
                        leading: Text(
                          '🔋',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentSharedBatteryTitle,
                        subtitle: l10n.transparencyConsentSharedBatteryBody,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  key: TransparencyConsentKeys.neverCard,
                  title: l10n.transparencyConsentNeverTitle,
                  child: Column(
                    children: [
                      RowTile(
                        leading: Text(
                          '💬',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentNeverMessagesTitle,
                        subtitle: l10n.transparencyConsentNeverMessagesBody,
                        showDivider: true,
                      ),
                      RowTile(
                        leading: Text(
                          '📷',
                          style: TextStyle(fontSize: 20, color: colors.ink),
                        ),
                        title: l10n.transparencyConsentNeverPhotosTitle,
                        subtitle: l10n.transparencyConsentNeverPhotosBody,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  key: TransparencyConsentKeys.advisorCard,
                  title: l10n.transparencyConsentAdvisorTitle,
                  child: Text(
                    l10n.transparencyConsentAdvisorBody,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.65,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: PrimaryBtn(
            key: TransparencyConsentKeys.acceptCta,
            label: l10n.transparencyConsentAccept,
            variant: PrimaryBtnVariant.teal,
            semanticsLabel: l10n.transparencyConsentAcceptSemantics,
            onPressed: recording ? null : () => onAccept(),
          ),
        ),
      ],
    );
  }
}
