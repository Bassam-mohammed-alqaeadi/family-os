import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n02_day/child_call_play_models.dart';
import 'package:family_os/features/n02_day/child_call_play_repository.dart';

abstract final class ChildCallPlayKeys {
  static const screen = Key('child_call_play_screen');
  static const loading = Key('child_call_play_loading');
  static const empty = Key('child_call_play_empty');
  static const body = Key('child_call_play_body');
  static const hero = Key('child_call_play_hero');
  static const games = Key('child_call_play_games');
  static const parentLean = Key('child_call_play_parent_lean');
  static const sosIconCta = Key('child_call_play_sos_icon');

  static Key game(String id) => Key('child_call_play_game_$id');
}

/// SCR-CHD-036 — مرح المكالمة (safe-circle games · Rule 23 labels).
class ChildCallPlayScreen extends StatefulWidget {
  const ChildCallPlayScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildCallPlayRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildCallPlayScreen> createState() => _ChildCallPlayScreenState();
}

class _ChildCallPlayScreenState extends State<ChildCallPlayScreen> {
  late ChildCallPlayRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildCallPlaySnapshot _snap = const ChildCallPlaySnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildCallPlayRepository;
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

  Future<void> _openGame(CallPlayGame game) async {
    final snap = await _repo.openGame(game.id);
    if (!mounted) return;
    setState(() => _snap = snap);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: _toast(l10n, game.toastKey));
  }

  String _peer(AppLocalizations l10n) => switch (_snap.peerLabelKey) {
    'grandpa' => l10n.childCallPlayPeerGrandpa,
    _ => l10n.childCallPlayPeerGrandpa,
  };

  String _title(AppLocalizations l10n, String key) => switch (key) {
    'draw' => l10n.childCallPlayGameDraw,
    'xo' => l10n.childCallPlayGameXo,
    'quiz' => l10n.childCallPlayGameQuiz,
    _ => key,
  };

  String _sub(AppLocalizations l10n, String key) => switch (key) {
    'drawSub' => l10n.childCallPlayGameDrawSub,
    'xoSub' => l10n.childCallPlayGameXoSub,
    'quizSub' => l10n.childCallPlayGameQuizSub,
    _ => key,
  };

  String _toast(AppLocalizations l10n, String key) => switch (key) {
    'toastDraw' => l10n.childCallPlayToastDraw,
    'toastXo' => l10n.childCallPlayToastXo,
    'toastQuiz' => l10n.childCallPlayToastQuiz,
    _ => key,
  };

  String _cta(AppLocalizations l10n, CallPlayGame g) => switch (g.id) {
    'draw' => l10n.childCallPlayCtaOpen,
    'xo' => l10n.childCallPlayCtaPlay,
    'quiz' => l10n.childCallPlayCtaChallenge,
    _ => l10n.childCallPlayCtaOpen,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildCallPlayKeys.screen,
      backgroundColor: colors.childBg,
      appBar: AppBar(
        backgroundColor: colors.childBg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childCallPlayTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildCallPlayKeys.sosIconCta,
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
        key: ChildCallPlayKeys.parentLean,
        title: l10n.childCallPlayParentLeanTitle,
        message: l10n.childCallPlayParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildCallPlayKeys.loading,
        child: Semantics(
          label: l10n.childCallPlayLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildCallPlayKeys.empty,
        title: l10n.childCallPlayEmptyTitle,
        message: l10n.childCallPlayEmptyMessage,
        actionLabel: l10n.childCallPlayEmptyCta,
        onAction: () => _go('SCR-CHD-007'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final peer = _peer(l10n);

    return SingleChildScrollView(
      key: ChildCallPlayKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: ChildCallPlayKeys.hero,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.teal, colors.teal.withValues(alpha: 0.75)],
              ),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        String.fromCharCode(peer.runes.first),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('📞', style: TextStyle(fontSize: 20)),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        String.fromCharCode(l10n.childCallPlayYou.runes.first),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.childCallPlayHeroTitle(peer),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  l10n.childCallPlayHeroSub,
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: ChildCallPlayKeys.games,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childCallPlayGamesTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                for (final g in _snap.games)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(g.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title(l10n, g.titleKey),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: colors.ink,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _sub(l10n, g.subKey),
                                style: TextStyle(
                                  color: colors.ink2,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (g.primary)
                          FilledButton(
                            key: ChildCallPlayKeys.game(g.id),
                            onPressed: () => _openGame(g),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              backgroundColor: colors.teal,
                            ),
                            child: Text(_cta(l10n, g)),
                          )
                        else
                          OutlinedButton(
                            key: ChildCallPlayKeys.game(g.id),
                            onPressed: () => _openGame(g),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: colors.teal,
                              side: BorderSide(color: colors.teal),
                            ),
                            child: Text(_cta(l10n, g)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BannerNote(
            message: l10n.childCallPlayBanner,
            variant: BannerVariant.t,
          ),
        ],
      ),
    );
  }
}
