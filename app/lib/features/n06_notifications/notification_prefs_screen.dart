import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/settings_persist_toggle.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_runtime.dart';

/// Optional time-picker override for widget tests.
typedef QuietHoursTimePicker = Future<TimeOfDay?> Function(
  BuildContext context,
  TimeOfDay initial,
);

/// Widget keys for SCR-FAT-058 / SET-010 / SET-011 / SET-021 / UI-010 acceptance.
abstract final class NotificationPrefsKeys {
  static const quietHoursSwitch = Key('notif_quiet_hours_switch');
  static const quietStart = Key('notif_quiet_start');
  static const quietEnd = Key('notif_quiet_end');
  static const sosPierceBanner = Key('notif_sos_pierce_banner');
  static const save = Key('notif_prefs_save');
  static const memberLabel = Key('notif_prefs_member_label');
  static const analysisNoticesSwitch = Key('notif_analysis_notices_switch');
  static const childRequestsSwitch = Key('notif_child_requests_switch');
  static const summaryDigestSwitch = Key('notif_summary_digest_switch');
  static const eveningDigestSwitch = Key('notif_evening_digest_switch');
  static const eveningDigestTime = Key('notif_evening_digest_time');
  static const cardCritical = Key('notif_card_critical');
  static const cardImportant = Key('notif_card_important');
  static const cardReassurance = Key('notif_card_reassurance');

  /// Must never appear — mute-SOS is forbidden (P-4 / SET-011 / SET-021 / UI-010).
  static const muteSosToggle = Key('notif_mute_sos_toggle');
}

