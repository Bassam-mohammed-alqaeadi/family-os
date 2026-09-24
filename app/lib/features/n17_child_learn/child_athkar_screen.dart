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
import 'package:family_os/features/n17_child_learn/child_athkar_models.dart';
import 'package:family_os/features/n17_child_learn/child_athkar_repository.dart';

abstract final class ChildAthkarKeys {
  static const screen = Key('child_athkar_screen');
  static const loading = Key('child_athkar_loading');
  static const empty = Key('child_athkar_empty');
  static const body = Key('child_athkar_body');
  static const thikrCard = Key('child_athkar_thikr');
  static const sayCta = Key('child_athkar_say');
  static const morningStat = Key('child_athkar_morning');
  static const eveningStat = Key('child_athkar_evening');
  static const parentLean = Key('child_athkar_parent_lean');
  static const sosIconCta = Key('child_athkar_sos_icon');
}

/// SCR-CHD-027 — أذكاري اليومية.
class ChildAthkarScreen extends StatefulWidget {
  const ChildAthkarScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildAthkarRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildAthkarScreen> createState() => _ChildAthkarScreenState();
}

class _ChildAthkarScreenState extends State<ChildAthkarScreen> {
  late ChildAthkarRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildAthkarSnapshot _snap = const ChildAthkarSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildAthkarRepository;
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

  String _session(AppLocalizations l10n) => switch (_snap.sessionKey) {
    'morning' => l10n.childAthkarSessionMorning,
    'evening' => l10n.childAthkarSessionEvening,
    _ => l10n.childAthkarSessionEvening,
  };

  String _thikr(AppLocalizations l10n) => switch (_snap.thikrKey) {
    'amsayna' => l10n.childAthkarThikrAmsayna,
    _ => l10n.childAthkarThikrAmsayna,
  };

  Future<void> _say() async {
    if (_snap.complete) {
      AppToast.show(
        context,
        message: AppLocalizations.of(context).childAthkarCompleteToast,
      );
      return;
    }
    final snap = await _repo.markSaid();
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      message: snap.complete
          ? l10n.childAthkarCompleteToast
          : l10n.childAthkarProgressToast(snap.done, snap.total),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildAthkarKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childAthkarTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildAthkarKeys.sosIconCta,
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
        key: ChildAthkarKeys.parentLean,
        title: l10n.childAthkarParentLeanTitle,
        message: l10n.childAthkarParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildAthkarKeys.loading,
        child: Semantics(
          label: l10n.childAthkarLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildAthkarKeys.empty,
        title: l10n.childAthkarEmptyTitle,
        message: l10n.childAthkarEmptyMessage,
        actionLabel: l10n.childAthkarEmptyCta,
        onAction: () => _go('SCR-CHD-004'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildAthkarKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ChildAthkarKeys.thikrCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                children: [
                  Text(
                    l10n.childAthkarProgress(
                      _session(l10n),
                      _snap.done,
                      _snap.total,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _thikr(l10n),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      height: 2.0,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryBtn(
                    key: ChildAthkarKeys.sayCta,
                    label: _snap.complete
                        ? l10n.childAthkarDoneCta
                        : l10n.childAthkarSayCta,
                    variant: PrimaryBtnVariant.teal,
                    onPressed: _say,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  key: ChildAthkarKeys.morningStat,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(radii.card),
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Text(
                          l10n.childAthkarStatMorning,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                        Text(
                          l10n.childAthkarStatValue(
                            _snap.morningDone,
                            _snap.morningTotal,
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.teal600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DecoratedBox(
                  key: ChildAthkarKeys.eveningStat,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(radii.card),
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Text(
                          l10n.childAthkarStatEvening,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                        Text(
                          l10n.childAthkarStatValue(_snap.done, _snap.total),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BannerNote(
            variant: BannerVariant.t,
            message: l10n.childAthkarGentleBanner,
          ),
        ],
      ),
    );
  }
}
