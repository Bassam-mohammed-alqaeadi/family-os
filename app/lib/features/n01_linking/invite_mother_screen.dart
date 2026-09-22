import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Mother permission level chosen by the father on invite (Wave-1).
enum MotherInviteLevel {
  /// مطّلعة — see and be notified.
  observer,

  /// مشاركة — approve requests + extra time (default / recommended).
  partner,

  /// كاملة — edit rules and limits with the father.
  full,
}

/// SCR-FAT-008 — دعوة الأم (bare parent onboarding, mock-first).
///
/// Parametric / Rule 23: email starts empty — no prefilled invitee or
/// person name. Toast uses typed email local-part only (no fixed name).
/// No real email send / Firebase on this card.
class InviteMotherScreen extends StatefulWidget {
  const InviteMotherScreen({super.key, this.onInviteSent});

  /// Test seam — when null, shows toast and navigates to `/scr-fat-027`.
  final VoidCallback? onInviteSent;

  @override
  State<InviteMotherScreen> createState() => _InviteMotherScreenState();
}

class _InviteMotherScreenState extends State<InviteMotherScreen> {
  final _emailController = TextEditingController();
  MotherInviteLevel _level = MotherInviteLevel.partner;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_onEmailChanged)
      ..dispose();
    super.dispose();
  }

  void _onEmailChanged() => setState(() {});

  bool get _canSubmit => _emailController.text.trim().isNotEmpty;

  String _levelName(AppLocalizations l10n, MotherInviteLevel level) {
    return switch (level) {
      MotherInviteLevel.observer => l10n.inviteMotherLevelObserverTitle,
      MotherInviteLevel.partner => l10n.inviteMotherLevelPartnerTitle,
      MotherInviteLevel.full => l10n.inviteMotherLevelFullTitle,
    };
  }

  String _levelDesc(AppLocalizations l10n, MotherInviteLevel level) {
    return switch (level) {
      MotherInviteLevel.observer => l10n.inviteMotherLevelObserverDesc,
      MotherInviteLevel.partner => l10n.inviteMotherLevelPartnerDesc,
      MotherInviteLevel.full => l10n.inviteMotherLevelFullDesc,
    };
  }

  String _emailLocalPart(String email) {
    final trimmed = email.trim();
    final at = trimmed.indexOf('@');
    if (at <= 0) return trimmed;
    return trimmed.substring(0, at);
  }

  void _submit() {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context);
    final localPart = _emailLocalPart(_emailController.text);
    final levelName = _levelName(l10n, _level);

    if (widget.onInviteSent != null) {
      widget.onInviteSent!();
      return;
    }

    AppToast.show(
      context,
      message: l10n.inviteMotherToast(localPart, levelName),
    );
    context.go('/scr-fat-027');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.inviteMotherTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          children: [
            Text(
              key: const Key('invite_mother_intro'),
              l10n.inviteMotherIntro,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: l10n.inviteMotherEmailLabel,
              child: Semantics(
                textField: true,
                label: l10n.inviteMotherEmailLabel,
                child: TextField(
                  key: const Key('invite_mother_email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    colors: colors,
                    radii: radii,
                    hint: l10n.inviteMotherEmailHint,
                  ),
                ),
              ),
            ),
            for (final level in MotherInviteLevel.values)
              _LevelRow(
                key: Key('invite_mother_level_${level.name}'),
                selected: _level == level,
                title: _levelName(l10n, level),
                description: _levelDesc(l10n, level),
                recommendedTag: level == MotherInviteLevel.partner
                    ? l10n.inviteMotherRecommendedTag
                    : null,
                onTap: () => setState(() => _level = level),
              ),
            const SizedBox(height: 4),
            BannerNote(
              key: const Key('invite_mother_banner'),
              variant: BannerVariant.p,
              leading: Text(
                l10n.inviteMotherBannerLeading,
                style: TextStyle(fontSize: 14, color: colors.p700),
              ),
              message: l10n.inviteMotherBanner,
            ),
            const SizedBox(height: 16),
            PrimaryBtn(
              key: const Key('invite_mother_submit'),
              label: l10n.inviteMotherSubmit,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required FamilyColors colors,
    required FamilyRadii radii,
    required String hint,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.input),
      borderSide: BorderSide(color: colors.border, width: 1.5),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.ink2.withValues(alpha: 0.55)),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.input),
        borderSide: BorderSide(color: colors.p400, width: 1.5),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    super.key,
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
    this.recommendedTag,
  });

  final bool selected;
  final String title;
  final String description;
  final String? recommendedTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final marker = selected ? '●' : '○';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: recommendedTag == null
            ? '$title. $description'
            : '$title. $recommendedTag. $description',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radii.card),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? colors.p50 : colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(
                  color: selected ? colors.p500 : colors.border,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        color: selected ? colors.p500 : colors.ink2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: colors.ink,
                                ),
                              ),
                              if (recommendedTag != null)
                                Tag(
                                  label: recommendedTag!,
                                  variant: TagVariant.g,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colors.ink2,
                              height: 1.6,
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
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
