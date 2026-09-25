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
import 'package:family_os/features/n14_studio/quran_progress_models.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n14_studio/studio_ux_bridge.dart';

/// Widget keys for SCR-FAT-072 acceptance.
abstract final class QuranProgressKeys {
  static const screen = Key('quran_progress_screen');
  static const loading = Key('quran_progress_loading');
  static const empty = Key('quran_progress_empty');
  static const body = Key('quran_progress_body');
  static const heroCard = Key('quran_progress_hero');
  static const downloadCard = Key('quran_progress_download');
  static const downloadCta = Key('quran_progress_download_cta');
  static const recitationCard = Key('quran_progress_recitation');
  static const playCta = Key('quran_progress_play');
  static const approveCta = Key('quran_progress_approve');
  static const whisperCta = Key('quran_progress_whisper');
  static const approvedBanner = Key('quran_progress_approved');
  static const planCard = Key('quran_progress_plan');
  static const cycleSurahCta = Key('quran_progress_cycle_surah');
  static const publishPlanCta = Key('quran_progress_publish_plan');
  static const observerHint = Key('quran_progress_observer');
  static const childLean = Key('quran_progress_child_lean');
  static const sosIconCta = Key('quran_progress_sos_icon');
}

/// SCR-FAT-072 — متابعة حفظ القرآن (Quran ward progress + offline download).
///
/// Prototype FAT-072 · minutes-only reward (ع-١) · partner+ approve ·
/// Rule 12/23 · P-4 SOS · empty → FAT-003.
class QuranProgressScreen extends StatefulWidget {
  const QuranProgressScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final QuranProgressRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<QuranProgressScreen> createState() => _QuranProgressScreenState();
}

class _QuranProgressScreenState extends State<QuranProgressScreen> {
  late QuranProgressRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  QuranProgressSnapshot _snap = const QuranProgressSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  bool get _canAct {
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
    _repo = widget.repository ?? Stage1StudioRuntime.quranProgress;
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

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _blockedToast(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.quranProgressObserverBlocked);
  }

  String _childName(AppLocalizations l10n) {
    return switch (_snap.childNameKey) {
      'childOne' => l10n.quranProgressChildOne,
      'childTwo' => l10n.quranProgressChildTwo,
      'childThree' => l10n.quranProgressChildThree,
      _ => l10n.quranProgressChildOne,
    };
  }

  String _surah(AppLocalizations l10n) {
    return switch (_snap.surahKey) {
      'naba' => l10n.quranProgressSurahNaba,
      'mulk' => l10n.quranProgressSurahMulk,
      _ => l10n.quranProgressSurahNaba,
    };
  }

  String _reciter(AppLocalizations l10n) {
    return switch (_snap.reciterKey) {
      'defaultReciter' => l10n.quranProgressReciterDefault,
      _ => l10n.quranProgressReciterDefault,
    };
  }

  String _audioSize(AppLocalizations l10n) {
    return switch (_snap.audioSizeKey) {
      'size184' => l10n.quranProgressAudioSize184,
      _ => l10n.quranProgressAudioSize184,
    };
  }

