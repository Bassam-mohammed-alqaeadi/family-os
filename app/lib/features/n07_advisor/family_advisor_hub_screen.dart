import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_models.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_repository.dart';

abstract final class FamilyAdvisorHubKeys {
  static const screen = Key('family_advisor_hub_screen');
  static const loading = Key('family_advisor_hub_loading');
  static const empty = Key('family_advisor_hub_empty');
  static const body = Key('family_advisor_hub_body');
  static const suggestions = Key('family_advisor_hub_suggestions');
  static const capabilities = Key('family_advisor_hub_capabilities');
  static const sovereignty = Key('family_advisor_hub_sovereignty');
  static const honesty = Key('family_advisor_hub_honesty');
  static const askField = Key('family_advisor_hub_ask');
  static const askSend = Key('family_advisor_hub_ask_send');
  static const childLean = Key('family_advisor_hub_child_lean');
  static const sosIconCta = Key('family_advisor_hub_sos_icon');

  static Key chip(String id) => Key('family_advisor_hub_chip_$id');
  static Key cap(String id) => Key('family_advisor_hub_cap_$id');
}

/// SCR-FAT-074 — عقل عائلتي / مستشار العائلة hub.
class FamilyAdvisorHubScreen extends StatefulWidget {
  const FamilyAdvisorHubScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final FamilyAdvisorHubRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<FamilyAdvisorHubScreen> createState() => _FamilyAdvisorHubScreenState();
}

class _FamilyAdvisorHubScreenState extends State<FamilyAdvisorHubScreen> {
  late FamilyAdvisorHubRepository _repo;
  late final SosFireService _sos;
  final _askCtrl = TextEditingController();
  var _sosBusy = false;
  var _loading = true;
  FamilyAdvisorHubSnapshot _snap = const FamilyAdvisorHubSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;
  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1FamilyAdvisorHubRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _askCtrl.dispose();
    super.dispose();
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

  String _chipLabel(AppLocalizations l10n, String key) => switch (key) {
    'daySummary' => l10n.familyAdvisorHubChipDay,
    'weeklyReport' => l10n.familyAdvisorHubChipWeekly,
    'familyActivity' => l10n.familyAdvisorHubChipActivity,
    'patterns' => l10n.familyAdvisorHubChipPatterns,
    _ => l10n.familyAdvisorHubChipWeekly,
  };

  String _capTitle(AppLocalizations l10n, String key) => switch (key) {
    'voice' => l10n.familyAdvisorHubCapVoice,
    'delegate' => l10n.familyAdvisorHubCapDelegate,
    'maps' => l10n.familyAdvisorHubCapMaps,
    'motherFeed' => l10n.familyAdvisorHubCapMother,
    'limits' => l10n.familyAdvisorHubCapLimits,
    'agentLog' => l10n.familyAdvisorHubCapAgentLog,
    _ => key,
  };

  String _capSub(AppLocalizations l10n, String key) => switch (key) {
    'voiceSub' => l10n.familyAdvisorHubCapVoiceSub,
    'delegateSub' => l10n.familyAdvisorHubCapDelegateSub,
    'mapsSub' => l10n.familyAdvisorHubCapMapsSub,
    'motherFeedSub' => l10n.familyAdvisorHubCapMotherSub,
    'limitsSub' => l10n.familyAdvisorHubCapLimitsSub,
    'agentLogSub' => l10n.familyAdvisorHubCapAgentLogSub,
    _ => key,
  };

  void _onChip(AdvisorSuggestionChip chip) {
    final l10n = AppLocalizations.of(context);
    if (chip.navigateTo != null) {
      _go(chip.navigateTo!);
      return;
    }
    final msg = switch (chip.sheetKey) {
      'daySummary' => l10n.familyAdvisorHubSheetDay,
      'activity' => l10n.familyAdvisorHubSheetActivity,
      _ => l10n.familyAdvisorHubSheetDay,
    };
    AppToast.show(context, message: msg);
  }

