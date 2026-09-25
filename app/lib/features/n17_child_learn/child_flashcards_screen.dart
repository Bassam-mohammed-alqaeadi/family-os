import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_flashcards_models.dart';
import 'package:family_os/features/n17_child_learn/child_flashcards_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

/// Widget keys for SCR-CHD-014 acceptance.
abstract final class ChildFlashcardsKeys {
  static const screen = Key('child_flashcards_screen');
  static const loading = Key('child_flashcards_loading');
  static const empty = Key('child_flashcards_empty');
  static const body = Key('child_flashcards_body');
  static const flipCard = Key('child_flashcards_flip');
  static const prevCta = Key('child_flashcards_prev');
  static const nextCta = Key('child_flashcards_next');
  static const knownCta = Key('child_flashcards_known');
  static const reviewCta = Key('child_flashcards_review');
  static const quizCta = Key('child_flashcards_quiz');
  static const parentLean = Key('child_flashcards_parent_lean');
  static const sosIconCta = Key('child_flashcards_sos_icon');
}

/// SCR-CHD-014 — واجبي / بطاقاتي التفاعلية (child flashcards).
///
/// Prototype CHD-014 · S-EDU-008…011 · RoleGuard child · flip + know/review ·
/// quiz→015 · P-4 SOS · Rule 12/23 · minutes-only reward CTA.
class ChildFlashcardsScreen extends StatefulWidget {
  const ChildFlashcardsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildFlashcardsRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildFlashcardsScreen> createState() => _ChildFlashcardsScreenState();
}

class _ChildFlashcardsScreenState extends State<ChildFlashcardsScreen> {
  late ChildFlashcardsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  ChildFlashcardsSnapshot _snap = const ChildFlashcardsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.flashcards;
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

  Future<void> _mutate(
    Future<ChildFlashcardsSnapshot> Function() action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final snap = await action();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
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

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  String _lessonTitle(AppLocalizations l10n) {
    return switch (_snap.lessonTitleKey) {
      'fractionsOps' => l10n.childFlashcardsLessonFractionsOps,
      _ => l10n.childFlashcardsLessonFractionsOps,
    };
  }

  String _source(AppLocalizations l10n) {
    return switch (_snap.sourceNameKey) {
      'mathPdf' => l10n.childFlashcardsSourceMathPdf,
      _ => l10n.childFlashcardsSourceMathPdf,
    };
  }

  String _q(AppLocalizations l10n, String key) {
    return switch (key) {
      'qOrdinaryFraction' => l10n.childFlashcardsQOrdinaryFraction,
      'qAddNumerators' => l10n.childFlashcardsQAddNumerators,
      _ => l10n.childFlashcardsQOrdinaryFraction,
    };
  }

  String _a(AppLocalizations l10n, String key) {
    return switch (key) {
      'aOrdinaryFraction' => l10n.childFlashcardsAOrdinaryFraction,
      'aAddNumerators' => l10n.childFlashcardsAAddNumerators,
      _ => l10n.childFlashcardsAOrdinaryFraction,
    };
  }

  String _h(AppLocalizations l10n, String key) {
    return switch (key) {
      'hPizza' => l10n.childFlashcardsHPizza,
      'hSameDenom' => l10n.childFlashcardsHSameDenom,
      _ => l10n.childFlashcardsHPizza,
    };
  }

  Future<void> _onNext() async {
    final l10n = AppLocalizations.of(context);
    final atEnd = _snap.currentIndex >= _snap.cards.length - 1;
    await _mutate(_repo.next);
    if (atEnd && mounted) {
      AppToast.show(context, message: l10n.childFlashcardsEndToast);
    }
  }

  Future<void> _onPrev() async {
    final l10n = AppLocalizations.of(context);
    final atStart = _snap.currentIndex <= 0;
    await _mutate(_repo.previous);
    if (atStart && mounted) {
      AppToast.show(context, message: l10n.childFlashcardsFirstToast);
    }
  }

  Future<void> _onKnown() async {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childFlashcardsKnownToast);
    await _mutate(_repo.markKnown);
  }

  Future<void> _onReview() async {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childFlashcardsReviewToast);
    await _mutate(_repo.markReview);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildFlashcardsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childFlashcardsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildFlashcardsKeys.sosIconCta,
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
      body: SafeArea(child: _buildBody(l10n, colors)),
    );
  }

  Widget _buildBody(AppLocalizations l10n, FamilyColors colors) {
    if (!_isChild) {
      return AppEmptyState(
        key: ChildFlashcardsKeys.parentLean,
        title: l10n.childFlashcardsParentLeanTitle,
        message: l10n.childFlashcardsParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildFlashcardsKeys.loading,
        child: Semantics(
          label: l10n.childFlashcardsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildFlashcardsKeys.empty,
        title: l10n.childFlashcardsEmptyTitle,
        message: l10n.childFlashcardsEmptyMessage,
        actionLabel: l10n.childFlashcardsEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final card = _snap.currentCard!;
    final flipped = _snap.flipped;

    return SingleChildScrollView(
      key: ChildFlashcardsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lessonTitle(l10n),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    Text(
                      l10n.childFlashcardsSourceLine(_source(l10n)),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.teal600,
                      ),
                    ),
                  ],
                ),
              ),
              Tag(
                label: l10n.childFlashcardsCounter(
                  _snap.currentIndex + 1,
                  _snap.cards.length,
                ),
                variant: TagVariant.t,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ChildFlashcardsKeys.flipCard,
              onTap: _busy ? null : () => _mutate(_repo.flip),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 190),
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFDF9), Color(0xFFF7F4EB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: flipped ? colors.teal : colors.border,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tag(
                      label: flipped
                          ? l10n.childFlashcardsSideAnswer
                          : l10n.childFlashcardsSideQuestion,
                      variant: flipped ? TagVariant.g : TagVariant.p,
                    ),
                    const SizedBox(height: 12),
                    if (!flipped) ...[
                      Text(
                        _q(l10n, card.questionKey),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.childFlashcardsTapHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ] else ...[
                      Text(
                        _a(l10n, card.answerKey),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                          height: 1.75,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            _h(l10n, card.hintKey),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.tealDeep,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryBtn(
                              key: ChildFlashcardsKeys.knownCta,
                              label: l10n.childFlashcardsKnownCta,
                              variant: PrimaryBtnVariant.mint,
                              onPressed: _busy ? null : _onKnown,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PrimaryBtn(
                              key: ChildFlashcardsKeys.reviewCta,
                              label: l10n.childFlashcardsReviewCta,
                              variant: PrimaryBtnVariant.sec,
                              onPressed: _busy ? null : _onReview,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryBtn(
                  key: ChildFlashcardsKeys.prevCta,
                  label: l10n.childFlashcardsPrevCta,
                  variant: PrimaryBtnVariant.sec,
                  onPressed: _busy ? null : _onPrev,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryBtn(
                  key: ChildFlashcardsKeys.nextCta,
                  label: l10n.childFlashcardsNextCta,
                  variant: PrimaryBtnVariant.teal,
                  onPressed: _busy ? null : _onNext,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: ChildFlashcardsKeys.quizCta,
            label: l10n.childFlashcardsQuizCta(_snap.quizRewardMinutes),
            variant: PrimaryBtnVariant.mint,
            onPressed: () => _go(_snap.quizScreenId),
          ),
        ],
      ),
    );
  }
}
