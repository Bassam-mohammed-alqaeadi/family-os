import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n07_advisor/peer_compare_models.dart';
import 'package:family_os/features/n07_advisor/peer_compare_repository.dart';

abstract final class PeerCompareKeys {
  static const screen = Key('peer_compare_screen');
  static const loading = Key('peer_compare_loading');
  static const empty = Key('peer_compare_empty');
  static const body = Key('peer_compare_body');
  static const privacy = Key('peer_compare_privacy');
  static const metrics = Key('peer_compare_metrics');
  static const compass = Key('peer_compare_compass');
  static const childLean = Key('peer_compare_child_lean');
  static const sosIconCta = Key('peer_compare_sos_icon');
}

/// SCR-FAT-081 — مقارنة الأقران (anonymous · compass not court).
class PeerCompareScreen extends StatefulWidget {
  const PeerCompareScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final PeerCompareRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<PeerCompareScreen> createState() => _PeerCompareScreenState();
}

class _PeerCompareScreenState extends State<PeerCompareScreen> {
  late PeerCompareRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  PeerCompareSnapshot _snap = const PeerCompareSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1PeerCompareRepository;
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

  String _child(AppLocalizations l10n) => switch (_snap.childLabelKey) {
    'childOne' => l10n.peerCompareChildOne,
    _ => l10n.peerCompareChildOne,
  };

  String _title(AppLocalizations l10n, String key) => switch (key) {
    'screenTime' => l10n.peerCompareMetricScreen,
    'learnTime' => l10n.peerCompareMetricLearn,
    'sleep' => l10n.peerCompareMetricSleep,
    _ => key,
  };

  String _detail(AppLocalizations l10n, String key) => switch (key) {
    'screenDetail' => l10n.peerCompareDetailScreen,
    'learnDetail' => l10n.peerCompareDetailLearn,
    'sleepDetail' => l10n.peerCompareDetailSleep,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: PeerCompareKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.peerCompareTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: PeerCompareKeys.sosIconCta,
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
    if (_isChild) {
      return AppEmptyState(
        key: PeerCompareKeys.childLean,
        title: l10n.peerCompareChildLeanTitle,
        message: l10n.peerCompareChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: PeerCompareKeys.loading,
        child: Semantics(
          label: l10n.peerCompareLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: PeerCompareKeys.empty,
        title: l10n.peerCompareEmptyTitle,
        message: l10n.peerCompareEmptyMessage,
        actionLabel: l10n.peerCompareEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: PeerCompareKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerNote(
            key: PeerCompareKeys.privacy,
            variant: BannerVariant.t,
            message: l10n.peerComparePrivacyBanner,
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: PeerCompareKeys.metrics,
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
                    l10n.peerCompareHeading(_child(l10n), _snap.ageYears),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  for (final m in _snap.metrics)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _title(l10n, m.titleKey),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: colors.ink,
                                  ),
                                ),
                                Text(
                                  _detail(l10n, m.detailKey),
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
                            label: m.positive
                                ? l10n.peerCompareTagBetter
                                : l10n.peerCompareTagImprove,
                            variant: m.positive ? TagVariant.g : TagVariant.a,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: PeerCompareKeys.compass,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                l10n.peerCompareCompassNote,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
