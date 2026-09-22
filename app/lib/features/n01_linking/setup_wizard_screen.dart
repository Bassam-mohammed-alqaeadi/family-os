import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/progress_bar.dart';
import 'package:family_os/core/design/components/row_tile.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/onboarding_progress_flags.dart';
import 'package:family_os/features/n01_linking/onboarding_progress_repository.dart';

/// SCR-FAT-002 — معالج الإعداد (bare parent onboarding, mock-first).
///
/// Checklist of **suggestions** (never forced gates). Skip always allowed.
/// Progress comes from cached onboarding flags (offline-safe). No Firebase.
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({
    super.key,
    this.onAddChild,
    this.onInviteMother,
    this.onSetupSos,
    this.onSkipLater,
    this.repository,
  });

  /// Test seams — when null, navigate to the linked screen paths.
  final VoidCallback? onAddChild;
  final VoidCallback? onInviteMother;
  final VoidCallback? onSetupSos;
  final VoidCallback? onSkipLater;

  /// Rule 25 seam — null → prefs-backed Stage-1 store (cached offline).
  final OnboardingProgressRepository? repository;

  @override
  State<SetupWizardScreen> createState() => SetupWizardScreenState();
}

class SetupWizardScreenState extends State<SetupWizardScreen> {
  late final OnboardingProgressRepository _repository;
  OnboardingProgressFlags _flags = OnboardingProgressFlags.afterFamilyCreate();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        PrefsOnboardingProgressRepository(stage1OnboardingProgressStore);
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repository.load();
    if (!mounted) return;
    setState(() => _flags = loaded);
  }

  /// Exposed for tests — never used to gate Skip.
  OnboardingProgressFlags get flags => _flags;

  void _goAddChild(BuildContext context) {
    if (widget.onAddChild != null) {
      widget.onAddChild!();
      return;
    }
    context.go('/scr-fat-003');
  }

  void _goInviteMother(BuildContext context) {
    if (widget.onInviteMother != null) {
      widget.onInviteMother!();
      return;
    }
    context.go('/scr-fat-008');
  }

  void _goSetupSos(BuildContext context) {
    if (widget.onSetupSos != null) {
      widget.onSetupSos!();
      return;
    }
    context.go('/scr-fat-028');
  }

  /// Skip is **never** gated on checklist completeness (UI-002 AC1 / AC3).
  void _goSkipLater(BuildContext context) {
    if (widget.onSkipLater != null) {
      widget.onSkipLater!();
      return;
    }
    context.go('/scr-fat-010');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final percent = _flags.progressPercent;
    final progress = _flags.progressFraction;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.setupWizardTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.setupWizardSubtitle,
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
            AppCard(
              key: const Key('setup_wizard_progress_card'),
              child: Column(
                children: [
                  Semantics(
                    label: l10n.setupWizardProgressSemantics(percent),
                    child: Text(
                      key: const Key('setup_wizard_progress_percent'),
                      l10n.setupWizardProgressHero(percent),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: colors.p600,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    key: const Key('setup_wizard_progress_caption'),
                    l10n.setupWizardProgressCaption,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ProgressBar(
                    key: const Key('setup_wizard_progress_bar'),
                    // Cached / default flags — offline shows last known %.
                    value: progress,
                    variant: ProgressBarVariant.pu,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              key: const Key('setup_wizard_checklist'),
              child: Column(
                children: [
                  RowTile(
                    key: const Key('setup_wizard_done_account'),
                    leading: Text(
                      _flags.accountCreated ? '✅' : '○',
                      style: const TextStyle(fontSize: 18),
                    ),
                    title: l10n.setupWizardStepAccountTitle,
                    subtitle: _flags.accountCreated
                        ? l10n.setupWizardStepAccountSubtitle
                        : l10n.setupWizardStepSuggestedPending,
                    // Done — not tappable (no onTap).
                  ),
                  RowTile(
                    key: const Key('setup_wizard_add_child'),
                    leading: const Text('👦', style: TextStyle(fontSize: 18)),
                    title: l10n.setupWizardStepAddChildTitle,
                    subtitle: l10n.setupWizardStepAddChildSubtitle,
                    trailing: Tag(
                      label: l10n.setupWizardStepAddChildTag,
                      variant: TagVariant.a,
                    ),
                    onTap: () => _goAddChild(context),
                  ),
                  RowTile(
                    key: const Key('setup_wizard_invite_mother'),
                    leading: const Text('🤍', style: TextStyle(fontSize: 18)),
                    title: l10n.setupWizardStepInviteTitle,
                    subtitle: l10n.setupWizardStepInviteSubtitle,
                    trailing: Icon(
                      Icons.chevron_left,
                      color: colors.ink2,
                      size: 22,
                    ),
                    onTap: () => _goInviteMother(context),
                  ),
                  RowTile(
                    key: const Key('setup_wizard_sos'),
                    leading: const Text('🚨', style: TextStyle(fontSize: 18)),
                    title: l10n.setupWizardStepSosTitle,
                    subtitle: l10n.setupWizardStepSosSubtitle,
                    trailing: Icon(
                      Icons.chevron_left,
                      color: colors.ink2,
                      size: 22,
                    ),
                    showDivider: false,
                    onTap: () => _goSetupSos(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryBtn(
              key: const Key('setup_wizard_skip'),
              label: l10n.setupWizardSkipLater,
              variant: PrimaryBtnVariant.ghost,
              // Always enabled — incomplete checklist never blocks (UI-002).
              onPressed: () => _goSkipLater(context),
            ),
          ],
        ),
      ),
    );
  }
}
