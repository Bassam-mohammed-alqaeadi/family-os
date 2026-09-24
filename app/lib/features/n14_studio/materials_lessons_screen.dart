import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/materials_lessons_models.dart';
import 'package:family_os/features/n14_studio/materials_lessons_repository.dart';

/// Widget keys for SCR-FAT-048 acceptance.
abstract final class MaterialsLessonsKeys {
  static const screen = Key('materials_lessons_screen');
  static const loading = Key('materials_lessons_loading');
  static const empty = Key('materials_lessons_empty');
  static const body = Key('materials_lessons_body');
  static const list = Key('materials_lessons_list');
  static const addSubjectCta = Key('materials_lessons_add_subject');
  static const addLessonCta = Key('materials_lessons_add_lesson');
  static const assignmentCta = Key('materials_lessons_assignment');
  static const observerHint = Key('materials_lessons_observer');
  static const childLean = Key('materials_lessons_child_lean');
  static const sosCta = Key('materials_lessons_sos');
  static const sosIconCta = Key('materials_lessons_sos_icon');

  static Key subjectRow(String id) => Key('materials_lessons_subj_$id');
}

/// SCR-FAT-048 — المواد والدروس (materials and lessons).
///
/// Prototype FAT-048 · education wave · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · CTA → FAT-049 create assignment.
class MaterialsLessonsScreen extends StatefulWidget {
  const MaterialsLessonsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1MaterialsLessonsRepository].
  final MaterialsLessonsRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may add / assign.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<MaterialsLessonsScreen> createState() => _MaterialsLessonsScreenState();
}

class _MaterialsLessonsScreenState extends State<MaterialsLessonsScreen> {
  late MaterialsLessonsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  MaterialsLessonsSnapshot _snap = const MaterialsLessonsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may add subjects/lessons and assign.
  bool get _canAct {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1MaterialsLessonsRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant MaterialsLessonsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1MaterialsLessonsRepository;
      _load();
    }
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
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _blockedToast(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.materialsLessonsObserverBlocked);
  }

  String _titleFor(AppLocalizations l10n, String titleKey) {
    return switch (titleKey) {
      'math' => l10n.materialsLessonsSubjectMath,
      'quran' => l10n.materialsLessonsSubjectQuran,
      'english' => l10n.materialsLessonsSubjectEnglish,
      'science' => l10n.materialsLessonsSubjectScience,
      'custom' => l10n.materialsLessonsSubjectCustom,
      _ => l10n.materialsLessonsSubjectMath,
    };
  }

  String _subtitleFor(AppLocalizations l10n, MaterialsSubject subject) {
    return switch (subject.subtitleKey) {
      'mathActive' => l10n.materialsLessonsMetaMathActive(
        subject.lessons,
        subject.quizzes,
      ),
      'quranWeekly' => l10n.materialsLessonsMetaQuranWeekly,
      'englishCards' => l10n.materialsLessonsMetaEnglishCards(
        subject.flashcards,
      ),
      'scienceImported' => l10n.materialsLessonsMetaScienceImported,
      'justAdded' => l10n.materialsLessonsMetaJustAdded,
      'lessonCount' => l10n.materialsLessonsMetaLessonCount(subject.lessons),
      _ => l10n.materialsLessonsMetaScienceImported,
    };
  }

  String _emojiFor(MaterialsSubjectKind kind) {
    return switch (kind) {
      MaterialsSubjectKind.math => '➗',
      MaterialsSubjectKind.quran => '📖',
      MaterialsSubjectKind.english => '🇬🇧',
      MaterialsSubjectKind.science => '🔬',
      MaterialsSubjectKind.custom => '📚',
    };
  }

  void _onSubjectTap(MaterialsSubject subject) {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (subject.hasActivePath) {
      _go('SCR-FAT-047');
      return;
    }
    AppToast.show(context, message: l10n.materialsLessonsSubjectToast);
  }

  Future<void> _onAddSubject() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    await _repo.addSubject();
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    AppToast.show(
      context,
      message: l10n.materialsLessonsAddSubjectPersistedToast,
    );
  }

  Future<void> _onAddLesson() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    await _repo.addLesson();
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    AppToast.show(
      context,
      message: l10n.materialsLessonsAddLessonPersistedToast,
    );
    // Source attach remains the content path (FAT-041).
    _go('SCR-FAT-041');
  }

  void _onCreateAssignment() {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    _go('SCR-FAT-049');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: MaterialsLessonsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.materialsLessonsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: MaterialsLessonsKeys.sosIconCta,
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
      body: SafeArea(child: _buildBody(context, l10n, colors)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (_isChild) {
      return AppEmptyState(
        key: MaterialsLessonsKeys.childLean,
        title: l10n.materialsLessonsChildLeanTitle,
        message: l10n.materialsLessonsChildLeanMessage,
        actionLabel: l10n.materialsLessonsSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: MaterialsLessonsKeys.childLean,
        title: l10n.materialsLessonsChildLeanTitle,
        message: l10n.materialsLessonsChildLeanMessage,
        actionLabel: l10n.materialsLessonsSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: MaterialsLessonsKeys.loading,
        child: Semantics(
          label: l10n.materialsLessonsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: MaterialsLessonsKeys.empty,
        title: l10n.materialsLessonsEmptyTitle,
        message: l10n.materialsLessonsEmptyMessage,
        actionLabel: l10n.materialsLessonsEmptyCta,
        onAction: () => _go('SCR-FAT-041'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: MaterialsLessonsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: MaterialsLessonsKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.materialsLessonsObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          DecoratedBox(
            key: MaterialsLessonsKeys.list,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final subject in _snap.subjects)
                    _SubjectRow(
                      rowKey: MaterialsLessonsKeys.subjectRow(subject.id),
                      emoji: _emojiFor(subject.kind),
                      title: _titleFor(l10n, subject.titleKey),
                      subtitle: _subtitleFor(l10n, subject),
                      colors: colors,
                      onTap: () => _onSubjectTap(subject),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryBtn(
                  key: MaterialsLessonsKeys.addSubjectCta,
                  label: l10n.materialsLessonsAddSubjectCta,
                  variant: PrimaryBtnVariant.sec,
                  onPressed: _onAddSubject,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryBtn(
                  key: MaterialsLessonsKeys.addLessonCta,
                  label: l10n.materialsLessonsAddLessonCta,
                  onPressed: _onAddLesson,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: MaterialsLessonsKeys.assignmentCta,
            label: l10n.materialsLessonsAssignmentCta,
            onPressed: _onCreateAssignment,
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.rowKey,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final Key rowKey;
  final String emoji;
  final String title;
  final String subtitle;
  final FamilyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
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
              Icon(Icons.chevron_left, color: colors.ink2, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
