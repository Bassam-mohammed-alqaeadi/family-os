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
import 'package:family_os/features/n12_devices/language_help_models.dart';
import 'package:family_os/features/n12_devices/language_help_repository.dart';

/// Widget keys for SCR-FAT-061 acceptance.
abstract final class LanguageHelpKeys {
  static const screen = Key('language_help_screen');
  static const loading = Key('language_help_loading');
  static const empty = Key('language_help_empty');
  static const body = Key('language_help_body');
  static const languageCard = Key('language_help_language_card');
  static const helpCenterCard = Key('language_help_help_center_card');
  static const arabicRow = Key('language_help_arabic_row');
  static const englishRow = Key('language_help_english_row');
  static const supportCta = Key('language_help_support_cta');
  static const observerHint = Key('language_help_observer');
  static const childLean = Key('language_help_child_lean');
  static const sosIconCta = Key('language_help_sos_icon');

  static Key helpRow(String id) => Key('language_help_row_$id');
}

/// SCR-FAT-061 — اللغة والمساعدة (language & help).
///
/// Prototype FAT-061 · settings-adjacent · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · locale switch Stage-1 toast · help links.
class LanguageHelpScreen extends StatefulWidget {
  const LanguageHelpScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1LanguageHelpRepository].
  final LanguageHelpRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may switch / support.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<LanguageHelpScreen> createState() => _LanguageHelpScreenState();
}

class _LanguageHelpScreenState extends State<LanguageHelpScreen> {
  late LanguageHelpRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  LanguageHelpSnapshot _snap = const LanguageHelpSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may switch locale and contact support.
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
    _repo = widget.repository ?? stage1LanguageHelpRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant LanguageHelpScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1LanguageHelpRepository;
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
    AppToast.show(context, message: l10n.languageHelpObserverBlocked);
  }

  void _onEnglishTap(AppLocalizations l10n) {
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_snap.currentLocale == LanguageHelpLocale.english) return;
    AppToast.show(context, message: l10n.languageHelpLocaleToast);
  }

  void _onSupportTap(AppLocalizations l10n) {
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    AppToast.show(context, message: l10n.languageHelpSupportToast);
  }

  void _onHelpLink(LanguageHelpLink link) {
    final screenId = switch (link.kind) {
      LanguageHelpLinkKind.deviceDisconnect => 'SCR-FAT-026',
      LanguageHelpLinkKind.parentModeUnlock => 'SCR-FAT-030',
    };
    _go(screenId);
  }

  String _helpTitle(AppLocalizations l10n, LanguageHelpLinkKind kind) {
    return switch (kind) {
      LanguageHelpLinkKind.deviceDisconnect =>
        l10n.languageHelpDeviceDisconnectTitle,
      LanguageHelpLinkKind.parentModeUnlock =>
        l10n.languageHelpParentModeTitle,
    };
  }

  String? _helpSubtitle(AppLocalizations l10n, LanguageHelpLinkKind kind) {
    return switch (kind) {
      LanguageHelpLinkKind.deviceDisconnect =>
        l10n.languageHelpDeviceDisconnectSubtitle,
      LanguageHelpLinkKind.parentModeUnlock => null,
    };
  }

  IconData _helpIcon(LanguageHelpLinkKind kind) {
    return switch (kind) {
      LanguageHelpLinkKind.deviceDisconnect => Icons.battery_alert_outlined,
      LanguageHelpLinkKind.parentModeUnlock => Icons.lock_open_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: LanguageHelpKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.languageHelpTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: LanguageHelpKeys.sosIconCta,
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
        key: LanguageHelpKeys.childLean,
        title: l10n.languageHelpChildLeanTitle,
        message: l10n.languageHelpChildLeanMessage,
        actionLabel: l10n.languageHelpSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (!_isParent) {
      return AppEmptyState(
        key: LanguageHelpKeys.childLean,
        title: l10n.languageHelpChildLeanTitle,
        message: l10n.languageHelpChildLeanMessage,
        actionLabel: l10n.languageHelpSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: LanguageHelpKeys.loading,
        child: Semantics(
          label: l10n.languageHelpLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: LanguageHelpKeys.empty,
        title: l10n.languageHelpEmptyTitle,
        message: l10n.languageHelpEmptyMessage,
        actionLabel: l10n.languageHelpEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: LanguageHelpKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: LanguageHelpKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.languageHelpObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          _SectionCard(
            cardKey: LanguageHelpKeys.languageCard,
            title: l10n.languageHelpLanguageSection,
            colors: colors,
            radii: radii,
            children: [
              _LanguageRow(
                rowKey: LanguageHelpKeys.arabicRow,
                title: l10n.languageHelpArabic,
                subtitle: l10n.languageHelpArabicSubtitle,
                colors: colors,
                trailing: _snap.currentLocale == LanguageHelpLocale.arabic
                    ? Tag(
                        label: l10n.languageHelpCurrentTag,
                        variant: TagVariant.p,
                      )
                    : null,
              ),
              Divider(height: 1, color: colors.border),
              _LanguageRow(
                rowKey: LanguageHelpKeys.englishRow,
                title: l10n.languageHelpEnglish,
                colors: colors,
                onTap: () => _onEnglishTap(l10n),
                trailing: _snap.currentLocale == LanguageHelpLocale.english
                    ? Tag(
                        label: l10n.languageHelpCurrentTag,
                        variant: TagVariant.p,
                      )
                    : Text(
                        l10n.languageHelpChooseAction,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.p700,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            cardKey: LanguageHelpKeys.helpCenterCard,
            title: l10n.languageHelpHelpCenterSection,
            colors: colors,
            radii: radii,
            children: [
              for (var i = 0; i < _snap.helpLinks.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.border),
                _HelpRow(
                  rowKey: LanguageHelpKeys.helpRow(_snap.helpLinks[i].id),
                  icon: _helpIcon(_snap.helpLinks[i].kind),
                  title: _helpTitle(l10n, _snap.helpLinks[i].kind),
                  subtitle: _helpSubtitle(l10n, _snap.helpLinks[i].kind),
                  colors: colors,
                  onTap: () => _onHelpLink(_snap.helpLinks[i]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: LanguageHelpKeys.supportCta,
            label: l10n.languageHelpSupportCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: () => _onSupportTap(l10n),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.cardKey,
    required this.title,
    required this.colors,
    required this.radii,
    required this.children,
  });

  final Key cardKey;
  final String title;
  final FamilyColors colors;
  final FamilyRadii radii;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: cardKey,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.rowKey,
    required this.title,
    required this.colors,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Key rowKey;
  final String title;
  final String? subtitle;
  final FamilyColors colors;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
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
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.colors,
    this.subtitle,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String? subtitle;
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colors.p700),
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
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ],
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
