import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/progress_bar.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_lesson_models.dart';
import 'package:family_os/features/n17_child_learn/child_lesson_repository.dart';

/// Widget keys for SCR-CHD-013 acceptance.
abstract final class ChildLessonKeys {
  static const screen = Key('child_lesson_screen');
  static const loading = Key('child_lesson_loading');
  static const empty = Key('child_lesson_empty');
  static const body = Key('child_lesson_body');
  static const progress = Key('child_lesson_progress');
  static const pizza = Key('child_lesson_pizza');
  static const nextCta = Key('child_lesson_next');
  static const tutorCta = Key('child_lesson_tutor');
  static const parentLean = Key('child_lesson_parent_lean');
  static const sosIconCta = Key('child_lesson_sos_icon');
}

/// SCR-CHD-013 — الدرس (child interactive lesson).
///
/// Prototype CHD-013 · S-EDU-004/005 · RoleGuard child · minutes-only toast ·
/// next→014 · tutor→017 · P-4 SOS · Rule 12/23.
class ChildLessonScreen extends StatefulWidget {
  const ChildLessonScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildLessonRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildLessonScreen> createState() => _ChildLessonScreenState();
}

class _ChildLessonScreenState extends State<ChildLessonScreen> {
  late ChildLessonRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildLessonSnapshot _snap = const ChildLessonSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildLessonRepository;
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

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  String _title(AppLocalizations l10n) {
    return switch (_snap.titleKey) {
      'addingFractions' => l10n.childLessonTitleAddingFractions,
      _ => l10n.childLessonTitleAddingFractions,
    };
  }

  String _hook(AppLocalizations l10n) {
    return switch (_snap.hookKey) {
      'imaginePizza' => l10n.childLessonHookImaginePizza,
      _ => l10n.childLessonHookImaginePizza,
    };
  }

  String _body(AppLocalizations l10n) {
    return switch (_snap.bodyKey) {
      'pizzaFractionsBody' => l10n.childLessonBodyPizzaFractions,
      _ => l10n.childLessonBodyPizzaFractions,
    };
  }

  void _onNext() {
    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      message: l10n.childLessonRewardToast(_snap.rewardMinutes),
    );
    _go(_snap.nextScreenId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildLessonKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          _loading || _snap.isEmpty ? l10n.childLessonAppBar : _title(l10n),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildLessonKeys.sosIconCta,
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
        key: ChildLessonKeys.parentLean,
        title: l10n.childLessonParentLeanTitle,
        message: l10n.childLessonParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildLessonKeys.loading,
        child: Semantics(
          label: l10n.childLessonLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildLessonKeys.empty,
        title: l10n.childLessonEmptyTitle,
        message: l10n.childLessonEmptyMessage,
        actionLabel: l10n.childLessonEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildLessonKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProgressBar(
                    key: ChildLessonKeys.progress,
                    value: _snap.progressPercent / 100.0,
                    variant: ProgressBarVariant.pu,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _hook(l10n),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _body(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                      height: 1.85,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    key: ChildLessonKeys.pizza,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _snap.pizzaFilled.length; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _snap.pizzaFilled[i]
                                ? colors.teal
                                : colors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryBtn(
            key: ChildLessonKeys.nextCta,
            label: l10n.childLessonNextCta,
            variant: PrimaryBtnVariant.teal,
            onPressed: _onNext,
          ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: ChildLessonKeys.tutorCta,
            label: l10n.childLessonTutorCta,
            variant: PrimaryBtnVariant.ghost,
            onPressed: () => _go(_snap.tutorScreenId),
          ),
        ],
      ),
    );
  }
}
