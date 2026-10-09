import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/settings_persist_toggle.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';
import 'package:family_os/core/policy/sos_settings.dart';
import 'package:family_os/core/sos_final/sos_prefs_local_persistence.dart';
import 'package:family_os/core/sos_final/sos_readiness.dart';

/// Widget keys for SCR-FAT-028 / SET-020 / SET-021 acceptance.
abstract final class EmergencySetupKeys {
  static const protocolBanner = Key('sos_ladder_protocol_banner');
  static const sosReceiptBanner = Key('sos_receipt_cannot_disable_banner');
  static const ladderList = Key('sos_ladder_list');
  static const rung1Section = Key('sos_ladder_rung1');
  static const addBackup = Key('sos_ladder_add_backup');
  static const inlineError = Key('sos_ladder_inline_error');
  static const maxReachedBanner = Key('sos_ladder_max_reached_banner');
  static const readinessCard = Key('sos_ladder_readiness_card');
  static const panicQuietToggle = Key('sos_panic_quiet_toggle');
  static const readOnlyLean = Key('sos_ladder_read_only_lean');
  static const unverifiedNote = Key('sos_ladder_unverified_note');
  static const verifyHonesty = Key('sos_ladder_verify_local_honesty');
  static const backupSheet = Key('sos_ladder_backup_sheet');
  static const backupSave = Key('sos_ladder_backup_save');
  static const nationalNumberField = Key('sos_national_number_field');
  static const audioVideoToggle = Key('sos_audio_video_toggle');
  static const muteSosToggle = Key('sos_mute_toggle');

  static Key parentRow(String memberId) => Key('sos_ladder_parent_$memberId');
  static Key parentSwitch(String memberId) =>
      Key('sos_ladder_parent_switch_$memberId');
  static Key parentRemove(String memberId) =>
      Key('sos_ladder_parent_remove_$memberId');
  static Key backupRow(String id) => Key('sos_ladder_backup_$id');
  static Key backupSwitch(String id) => Key('sos_ladder_backup_switch_$id');
  static Key backupRemove(String id) => Key('sos_ladder_backup_remove_$id');
  static Key backupEdit(String id) => Key('sos_ladder_backup_edit_$id');
  static Key backupVerify(String id) => Key('sos_ladder_backup_verify_$id');
  static Key backupPriorityUp(String id) =>
      Key('sos_ladder_backup_priority_up_$id');
  static Key backupPriorityDown(String id) =>
      Key('sos_ladder_backup_priority_down_$id');
  static const partnerSummary = Key('sos_ladder_partner_summary');

  static const childEscalationSection = Key('sos_child_escalation_section');
  static const childEscalationEmpty = Key('sos_child_escalation_empty');
  static const childEscalationSmsHonesty = Key(
    'sos_child_escalation_sms_honesty',
  );
  static Key childEscalationCard(String childId) =>
      Key('sos_child_escalation_card_$childId');
  static Key childEscalationEnable(String childId) =>
      Key('sos_child_escalation_enable_$childId');
  static Key childEscalationUseBackups(String childId) =>
      Key('sos_child_escalation_use_backups_$childId');
  static Key childEscalationPrepareSms(String childId) =>
      Key('sos_child_escalation_prepare_sms_$childId');
  static Key childEscalationDelay(String childId) =>
      Key('sos_child_escalation_delay_$childId');
}

class EmergencySetupScreen extends StatefulWidget {
  const EmergencySetupScreen({
    super.key,
    this.familyId = SosLadder.defaultFamilyId,
    this.repository,
    this.roleOverride,
    this.motherLevel,
    this.settings,
    this.childrenOverride,
  });

  final String familyId;
  final SosLadderRepository? repository;
  final AppRole? roleOverride;
  final MotherLevel? motherLevel;
  final SosSettingsStore? settings;
  final List<RosterChildRef>? childrenOverride;

  @override
  EmergencySetupScreenState createState() => EmergencySetupScreenState();
}

