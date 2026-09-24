import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n08_platform/smart_alert_detail_models.dart';
import 'package:family_os/features/n08_platform/smart_alert_detail_repository.dart';

/// Widget keys for SCR-FAT-066 acceptance.
abstract final class SmartAlertDetailKeys {
  static const screen = Key('smart_alert_detail_screen');
  static const loading = Key('smart_alert_detail_loading');
  static const empty = Key('smart_alert_detail_empty');
  static const body = Key('smart_alert_detail_body');
  static const behaviorBanner = Key('smart_alert_detail_behavior');
  static const changesCard = Key('smart_alert_detail_changes');
  static const dialogueCard = Key('smart_alert_detail_dialogue');
  static const scheduleCta = Key('smart_alert_detail_schedule');
  static const silentCta = Key('smart_alert_detail_silent');
  static const childLean = Key('smart_alert_detail_child_lean');
  static const sosIconCta = Key('smart_alert_detail_sos_icon');

  static Key change(String id) => Key('smart_alert_detail_change_$id');
}

/// SCR-FAT-066 — تفصيل التنبيه وخطوة الحوار.
///
/// Prototype FAT-066 · amber behavior banner · dialogue not punishment ·
/// schedule / silent follow · P-4 SOS · Rule 12/23 · no planted child names.
class SmartAlertDetailScreen extends StatefulWidget {
  const SmartAlertDetailScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final SmartAlertDetailRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<SmartAlertDetailScreen> createState() => _SmartAlertDetailScreenState();
}

class _SmartAlertDetailScreenState extends State<SmartAlertDetailScreen> {
  late SmartAlertDetailRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  SmartAlertDetailSnapshot _snap = const SmartAlertDetailSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1SmartAlertDetailRepository;
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

  String _changeTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'shorterReplies' => l10n.smartAlertDetailChangeShorter,
      'lateNights' => l10n.smartAlertDetailChangeLateNights,
      'sadWords' => l10n.smartAlertDetailChangeSadWords,
      _ => l10n.smartAlertDetailChangeShorter,
    };
  }

  String _changeSub(AppLocalizations l10n, String key) {
    return switch (key) {
      'shorterRepliesSub' => l10n.smartAlertDetailChangeShorterSub,
      'lateNightsSub' => l10n.smartAlertDetailChangeLateNightsSub,
      'sadWordsSub' => l10n.smartAlertDetailChangeSadWordsSub,
      _ => l10n.smartAlertDetailChangeShorterSub,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: SmartAlertDetailKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.smartAlertDetailTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: SmartAlertDetailKeys.sosIconCta,
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
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: SmartAlertDetailKeys.childLean,
        title: l10n.smartAlertDetailChildLeanTitle,
        message: l10n.smartAlertDetailChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: SmartAlertDetailKeys.loading,
        child: Semantics(
          label: l10n.smartAlertDetailLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: SmartAlertDetailKeys.empty,
        title: l10n.smartAlertDetailEmptyTitle,
        message: l10n.smartAlertDetailEmptyMessage,
        actionLabel: l10n.smartAlertDetailEmptyCta,
        onAction: () => _go('SCR-FAT-065'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: SmartAlertDetailKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: SmartAlertDetailKeys.behaviorBanner,
            variant: BannerVariant.a,
            message: l10n.smartAlertDetailBehaviorBanner,
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            key: SmartAlertDetailKeys.changesCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.smartAlertDetailChangesHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final c in _snap.changes) ...[
                    ListTile(
                      key: SmartAlertDetailKeys.change(c.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _changeTitle(l10n, c.titleKey),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        _changeSub(l10n, c.subtitleKey),
                        style: TextStyle(fontSize: 12, color: colors.ink2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            key: SmartAlertDetailKeys.dialogueCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.smartAlertDetailDialogueHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.smartAlertDetailDialogueQuote,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.smartAlertDetailDialogueHint,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryBtn(
                    key: SmartAlertDetailKeys.scheduleCta,
                    label: l10n.smartAlertDetailScheduleCta,
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: l10n.smartAlertDetailScheduleToast,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  PrimaryBtn(
                    key: SmartAlertDetailKeys.silentCta,
                    label: l10n.smartAlertDetailSilentCta,
                    variant: PrimaryBtnVariant.ghost,
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: l10n.smartAlertDetailSilentToast,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
