import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_focus_models.dart';
import 'package:family_os/features/n17_child_learn/child_focus_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

/// Widget keys for SCR-CHD-018 acceptance.
abstract final class ChildFocusKeys {
  static const screen = Key('child_focus_screen');
  static const loading = Key('child_focus_loading');
  static const empty = Key('child_focus_empty');
  static const body = Key('child_focus_body');
  static const timerCircle = Key('child_focus_timer');
  static const praiseBanner = Key('child_focus_praise');
  static const startCta = Key('child_focus_start');
  static const soundsCta = Key('child_focus_sounds');
  static const honestyNote = Key('child_focus_gift_note');
  static const parentLean = Key('child_focus_parent_lean');
  static const sosIconCta = Key('child_focus_sos_icon');
}

/// SCR-CHD-018 — وضع التركيز (child focus mode).
///
/// Prototype CHD-018 · RoleGuard child · gift focus time never deducted ·
/// praise from parent · sounds→035 · P-4 SOS · Rule 12/23 · minutes-only.
class ChildFocusScreen extends StatefulWidget {
  const ChildFocusScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildFocusRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildFocusScreen> createState() => _ChildFocusScreenState();
}

class _ChildFocusScreenState extends State<ChildFocusScreen> {
  late ChildFocusRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildFocusSnapshot _snap = const ChildFocusSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.focus;
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

  String _praiseQuote(AppLocalizations l10n) {
    return switch (_snap.praiseMessageKey) {
      'resistDistraction' => l10n.childFocusPraiseResistDistraction,
      _ => l10n.childFocusPraiseResistDistraction,
    };
  }

  String _timerLabel() {
    final m = _snap.sessionMinutes;
    return '${m.toString().padLeft(2, '0')}:00';
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final snap = await _repo.startSession();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(context, message: l10n.childFocusStartToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildFocusKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childFocusTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildFocusKeys.sosIconCta,
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
        key: ChildFocusKeys.parentLean,
        title: l10n.childFocusParentLeanTitle,
        message: l10n.childFocusParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildFocusKeys.loading,
        child: Semantics(
          label: l10n.childFocusLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildFocusKeys.empty,
        title: l10n.childFocusEmptyTitle,
        message: l10n.childFocusEmptyMessage,
        actionLabel: l10n.childFocusEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final hasPraise = _snap.praiseMessageKey != null;

    return SingleChildScrollView(
      key: ChildFocusKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPraise) ...[
            DecoratedBox(
              key: ChildFocusKeys.praiseBanner,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.amber.withValues(alpha: 0.25),
                    colors.amber100,
                  ],
                ),
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.amber, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.childFocusPraiseHeading,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _praiseQuote(l10n),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Center(
            child: Semantics(
              label: l10n.childFocusTimerSemantics(_snap.sessionMinutes),
              child: Container(
                key: ChildFocusKeys.timerCircle,
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.teal100, width: 10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timerLabel(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    Text(
                      l10n.childFocusTimerCaption,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.teal600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            key: ChildFocusKeys.honestyNote,
            l10n.childFocusGiftNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryBtn(
                  key: ChildFocusKeys.startCta,
                  label: _snap.sessionActive
                      ? l10n.childFocusRunningCta
                      : l10n.childFocusStartCta(_snap.sessionMinutes),
                  onPressed: _snap.sessionActive ? null : _start,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryBtn(
                  key: ChildFocusKeys.soundsCta,
                  label: l10n.childFocusSoundsCta,
                  variant: PrimaryBtnVariant.sec,
                  onPressed: () => _go(_snap.soundsScreenId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