/// SCR-FAT-058 — الإشعارات (SET-010 + SET-011 + SET-021 + UI-010).
///
/// Three urgency cards matching frozen prototype: Critical (info) · Important
/// (child requests, Advisor, quiet hours) · Reassurance (summary + evening).
/// SOS receipt always on — no mute control (P-4).
class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({
    super.key,
    this.memberId,
    this.repository,
    this.pickTime,
    this.canEditOverride,
  });

  /// Explicit member row; when null, resolved from [CurrentRole].
  final String? memberId;

  /// Rule 25 seam — null → Local KV via PrefsMiscLocalPersistence (DOM-PREFS-MISC).
  final NotificationPrefsRepository? repository;

  /// Test seam — when null, uses [showTimePicker].
  final QuietHoursTimePicker? pickTime;

  /// Test seam — when null, father/mother may edit own row; child read-only.
  final bool? canEditOverride;

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  NotificationPrefsRepository? _repository;
  late NotificationPrefs _prefs;
  String? _memberId;
  var _loading = true;
  var _saving = false;
  var _didResolveMember = false;
  var _unavailable = false;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repository = widget.repository;
    } else {
      _bootstrapLocal();
    }
    _prefs = NotificationPrefs.defaults(memberId: widget.memberId ?? 'father');
  }

  Future<void> _bootstrapLocal() async {
    try {
      await PrefsMiscRuntime.ensureOpen();
      if (PrefsMiscRuntime.unavailable ||
          PrefsMiscRuntime.notification == null) {
        throw StateError('PrefsMiscRuntime unavailable');
      }
      _repository = PrefsMiscRuntime.notification;
      _unavailable = false;
    } catch (e, st) {
      debugPrint(
        'DOM-PREFS-MISC-NOTIF: Local KV bootstrap failed — '
        'no Memory Prefs fallback: $e\n$st',
      );
      if (!mounted) return;
      setState(() {
        _repository = null;
        _unavailable = true;
        _loading = false;
      });
      return;
    }
    if (_memberId != null && mounted) {
      await _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = widget.memberId ?? _memberIdFromRole();
    if (!_didResolveMember || _memberId != next) {
      _didResolveMember = true;
      _memberId = next;
      _loading = true;
      _prefs = NotificationPrefs.defaults(memberId: next);
      _load();
    }
  }

  String _memberIdFromRole() {
    final role = CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
    return switch (role) {
      AppRole.father => 'father',
      AppRole.mother => 'mother',
      AppRole.child => 'child',
    };
  }

  Future<void> _load() async {
    final repo = _repository;
    final id = _memberId;
    if (repo == null || id == null) return;
    final loaded = await repo.load(id);
    if (!mounted) return;
    if (_memberId != id) return;
    setState(() {
      _prefs = loaded;
      _loading = false;
    });
  }

  AppRole get _role =>
      CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;

  bool get _canEdit {
    if (widget.canEditOverride != null) return widget.canEditOverride!;
    return _role == AppRole.father || _role == AppRole.mother;
  }

  bool get _canSave =>
      _canEdit &&
      _prefs.isValid &&
      !_saving &&
      !_loading &&
      _repository != null &&
      !_unavailable;

  Future<void> _persistQuietHours(bool enabled) async {
    if (!_canEdit) throw StateError('quiet hours read-only');
    final repo = _repository;
    if (repo == null) throw StateError('notification prefs unavailable');
    var next = _prefs.copyWith(quietHoursEnabled: enabled);
    if (enabled) {
      next = next.seedOnEnable();
    }
    await repo.save(next);
    if (!mounted) return;
    setState(() => _prefs = next);
  }

  Future<void> _persistAnalysisNotices(bool enabled) async {
    if (!_canEdit) throw StateError('analysis notices read-only');
    final repo = _repository;
    if (repo == null) throw StateError('notification prefs unavailable');
    final next = _prefs.copyWith(analysisNoticesEnabled: enabled);
    await repo.save(next);
    if (!mounted) return;
    setState(() => _prefs = next);
  }

  Future<void> _persistChildRequests(bool enabled) async {
    if (!_canEdit) throw StateError('child requests read-only');
    final repo = _repository;
    if (repo == null) throw StateError('notification prefs unavailable');
    final next = _prefs.copyWith(childRequestsEnabled: enabled);
    await repo.save(next);
    if (!mounted) return;
    setState(() => _prefs = next);
  }

  Future<void> _persistSummaryDigest(bool enabled) async {
    if (!_canEdit) throw StateError('summary digest read-only');
    final repo = _repository;
    if (repo == null) throw StateError('notification prefs unavailable');
    final next = _prefs.copyWith(summaryDigestEnabled: enabled);
    await repo.save(next);
    if (!mounted) return;
    setState(() => _prefs = next);
  }

  Future<void> _persistEveningDigest(bool enabled) async {
    if (!_canEdit) throw StateError('evening digest read-only');
    final repo = _repository;
    if (repo == null) throw StateError('notification prefs unavailable');
    var next = _prefs.copyWith(eveningDigestEnabled: enabled);
    if (enabled && next.eveningDigestTime == null) {
      next = next.copyWith(
        eveningDigestTime: NotificationPrefs.defaultEveningDigest,
      );
    }
    await repo.save(next);
    if (!mounted) return;
    setState(() => _prefs = next);
  }

  Future<void> _pick({required bool isStart}) async {
    if (!_canEdit) return;
    final initial = isStart
        ? (_prefs.quietStart ?? NotificationPrefs.defaultQuietStart)
        : (_prefs.quietEnd ?? NotificationPrefs.defaultQuietEnd);

    final TimeOfDay? picked;
    if (widget.pickTime != null) {
      picked = await widget.pickTime!(context, initial);
    } else {
      picked = await showTimePicker(context: context, initialTime: initial);
    }
    if (picked == null || !mounted) return;

    setState(() {
      _prefs = isStart
          ? _prefs.copyWith(quietStart: picked)
          : _prefs.copyWith(quietEnd: picked);
    });
  }

  Future<void> _pickEvening() async {
    if (!_canEdit) return;
    final initial =
        _prefs.eveningDigestTime ?? NotificationPrefs.defaultEveningDigest;
    final TimeOfDay? picked;
    if (widget.pickTime != null) {
      picked = await widget.pickTime!(context, initial);
    } else {
      picked = await showTimePicker(context: context, initialTime: initial);
    }
    if (picked == null || !mounted) return;
    setState(() => _prefs = _prefs.copyWith(eveningDigestTime: picked));
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final repo = _repository;
    if (repo == null) return;
    setState(() => _saving = true);
    await repo.save(_prefs);
    if (!mounted) return;
    setState(() => _saving = false);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.notificationPrefsSaveToast);
  }

  String _formatTod(TimeOfDay? tod) {
    if (tod == null) return '--:--';
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _memberDisplay(AppLocalizations l10n) {
    return switch (_memberId) {
      'mother' => l10n.notificationPrefsMemberMother,
      'child' => l10n.notificationPrefsMemberChild,
      _ => l10n.notificationPrefsMemberFather,
    };
  }

  Widget _card({
    required Key key,
    required FamilyColors colors,
    required FamilyRadii radii,
    required String title,
    required List<Widget> children,
  }) {
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final canEdit = _canEdit;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.notificationPrefsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      children: [
                        Text(
                          key: NotificationPrefsKeys.memberLabel,
                          l10n.notificationPrefsMemberHeading(
                            _memberDisplay(l10n),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.p700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.notificationPrefsSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: colors.ink2,
                          ),
                        ),
                        if (_unavailable) ...[
                          const SizedBox(height: 12),
                          BannerNote(
                            key: const Key('notif_prefs_unavailable'),
                            variant: BannerVariant.a,
                            message: l10n.errorLocalSaveMessage,
                          ),
                        ],
                        const SizedBox(height: 12),
                        BannerNote(
                          key: NotificationPrefsKeys.sosPierceBanner,
                          variant: BannerVariant.p,
                          message: l10n.notificationPrefsSosPierceBanner,
                        ),
                        const SizedBox(height: 16),
                        _card(
                          key: NotificationPrefsKeys.cardCritical,
                          colors: colors,
                          radii: radii,
                          title: l10n.notificationPrefsCardCriticalTitle,
                          children: [
                            Text(
                              l10n.notificationPrefsCardCriticalBody,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color: colors.ink2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _card(
                          key: NotificationPrefsKeys.cardImportant,
                          colors: colors,
                          radii: radii,
                          title: l10n.notificationPrefsCardImportantTitle,
                          children: [
                            SettingsPersistToggle(
                              title: l10n.notificationPrefsChildRequests,
                              value: _prefs.childRequestsEnabled,
                              enabled: canEdit,
                              switchKey:
                                  NotificationPrefsKeys.childRequestsSwitch,
                              successMessage: l10n.notificationPrefsSaveToast,
                              errorMessage: l10n.settingsPersistError,
                              onPersist: _persistChildRequests,
                            ),
                            const SizedBox(height: 8),
                            SettingsPersistToggle(
                              title: l10n.notificationPrefsAnalysisNotices,
                              subtitle:
                                  l10n.notificationPrefsAnalysisNoticesHint,
                              value: _prefs.analysisNoticesEnabled,
                              enabled: canEdit,
                              switchKey:
                                  NotificationPrefsKeys.analysisNoticesSwitch,
                              successMessage: l10n.notificationPrefsSaveToast,
                              errorMessage: l10n.settingsPersistError,
                              onPersist: _persistAnalysisNotices,
                            ),
                            const SizedBox(height: 8),
                            SettingsPersistToggle(
                              title: l10n.notificationPrefsQuietHours,
                              subtitle: l10n.notificationPrefsQuietHoursHint,
                              value: _prefs.quietHoursEnabled,
                              enabled: canEdit,
                              switchKey: NotificationPrefsKeys.quietHoursSwitch,
                              successMessage: l10n.notificationPrefsSaveToast,
                              errorMessage: l10n.settingsPersistError,
                              onPersist: _persistQuietHours,
                            ),
                            if (_prefs.quietHoursEnabled) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TimeChip(
                                      key: NotificationPrefsKeys.quietStart,
                                      label: l10n.notificationPrefsStart,
                                      value: _formatTod(_prefs.quietStart),
                                      enabled: canEdit,
                                      colors: colors,
                                      radii: radii,
                                      onTap: () => _pick(isStart: true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _TimeChip(
                                      key: NotificationPrefsKeys.quietEnd,
                                      label: l10n.notificationPrefsEnd,
                                      value: _formatTod(_prefs.quietEnd),
                                      enabled: canEdit,
                                      colors: colors,
                                      radii: radii,
                                      onTap: () => _pick(isStart: false),
                                    ),
                                  ),
                                ],
                              ),
                              if (!_prefs.isValid)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    l10n.notificationPrefsValidation,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.amberDeep,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        _card(
                          key: NotificationPrefsKeys.cardReassurance,
                          colors: colors,
                          radii: radii,
                          title: l10n.notificationPrefsCardReassuranceTitle,
                          children: [
                            SettingsPersistToggle(
                              title: l10n.notificationPrefsSummaryDigest,
                              subtitle: l10n.notificationPrefsSummaryDigestHint,
                              value: _prefs.summaryDigestEnabled,
                              enabled: canEdit,
                              switchKey:
                                  NotificationPrefsKeys.summaryDigestSwitch,
                              successMessage: l10n.notificationPrefsSaveToast,
                              errorMessage: l10n.settingsPersistError,
                              onPersist: _persistSummaryDigest,
                            ),
                            const SizedBox(height: 8),
                            SettingsPersistToggle(
                              title: l10n.notificationPrefsEveningDigest,
                              value: _prefs.eveningDigestEnabled,
                              enabled: canEdit,
                              switchKey:
                                  NotificationPrefsKeys.eveningDigestSwitch,
                              successMessage: l10n.notificationPrefsSaveToast,
                              errorMessage: l10n.settingsPersistError,
                              onPersist: _persistEveningDigest,
                            ),
                            if (_prefs.eveningDigestEnabled) ...[
                              const SizedBox(height: 10),
                              _TimeChip(
                                key: NotificationPrefsKeys.eveningDigestTime,
                                label: l10n.notificationPrefsEveningDigestTime,
                                value: _formatTod(
                                  _prefs.eveningDigestTime ??
                                      NotificationPrefs.defaultEveningDigest,
                                ),
                                enabled: canEdit,
                                colors: colors,
                                radii: radii,
                                onTap: _pickEvening,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: PrimaryBtn(
                      key: NotificationPrefsKeys.save,
                      label: l10n.notificationPrefsSave,
                      onPressed: _canSave ? _save : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.colors,
    required this.radii,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(radii.btn),
      child: Ink(
        decoration: BoxDecoration(
          color: colors.p50,
          borderRadius: BorderRadius.circular(radii.btn),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.ink2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
