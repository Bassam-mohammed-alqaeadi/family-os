import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n07_advisor/advisor_voice_models.dart';
import 'package:family_os/features/n07_advisor/advisor_voice_repository.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

abstract final class AdvisorVoiceKeys {
  static const screen = Key('advisor_voice_screen');
  static const loading = Key('advisor_voice_loading');
  static const empty = Key('advisor_voice_empty');
  static const body = Key('advisor_voice_body');
  static const mic = Key('advisor_voice_mic');
  static const talkCta = Key('advisor_voice_talk');
  static const lastChat = Key('advisor_voice_last');
  static const honesty = Key('advisor_voice_honesty');
  static const childLean = Key('advisor_voice_child_lean');
  static const sosIconCta = Key('advisor_voice_sos_icon');
}

/// SCR-FAT-083 — المحادثة الصوتية مع مستشار العائلة.
class AdvisorVoiceScreen extends StatefulWidget {
  const AdvisorVoiceScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final AdvisorVoiceRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<AdvisorVoiceScreen> createState() => _AdvisorVoiceScreenState();
}

class _AdvisorVoiceScreenState extends State<AdvisorVoiceScreen> {
  late AdvisorVoiceRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  AdvisorVoiceSnapshot _snap = const AdvisorVoiceSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1ReportsRuntime.advisorVoice;
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

  String _user(AppLocalizations l10n, String key) => switch (key) {
    'qHomework' => l10n.advisorVoiceUserHomework,
    _ => key,
  };

  String _reply(AppLocalizations l10n, String key) => switch (key) {
    'aHomework' => l10n.advisorVoiceReplyHomework,
    _ => key,
  };

  Future<void> _talk() async {
    final snap = await _repo.pressTalk();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).advisorVoiceListeningToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: AdvisorVoiceKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.advisorVoiceTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: AdvisorVoiceKeys.sosIconCta,
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
        key: AdvisorVoiceKeys.childLean,
        title: l10n.advisorVoiceChildLeanTitle,
        message: l10n.advisorVoiceChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: AdvisorVoiceKeys.loading,
        child: Semantics(
          label: l10n.advisorVoiceLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: AdvisorVoiceKeys.empty,
        title: l10n.advisorVoiceEmptyTitle,
        message: l10n.advisorVoiceEmptyMessage,
        actionLabel: l10n.advisorVoiceEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: AdvisorVoiceKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          DecoratedBox(
            key: AdvisorVoiceKeys.mic,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [colors.teal, colors.teal600]),
            ),
            child: const SizedBox(
              width: 150,
              height: 150,
              child: Center(child: Text('🎙', style: TextStyle(fontSize: 56))),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.advisorVoiceHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 14),
          PrimaryBtn(
            key: AdvisorVoiceKeys.talkCta,
            label: l10n.advisorVoiceTalkCta,
            variant: PrimaryBtnVariant.teal,
            onPressed: _talk,
          ),
          if (_snap.lastTurns.isNotEmpty) ...[
            const SizedBox(height: 14),
            DecoratedBox(
              key: AdvisorVoiceKeys.lastChat,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.advisorVoiceLastHeading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    for (final t in _snap.lastTurns) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          _user(l10n, t.userKey),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.teal600,
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _reply(l10n, t.replyKey),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          BannerNote(
            key: AdvisorVoiceKeys.honesty,
            variant: BannerVariant.t,
            message: l10n.advisorVoiceHonestyBanner,
          ),
        ],
      ),
    );
  }
}
