import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_coming_gifts_models.dart';
import 'package:family_os/features/n17_child_learn/child_coming_gifts_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

abstract final class ChildComingGiftsKeys {
  static const screen = Key('child_coming_gifts_screen');
  static const loading = Key('child_coming_gifts_loading');
  static const empty = Key('child_coming_gifts_empty');
  static const body = Key('child_coming_gifts_body');
  static const hero = Key('child_coming_gifts_hero');
  static const links = Key('child_coming_gifts_links');
  static const parentLean = Key('child_coming_gifts_parent_lean');
  static const sosIconCta = Key('child_coming_gifts_sos_icon');

  static Key link(String id) => Key('child_coming_gifts_link_$id');
}

/// SCR-CHD-031 — قادم لك (teaser hub · no date promises).
class ChildComingGiftsScreen extends StatefulWidget {
  const ChildComingGiftsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildComingGiftsRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildComingGiftsScreen> createState() => _ChildComingGiftsScreenState();
}

class _ChildComingGiftsScreenState extends State<ChildComingGiftsScreen> {
  late ChildComingGiftsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildComingGiftsSnapshot _snap = const ChildComingGiftsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.comingGifts;
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

  String _title(AppLocalizations l10n, String key) => switch (key) {
    'callPlay' => l10n.childComingGiftsCallPlay,
    'challenges' => l10n.childComingGiftsChallenges,
    'stories' => l10n.childComingGiftsStories,
    'sounds' => l10n.childComingGiftsSounds,
    'stickers' => l10n.childComingGiftsStickers,
    'smartTilawa' => l10n.childComingGiftsSmartTilawa,
    _ => key,
  };

  String _sub(AppLocalizations l10n, String key) => switch (key) {
    'callPlaySub' => l10n.childComingGiftsCallPlaySub,
    'challengesSub' => l10n.childComingGiftsChallengesSub,
    'storiesSub' => l10n.childComingGiftsStoriesSub,
    'soundsSub' => l10n.childComingGiftsSoundsSub,
    'stickersSub' => l10n.childComingGiftsStickersSub,
    'smartTilawaSub' => l10n.childComingGiftsSmartTilawaSub,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildComingGiftsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childComingGiftsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildComingGiftsKeys.sosIconCta,
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
        key: ChildComingGiftsKeys.parentLean,
        title: l10n.childComingGiftsParentLeanTitle,
        message: l10n.childComingGiftsParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildComingGiftsKeys.loading,
        child: Semantics(
          label: l10n.childComingGiftsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildComingGiftsKeys.empty,
        title: l10n.childComingGiftsEmptyTitle,
        message: l10n.childComingGiftsEmptyMessage,
        actionLabel: l10n.childComingGiftsEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildComingGiftsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ChildComingGiftsKeys.hero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.teal, colors.teal600],
              ),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
              child: Column(
                children: [
                  const Text('🔮', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 6),
                  Text(
                    l10n.childComingGiftsHeroTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.childComingGiftsHeroSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: ChildComingGiftsKeys.links,
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
                    l10n.childComingGiftsLinksHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  for (final link in _snap.links)
                    InkWell(
                      key: ChildComingGiftsKeys.link(link.id),
                      onTap: () => _go(link.navigateTo),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _title(l10n, link.titleKey),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: colors.ink,
                                    ),
                                  ),
                                  Text(
                                    _sub(l10n, link.subKey),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tag(
                              label: l10n.childComingGiftsNewTag,
                              variant: TagVariant.g,
                            ),
                          ],
                        ),
                      ),
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
