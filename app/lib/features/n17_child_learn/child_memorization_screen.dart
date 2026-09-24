import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_memorization_models.dart';
import 'package:family_os/features/n17_child_learn/child_memorization_repository.dart';

abstract final class ChildMemorizationKeys {
  static const screen = Key('child_memorization_screen');
  static const loading = Key('child_memorization_loading');
  static const empty = Key('child_memorization_empty');
  static const body = Key('child_memorization_body');
  static const hero = Key('child_memorization_hero');
  static const reviews = Key('child_memorization_reviews');
  static const parentLean = Key('child_memorization_parent_lean');
  static const sosIconCta = Key('child_memorization_sos_icon');

  static Key review(String id) => Key('child_memorization_rev_$id');
  static Key reviewCta(String id) => Key('child_memorization_rev_cta_$id');
}

/// SCR-CHD-026 — حفظي وتقدمي.
class ChildMemorizationScreen extends StatefulWidget {
  const ChildMemorizationScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildMemorizationRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildMemorizationScreen> createState() =>
      _ChildMemorizationScreenState();
}

class _ChildMemorizationScreenState extends State<ChildMemorizationScreen> {
  late ChildMemorizationRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildMemorizationSnapshot _snap = const ChildMemorizationSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildMemorizationRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'self');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-CHD-005'));
  }

  void _go(String id) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(id);
      return;
    }
    context.push(screenPath(id));
  }

  String _surah(AppLocalizations l10n, String key) => switch (key) {
    'fatiha' => l10n.childMemSurahFatiha,
    'ikhlas' => l10n.childMemSurahIkhlas,
    'naba' => l10n.childMemSurahNaba,
    'mulk' => l10n.childMemSurahMulk,
    _ => key,
  };

  String _badge(AppLocalizations l10n, String key) => switch (key) {
    'firstSurah' => l10n.childMemBadgeFirst,
    'threeSurahs' => l10n.childMemBadgeThree,
    'halfAmma' => l10n.childMemBadgeHalfAmma,
    'littleHafiz' => l10n.childMemBadgeHafiz,
    _ => key,
  };

  String _reviewTitle(AppLocalizations l10n, String key) => switch (key) {
    'tabarak' => l10n.childMemReviewTabarak,
    'nabaFull' => l10n.childMemReviewNaba,
    _ => key,
  };

  String _reviewMeta(AppLocalizations l10n, String key) => switch (key) {
    'fourDaysAgo' => l10n.childMemReviewFourDays,
    'tomorrow' => l10n.childMemReviewTomorrow,
    _ => key,
  };

  Future<void> _review(String id) async {
    await _repo.startReview(id);
    if (!mounted) return;
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childMemReviewToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildMemorizationKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childMemTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildMemorizationKeys.sosIconCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _sosBusy ? null : _openSos,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.sos, color: colors.coral),
          ),
        ],
      ),
      body: SafeArea(child: _body(l10n, colors)),
    );
  }

  Widget _body(AppLocalizations l10n, FamilyColors colors) {
    if (!_isChild) {
      return AppEmptyState(
        key: ChildMemorizationKeys.parentLean,
        title: l10n.childMemParentLeanTitle,
        message: l10n.childMemParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildMemorizationKeys.loading,
        child: Semantics(
          label: l10n.childMemLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildMemorizationKeys.empty,
        title: l10n.childMemEmptyTitle,
        message: l10n.childMemEmptyMessage,
        actionLabel: l10n.childMemEmptyCta,
        onAction: () => _go('SCR-CHD-025'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildMemorizationKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ChildMemorizationKeys.hero,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                children: [
                  Text(
                    l10n.childMemHeroLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  Text(
                    l10n.childMemHeroValue(_snap.surahCount, _snap.extraAyahs),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colors.teal600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final s in _snap.surahs)
                        Tag(
                          label: s.progress >= 1
                              ? '${_surah(l10n, s.nameKey)} ✓'
                              : '${_surah(l10n, s.nameKey)} ${(s.progress * 100).round()}%',
                          variant: s.progress >= 1
                              ? TagVariant.g
                              : TagVariant.t,
                        ),
                    ],
                  ),
                  if (_snap.badges.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final b in _snap.badges)
                          Tag(
                            label: _badge(l10n, b.labelKey),
                            variant: b.earned ? TagVariant.g : TagVariant.t,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n.childMemBadgesHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_snap.reviews.isNotEmpty) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              key: ChildMemorizationKeys.reviews,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.childMemReviewsHeading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    for (final r in _snap.reviews)
                      Padding(
                        key: ChildMemorizationKeys.review(r.id),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Text('📖', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _reviewTitle(l10n, r.titleKey),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: colors.ink,
                                    ),
                                  ),
                                  Text(
                                    _reviewMeta(l10n, r.metaKey),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (r.dueToday)
                              SizedBox(
                                width: 96,
                                child: PrimaryBtn(
                                  key: ChildMemorizationKeys.reviewCta(r.id),
                                  label: l10n.childMemReviewCta,
                                  variant: PrimaryBtnVariant.teal,
                                  fullWidth: false,
                                  onPressed: () => _review(r.id),
                                ),
                              )
                            else
                              Text(
                                l10n.childMemReviewTomorrowShort,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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
          ],
          const SizedBox(height: 10),
          BannerNote(
            variant: BannerVariant.t,
            message: l10n.childMemHadithBanner,
          ),
        ],
      ),
    );
  }
}
