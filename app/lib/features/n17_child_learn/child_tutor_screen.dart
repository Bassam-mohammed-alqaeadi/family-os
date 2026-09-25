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
import 'package:family_os/features/n17_child_learn/child_tutor_models.dart';
import 'package:family_os/features/n17_child_learn/child_tutor_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

/// Widget keys for SCR-CHD-017 acceptance.
abstract final class ChildTutorKeys {
  static const screen = Key('child_tutor_screen');
  static const loading = Key('child_tutor_loading');
  static const empty = Key('child_tutor_empty');
  static const body = Key('child_tutor_body');
  static const policyBanner = Key('child_tutor_policy');
  static const transparencyNote = Key('child_tutor_transparency');
  static const thread = Key('child_tutor_thread');
  static const choices = Key('child_tutor_choices');
  static const photoCta = Key('child_tutor_photo');
  static const parentLean = Key('child_tutor_parent_lean');
  static const sosIconCta = Key('child_tutor_sos_icon');

  static Key bubble(String id) => Key('child_tutor_bubble_$id');

  static Key choice(String id) => Key('child_tutor_choice_$id');
}

/// SCR-CHD-017 — معلمي الذكي (Socratic tutor — never gives the answer).
///
/// Prototype CHD-017 · Khanmigo spirit · RoleGuard child · parent transparency
/// note · P-4 SOS · Rule 12/23 · Stage-1 mock choices.
class ChildTutorScreen extends StatefulWidget {
  const ChildTutorScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildTutorRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildTutorScreen> createState() => _ChildTutorScreenState();
}

class _ChildTutorScreenState extends State<ChildTutorScreen> {
  late ChildTutorRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildTutorSnapshot _snap = const ChildTutorSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.tutor;
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

  String _bubbleText(AppLocalizations l10n, String key) {
    return switch (key) {
      'greetStuck' => l10n.childTutorBubbleGreetStuck,
      'childDifferentDenom' => l10n.childTutorBubbleChildDifferentDenom,
      'tutorLcmPrompt' => l10n.childTutorBubbleLcmPrompt,
      _ => l10n.childTutorBubbleGreetStuck,
    };
  }

  String _choiceLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'ten' => l10n.childTutorChoiceTen,
      'seven' => l10n.childTutorChoiceSeven,
      _ => l10n.childTutorChoiceTen,
    };
  }

  String _choiceReply(AppLocalizations l10n, String key) {
    return switch (key) {
      'replyTen' => l10n.childTutorReplyTen,
      'replySeven' => l10n.childTutorReplySeven,
      _ => l10n.childTutorReplyTen,
    };
  }

  void _onChoice(ChildTutorChoice choice) {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: _choiceReply(l10n, choice.replyKey));
  }

  void _onPhoto() {
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childTutorPhotoToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildTutorKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.childTutorTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.childTutorSubtitle,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: ChildTutorKeys.sosIconCta,
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
        key: ChildTutorKeys.parentLean,
        title: l10n.childTutorParentLeanTitle,
        message: l10n.childTutorParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildTutorKeys.loading,
        child: Semantics(
          label: l10n.childTutorLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildTutorKeys.empty,
        title: l10n.childTutorEmptyTitle,
        message: l10n.childTutorEmptyMessage,
        actionLabel: l10n.childTutorEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildTutorKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: ChildTutorKeys.policyBanner,
            variant: BannerVariant.t,
            message: l10n.childTutorPolicyBanner,
          ),
          const SizedBox(height: 8),
          Text(
            key: ChildTutorKeys.transparencyNote,
            l10n.childTutorTransparencyNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            key: ChildTutorKeys.thread,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final b in _snap.bubbles) ...[
                _Bubble(
                  bubbleKey: ChildTutorKeys.bubble(b.id),
                  text: _bubbleText(l10n, b.textKey),
                  kind: b.kind,
                  colors: colors,
                  radii: radii,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            key: ChildTutorKeys.choices,
            children: [
              for (var i = 0; i < _snap.choices.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: PrimaryBtn(
                    key: ChildTutorKeys.choice(_snap.choices[i].id),
                    label: _choiceLabel(l10n, _snap.choices[i].labelKey),
                    variant: PrimaryBtnVariant.sec,
                    onPressed: () => _onChoice(_snap.choices[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: ChildTutorKeys.photoCta,
            label: l10n.childTutorPhotoCta,
            variant: PrimaryBtnVariant.ghost,
            onPressed: _onPhoto,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.bubbleKey,
    required this.text,
    required this.kind,
    required this.colors,
    required this.radii,
  });

  final Key bubbleKey;
  final String text;
  final ChildTutorBubbleKind kind;
  final FamilyColors colors;
  final FamilyRadii radii;

  @override
  Widget build(BuildContext context) {
    final isTutor = kind == ChildTutorBubbleKind.tutor;
    return Align(
      alignment: isTutor
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          key: bubbleKey,
          decoration: BoxDecoration(
            color: isTutor ? colors.teal100 : colors.p100,
            borderRadius: BorderRadius.circular(radii.card),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colors.ink,
                height: 1.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
