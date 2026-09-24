import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/settings_persist_toggle.dart';
import 'package:family_os/core/design/components/sos_readiness_card.dart';
import 'package:family_os/core/design/components/trusted_contact_card.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';
import 'package:family_os/core/policy/sos_settings.dart';

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

  /// Must NEVER appear — national emergency number is forbidden.
  static const nationalNumberField = Key('sos_national_number_field');

  /// Must NEVER appear — audio/video SOS settings forbidden.
  static const audioVideoToggle = Key('sos_audio_video_toggle');

  /// Must never appear — mute-SOS is forbidden for guardians (P-4 / SET-021).
  static const muteSosToggle = Key('sos_mute_toggle');

  static Key parentRow(String memberId) => Key('sos_ladder_parent_$memberId');

  static Key parentSwitch(String memberId) =>
      Key('sos_ladder_parent_switch_$memberId');

  static Key parentRemove(String memberId) =>
      Key('sos_ladder_parent_remove_$memberId');

  static Key backupRow(String id) => Key('sos_ladder_backup_$id');

  static Key backupSwitch(String id) => Key('sos_ladder_backup_switch_$id');

  static Key backupRemove(String id) => Key('sos_ladder_backup_remove_$id');
}

/// SCR-FAT-028 — إعداد الطوارئ (SET-020 parents immovable; SET-021 no SOS mute).
///
/// Max 5 backups with verification + priority. Panic Quiet preference.
/// Configure: Primary + Mother Full only. No national number / audio-video.
class EmergencySetupScreen extends StatefulWidget {
  const EmergencySetupScreen({
    super.key,
    this.familyId = SosLadder.defaultFamilyId,
    this.repository,
    this.roleOverride = AppRole.father,
    this.motherLevel,
    this.settings,
  });

  final String familyId;

  /// Rule 25 seam — null → prefs-backed Stage-1 store.
  final SosLadderRepository? repository;

  /// Test / router seam — defaults to father (Primary).
  final AppRole roleOverride;

  /// Mother authority when [roleOverride] is mother.
  final MotherLevel? motherLevel;

  /// Null → [stage1SosSettingsStore].
  final InMemorySosSettingsStore? settings;

  @override
  EmergencySetupScreenState createState() => EmergencySetupScreenState();
}

class EmergencySetupScreenState extends State<EmergencySetupScreen> {
  late final SosLadderRepository _repository;
  late final InMemorySosSettingsStore _settings;
  late SosLadder _ladder;
  var _loading = true;
  String? _inlineError;

  SosActor get _actor {
    final role = widget.roleOverride;
    if (role == AppRole.mother) {
      return SosActor.mother(widget.motherLevel ?? MotherLevel.partner);
    }
    if (role == AppRole.child) return SosActor.child();
    return SosActor.primary();
  }

  bool get _canConfigure => SosRoleActions.canConfigure(_actor);

