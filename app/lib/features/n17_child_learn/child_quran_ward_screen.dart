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
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_models.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

abstract final class ChildQuranWardKeys {
  static const screen = Key('child_quran_ward_screen');
  static const loading = Key('child_quran_ward_loading');
  static const empty = Key('child_quran_ward_empty');
  static const body = Key('child_quran_ward_body');
  static const giftBanner = Key('child_quran_ward_gift');
  static const hero = Key('child_quran_ward_hero');
  static const ayahCard = Key('child_quran_ward_ayah');
  static const playCta = Key('child_quran_ward_play');
  static const recordCta = Key('child_quran_ward_record');
  static const statusCard = Key('child_quran_ward_status');
  static const parentLean = Key('child_quran_ward_parent_lean');
  static const sosIconCta = Key('child_quran_ward_sos_icon');
}

/// SCR-CHD-025 — وردي حفظ وتلاوة (licensed mushaf · minutes reward).
class ChildQuranWardScreen extends StatefulWidget {
  const ChildQuranWardScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildQuranWardRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildQuranWardScreen> createState() => _ChildQuranWardScreenState();
}

class _ChildQuranWardScreenState extends State<ChildQuranWardScreen> {
  late ChildQuranWardRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildQuranWardSnapshot _snap = const ChildQuranWardSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.quranWard;
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

  String _surah(AppLocalizations l10n) => switch (_snap.surahKey) {
    'mulk' => l10n.childQuranWardSurahMulk,
    'naba' => l10n.childQuranWardSurahNaba,
    _ => l10n.childQuranWardSurahMulk,
  };

  String _reciter(AppLocalizations l10n) => switch (_snap.reciterKey) {
    'defaultReciter' => l10n.childQuranWardReciterDefault,
    _ => l10n.childQuranWardReciterDefault,
  };

  /// Licensed mushaf sample — never AI-generated (Rule 26 / S-EDU-037).
  String _ayah(AppLocalizations l10n) => switch (_snap.ayahKey) {
    'mulk16' => l10n.childQuranWardAyahMulk16,
    'naba1' => l10n.childQuranWardAyahNaba1,
    _ => l10n.childQuranWardAyahMulk16,
  };

  Future<void> _play() async {
    final snap = await _repo.togglePlay();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childQuranWardPlayToast,
    );
  }

  Future<void> _record() async {
    final snap = await _repo.submitRecitation();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).childQuranWardRecordToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildQuranWardKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childQuranWardTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildQuranWardKeys.sosIconCta,
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
        key: ChildQuranWardKeys.parentLean,
        title: l10n.childQuranWardParentLeanTitle,
        message: l10n.childQuranWardParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildQuranWardKeys.loading,
        child: Semantics(
          label: l10n.childQuranWardLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildQuranWardKeys.empty,
        title: l10n.childQuranWardEmptyTitle,
        message: l10n.childQuranWardEmptyMessage,
        actionLabel: l10n.childQuranWardEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final approved =
        _snap.recitationStatus == ChildWardRecitationStatus.approved;
    final sent = _snap.recitationStatus == ChildWardRecitationStatus.sent;

    return SingleChildScrollView(
      key: ChildQuranWardKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_snap.giftCount > 0) ...[
            BannerNote(
              key: ChildQuranWardKeys.giftBanner,
              variant: BannerVariant.g,
              message: l10n.childQuranWardGiftBanner(_snap.giftCount),
            ),
            const SizedBox(height: 10),
          ],
          DecoratedBox(
            key: ChildQuranWardKeys.hero,
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
                      Expanded(
                        child: Text(
                          l10n.childQuranWardParentsSet,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      if (_snap.offlineReady)
                        Tag(
                          label: l10n.childQuranWardOfflineTag,
                          variant: TagVariant.g,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.childQuranWardSurahTitle(_surah(l10n)),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l10n.childQuranWardAyahRange(
                      _snap.fromAyah,
                      _snap.toAyah,
                      _reciter(l10n),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.childQuranWardReward(_snap.rewardMinutes),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.mint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          BannerNote(
            variant: BannerVariant.t,
            message: l10n.childQuranWardOfflineNote,
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: ChildQuranWardKeys.ayahCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                children: [
                  Text(
                    l10n.childQuranWardVoiceOf(_reciter(l10n)),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ayah(l10n),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      height: 2.2,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryBtn(
                    key: ChildQuranWardKeys.playCta,
                    label: l10n.childQuranWardPlayCta,
                    variant: PrimaryBtnVariant.teal,
                    onPressed: _play,
                  ),
                  const SizedBox(height: 8),
                  PrimaryBtn(
                    key: ChildQuranWardKeys.recordCta,
                    label: l10n.childQuranWardRecordCta,
                    variant: PrimaryBtnVariant.sec,
                    onPressed: _record,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: ChildQuranWardKeys.statusCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.childQuranWardStatusHeading,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        Text(
                          approved
                              ? l10n.childQuranWardStatusApproved(
                                  _snap.rewardMinutes,
                                )
                              : sent
                              ? l10n.childQuranWardStatusSent
                              : l10n.childQuranWardStatusNone,
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
                    label: approved
                        ? l10n.childQuranWardTagApproved
                        : sent
                        ? l10n.childQuranWardTagSent
                        : l10n.childQuranWardTagNew,
                    variant: approved ? TagVariant.g : TagVariant.t,
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
