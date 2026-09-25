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
import 'package:family_os/features/n07_advisor/mother_ai_feed_models.dart';
import 'package:family_os/features/n07_advisor/mother_ai_feed_repository.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

abstract final class MotherAiFeedKeys {
  static const screen = Key('mother_ai_feed_screen');
  static const loading = Key('mother_ai_feed_loading');
  static const empty = Key('mother_ai_feed_empty');
  static const body = Key('mother_ai_feed_body');
  static const fatherWatch = Key('mother_ai_feed_father_watch');
  static const welcome = Key('mother_ai_feed_welcome');
  static const whisperCard = Key('mother_ai_feed_whisper');
  static const whisperCta = Key('mother_ai_feed_whisper_cta');
  static const whisperSent = Key('mother_ai_feed_whisper_sent');
  static const observerHint = Key('mother_ai_feed_observer');
  static const childLean = Key('mother_ai_feed_child_lean');
  static const sosIconCta = Key('mother_ai_feed_sos_icon');

  static Key item(String id) => Key('mother_ai_feed_item_$id');
}

/// SCR-FAT-076 — إخطارات الذكاء للأم.
class MotherAiFeedScreen extends StatefulWidget {
  const MotherAiFeedScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final MotherAiFeedRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<MotherAiFeedScreen> createState() => _MotherAiFeedScreenState();
}

class _MotherAiFeedScreenState extends State<MotherAiFeedScreen> {
  late MotherAiFeedRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  MotherAiFeedSnapshot _snap = const MotherAiFeedSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;
  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;
  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;
  bool get _canWhisper {
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
    _repo = widget.repository ?? Stage1ReportsRuntime.motherAiFeed;
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
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String id) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(id);
      return;
    }
    context.push(screenPath(id));
  }

  Future<void> _sendWhisper() async {
    final l10n = AppLocalizations.of(context);
    if (!_canWhisper) {
      AppToast.show(context, message: l10n.motherAiFeedObserverBlocked);
      return;
    }
    if (_busy || _snap.whisperSent) return;
    setState(() => _busy = true);
    final snap = await _repo.sendWhisper();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
    AppToast.show(context, message: l10n.motherAiFeedWhisperToast);
  }

  String _itemTitle(AppLocalizations l10n, String key) => switch (key) {
    'weekSummary' => l10n.motherAiFeedItemWeekTitle,
    'sleepNote' => l10n.motherAiFeedItemSleepTitle,
    _ => l10n.motherAiFeedItemWeekTitle,
  };

  String _itemBody(AppLocalizations l10n, String key) => switch (key) {
    'mathImprove' => l10n.motherAiFeedItemMathBody(l10n.motherAiFeedChildOne),
    'weekendLate' => l10n.motherAiFeedItemSleepBody(l10n.motherAiFeedChildOne),
    _ => l10n.motherAiFeedItemMathBody(l10n.motherAiFeedChildOne),
  };

  String _tag(AppLocalizations l10n, String key) => switch (key) {
    'excellent' => l10n.motherAiFeedTagExcellent,
    'watch' => l10n.motherAiFeedTagWatch,
    _ => l10n.motherAiFeedTagGood,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: MotherAiFeedKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.motherAiFeedTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: MotherAiFeedKeys.sosIconCta,
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
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: MotherAiFeedKeys.childLean,
        title: l10n.motherAiFeedChildLeanTitle,
        message: l10n.motherAiFeedChildLeanMessage,
        actionLabel: l10n.motherAiFeedSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }
    if (_loading) {
      return Center(
        key: MotherAiFeedKeys.loading,
        child: Semantics(
          label: l10n.motherAiFeedLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: MotherAiFeedKeys.empty,
        title: l10n.motherAiFeedEmptyTitle,
        message: l10n.motherAiFeedEmptyMessage,
        actionLabel: l10n.motherAiFeedEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: MotherAiFeedKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_role == AppRole.father)
            BannerNote(
              key: MotherAiFeedKeys.fatherWatch,
              variant: BannerVariant.p,
              message: l10n.motherAiFeedFatherWatchBanner,
            ),
          if (_role == AppRole.father) const SizedBox(height: 10),
          if (_isObserverMother) ...[
            BannerNote(
              key: MotherAiFeedKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.motherAiFeedObserverHint,
            ),
            const SizedBox(height: 10),
          ],
          BannerNote(
            key: MotherAiFeedKeys.welcome,
            variant: BannerVariant.t,
            message: l10n.motherAiFeedWelcomeBanner,
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: MotherAiFeedKeys.whisperCard,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFFFF7F9), colors.p50],
              ),
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: const Color(0xFFFF8FA3), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.motherAiFeedWhisperHeading,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: colors.p700,
                          ),
                        ),
                      ),
                      Tag(
                        label: l10n.motherAiFeedPartnershipTag,
                        variant: TagVariant.p,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.motherAiFeedWhisperBody(l10n.motherAiFeedChildOne),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_snap.whisperSent)
                    Text(
                      key: MotherAiFeedKeys.whisperSent,
                      l10n.motherAiFeedWhisperSentBanner,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.mintInk,
                      ),
                    )
                  else
                    PrimaryBtn(
                      key: MotherAiFeedKeys.whisperCta,
                      label: l10n.motherAiFeedWhisperCta,
                      variant: PrimaryBtnVariant.primary,
                      onPressed: _busy || !_canWhisper ? null : _sendWhisper,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
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
                    l10n.motherAiFeedSummariesHeading,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final item in _snap.items)
                    Padding(
                      key: MotherAiFeedKeys.item(item.id),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Text('🧠', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _itemTitle(l10n, item.titleKey),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: colors.ink,
                                  ),
                                ),
                                Text(
                                  _itemBody(l10n, item.bodyKey),
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
                            label: _tag(l10n, item.tagKey),
                            variant: item.tagKey == 'watch'
                                ? TagVariant.a
                                : TagVariant.g,
                          ),
                        ],
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