  bool get _atBackupLimit =>
      _ladder.backups.length >= kSosMaxBackupContacts;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? PrefsSosLadderRepository(stage1SosLadderStore);
    _settings = widget.settings ?? stage1SosSettingsStore;
    _ladder = SosLadder.defaults(familyId: widget.familyId);
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repository.load(widget.familyId);
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
      final next = await _repository.removeFromRung1(
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

  Future<void> attemptDisableParent(String memberId) async {
    final l10n = AppLocalizations.of(context);
    try {
      final next = await _repository.setEmergencyContactEnabled(
        memberId,
        false,
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
      final next = await _repository.setEmergencyContactEnabled(
        id,
        enabled,
        familyId: widget.familyId,
      );
      if (!mounted) return;
      setState(() {
        _ladder = next;
        _inlineError = null;
      });
    } on SosLadderValidationException {
      if (!mounted) return;
      setState(
        () => _inlineError =
            AppLocalizations.of(context).sosLadderParentImmovableError,
      );
    }
  }

  Future<void> _onBackupRemove(String id) async {
    if (!_canConfigure) return;
    try {
      final next = await _repository.removeBackup(
        id,
        familyId: widget.familyId,
      );
      if (!mounted) return;
      setState(() {
        _ladder = next;
        _inlineError = null;
      });
    } on SosLadderValidationException {
      if (!mounted) return;
      setState(
        () => _inlineError =
            AppLocalizations.of(context).sosLadderParentImmovableError,
      );
    }
  }

  Future<void> _onAddBackup() async {
    if (!_canConfigure || _atBackupLimit) return;
    final l10n = AppLocalizations.of(context);
    final id = 'backup_${_ladder.backups.length + 1}';
    final priority = _ladder.backups.length + 1;
    try {
      final next = await _repository.upsertBackup(
        SosBackupContact(
          id: id,
          name: l10n.sosLadderBackupDefaultName,
          relation: l10n.sosLadderBackupDefaultRelation,
          delaySeconds: 60,
          priority: priority.clamp(1, kSosMaxBackupContacts),
          verification: SosVerificationStatus.unverified,
        ),
        familyId: widget.familyId,
      );
      if (!mounted) return;
      setState(() {
        _ladder = next;
        _inlineError = null;
      });
    } on SosLadderValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _inlineError = e.code == SosLadderValidationCode.backupLimitExceeded
            ? l10n.sosLadderMaxBackupsError
            : l10n.sosLadderParentImmovableError;
      });
    }
  }

  Future<void> _persistPanicQuiet(bool next) async {
    _settings.setPanicQuietPreferred(next);
    if (mounted) setState(() {});
  }

  String _parentLabel(AppLocalizations l10n, String memberId) =>
      switch (memberId) {
        'father' => l10n.sosLadderFatherLabel,
        'mother' => l10n.sosLadderMotherLabel,
        _ => memberId,
      };

  String _verificationLabel(
    AppLocalizations l10n,
    SosVerificationStatus status,
  ) =>
      switch (status) {
        SosVerificationStatus.unverified =>
          l10n.sosLadderVerificationUnverified,
        SosVerificationStatus.pending => l10n.sosLadderVerificationPending,
        SosVerificationStatus.verified => l10n.sosLadderVerificationVerified,
        SosVerificationStatus.revoked => l10n.sosLadderVerificationRevoked,
        SosVerificationStatus.failed => l10n.sosLadderVerificationFailed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.emergencySetupTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_canConfigure
              ? AppEmptyState(
                  key: EmergencySetupKeys.readOnlyLean,
                  title: l10n.sosLadderReadOnlyTitle,
                  message: l10n.sosLadderReadOnlyMessage,
                )
              : ListView(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
                  children: [
                    BannerNote(
                      key: EmergencySetupKeys.protocolBanner,
                      message: l10n.sosLadderProtocolBanner,
                    ),
                    const SizedBox(height: 12),
                    BannerNote(
                      key: EmergencySetupKeys.sosReceiptBanner,
                      variant: BannerVariant.p,
                      message: l10n.sosReceiptCannotDisableBanner,
                    ),
                    const SizedBox(height: 12),
                    KeyedSubtree(
                      key: EmergencySetupKeys.readinessCard,
                      child: SosReadinessCard(
                        title: l10n.sosReadinessTitle,
                        body: l10n.sosReadinessBody,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.sosLadderSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.ink2,
                        height: 1.5,
                      ),
                    ),
                    if (_inlineError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _inlineError!,
                        key: EmergencySetupKeys.inlineError,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.coral,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (_atBackupLimit) ...[
                      const SizedBox(height: 12),
                      BannerNote(
                        key: EmergencySetupKeys.maxReachedBanner,
                        variant: BannerVariant.t,
                        message: l10n.sosLadderMaxBackupsError,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      l10n.sosLadderHeading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    KeyedSubtree(
                      key: EmergencySetupKeys.ladderList,
                      child: Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          12,
                          10,
                          8,
                          10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            KeyedSubtree(
                              key: EmergencySetupKeys.rung1Section,
                              child: Column(
                                children: [
                                  for (final id in _ladder.rung1MemberIds)
                                    _ParentRungRow(
                                      memberId: id,
                                      label: _parentLabel(l10n, id),
                                      lockedHint: l10n.sosLadderRung1LockedHint,
                                      mandatoryTag: l10n.sosLadderMandatoryTag,
                                      colors: colors,
                                    ),
                                ],
                              ),
                            ),
                            for (final contact
                                in _ladder.backupsByPriority) ...[
                              Divider(height: 1, color: colors.border),
                              KeyedSubtree(
                                key: EmergencySetupKeys.backupRow(contact.id),
                                child: TrustedContactCard(
                                  contact: contact,
                                  priorityLabel: l10n
                                      .sosLadderPriorityLabel(contact.priority),
                                  verificationLabel: _verificationLabel(
                                    l10n,
                                    contact.verification,
                                  ),
                                  delayLabel: l10n.sosLadderBackupDelay(
                                    contact.delaySeconds,
                                  ),
                                  switchKey: EmergencySetupKeys.backupSwitch(
                                    contact.id,
                                  ),
                                  removeKey: EmergencySetupKeys.backupRemove(
                                    contact.id,
                                  ),
                                  onToggle: (v) =>
                                      _onBackupToggle(contact.id, v),
                                  onRemove: () => _onBackupRemove(contact.id),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: EmergencySetupKeys.addBackup,
                      onPressed: _atBackupLimit ? null : _onAddBackup,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.sosLadderAddBackup),
                    ),
                    const SizedBox(height: 20),
                    SettingsPersistToggle(
                      title: l10n.sosPanicQuietTitle,
                      subtitle: l10n.sosPanicQuietSubtitle,
                      value: _settings.settings.panicQuietPreferred,
                      switchKey: EmergencySetupKeys.panicQuietToggle,
                      successMessage: l10n.sosPanicQuietTitle,
                      errorMessage: l10n.settingsPersistError,
                      onPersist: _persistPanicQuiet,
                    ),
                  ],
                ),
    );
  }
}

class _ParentRungRow extends StatelessWidget {
  const _ParentRungRow({
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
    return Padding(
      key: EmergencySetupKeys.parentRow(memberId),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '1',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.p600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
          // Switch always ON and disabled — cannot toggle emergency off (SET-020).
          Switch(
            key: EmergencySetupKeys.parentSwitch(memberId),
            value: true,
            onChanged: null,
          ),
          // No remove control for rung-1 parents (key must stay absent).
        ],
      ),
    );
  }
}