class EmergencySetupScreenState extends State<EmergencySetupScreen> {
  SosLadderRepository? _repository;
  late SosSettingsStore _settings;
  late SosLadder _ladder;
  var _loading = true;
  var _localPersistenceOk = true;
  String? _inlineError;

  static const _escalationDelays = [30, 60, 120, 300];

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  MotherLevel get _motherLevel =>
      widget.motherLevel ??
      resolveAuthorizationContext(context, fallbackRole: _role).motherLevel;

  SosActor get _actor => _role == AppRole.mother
      ? SosActor.mother(_motherLevel)
      : (_role == AppRole.child ? SosActor.child() : SosActor.primary());

  bool get _canConfigure => SosRoleActions.canConfigure(_actor);
  bool get _atBackupLimit => _ladder.backups.length >= kSosMaxBackupContacts;
  bool get _hasUnverifiedArmed => _ladder.backups.any(
    (b) => b.enabled && b.verification != SosVerificationStatus.verified,
  );

  List<RosterChildRef> get _rosterChildren =>
      widget.childrenOverride ?? activeFamilyRosterChildren();

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? stage1SosSettingsStore;
    _ladder = SosLadder.defaults(familyId: widget.familyId);
    if (widget.repository != null) {
      _repository = widget.repository;
      _load();
    } else {
      _bootstrapLocal();
    }
  }

  Future<void> _bootstrapLocal() async {
    try {
      await SosPrefsRuntime.ensureOpen();
      if (SosPrefsRuntime.unavailable || SosPrefsRuntime.ladder == null) {
        throw StateError('SosPrefsRuntime unavailable');
      }
      _repository = SosPrefsRuntime.ladder;
      if (widget.settings == null && SosPrefsRuntime.settings != null) {
        _settings = SosPrefsRuntime.settings!;
      }
      _localPersistenceOk = true;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _repository = null;
        _localPersistenceOk = false;
        _loading = false;
      });
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    if (_repository == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final loaded = await _repository!.load(widget.familyId);
    if (!mounted) return;
    setState(() {
      _ladder = loaded;
      _loading = false;
      _inlineError = null;
    });
  }

  /// Test / defensive seam — illegal remove surfaces inline ARB error.
  Future<void> attemptRemove(String memberId) async {
    final l10n = AppLocalizations.of(context);
    try {
      final next = await _repository!.removeFromRung1(
        memberId,
        familyId: widget.familyId,
      );
      if (!mounted) return;
      setState(() {
        _ladder = next;
        _inlineError = null;
      });
    } on SosLadderValidationException {
      if (!mounted) return;
      setState(() => _inlineError = l10n.sosLadderParentImmovableError);
    }
  }

  Future<void> _onBackupToggle(String id, bool enabled) async {
    if (!_canConfigure) return;
    try {
      final next = await _repository!.setEmergencyContactEnabled(
        id,
        enabled,
        familyId: widget.familyId,
      );
      if (mounted) {
        setState(() {
          _ladder = next;
          _inlineError = null;
        });
      }
    } on SosLadderValidationException {
      if (mounted) {
        setState(
          () => _inlineError = AppLocalizations.of(
            context,
          ).sosLadderParentImmovableError,
        );
      }
    }
  }

  Future<void> _onBackupRemove(String id) async {
    if (!_canConfigure) return;
    try {
      final next = await _repository!.removeBackup(
        id,
        familyId: widget.familyId,
      );
      if (mounted) {
        setState(() {
          _ladder = next;
          _inlineError = null;
        });
      }
    } on SosLadderValidationException {
      if (mounted) {
        setState(
          () => _inlineError = AppLocalizations.of(
            context,
          ).sosLadderParentImmovableError,
        );
      }
    }
  }

  Future<void> _upsertContact(SosBackupContact contact) async {
    if (!_canConfigure) return;
    final l10n = AppLocalizations.of(context);
    try {
      final next = await _repository!.upsertBackup(
        contact,
        familyId: widget.familyId,
      );
      if (mounted) {
        setState(() {
          _ladder = next;
          _inlineError = null;
        });
      }
    } on SosLadderValidationException catch (e) {
      if (mounted) {
        setState(() {
          _inlineError = e.code == SosLadderValidationCode.backupLimitExceeded
              ? l10n.sosLadderMaxBackupsError
              : l10n.sosLadderParentImmovableError;
        });
      }
    }
  }

  Future<void> _openBackupSheet({SosBackupContact? existing}) async {
    if (!_canConfigure) return;
    if (existing == null && _atBackupLimit) return;
    final l10n = AppLocalizations.of(context);
    final saved = await showModalBottomSheet<SosBackupContact>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BackupEditorSheet(
        key: EmergencySetupKeys.backupSheet,
        l10n: l10n,
        existing: existing,
        nextPriority: existing?.priority ?? (_ladder.backups.length + 1),
        nextId: existing?.id ?? 'backup_${_ladder.backups.length + 1}',
      ),
    );
    if (saved != null && mounted) await _upsertContact(saved);
  }

  Future<void> _advanceVerification(SosBackupContact contact) async {
    if (!_canConfigure) return;
    final nextStatus = switch (contact.verification) {
      SosVerificationStatus.unverified ||
      SosVerificationStatus.failed ||
      SosVerificationStatus.revoked => SosVerificationStatus.pending,
      SosVerificationStatus.pending => SosVerificationStatus.verified,
      SosVerificationStatus.verified => SosVerificationStatus.revoked,
    };
    await _upsertContact(contact.copyWith(verification: nextStatus));
  }

  Future<void> _persistPanicQuiet(bool next) async {
    _settings.setPanicQuietPreferred(next);
    if (mounted) setState(() {});
  }

  Future<void> _persistChildEscalation(
    String childId,
    ChildSosEscalationPrefs prefs,
  ) async {
    _settings.setChildEscalation(childId, prefs);
    if (mounted) setState(() {});
  }

  Future<void> _moveBackupPriority(String id, int delta) async {
    if (!_canConfigure || _repository == null) return;
    try {
      final next = await _repository!.moveBackupPriority(
        id,
        delta,
        familyId: widget.familyId,
      );
      if (mounted) {
        setState(() {
          _ladder = next;
          _inlineError = null;
        });
      }
    } on SosLadderValidationException {
      if (mounted) {
        setState(
          () => _inlineError = AppLocalizations.of(
            context,
          ).sosLadderParentImmovableError,
        );
      }
    }
  }

  SosReadinessSnapshot _evaluateReadiness() {
    final hasPhone = _ladder.backups.any((b) => b.phoneE164.trim().isNotEmpty);
    return SosReadinessEvaluator.evaluate(
      SosReadinessInputs(
        ladder: _ladder,
        settings: _settings.settings,
        childLinked: true,
        localPersistenceOk: _localPersistenceOk && _repository != null,
        pushCapability: CapabilityStatus.mockRemote,
        smsConfigured: hasPhone,
        callConfigured: hasPhone,
        locationClass: SosLocationClass.unavailable,
        breakGlassApplicable: SosRoleActions.canBreakGlass(_actor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final snap = _loading ? null : _evaluateReadiness();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.emergencySetupTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        iconTheme: IconThemeData(color: colors.ink),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.p600))
          : !_canConfigure
          ? _PartnerReadOnlySummary(
              key: EmergencySetupKeys.readOnlyLean,
              l10n: l10n,
              colors: colors,
              ladder: _ladder,
              snap: snap,
            )
          : SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BannerNote(
                    key: EmergencySetupKeys.protocolBanner,
                    message: l10n.sosLadderProtocolBanner,
                  ),
                  const SizedBox(height: 8),
                  BannerNote(
                    key: EmergencySetupKeys.sosReceiptBanner,
                    variant: BannerVariant.p,
                    message: l10n.sosReceiptCannotDisableBanner,
                  ),
                  const SizedBox(height: 24),
                  _DashboardSectionHeader(
                    title: l10n.sosDashboardReadinessTitle,
                    icon: Icons.speed_rounded,
                    colors: colors,
                  ),
                  if (snap != null) ...[
                    KeyedSubtree(
                      key: EmergencySetupKeys.readinessCard,
                      child: _ReadinessGrid(
                        rows: snap.rows,
                        l10n: l10n,
                        colors: colors,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BannerNote(
                      variant: BannerVariant.t,
                      message: l10n.sosReadinessBody,
                    ),
                  ],
                  const SizedBox(height: 32),
                  _DashboardSectionHeader(
                    title: l10n.sosLadderHeading,
                    subtitle: l10n.sosLadderSubtitle,
                    icon: Icons.shield_rounded,
                    colors: colors,
                  ),
                  BannerNote(
                    key: EmergencySetupKeys.verifyHonesty,
                    variant: BannerVariant.t,
                    message: l10n.sosLadderVerifyLocalHonesty,
                  ),
                  const SizedBox(height: 12),
                  if (_hasUnverifiedArmed) ...[
                    BannerNote(
                      key: EmergencySetupKeys.unverifiedNote,
                      variant: BannerVariant.a,
                      message: l10n.sosLadderUnverifiedEscalationNote,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_inlineError != null) ...[
                    Text(
                      _inlineError!,
                      key: EmergencySetupKeys.inlineError,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.coral,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_atBackupLimit) ...[
                    BannerNote(
                      key: EmergencySetupKeys.maxReachedBanner,
                      variant: BannerVariant.t,
                      message: l10n.sosLadderMaxBackupsError,
                    ),
                    const SizedBox(height: 12),
                  ],
                  KeyedSubtree(
                    key: EmergencySetupKeys.ladderList,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.p50.withValues(alpha: 0.5),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  l10n.sosLadderRung1SectionTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: colors.p600,
                                  ),
                                ),
                              ),
                              KeyedSubtree(
                                key: EmergencySetupKeys.rung1Section,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      for (final id in _ladder.rung1MemberIds)
                                        _LockedParentCard(
                                          memberId: id,
                                          label: id == 'father'
                                              ? l10n.sosLadderFatherLabel
                                              : l10n.sosLadderMotherLabel,
                                          lockedHint:
                                              l10n.sosLadderRung1LockedHint,
                                          mandatoryTag:
                                              l10n.sosLadderMandatoryTag,
                                          colors: colors,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final contact in _ladder.backupsByPriority) ...[
                          KeyedSubtree(
                            key: EmergencySetupKeys.backupRow(contact.id),
                            child: _DashboardBackupCard(
                              contact: contact,
                              l10n: l10n,
                              colors: colors,
                              canMoveUp: contact.priority > 1,
                              canMoveDown:
                                  contact.priority < _ladder.backups.length,
                              onToggle: (v) => _onBackupToggle(contact.id, v),
                              onEdit: () => _openBackupSheet(existing: contact),
                              onDelete: () => _onBackupRemove(contact.id),
                              onVerify: () => _advanceVerification(contact),
                              onPriorityUp: () =>
                                  _moveBackupPriority(contact.id, -1),
                              onPriorityDown: () =>
                                  _moveBackupPriority(contact.id, 1),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (!_atBackupLimit)
                          Semantics(
                            button: true,
                            label: l10n.sosLadderAddBackup,
                            child: InkWell(
                              key: EmergencySetupKeys.addBackup,
                              onTap: () => _openBackupSheet(),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colors.p600.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: colors.p600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.sosLadderAddBackup,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: colors.p600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _DashboardSectionHeader(
                    title: l10n.sosPanicQuietTitle,
                    icon: Icons.do_not_disturb_on_rounded,
                    colors: colors,
                  ),
                  Semantics(
                    container: true,
                    label: l10n.sosPanicQuietSubtitle,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.amber, width: 1.5),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: SettingsPersistToggle(
                        title: l10n.sosPanicQuietTitle,
                        subtitle: l10n.sosPanicQuietSubtitle,
                        value: _settings.settings.panicQuietPreferred,
                        switchKey: EmergencySetupKeys.panicQuietToggle,
                        successMessage: l10n.sosPanicQuietTitle,
                        errorMessage: l10n.settingsPersistError,
                        onPersist: _persistPanicQuiet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  KeyedSubtree(
                    key: EmergencySetupKeys.childEscalationSection,
                    child: _ChildEscalationDashboard(
                      l10n: l10n,
                      colors: colors,
                      children: _rosterChildren,
                      settings: _settings.settings,
                      delays: _escalationDelays,
                      onPersist: _persistChildEscalation,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: subtitle != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(icon, size: 20, color: colors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.ink2,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessGrid extends StatelessWidget {
  const _ReadinessGrid({
    required this.rows,
    required this.l10n,
    required this.colors,
  });

  final List<SosReadinessRow> rows;
  final AppLocalizations l10n;
  final FamilyColors colors;

  String _title(String id) => switch (id) {
    'child_trigger' => l10n.sosReadinessRowChild,
    'local_persistence' => l10n.sosReadinessRowPersistence,
    'push_alerts' => l10n.sosReadinessRowPush,
    'sms_fallback' => l10n.sosReadinessRowSms,
    'call_fallback' => l10n.sosReadinessRowCall,
    'location' => l10n.sosReadinessRowLocation,
    'trusted_ladder' => l10n.sosReadinessRowLadder,
    'panic_quiet' => l10n.sosReadinessRowPanicQuiet,
    'break_glass' => l10n.sosReadinessRowBreakGlass,
    _ => id,
  };

  Color _dotColor(SosReadinessClass klass) => switch (klass) {
    // Soft mint — never scream "armed" for Local-only available rows.
    SosReadinessClass.available => colors.mint.withValues(alpha: 0.75),
    SosReadinessClass.degraded => colors.amber,
    SosReadinessClass.unavailable ||
    SosReadinessClass.notConfigured => colors.ink2,
  };

  Color _statusInk(SosReadinessClass klass) => switch (klass) {
    SosReadinessClass.available => colors.ink,
    SosReadinessClass.degraded => colors.amberInk,
    SosReadinessClass.unavailable ||
    SosReadinessClass.notConfigured => colors.ink2,
  };

  String _klassLabel(SosReadinessClass klass) => switch (klass) {
    SosReadinessClass.available => l10n.sosReadinessClassAvailable,
    SosReadinessClass.degraded => l10n.sosReadinessClassDegraded,
    SosReadinessClass.unavailable => l10n.sosReadinessClassUnavailable,
    SosReadinessClass.notConfigured => l10n.sosReadinessClassNotConfigured,
  };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final r = rows[i];
        final status = _klassLabel(r.klass);
        final title = _title(r.id);
        return Semantics(
          label: '$title · $status',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  key: Key('sos_readiness_status_${r.id}'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _statusInk(r.klass),
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        key: Key('sos_readiness_dot_${r.id}'),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _dotColor(r.klass),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LockedParentCard extends StatelessWidget {
  const _LockedParentCard({
    required this.memberId,
    required this.label,
    required this.lockedHint,
    required this.mandatoryTag,
    required this.colors,
  });

  final String memberId;
  final String label;
  final String lockedHint;
  final String mandatoryTag;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: EmergencySetupKeys.parentRow(memberId),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield,
            color: colors.p600.withValues(alpha: 0.5),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lockedHint,
                  style: TextStyle(fontSize: 11, color: colors.ink2),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.p50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              mandatoryTag,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: colors.p600,
              ),
            ),
          ),
          Switch(
            key: EmergencySetupKeys.parentSwitch(memberId),
            value: true,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}

class _PartnerReadOnlySummary extends StatelessWidget {
  const _PartnerReadOnlySummary({
    super.key,
    required this.l10n,
    required this.colors,
    required this.ladder,
    required this.snap,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final SosLadder ladder;
  final SosReadinessSnapshot? snap;

  @override
  Widget build(BuildContext context) {
    final verified = ladder.verifiedEscalationBackups.length;
    final total = ladder.backups.length;
    return SingleChildScrollView(
      key: EmergencySetupKeys.partnerSummary,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppEmptyState(
            title: l10n.sosLadderReadOnlyTitle,
            message: l10n.sosLadderReadOnlyMessage,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sosLadderPartnerSummaryTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.sosLadderPartnerSummaryBody(
                    ladder.rung1MemberIds.length,
                    verified,
                    total,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.ink2,
                    height: 1.45,
                  ),
                ),
                if (snap != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    snap!.claimsReady
                        ? l10n.sosReadinessClassAvailable
                        : l10n.sosReadinessClassDegraded,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: snap!.claimsReady
                          ? colors.mintInk
                          : colors.amberInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBackupCard extends StatelessWidget {
  const _DashboardBackupCard({
    required this.contact,
    required this.l10n,
    required this.colors,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onVerify,
    required this.onPriorityUp,
    required this.onPriorityDown,
  });

  final SosBackupContact contact;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onVerify;
  final VoidCallback onPriorityUp;
  final VoidCallback onPriorityDown;

  String _verifyLabel() => switch (contact.verification) {
    SosVerificationStatus.verified => l10n.sosLadderVerifyRevoke,
    SosVerificationStatus.pending => l10n.sosLadderVerifyConfirmLocal,
    SosVerificationStatus.unverified ||
    SosVerificationStatus.failed ||
    SosVerificationStatus.revoked => l10n.sosLadderNeedsVerify,
  };

  @override
  Widget build(BuildContext context) {
    final isVerified = contact.verification == SosVerificationStatus.verified;

    return Semantics(
      container: true,
      label:
          '${contact.name}. ${isVerified ? l10n.sosLadderVerificationVerified : l10n.sosLadderSkippedEscalation}',
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVerified
                ? colors.mint.withValues(alpha: 0.55)
                : colors.border,
            width: isVerified ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isVerified ? colors.mint100 : colors.p50,
                    foregroundColor: isVerified ? colors.mintInk : colors.p600,
                    child: Text(
                      '${contact.priority}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? colors.mint100
                                : colors.amber100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isVerified
                                ? l10n.sosLadderVerificationVerified
                                : l10n.sosLadderSkippedEscalation,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isVerified
                                  ? colors.mintInk
                                  : colors.amberInk,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${contact.relation} · ${contact.phoneE164}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.ink,
                            height: 1.35,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.sosLadderBackupDelay(contact.delaySeconds),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: contact.name,
                    toggled: contact.enabled,
                    child: Switch(
                      key: EmergencySetupKeys.backupSwitch(contact.id),
                      value: contact.enabled,
                      onChanged: onToggle,
                      activeThumbColor: colors.p600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Semantics(
                      button: true,
                      label: isVerified
                          ? l10n.sosLadderVerificationVerified
                          : _verifyLabel(),
                      child: FilledButton.tonalIcon(
                        key: EmergencySetupKeys.backupVerify(contact.id),
                        onPressed: onVerify,
                        icon: Icon(
                          isVerified ? Icons.verified : Icons.gpp_maybe,
                          size: 16,
                          color: isVerified ? colors.mintInk : colors.amberInk,
                        ),
                        label: Text(
                          isVerified
                              ? l10n.sosLadderVerificationVerified
                              : _verifyLabel(),
                          style: TextStyle(
                            color: isVerified
                                ? colors.mintInk
                                : colors.amberInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: isVerified
                              ? colors.mint100
                              : colors.amber100,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: EmergencySetupKeys.backupPriorityUp(contact.id),
                    icon: Icon(Icons.keyboard_arrow_up, color: colors.ink2),
                    onPressed: canMoveUp ? onPriorityUp : null,
                    tooltip: l10n.sosLadderPriorityUp,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    key: EmergencySetupKeys.backupPriorityDown(contact.id),
                    icon: Icon(Icons.keyboard_arrow_down, color: colors.ink2),
                    onPressed: canMoveDown ? onPriorityDown : null,
                    tooltip: l10n.sosLadderPriorityDown,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    key: EmergencySetupKeys.backupEdit(contact.id),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: colors.ink2,
                      size: 18,
                    ),
                    onPressed: onEdit,
                    tooltip: l10n.sosLadderBackupSheetTitleEdit,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    key: EmergencySetupKeys.backupRemove(contact.id),
                    icon: Icon(
                      Icons.delete_outline,
                      color: colors.coral,
                      size: 18,
                    ),
                    onPressed: onDelete,
                    tooltip: l10n.sosLadderBackupRemoveSemantics,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildEscalationDashboard extends StatelessWidget {
  const _ChildEscalationDashboard({
    required this.l10n,
    required this.colors,
    required this.children,
    required this.settings,
    required this.delays,
    required this.onPersist,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final List<RosterChildRef> children;
  final SosLocalSettings settings;
  final List<int> delays;
  final Future<void> Function(String childId, ChildSosEscalationPrefs prefs)
  onPersist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSectionHeader(
          title: l10n.sosChildEscalationSectionTitle,
          subtitle: l10n.sosChildEscalationSectionHint,
          icon: Icons.family_restroom_rounded,
          colors: colors,
        ),
        BannerNote(
          key: EmergencySetupKeys.childEscalationSmsHonesty,
          variant: BannerVariant.t,
          message: l10n.sosChildEscalationSmsHonesty,
        ),
        const SizedBox(height: 12),
        if (children.isEmpty)
          AppEmptyState(
            key: EmergencySetupKeys.childEscalationEmpty,
            title: l10n.sosChildEscalationEmptyTitle,
            message: l10n.sosChildEscalationEmptyChildren,
          )
        else
          for (final child in children) ...[
            _ChildControlCard(
              childId: child.id.value,
              label: l10n.sosChildEscalationChildLabel(child.id.value),
              prefs: settings.escalationFor(child.id.value),
              delays: delays,
              l10n: l10n,
              colors: colors,
              onPersist: onPersist,
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _ChildControlCard extends StatelessWidget {
  const _ChildControlCard({
    required this.childId,
    required this.label,
    required this.prefs,
    required this.delays,
    required this.l10n,
    required this.colors,
    required this.onPersist,
  });

  final String childId;
  final String label;
  final ChildSosEscalationPrefs prefs;
  final List<int> delays;
  final AppLocalizations l10n;
  final FamilyColors colors;
  final Future<void> Function(String childId, ChildSosEscalationPrefs prefs)
  onPersist;

  Future<void> _save(ChildSosEscalationPrefs next) => onPersist(childId, next);

  @override
  Widget build(BuildContext context) {
    final delayValue = delays.contains(prefs.delaySeconds)
        ? prefs.delaySeconds
        : delays[1];

    return Container(
      key: EmergencySetupKeys.childEscalationCard(childId),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.p50,
                  child: Icon(Icons.person, color: colors.p600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.ink,
                        ),
                      ),
                      if (prefs.enabled) ...[
                        const SizedBox(height: 4),
                        Text(
                          key: Key('sos_child_escalation_glance_$childId'),
                          l10n.sosEscalationSecondsShort(prefs.delaySeconds),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.p600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  key: EmergencySetupKeys.childEscalationEnable(childId),
                  value: prefs.enabled,
                  onChanged: (v) => _save(prefs.copyWith(enabled: v)),
                  activeThumbColor: colors.p600,
                ),
              ],
            ),
          ),
          if (prefs.enabled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.sosChildEscalationDelay,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            key: EmergencySetupKeys.childEscalationDelay(
                              childId,
                            ),
                            value: delayValue,
                            items: [
                              for (final d in delays)
                                DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    l10n.sosEscalationSecondsShort(d),
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                _save(prefs.copyWith(delaySeconds: v));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SettingsPersistToggle(
                    title: l10n.sosChildEscalationUseBackups,
                    value: prefs.notifyTrustedBackups,
                    switchKey: EmergencySetupKeys.childEscalationUseBackups(
                      childId,
                    ),
                    successMessage: l10n.sosChildEscalationUseBackups,
                    errorMessage: l10n.settingsPersistError,
                    onPersist: (v) =>
                        _save(prefs.copyWith(notifyTrustedBackups: v)),
                  ),
                  const Divider(height: 24),
                  SettingsPersistToggle(
                    title: l10n.sosChildEscalationPrepareSms,
                    value: prefs.prepareSmsFallback,
                    switchKey: EmergencySetupKeys.childEscalationPrepareSms(
                      childId,
                    ),
                    successMessage: l10n.sosChildEscalationPrepareSms,
                    errorMessage: l10n.settingsPersistError,
                    onPersist: (v) =>
                        _save(prefs.copyWith(prepareSmsFallback: v)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BackupEditorSheet extends StatefulWidget {
  const _BackupEditorSheet({
    super.key,
    required this.l10n,
    required this.nextId,
    required this.nextPriority,
    this.existing,
  });

  final AppLocalizations l10n;
  final String nextId;
  final int nextPriority;
  final SosBackupContact? existing;

  @override
  State<_BackupEditorSheet> createState() => _BackupEditorSheetState();
}

class _BackupEditorSheetState extends State<_BackupEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _relation;
  late final TextEditingController _phone;
  late int _delay;

  static const _delays = [30, 60, 120, 300];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(
      text: e?.name ?? widget.l10n.sosLadderBackupDefaultName,
    );
    _relation = TextEditingController(
      text: e?.relation ?? widget.l10n.sosLadderBackupDefaultRelation,
    );
    _phone = TextEditingController(text: e?.phoneE164 ?? '');
    _delay = e?.delaySeconds ?? 60;
    if (!_delays.contains(_delay)) _delay = 60;
  }

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final phone = _phone.text.trim();
    var contact = SosBackupContact(
      id: widget.existing?.id ?? widget.nextId,
      name: _name.text.trim().isEmpty
          ? widget.l10n.sosLadderBackupDefaultName
          : _name.text.trim(),
      relation: _relation.text.trim().isEmpty
          ? widget.l10n.sosLadderBackupDefaultRelation
          : _relation.text.trim(),
      delaySeconds: _delay,
      priority:
          widget.existing?.priority ??
          widget.nextPriority.clamp(1, kSosMaxBackupContacts),
      enabled: widget.existing?.enabled ?? true,
      phoneE164: phone,
      verification:
          widget.existing?.verification ?? SosVerificationStatus.unverified,
    );
    if (widget.existing != null && phone != widget.existing!.phoneE164) {
      contact = contact.withPhoneChanged(phone);
    }
    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing == null
                  ? widget.l10n.sosLadderBackupSheetTitleAdd
                  : widget.l10n.sosLadderBackupSheetTitleEdit,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: widget.l10n.sosLadderBackupFieldName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _relation,
              decoration: InputDecoration(
                labelText: widget.l10n.sosLadderBackupFieldRelation,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: widget.l10n.sosLadderBackupFieldPhone,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: widget.l10n.sosLadderBackupFieldDelay,
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _delay,
                  isExpanded: true,
                  items: [
                    for (final d in _delays)
                      DropdownMenuItem(
                        value: d,
                        child: Text(widget.l10n.sosEscalationSecondsShort(d)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _delay = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: EmergencySetupKeys.backupSave,
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.p600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(48, 48),
              ),
              child: Text(
                widget.l10n.sosLadderBackupSave,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
