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
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/community_library_models.dart';
import 'package:family_os/features/n14_studio/community_library_repository.dart';

/// Widget keys for SCR-FAT-046 acceptance.
abstract final class CommunityLibraryKeys {
  static const screen = Key('community_library_screen');
  static const loading = Key('community_library_loading');
  static const empty = Key('community_library_empty');
  static const body = Key('community_library_body');
  static const search = Key('community_library_search');
  static const topRated = Key('community_library_top_rated');
  static const publishCard = Key('community_library_publish');
  static const publishCta = Key('community_library_publish_cta');
  static const controlsNote = Key('community_library_controls');
  static const pathCta = Key('community_library_path_cta');
  static const importSheet = Key('community_library_import_sheet');
  static const importCta = Key('community_library_import_cta');
  static const observerHint = Key('community_library_observer');
  static const childLean = Key('community_library_child_lean');
  static const sosCta = Key('community_library_sos');
  static const sosIconCta = Key('community_library_sos_icon');

  static Key packageRow(String id) => Key('community_library_pkg_$id');
}

/// SCR-FAT-046 — مكتبة المجتمع (community library).
///
/// Prototype FAT-046 · studio wave · Rule 12/23 · mother levels · mock-first ·
/// ARB · P-4 SOS · six community controls · import CTA → FAT-047 learning path.
class CommunityLibraryScreen extends StatefulWidget {
  const CommunityLibraryScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1CommunityLibraryRepository].
  final CommunityLibraryRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full import;
  /// publish needs father approval for mother (prototype §7).
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<CommunityLibraryScreen> createState() => _CommunityLibraryScreenState();
}

