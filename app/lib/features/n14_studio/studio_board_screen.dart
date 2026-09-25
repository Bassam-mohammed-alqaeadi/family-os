import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/studio_board_models.dart';
import 'package:family_os/features/n14_studio/studio_board_repository.dart';
import 'package:family_os/features/n14_studio/studio_ux_bridge.dart';

/// Widget keys for SCR-FAT-040 acceptance.
abstract final class StudioBoardKeys {
  static const screen = Key('studio_board_screen');
  static const loading = Key('studio_board_loading');
  static const empty = Key('studio_board_empty');
  static const body = Key('studio_board_body');
  static const createCta = Key('studio_board_create');
  static const suggestionsSection = Key('studio_board_suggestions');
  static const recentSection = Key('studio_board_recent');
  static const recentAllCta = Key('studio_board_recent_all');
  static const quickCamera = Key('studio_board_quick_camera');
  static const quickLibrary = Key('studio_board_quick_library');
  static const quickResults = Key('studio_board_quick_results');
  static const observerHint = Key('studio_board_observer');
  static const childLean = Key('studio_board_child_lean');
  static const sosCta = Key('studio_board_sos');
  static const sosIconCta = Key('studio_board_sos_icon');

  static Key suggestionRow(String id) => Key('studio_board_sug_$id');
  static Key contentRow(String id) => Key('studio_board_cnt_$id');
}

/// SCR-FAT-040 — لوحة الاستوديو (studio board / content studio hub).
///
/// Prototype FAT-040 · S-EDU-064 · Rule 12/23 · mother levels · mock-first ·
/// ARB · P-4 SOS · links to FAT-041+ as CTAs (placeholders OK for destinations
/// not yet built).
class StudioBoardScreen extends StatefulWidget {
  const StudioBoardScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1StudioBoardRepository].
  final StudioBoardRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full create like father.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<StudioBoardScreen> createState() => _StudioBoardScreenState();
}

class _StudioBoardScreenState extends State<StudioBoardScreen> {
  late StudioBoardRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  StudioBoardSnapshot _snap = const StudioBoardSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full (prototype §7 — mother can create).
  bool get _canCreate {
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
    _repo = widget.repository ?? Stage1StudioRuntime.board;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant StudioBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? Stage1StudioRuntime.board;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: StudioBoardKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.studioBoardTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: StudioBoardKeys.sosIconCta,
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
        key: StudioBoardKeys.childLean,
        title: l10n.studioBoardChildLeanTitle,
        message: l10n.studioBoardChildLeanMessage,
        actionLabel: l10n.studioBoardSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: StudioBoardKeys.childLean,
        title: l10n.studioBoardChildLeanTitle,
        message: l10n.studioBoardChildLeanMessage,
      );
    }

    if (_loading) {
      return Center(
        key: StudioBoardKeys.loading,
        child: Semantics(
          label: l10n.studioBoardLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return _buildEmpty(context, l10n, colors);
    }

    return _buildHub(context, l10n, colors);
  }

  Widget _buildEmpty(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    return SingleChildScrollView(
      key: StudioBoardKeys.empty,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: StudioBoardKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.studioBoardObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          if (_canCreate) ...[
            _CreateHero(
              key: StudioBoardKeys.createCta,
              title: l10n.studioBoardCreateTitle,
              subtitle: l10n.studioBoardCreateSubtitle,
              onTap: () => _go('SCR-FAT-041'),
            ),
            const SizedBox(height: 12),
          ],
          AppEmptyState(
            title: l10n.studioBoardEmptyTitle,
            message: l10n.studioBoardEmptyMessage,
          ),
          const SizedBox(height: 16),
          _QuickActions(
            canCreate: _canCreate,
            l10n: l10n,
            onCamera: () => _go('SCR-FAT-042'),
            onLibrary: () => _go('SCR-FAT-046'),
            onResults: () => _go('SCR-FAT-050'),
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: StudioBoardKeys.sosCta,
            label: l10n.studioBoardSosCta,
            onPressed: _sosBusy ? null : _openSos,
          ),
        ],
      ),
    );
  }

  Widget _buildHub(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    return SingleChildScrollView(
      key: StudioBoardKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: StudioBoardKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.studioBoardObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          if (_canCreate) ...[
            _CreateHero(
              key: StudioBoardKeys.createCta,
              title: l10n.studioBoardCreateTitle,
              subtitle: l10n.studioBoardCreateSubtitle,
              onTap: () => _go('SCR-FAT-041'),
            ),
            const SizedBox(height: 12),
          ],
          if (_snap.suggestions.isNotEmpty) ...[
            _SuggestionsCard(
              sectionKey: StudioBoardKeys.suggestionsSection,
              suggestions: _snap.suggestions,
              canAct: _canCreate,
              l10n: l10n,
              colors: colors,
              onTap: (s) => _go(s.targetScreenId),
            ),
            const SizedBox(height: 12),
          ],
          _RecentCard(
            sectionKey: StudioBoardKeys.recentSection,
            items: _snap.recent,
            l10n: l10n,
            colors: colors,
            onOpenAll: () => _go('SCR-FAT-048'),
            onTapItem: (_) => _go('SCR-FAT-048'),
          ),
          const SizedBox(height: 16),
          _QuickActions(
            canCreate: _canCreate,
            l10n: l10n,
            onCamera: () => _go('SCR-FAT-042'),
            onLibrary: () => _go('SCR-FAT-046'),
            onResults: () => _go('SCR-FAT-050'),
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: StudioBoardKeys.sosCta,
            label: l10n.studioBoardSosCta,
            onPressed: _sosBusy ? null : _openSos,
          ),
        ],
      ),
    );
  }
}