  Future<void> _cycleSurah() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final snap = await _repo.cyclePlanSurah();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
    AppToast.show(
      context,
      message: l10n.quranProgressCycleSurahToast(_surah(l10n)),
    );
  }

  Future<void> _publishPlan() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    await _repo.publishPlanToChild();
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(
      context,
      message: l10n.quranProgressPublishPlanToast(
        _surah(l10n),
        _snap.rewardMinutes,
      ),
    );
  }

  Future<void> _togglePlay() async {
    final snap = await _repo.togglePlay();
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final snap = await _repo.approveRecitation();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
    AppToast.show(
      context,
      message: l10n.quranProgressApproveToast(
        _childName(l10n),
        snap.rewardMinutes,
      ),
    );
  }

  Future<void> _whisper() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    await _repo.whisperEncourage();
    if (!mounted) return;
    AppToast.show(
      context,
      message: l10n.quranProgressWhisperToast(_childName(l10n)),
    );
  }

  Future<void> _download() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    await _repo.requestDownload();
    if (!mounted) return;
    AppToast.show(
      context,
      message: l10n.quranProgressDownloadToast(_childName(l10n)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: QuranProgressKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.quranProgressTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: QuranProgressKeys.sosIconCta,
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
      body: SafeArea(child: _buildBody(context, l10n, colors)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: QuranProgressKeys.childLean,
        title: l10n.quranProgressChildLeanTitle,
        message: l10n.quranProgressChildLeanMessage,
        actionLabel: l10n.quranProgressSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: QuranProgressKeys.loading,
        child: Semantics(
          label: l10n.quranProgressLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: QuranProgressKeys.empty,
        title: l10n.quranProgressEmptyTitle,
        message: l10n.quranProgressEmptyMessage,
        actionLabel: l10n.quranProgressEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final child = _childName(l10n);
    final surah = _surah(l10n);
    final approved = _snap.recitationStatus == QuranRecitationStatus.approved;
    final hasRecitation = _snap.recitationStatus != QuranRecitationStatus.none;

    return SingleChildScrollView(
      key: QuranProgressKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: QuranProgressKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.quranProgressObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.quranProgressHeading(child),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: QuranProgressKeys.heroCard,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B3A31), Color(0xFF0E241E)],
              ),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Tag(
                        label: l10n.quranProgressActiveWardTag,
                        variant: TagVariant.t,
                      ),
                      const Spacer(),
                      if (_snap.offlineReady)
                        Tag(
                          label: l10n.quranProgressOfflineTag,
                          variant: TagVariant.g,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.quranProgressSurahTitle(surah),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l10n.quranProgressAyahRange(
                      _snap.fromAyah,
                      _snap.toAyah,
                      _reciter(l10n),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _snap.progress,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      color: colors.mint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        l10n.quranProgressCompleted(
                          _snap.completedAyahs,
                          _snap.toAyah,
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.quranProgressStreak(_snap.streakDays),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: QuranProgressKeys.downloadCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.mint, width: 1.5),
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
                          l10n.quranProgressDownloadHeading(child),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: colors.mintInk,
                          ),
                        ),
                      ),
                      Tag(
                        label: l10n.quranProgressInstalledTag,
                        variant: TagVariant.g,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.quranProgressDownloadBody(
                      surah,
                      _audioSize(l10n),
                      child,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryBtn(
                    key: QuranProgressKeys.downloadCta,
                    label: l10n.quranProgressDownloadCta(child),
                    variant: PrimaryBtnVariant.mint,
                    onPressed: _canAct ? _download : null,
                  ),
                ],
              ),
            ),
          ),
          if (hasRecitation) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              key: QuranProgressKeys.recitationCard,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.p400, width: 2),
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
                            l10n.quranProgressRecitationHeading,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: colors.p700,
                            ),
                          ),
                        ),
                        Tag(
                          label: approved
                              ? l10n.quranProgressApprovedTag
                              : l10n.quranProgressNewTag,
                          variant: TagVariant.g,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.quranProgressRecitationSub(child, surah),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.p50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                        child: Row(
                          children: [
                            IconButton(
                              key: QuranProgressKeys.playCta,
                              tooltip: l10n.quranProgressPlaySemantics,
                              onPressed: _togglePlay,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: Icon(
                                _snap.playingAudio
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: colors.p600,
                                size: 36,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                l10n.quranProgressRecitationClip(child, surah),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.ink,
                                ),
                              ),
                            ),
                            Text(
                              l10n.quranProgressClipDuration,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (approved)
                      Padding(
                        key: QuranProgressKeys.approvedBanner,
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          l10n.quranProgressApprovedBanner(_snap.rewardMinutes),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.mintInk,
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryBtn(
                              key: QuranProgressKeys.approveCta,
                              label: l10n.quranProgressApproveCta(
                                _snap.rewardMinutes,
                              ),
                              variant: PrimaryBtnVariant.mint,
                              onPressed: _busy || !_canAct ? null : _approve,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PrimaryBtn(
                              key: QuranProgressKeys.whisperCta,
                              label: l10n.quranProgressWhisperCta,
                              variant: PrimaryBtnVariant.ghost,
                              onPressed: !_canAct ? null : _whisper,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          DecoratedBox(
            key: QuranProgressKeys.planCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.quranProgressPlanHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PlanRow(
                    emoji: '📖',
                    title: l10n.quranProgressPlanSurah,
                    value: surah,
                    colors: colors,
                  ),
                  _PlanRow(
                    emoji: '🎙️',
                    title: l10n.quranProgressPlanReciter,
                    value: _reciter(l10n),
                    colors: colors,
                  ),
                  _PlanRow(
                    emoji: '🎁',
                    title: l10n.quranProgressPlanReward,
                    value: l10n.quranProgressPlanRewardValue(
                      _snap.rewardMinutes,
                    ),
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  PrimaryBtn(
                    key: QuranProgressKeys.cycleSurahCta,
                    label: l10n.quranProgressCycleSurahCta,
                    variant: PrimaryBtnVariant.ghost,
                    onPressed: _busy ? null : _cycleSurah,
                  ),
                  const SizedBox(height: 8),
                  PrimaryBtn(
                    key: QuranProgressKeys.publishPlanCta,
                    label: l10n.quranProgressPublishPlanCta,
                    onPressed: _busy ? null : _publishPlan,
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

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.emoji,
    required this.title,
    required this.value,
    required this.colors,
  });

  final String emoji;
  final String title;
  final String value;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