  Future<void> _sendAsk() async {
    final text = _askCtrl.text.trim();
    if (text.isEmpty) return;
    await _repo.askFreeText(text);
    if (!mounted) return;
    _askCtrl.clear();
    AppToast.show(
      context,
      message: AppLocalizations.of(context).familyAdvisorHubAskToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: FamilyAdvisorHubKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.familyAdvisorHubTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: FamilyAdvisorHubKeys.sosIconCta,
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
        key: FamilyAdvisorHubKeys.childLean,
        title: l10n.familyAdvisorHubChildLeanTitle,
        message: l10n.familyAdvisorHubChildLeanMessage,
        actionLabel: l10n.familyAdvisorHubSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }
    if (_loading) {
      return Center(
        key: FamilyAdvisorHubKeys.loading,
        child: Semantics(
          label: l10n.familyAdvisorHubLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: FamilyAdvisorHubKeys.empty,
        title: l10n.familyAdvisorHubEmptyTitle,
        message: l10n.familyAdvisorHubEmptyMessage,
        actionLabel: l10n.familyAdvisorHubEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: FamilyAdvisorHubKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.familyAdvisorHubGreeting,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.familyAdvisorHubSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            key: FamilyAdvisorHubKeys.suggestions,
            children: [
              for (final c in _snap.suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: colors.p50,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      key: FamilyAdvisorHubKeys.chip(c.id),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _onChip(c),
                      child: Semantics(
                        button: true,
                        label: _chipLabel(l10n, c.labelKey),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              _chipLabel(l10n, c.labelKey),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: colors.p700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _CapCard(
            key: FamilyAdvisorHubKeys.capabilities,
            heading: l10n.familyAdvisorHubCapsHeading,
            rows: _snap.capabilities,
            titleOf: (r) => _capTitle(l10n, r.titleKey),
            subOf: (r) => _capSub(l10n, r.subKey),
            onTap: (r) => _go(r.navigateTo),
            colors: colors,
            radii: radii,
          ),
          const SizedBox(height: 10),
          _CapCard(
            key: FamilyAdvisorHubKeys.sovereignty,
            heading: l10n.familyAdvisorHubSovHeading,
            rows: _snap.sovereigntyRows,
            titleOf: (r) => _capTitle(l10n, r.titleKey),
            subOf: (r) => _capSub(l10n, r.subKey),
            onTap: (r) => _go(r.navigateTo),
            colors: colors,
            radii: radii,
          ),
          if (_snap.honestyShown) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              key: FamilyAdvisorHubKeys.honesty,
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
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.p100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Text(
                            l10n.familyAdvisorHubHonestyQ,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.p50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Text(
                          l10n.familyAdvisorHubHonestyA,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: FamilyAdvisorHubKeys.askField,
                  controller: _askCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.familyAdvisorHubAskHint,
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: FamilyAdvisorHubKeys.askSend,
                tooltip: l10n.familyAdvisorHubAskSendSemantics,
                onPressed: _sendAsk,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.arrow_upward, color: colors.p600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.familyAdvisorHubFooter,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapCard extends StatelessWidget {
  const _CapCard({
    super.key,
    required this.heading,
    required this.rows,
    required this.titleOf,
    required this.subOf,
    required this.onTap,
    required this.colors,
    required this.radii,
  });

  final String heading;
  final List<AdvisorCapabilityRow> rows;
  final String Function(AdvisorCapabilityRow) titleOf;
  final String Function(AdvisorCapabilityRow) subOf;
  final void Function(AdvisorCapabilityRow) onTap;
  final FamilyColors colors;
  final FamilyRadii radii;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
              heading,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            for (final r in rows)
              ListTile(
                key: FamilyAdvisorHubKeys.cap(r.id),
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                title: Text(
                  titleOf(r),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                subtitle: Text(
                  subOf(r),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
                trailing: Icon(Icons.chevron_left, color: colors.ink2),
                onTap: () => onTap(r),
              ),
          ],
        ),
      ),
    );
  }
}
