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

/// Widget keys for SCR-FAT-041 acceptance.
abstract final class AddFromSourceKeys {
  static const screen = Key('add_from_source_screen');
  static const body = Key('add_from_source_body');
  static const tipBanner = Key('add_from_source_tip');
  static const pdfHero = Key('add_from_source_pdf');
  static const optionsSection = Key('add_from_source_options');
  static const rowAssignment = Key('add_from_source_assignment');
  static const rowCamera = Key('add_from_source_camera');
  static const rowLink = Key('add_from_source_link');
  static const rowTopic = Key('add_from_source_topic');
  static const rowVoice = Key('add_from_source_voice');
  static const rowLibrary = Key('add_from_source_library');
  static const pdfSheet = Key('add_from_source_pdf_sheet');
  static const pdfOptionMath = Key('add_from_source_pdf_math');
  static const pdfOptionScience = Key('add_from_source_pdf_science');
  static const pdfPickDevice = Key('add_from_source_pdf_device');
  static const pdfGenerate = Key('add_from_source_pdf_generate');
  static const observerHint = Key('add_from_source_observer');
  static const childLean = Key('add_from_source_child_lean');
  static const sosCta = Key('add_from_source_sos');
  static const sosIconCta = Key('add_from_source_sos_icon');
}

/// SCR-FAT-041 — أضف من أي مصدر (add from any source / input gates).
///
/// Prototype FAT-041 · F-13 rename · S-EDU-048…053 · Rule 12/23 · mother
/// levels · mock-first · ARB · P-4 SOS · CTAs to FAT-042/046/049/043
/// (placeholders OK).
class AddFromSourceScreen extends StatefulWidget {
  const AddFromSourceScreen({
    super.key,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

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
  State<AddFromSourceScreen> createState() => _AddFromSourceScreenState();
}

class _AddFromSourceScreenState extends State<AddFromSourceScreen> {
  late final SosFireService _sos;
  var _sosBusy = false;

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
    _sos = widget.sosFire ?? stage1SosFireService;
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

  void _onCreateTap(VoidCallback action) {
    if (!_canCreate) {
      final l10n = AppLocalizations.of(context);
      AppToast.show(context, message: l10n.addFromSourceObserverBlocked);
      return;
    }
    action();
  }

  Future<void> _openPdfSheet() async {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radii.card),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          key: AddFromSourceKeys.pdfSheet,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.addFromSourcePdfSheetTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.addFromSourcePdfSheetBody,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _PdfOptionTile(
                  tileKey: AddFromSourceKeys.pdfOptionMath,
                  icon: Icons.menu_book_outlined,
                  title: l10n.addFromSourcePdfMathTitle,
                  subtitle: l10n.addFromSourcePdfMathSub,
                  selected: true,
                  colors: colors,
                  radii: radii,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                _PdfOptionTile(
                  tileKey: AddFromSourceKeys.pdfOptionScience,
                  icon: Icons.science_outlined,
                  title: l10n.addFromSourcePdfScienceTitle,
                  subtitle: l10n.addFromSourcePdfScienceSub,
                  selected: false,
                  colors: colors,
                  radii: radii,
                  onTap: () {
                    AppToast.show(
                      context,
                      message: l10n.addFromSourcePdfSelectedToast,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _PdfOptionTile(
                  tileKey: AddFromSourceKeys.pdfPickDevice,
                  icon: Icons.folder_open_outlined,
                  title: l10n.addFromSourcePdfDeviceTitle,
                  subtitle: null,
                  selected: false,
                  dashed: true,
                  colors: colors,
                  radii: radii,
                  onTap: () {
                    AppToast.show(
                      context,
                      message: l10n.addFromSourcePdfDeviceToast,
                    );
                  },
                ),
                const SizedBox(height: 14),
                PrimaryBtn(
                  key: AddFromSourceKeys.pdfGenerate,
                  label: l10n.addFromSourcePdfGenerateCta,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    AppToast.show(
                      context,
                      message: l10n.addFromSourcePdfProcessingToast,
                    );
                    _go('SCR-FAT-043');
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
      key: AddFromSourceKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.addFromSourceTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: AddFromSourceKeys.sosIconCta,
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
        key: AddFromSourceKeys.childLean,
        title: l10n.addFromSourceChildLeanTitle,
        message: l10n.addFromSourceChildLeanMessage,
        actionLabel: l10n.addFromSourceSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: AddFromSourceKeys.childLean,
        title: l10n.addFromSourceChildLeanTitle,
        message: l10n.addFromSourceChildLeanMessage,
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: AddFromSourceKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: AddFromSourceKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.addFromSourceObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          BannerNote(
            key: AddFromSourceKeys.tipBanner,
            variant: BannerVariant.t,
            message: l10n.addFromSourceTip,
          ),
          const SizedBox(height: 12),
          _PdfHeroCard(
            cardKey: AddFromSourceKeys.pdfHero,
            title: l10n.addFromSourcePdfTitle,
            subtitle: l10n.addFromSourcePdfSubtitle,
            tagLabel: l10n.addFromSourcePdfTag,
            enabled: _canCreate,
            colors: colors,
            radii: radii,
            onTap: () => _onCreateTap(_openPdfSheet),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            key: AddFromSourceKeys.optionsSection,
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
                    l10n.addFromSourceOptionsHeading,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SourceRow(
                    rowKey: AddFromSourceKeys.rowAssignment,
                    icon: Icons.flag_outlined,
                    title: l10n.addFromSourceAssignmentTitle,
                    subtitle: l10n.addFromSourceAssignmentSub,
                    enabled: _canCreate,
                    colors: colors,
                    onTap: () => _onCreateTap(() => _go('SCR-FAT-049')),
                  ),
                  _SourceRow(
                    rowKey: AddFromSourceKeys.rowCamera,
                    icon: Icons.photo_camera_outlined,
                    title: l10n.addFromSourceCameraTitle,
                    subtitle: l10n.addFromSourceCameraSub,
                    enabled: _canCreate,
                    colors: colors,
                    onTap: () => _onCreateTap(() => _go('SCR-FAT-042')),
                  ),
                  _SourceRow(
                    rowKey: AddFromSourceKeys.rowLink,
                    icon: Icons.link,
                    title: l10n.addFromSourceLinkTitle,
                    subtitle: l10n.addFromSourceLinkSub,
                    enabled: _canCreate,
                    colors: colors,
                    onTap: () => _onCreateTap(() {
                      AppToast.show(
                        context,
                        message: l10n.addFromSourceLinkToast,
                      );
                    }),
                  ),
                  _SourceRow(
                    rowKey: AddFromSourceKeys.rowTopic,
                    icon: Icons.lightbulb_outline,
                    title: l10n.addFromSourceTopicTitle,
                    subtitle: l10n.addFromSourceTopicSub,
                    enabled: _canCreate,
                    colors: colors,
                    onTap: () => _onCreateTap(() {
                      AppToast.show(
                        context,
                        message: l10n.addFromSourceTopicToast,
                      );
                    }),
                  ),
                  _SourceRow(
                    rowKey: AddFromSourceKeys.rowVoice,
                    icon: Icons.mic_none_outlined,
                    title: l10n.addFromSourceVoiceTitle,
                    subtitle: l10n.addFromSourceVoiceSub,
                    enabled: _canCreate,
                    colors: colors,
                    onTap: () => _onCreateTap(() {
                      AppToast.show(
                        context,
                        message: l10n.addFromSourceVoiceToast,
                      );
                    }),
                  ),
                  _SourceRow(
                    rowKey: AddFromSourceKeys.rowLibrary,
                    icon: Icons.public_outlined,
                    title: l10n.addFromSourceLibraryTitle,
                    subtitle: l10n.addFromSourceLibrarySub,
                    enabled: _canCreate,
                    colors: colors,
                    onTap: () => _onCreateTap(() => _go('SCR-FAT-046')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: AddFromSourceKeys.sosCta,
            label: l10n.addFromSourceSosCta,
            onPressed: _sosBusy ? null : _openSos,
          ),
        ],
      ),
    );
  }
}

class _PdfHeroCard extends StatelessWidget {
  const _PdfHeroCard({
    required this.cardKey,
    required this.title,
    required this.subtitle,
    required this.tagLabel,
    required this.enabled,
    required this.colors,
    required this.radii,
    required this.onTap,
  });

  final Key cardKey;
  final String title;
  final String subtitle;
  final String tagLabel;
  final bool enabled;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      child: Material(
        key: cardKey,
        color: Colors.transparent,
          child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.p50,
                  Color.lerp(colors.p100, colors.surface, 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.p500, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 36, color: colors.p700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: colors.p700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Tag(label: tagLabel, variant: TagVariant.p),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, color: colors.p600, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final FamilyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                        height: 1.35,
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

class _PdfOptionTile extends StatelessWidget {
  const _PdfOptionTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.colors,
    required this.radii,
    required this.onTap,
    this.dashed = false,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool dashed;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: tileKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.card),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(
              color: selected ? colors.p500 : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 22, color: colors.p700),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: dashed ? colors.p700 : colors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ],
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
