import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_interactive_stories_models.dart';
import 'package:family_os/features/n17_child_learn/child_interactive_stories_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

abstract final class ChildInteractiveStoriesKeys {
  static const screen = Key('child_interactive_stories_screen');
  static const loading = Key('child_interactive_stories_loading');
  static const empty = Key('child_interactive_stories_empty');
  static const body = Key('child_interactive_stories_body');
  static const chapter = Key('child_interactive_stories_chapter');
  static const choices = Key('child_interactive_stories_choices');
  static const parentLean = Key('child_interactive_stories_parent_lean');
  static const sosIconCta = Key('child_interactive_stories_sos_icon');

  static Key choice(String id) => Key('child_interactive_stories_choice_$id');
}

/// SCR-CHD-033 — قصصي التفاعلية (value choices · no planted names).
class ChildInteractiveStoriesScreen extends StatefulWidget {
  const ChildInteractiveStoriesScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildInteractiveStoriesRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildInteractiveStoriesScreen> createState() =>
      _ChildInteractiveStoriesScreenState();
}

class _ChildInteractiveStoriesScreenState
    extends State<ChildInteractiveStoriesScreen> {
  late ChildInteractiveStoriesRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildInteractiveStoriesSnapshot _snap =
      const ChildInteractiveStoriesSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.stories;
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

  Future<void> _choose(ChildStoryChoice choice) async {
    final snap = await _repo.choose(choice.id);
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: _toast(l10n, choice.toastKey));
  }

  String _toast(AppLocalizations l10n, String key) => switch (key) {
    'toastReturn' => l10n.childInteractiveStoriesToastReturn,
    'toastTake' => l10n.childInteractiveStoriesToastTake,
    'toastAsk' => l10n.childInteractiveStoriesToastAsk,
    _ => key,
  };

  String _label(AppLocalizations l10n, String key) => switch (key) {
    'returnBag' => l10n.childInteractiveStoriesChoiceReturn,
    'takeBag' => l10n.childInteractiveStoriesChoiceTake,
    'askParent' => l10n.childInteractiveStoriesChoiceAsk,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildInteractiveStoriesKeys.screen,
      backgroundColor: colors.childBg,
      appBar: AppBar(
        backgroundColor: colors.childBg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childInteractiveStoriesTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildInteractiveStoriesKeys.sosIconCta,
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
        key: ChildInteractiveStoriesKeys.parentLean,
        title: l10n.childInteractiveStoriesParentLeanTitle,
        message: l10n.childInteractiveStoriesParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildInteractiveStoriesKeys.loading,
        child: Semantics(
          label: l10n.childInteractiveStoriesLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildInteractiveStoriesKeys.empty,
        title: l10n.childInteractiveStoriesEmptyTitle,
        message: l10n.childInteractiveStoriesEmptyMessage,
        actionLabel: l10n.childInteractiveStoriesEmptyCta,
        onAction: () => _go('SCR-CHD-014'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildInteractiveStoriesKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: ChildInteractiveStoriesKeys.chapter,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.teal, colors.teal.withValues(alpha: 0.75)],
              ),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childInteractiveStoriesChapterTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.childInteractiveStoriesChapterBody,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: ChildInteractiveStoriesKeys.choices,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.childInteractiveStoriesPrompt,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                for (final c in _snap.choices) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      key: ChildInteractiveStoriesKeys.choice(c.id),
                      onPressed: () => _choose(c),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: colors.teal,
                        side: BorderSide(color: colors.teal),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(_label(l10n, c.labelKey)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.childInteractiveStoriesFooter,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.ink2),
          ),
        ],
      ),
    );
  }
}