class _CreateHero extends StatelessWidget {
  const _CreateHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.card),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradients.grad,
            borderRadius: BorderRadius.circular(radii.card),
            boxShadow: [
              BoxShadow(
                color: colors.p500.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  const _SuggestionsCard({
    required this.sectionKey,
    required this.suggestions,
    required this.canAct,
    required this.l10n,
    required this.colors,
    required this.onTap,
  });

  final Key sectionKey;
  final List<StudioSuggestion> suggestions;
  final bool canAct;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final void Function(StudioSuggestion suggestion) onTap;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: sectionKey,
      decoration: BoxDecoration(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.studioBoardSuggestionsHeading,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final s in suggestions)
              _SuggestionRow(
                rowKey: StudioBoardKeys.suggestionRow(s.id),
                icon: _suggestionIcon(s.kind),
                title: _suggestionTitle(l10n, s.kind),
                subtitle: _suggestionSubtitle(l10n, s.kind),
                enabled: canAct,
                onTap: () => onTap(s),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _suggestionIcon(StudioSuggestionKind kind) {
    return switch (kind) {
      StudioSuggestionKind.fractions => Icons.calculate_outlined,
      StudioSuggestionKind.quranWird => Icons.menu_book_outlined,
    };
  }

  static String _suggestionTitle(AppLocalizations l10n, StudioSuggestionKind k) {
    return switch (k) {
      StudioSuggestionKind.fractions => l10n.studioBoardSugFractionsTitle,
      StudioSuggestionKind.quranWird => l10n.studioBoardSugWirdTitle,
    };
  }

  static String _suggestionSubtitle(
    AppLocalizations l10n,
    StudioSuggestionKind k,
  ) {
    return switch (k) {
      StudioSuggestionKind.fractions => l10n.studioBoardSugFractionsSub,
      StudioSuggestionKind.quranWird => l10n.studioBoardSugWirdSub,
    };
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: colors.p500, size: 28),
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
              if (enabled)
                Icon(Icons.chevron_left, color: colors.ink2, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.sectionKey,
    required this.items,
    required this.l10n,
    required this.colors,
    required this.onOpenAll,
    required this.onTapItem,
  });

  final Key sectionKey;
  final List<StudioContentItem> items;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final VoidCallback onOpenAll;
  final void Function(StudioContentItem item) onTapItem;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: sectionKey,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.studioBoardRecentHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                TextButton(
                  key: StudioBoardKeys.recentAllCta,
                  onPressed: onOpenAll,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: Text(l10n.studioBoardRecentAll),
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Text(
                  l10n.studioBoardEmptyMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.ink2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              for (final item in items)
                _ContentRow(
                  rowKey: StudioBoardKeys.contentRow(item.id),
                  icon: _contentIcon(item.kind),
                  title: _contentTitle(l10n, item.kind),
                  subtitle: _contentSubtitle(l10n, item.kind),
                  tagLabel: _statusLabel(l10n, item.status),
                  tagVariant: _statusVariant(item.status),
                  onTap: () => onTapItem(item),
                ),
          ],
        ),
      ),
    );
  }

  static IconData _contentIcon(StudioContentKind kind) {
    return switch (kind) {
      StudioContentKind.quiz => Icons.quiz_outlined,
      StudioContentKind.flashcards => Icons.style_outlined,
      StudioContentKind.quranWird => Icons.menu_book_outlined,
    };
  }

  static String _contentTitle(AppLocalizations l10n, StudioContentKind k) {
    return switch (k) {
      StudioContentKind.quiz => l10n.studioBoardContentQuizTitle,
      StudioContentKind.flashcards => l10n.studioBoardContentCardsTitle,
      StudioContentKind.quranWird => l10n.studioBoardContentWirdTitle,
    };
  }

  static String _contentSubtitle(AppLocalizations l10n, StudioContentKind k) {
    return switch (k) {
      StudioContentKind.quiz => l10n.studioBoardContentQuizSub,
      StudioContentKind.flashcards => l10n.studioBoardContentCardsSub,
      StudioContentKind.quranWird => l10n.studioBoardContentWirdSub,
    };
  }

  static String _statusLabel(AppLocalizations l10n, StudioContentStatus s) {
    return switch (s) {
      StudioContentStatus.active => l10n.studioBoardStatusActive,
      StudioContentStatus.progress => l10n.studioBoardStatusProgress,
      StudioContentStatus.excellent => l10n.studioBoardStatusExcellent,
    };
  }

  static TagVariant _statusVariant(StudioContentStatus s) {
    return switch (s) {
      StudioContentStatus.active => TagVariant.a,
      StudioContentStatus.progress => TagVariant.g,
      StudioContentStatus.excellent => TagVariant.g,
    };
  }
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tagLabel,
    required this.tagVariant,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String tagLabel;
  final TagVariant tagVariant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: colors.p500, size: 26),
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
              Tag(label: tagLabel, variant: tagVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.canCreate,
    required this.l10n,
    required this.onCamera,
    required this.onLibrary,
    required this.onResults,
  });

  final bool canCreate;
  final AppLocalizations l10n;
  final VoidCallback onCamera;
  final VoidCallback onLibrary;
  final VoidCallback onResults;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    final actions = <({Key key, IconData icon, String label, VoidCallback onTap})>[
      if (canCreate)
        (
          key: StudioBoardKeys.quickCamera,
          icon: Icons.photo_camera_outlined,
          label: l10n.studioBoardQuickCamera,
          onTap: onCamera,
        ),
      (
        key: StudioBoardKeys.quickLibrary,
        icon: Icons.public_outlined,
        label: l10n.studioBoardQuickLibrary,
        onTap: onLibrary,
      ),
      (
        key: StudioBoardKeys.quickResults,
        icon: Icons.bar_chart_outlined,
        label: l10n.studioBoardQuickResults,
        onTap: onResults,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in actions)
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radii.card),
            child: InkWell(
              key: a.key,
              onTap: a.onTap,
              borderRadius: BorderRadius.circular(radii.card),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radii.card),
                  border: Border.all(color: colors.border),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 96, minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.icon, size: 20, color: colors.p500),
                        const SizedBox(width: 6),
                        Text(
                          a.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