class _CommunityLibraryScreenState extends State<CommunityLibraryScreen> {
  late CommunityLibraryRepository _repo;
  late final SosFireService _sos;
  final _searchCtrl = TextEditingController();
  var _sosBusy = false;
  var _loading = true;
  var _query = '';
  CommunityLibrarySnapshot _snap = const CommunityLibrarySnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may import.
  bool get _canImport {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  /// Father publishes directly; mother partner/full requests father approval.
  bool get _canPublish {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  bool get _publishNeedsFatherApproval =>
      _role == AppRole.mother && _canPublish;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1CommunityLibraryRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant CommunityLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1CommunityLibraryRepository;
      _load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    AppToast.show(context, message: l10n.communityLibraryObserverBlocked);
  }

  String _titleFor(AppLocalizations l10n, String titleKey) {
    return switch (titleKey) {
      'fractions' => l10n.communityLibraryPackFractions,
      'juzAmma' => l10n.communityLibraryPackJuzAmma,
      'englishCards' => l10n.communityLibraryPackEnglish,
      'fractionsQuiz' => l10n.communityLibraryPublishPackFractionsQuiz,
      _ => l10n.communityLibraryPackFractions,
    };
  }

  String _authorFor(AppLocalizations l10n, CommunityAuthorKey key) {
    return switch (key) {
      CommunityAuthorKey.fatherRiyadh =>
        l10n.communityLibraryAuthorFatherRiyadh,
      CommunityAuthorKey.motherJeddah =>
        l10n.communityLibraryAuthorMotherJeddah,
      CommunityAuthorKey.fatherDammam =>
        l10n.communityLibraryAuthorFatherDammam,
    };
  }

  IconData _iconFor(CommunityPackageKind kind) {
    return switch (kind) {
      CommunityPackageKind.fractions => Icons.calculate_outlined,
      CommunityPackageKind.quran => Icons.menu_book_outlined,
      CommunityPackageKind.english => Icons.translate_outlined,
    };
  }

  void _onImport(CommunityPackage pack) {
    final l10n = AppLocalizations.of(context);
    if (!_canImport) {
      _blockedToast(l10n);
      return;
    }
    AppToast.show(context, message: l10n.communityLibraryImportedToast);
    _go('SCR-FAT-047');
  }

  void _onPublish() {
    final l10n = AppLocalizations.of(context);
    if (!_canPublish) {
      _blockedToast(l10n);
      return;
    }
    final message = _publishNeedsFatherApproval
        ? l10n.communityLibraryPublishPendingFatherToast
        : l10n.communityLibraryPublishSubmittedToast;
    AppToast.show(context, message: message);
  }

  void _openPackageSheet(CommunityPackage pack) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          key: CommunityLibraryKeys.importSheet,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _titleFor(l10n, pack.titleKey),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.communityLibraryPackDetail(
                    pack.lessons,
                    pack.quizzes,
                    _authorFor(l10n, pack.authorKey),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryBtn(
                  key: CommunityLibraryKeys.importCta,
                  label: l10n.communityLibraryImportCta,
                  onPressed: _canImport
                      ? () {
                          Navigator.of(ctx).pop();
                          _onImport(pack);
                        }
                      : () {
                          Navigator.of(ctx).pop();
                          _blockedToast(l10n);
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: CommunityLibraryKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.communityLibraryTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: CommunityLibraryKeys.sosIconCta,
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
        key: CommunityLibraryKeys.childLean,
        title: l10n.communityLibraryChildLeanTitle,
        message: l10n.communityLibraryChildLeanMessage,
        actionLabel: l10n.communityLibrarySosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: CommunityLibraryKeys.childLean,
        title: l10n.communityLibraryChildLeanTitle,
        message: l10n.communityLibraryChildLeanMessage,
      );
    }

    if (_loading) {
      return Center(
        key: CommunityLibraryKeys.loading,
        child: Semantics(
          label: l10n.communityLibraryLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: CommunityLibraryKeys.empty,
        title: l10n.communityLibraryEmptyTitle,
        message: l10n.communityLibraryEmptyMessage,
        actionLabel: l10n.communityLibraryEmptyCta,
        onAction: () => _go('SCR-FAT-041'),
      );
    }

    final filtered = _snap.filtered(_query);
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return ListView(
      key: CommunityLibraryKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (_isObserverMother) ...[
          BannerNote(
            key: CommunityLibraryKeys.observerHint,
            variant: BannerVariant.a,
            message: l10n.communityLibraryObserverHint,
          ),
          const SizedBox(height: 12),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.border),
          ),
          child: TextField(
            key: CommunityLibraryKeys.search,
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
            decoration: InputDecoration(
              hintText: l10n.communityLibrarySearchHint,
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
              prefixIcon: Icon(Icons.search, color: colors.ink2),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          key: CommunityLibraryKeys.topRated,
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
                  l10n.communityLibraryTopRatedHeading,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                if (filtered.packages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.communityLibrarySearchNoResults,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                  )
                else
                  for (final pack in filtered.packages)
                    _PackageRow(
                      rowKey: CommunityLibraryKeys.packageRow(pack.id),
                      icon: _iconFor(pack.kind),
                      title: _titleFor(l10n, pack.titleKey),
                      subtitle: l10n.communityLibraryPackMeta(
                        _authorFor(l10n, pack.authorKey),
                        pack.rating.toStringAsFixed(1),
                        pack.ratingCount,
                      ),
                      trustedLabel: pack.trusted
                          ? l10n.communityLibraryTrustedTag
                          : null,
                      colors: colors,
                      onTap: () => _openPackageSheet(pack),
                    ),
              ],
            ),
          ),
        ),
        if (_snap.publishOffer != null) ...[
          const SizedBox(height: 14),
          DecoratedBox(
            key: CommunityLibraryKeys.publishCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.communityLibraryPublishHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.communityLibraryPublishMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryBtn(
                    key: CommunityLibraryKeys.publishCta,
                    label: l10n.communityLibraryPublishCta(
                      _titleFor(l10n, _snap.publishOffer!.titleKey),
                    ),
                    variant: PrimaryBtnVariant.sec,
                    onPressed: _canPublish
                        ? _onPublish
                        : () => _blockedToast(l10n),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        PrimaryBtn(
          key: CommunityLibraryKeys.pathCta,
          label: l10n.communityLibraryPathCta,
          variant: PrimaryBtnVariant.ghost,
          onPressed: () => _go('SCR-FAT-047'),
        ),
        const SizedBox(height: 12),
        Text(
          key: CommunityLibraryKeys.controlsNote,
          l10n.communityLibrarySixControlsNote,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            key: CommunityLibraryKeys.sosCta,
            onPressed: _sosBusy ? null : _openSos,
            child: Text(
              l10n.communityLibrarySosCta,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.coral,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.trustedLabel,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final FamilyColors colors;
  final VoidCallback onTap;
  final String? trustedLabel;

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, color: colors.p600, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              if (trustedLabel != null) ...[
                const SizedBox(width: 8),
                Tag(label: trustedLabel!, variant: TagVariant.g),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
