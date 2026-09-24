import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_family_challenges_models.dart';
import 'package:family_os/features/n17_child_learn/child_family_challenges_repository.dart';

abstract final class ChildFamilyChallengesKeys {
  static const screen = Key('child_family_challenges_screen');
  static const loading = Key('child_family_challenges_loading');
  static const empty = Key('child_family_challenges_empty');
  static const body = Key('child_family_challenges_body');
  static const active = Key('child_family_challenges_active');
  static const done = Key('child_family_challenges_done');
  static const parentLean = Key('child_family_challenges_parent_lean');
  static const sosIconCta = Key('child_family_challenges_sos_icon');
}

/// SCR-CHD-034 — التحديات العائلية (friendly race · no shame ranks).
class ChildFamilyChallengesScreen extends StatefulWidget {
  const ChildFamilyChallengesScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildFamilyChallengesRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildFamilyChallengesScreen> createState() =>
      _ChildFamilyChallengesScreenState();
}

class _ChildFamilyChallengesScreenState
    extends State<ChildFamilyChallengesScreen> {
  late ChildFamilyChallengesRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildFamilyChallengesSnapshot _snap = const ChildFamilyChallengesSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildFamilyChallengesRepository;
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

  String _peerLabel(AppLocalizations l10n, String key) => switch (key) {
    'sibling' => l10n.childFamilyChallengesSibling,
    _ => l10n.childFamilyChallengesYou,
  };

  String _doneTitle(AppLocalizations l10n, String key) => switch (key) {
    'fajrWeek' => l10n.childFamilyChallengesDoneFajr,
    'ammaKhatma' => l10n.childFamilyChallengesDoneAmma,
    _ => key,
  };

  String _doneSub(AppLocalizations l10n, String key) => switch (key) {
    'fajrWeekSub' => l10n.childFamilyChallengesDoneFajrSub,
    'ammaKhatmaSub' => l10n.childFamilyChallengesDoneAmmaSub,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildFamilyChallengesKeys.screen,
      backgroundColor: colors.childBg,
      appBar: AppBar(
        backgroundColor: colors.childBg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childFamilyChallengesTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildFamilyChallengesKeys.sosIconCta,
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
        key: ChildFamilyChallengesKeys.parentLean,
        title: l10n.childFamilyChallengesParentLeanTitle,
        message: l10n.childFamilyChallengesParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildFamilyChallengesKeys.loading,
        child: Semantics(
          label: l10n.childFamilyChallengesLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildFamilyChallengesKeys.empty,
        title: l10n.childFamilyChallengesEmptyTitle,
        message: l10n.childFamilyChallengesEmptyMessage,
        actionLabel: l10n.childFamilyChallengesEmptyCta,
        onAction: () => _go('SCR-CHD-001'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildFamilyChallengesKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: ChildFamilyChallengesKeys.active,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childFamilyChallengesActiveTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.childFamilyChallengesActiveSub,
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
                const SizedBox(height: 12),
                for (final peer in _snap.peers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: colors.teal.withValues(alpha: 0.15),
                          child: Text(
                            String.fromCharCode(
                              _peerLabel(l10n, peer.labelKey).runes.first,
                            ),
                            style: TextStyle(
                              color: colors.teal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: Text(
                            _peerLabel(l10n, peer.labelKey),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: colors.ink,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              for (final d in peer.days)
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 3),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: d.done ? colors.mint : colors.border,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: d.done
                                      ? const Text(
                                          '✓',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  l10n.childFamilyChallengesTieNote,
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: ChildFamilyChallengesKeys.done,
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
                  l10n.childFamilyChallengesDoneTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                for (final d in _snap.done)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(d.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _doneTitle(l10n, d.titleKey),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: colors.ink,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _doneSub(l10n, d.subKey),
                                style: TextStyle(
                                  color: colors.ink2,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tag(label: l10n.childFamilyChallengesDoneTag),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BannerNote(
            message: l10n.childFamilyChallengesBanner,
            variant: BannerVariant.t,
          ),
        ],
      ),
    );
  }
}
