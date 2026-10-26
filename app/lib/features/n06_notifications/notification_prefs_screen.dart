import 'dart:async';

import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/settings_persist_toggle.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/i18n/clock_format.dart';
import 'package:family_os/core/i18n/numeral_format.dart' show formatAppInt;
import 'package:family_os/core/policy/notification_delivery.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/notification_tier.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_runtime.dart';

/// Optional time-picker override for widget tests.
typedef QuietHoursTimePicker =
    Future<TimeOfDay?> Function(BuildContext context, TimeOfDay initial);

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

  /// The polished surface states its own truth: where the row lives, what is not saved yet, what
  /// the next hour would actually do. Each of those statements is a key a test can pin.
  static const provenance = Key('notif_prefs_provenance');
  static const quietSummary = Key('notif_quiet_summary');
  static const quietNowState = Key('notif_quiet_now_state');
  static const quietValidation = Key('notif_quiet_validation');
  static const draftBadge = Key('notif_prefs_draft_badge');
  static const undo = Key('notif_prefs_undo');
  static const retry = Key('notif_prefs_retry');
  static const quietStartEarlier = Key('notif_quiet_start_earlier');
  static const quietStartLater = Key('notif_quiet_start_later');
  static const quietEndEarlier = Key('notif_quiet_end_earlier');
  static const quietEndLater = Key('notif_quiet_end_later');

  /// Must never appear — mute-SOS is forbidden (P-4 / SET-011 / SET-021 / UI-010).
  static const muteSosToggle = Key('notif_mute_sos_toggle');
}

/// SCR-FAT-058 — الإشعارات (SET-010 + SET-011 + SET-021 + UI-010).
///
/// Three urgency cards matching frozen prototype: Critical (info) · Important
/// (child requests, Advisor, quiet hours) · Reassurance (summary + evening).
/// SOS receipt always on — no mute control (P-4).
///
/// What this screen is allowed to claim, and why:
/// * **Its own provenance.** Whether the row lives on this handset or in the family account is read
///   off the repository it was handed, never typed here — so when the server-backed row arrives the
///   words change by themselves, and until then they say the uncomfortable thing out loud.
/// * **Visible drafts.** A picked time is neither saved nor hidden: the bar names itself «تغيير غير
///   محفوظ», offers تراجع, and a failed write keeps what the parent chose instead of rolling the
///   screen back in silence.
/// * **Minute control without a dialog.** Each time carries ±15-minute steps next to the wheel,
///   because «عاشرة بالليل» and «عاشرة إلا ربع» are two different nights.
/// * **A computed consequence.** The state line runs the same [NotificationDelivery] gate the
///   tests pin, so what the screen says about the next hour is what the app's rule says.
/// * **Digits and hour cycle the family chose.** Times render through [formatFamilyClock]: the
///   family's numeral profile for digits, the device's 24-hour setting for the face of the clock.
class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({
    super.key,
    this.memberId,
    this.repository,
    this.pickTime,
    this.canEditOverride,
    this.now,
  });

  /// Explicit member row; when null, resolved from [CurrentRole].
  final String? memberId;

  /// Rule 25 seam — null → Local KV via PrefsMiscLocalPersistence (DOM-PREFS-MISC).
  final NotificationPrefsRepository? repository;

  /// Test seam — when null, uses [showTimePicker].
  final QuietHoursTimePicker? pickTime;

  /// Test seam — when null, father/mother may edit own row; child read-only.
  final bool? canEditOverride;

  /// Test seam for the line about right now: the clock is injected, so a test can stand at 23:30.
  final DateTime Function()? now;

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  /// A wide handset gets a readable column, not copy that runs to the horizon.
  static const double _maxContentWidth = 720;

  /// One-tap precision beside the full picker, in minutes.
  static const int _stepMinutes = 15;

  NotificationPrefsRepository? _repository;
  NotificationPrefs? _saved;
  NotificationPrefs? _draft;
  String? _memberId;
  var _loading = true;
  var _saving = false;
  var _didResolveMember = false;
  var _unavailable = false;
  var _saveFailed = false;
  Timer? _ticker;

  NotificationPrefs get _prefs =>
      _draft ?? _saved ?? NotificationPrefs.defaults(memberId: _memberId ?? 'father');

  bool get _dirty => _draft != null;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repository = widget.repository;
    } else {
      _bootstrapLocal();
    }
    _saved = NotificationPrefs.defaults(memberId: widget.memberId ?? 'father');
    // "Right now" is a claim about a moving thing, so it is re-read on a clock: a parent watching
    // the screen at 22:00 should see the silence start while they are standing there.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapLocal() async {
    setState(() {
      _loading = true;
      _unavailable = false;
    });
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
      _draft = null;
      _saved = NotificationPrefs.defaults(memberId: next);
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
      _saved = loaded;
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

  /// Whether this screen's rows reach the family account or stay on the handset. Said by the
  /// repository it was given, so the copy follows the wiring instead of lagging behind it.
  bool get _serverBacked => _repository?.serverBacked ?? false;

  /// The one write path. Both a switch and the save bar go through it, so "saved" can only ever
  /// mean one thing on this screen. Throws on failure so [SettingsPersistToggle] rolls its own
  /// switch back and prints its own reason — one error surface, not two.
  Future<void> _write(NotificationPrefs next) async {
    final repo = _repository;
    if (repo == null) throw StateError('notification prefs unavailable');
    setState(() => _saving = true);
    var written = false;
    try {
      await repo.save(next);
      written = true;
    } catch (_) {
      written = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveFailed = !written;
      if (written) {
        _saved = next;
        // A draft cannot outlive the write that carried it.
        _draft = null;
      }
    });
    if (!written) throw StateError('notification prefs write failed');
  }

  Future<void> _persistQuietHours(bool enabled) async {
    if (!_canEdit) throw StateError('quiet hours read-only');
    var next = _prefs.copyWith(quietHoursEnabled: enabled);
    if (enabled) next = next.seedOnEnable();
    await _write(next);
  }

  Future<void> _persistAnalysisNotices(bool enabled) async {
    if (!_canEdit) throw StateError('analysis notices read-only');
    await _write(_prefs.copyWith(analysisNoticesEnabled: enabled));
  }

  Future<void> _persistChildRequests(bool enabled) async {
    if (!_canEdit) throw StateError('child requests read-only');
    await _write(_prefs.copyWith(childRequestsEnabled: enabled));
  }

  Future<void> _persistSummaryDigest(bool enabled) async {
    if (!_canEdit) throw StateError('summary digest read-only');
    await _write(_prefs.copyWith(summaryDigestEnabled: enabled));
  }

  Future<void> _persistEveningDigest(bool enabled) async {
    if (!_canEdit) throw StateError('evening digest read-only');
    var next = _prefs.copyWith(eveningDigestEnabled: enabled);
    if (enabled && next.eveningDigestTime == null) {
      next = next.copyWith(
        eveningDigestTime: NotificationPrefs.defaultEveningDigest,
      );
    }
    await _write(next);
  }

  void _stageQuiet({required bool isStart, TimeOfDay? value}) {
    if (!_canEdit) return;
    final NotificationPrefs next;
    if (isStart) {
      next = value == null
          ? _prefs.copyWith(clearStart: true)
          : _prefs.copyWith(quietStart: value);
    } else {
      next = value == null
          ? _prefs.copyWith(clearEnd: true)
          : _prefs.copyWith(quietEnd: value);
    }
    setState(() {
      _draft = next;
      _saveFailed = false;
    });
  }

  void _stageEvening(TimeOfDay? value) {
    if (!_canEdit) return;
    setState(() {
      _draft = value == null
          ? _prefs.copyWith(clearEvening: true)
          : _prefs.copyWith(eveningDigestTime: value);
      _saveFailed = false;
    });
  }

  /// Quarter-hour steps, wrapped on the 24-hour dial: 23:50 + 15 is 00:05, not an error.
  void _bumpQuiet({required bool isStart, required int direction}) {
    final current = isStart
        ? (_prefs.quietStart ?? NotificationPrefs.defaultQuietStart)
        : (_prefs.quietEnd ?? NotificationPrefs.defaultQuietEnd);
    _stageQuiet(isStart: isStart, value: _shifted(current, direction));
  }

  void _bumpEvening(int direction) {
    _stageEvening(
      _shifted(
        _prefs.eveningDigestTime ?? NotificationPrefs.defaultEveningDigest,
        direction,
      ),
    );
  }

  TimeOfDay _shifted(TimeOfDay from, int direction) {
    final raw =
        NotificationPrefs.toMinutes(from)! + direction * _stepMinutes;
    final wrapped = ((raw % 1440) + 1440) % 1440;
    return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
  }

  Future<void> _pick({required bool isStart}) async {
    final picked = await _askTime(
      isStart
          ? (_prefs.quietStart ?? NotificationPrefs.defaultQuietStart)
          : (_prefs.quietEnd ?? NotificationPrefs.defaultQuietEnd),
    );
    if (picked == null || !mounted) return;
    _stageQuiet(isStart: isStart, value: picked);
  }

  Future<void> _pickEvening() async {
    final picked = await _askTime(
      _prefs.eveningDigestTime ?? NotificationPrefs.defaultEveningDigest,
    );
    if (picked == null || !mounted) return;
    _stageEvening(picked);
  }

  Future<TimeOfDay?> _askTime(TimeOfDay initial) {
    if (!mounted || !_canEdit) return Future.value();
    if (widget.pickTime != null) return widget.pickTime!(context, initial);
    return showTimePicker(context: context, initialTime: initial);
  }

  void _undoDraft() {
    setState(() {
      _draft = null;
      _saveFailed = false;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context);
    try {
      await _write(_prefs);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, message: l10n.settingsPersistError);
      return;
    }
    if (!mounted) return;
    AppToast.show(context, message: l10n.notificationPrefsSaveToast);
  }

  /// Why the save bar is disabled, in the parent's words. A grey button without a reason is how a
  /// screen looks broken when it is only unfinished.
  String? _blockedReason(AppLocalizations l10n) {
    final prefs = _prefs;
    if (!prefs.quietHoursEnabled) return null;
    final start = NotificationPrefs.toMinutes(prefs.quietStart);
    final end = NotificationPrefs.toMinutes(prefs.quietEnd);
    if (start == null || end == null) return l10n.notificationPrefsValidation;
    if (start == end) return l10n.notificationPrefsEqualTimes;
    return null;
  }

  /// The length of the silence, from the two times the parent actually set.
  String? _durationLine(AppLocalizations l10n) {
    final prefs = _prefs;
    if (!prefs.quietHoursEnabled) return null;
    final start = NotificationPrefs.toMinutes(prefs.quietStart);
    final end = NotificationPrefs.toMinutes(prefs.quietEnd);
    if (start == null || end == null || start == end) return null;
    final span = ((end - start) % 1440 + 1440) % 1440;
    final hours = span ~/ 60;
    final minutes = span % 60;
    if (hours == 0) {
      return l10n.notificationPrefsQuietDurationMinutes(formatAppInt(minutes));
    }
    if (minutes == 0) {
      return l10n.notificationPrefsQuietDurationHours(formatAppInt(hours));
    }
    return l10n.notificationPrefsQuietDurationBoth(
      formatAppInt(hours),
      formatAppInt(minutes),
    );
  }

  bool get _crossesMidnight {
    final start = NotificationPrefs.toMinutes(_prefs.quietStart);
    final end = NotificationPrefs.toMinutes(_prefs.quietEnd);
    if (start == null || end == null) return false;
    return start > end;
  }

  bool get _insideQuietNow {
    final prefs = _prefs;
    if (!prefs.quietHoursEnabled || !prefs.isValid) return false;
    return prefs.isInQuietWindow(
      TimeOfDay.fromDateTime((widget.now ?? DateTime.now)()),
    );
  }

  /// What the next ordinary alert would do, decided by the app's own gate — not by a caption that
  /// agrees with it only when it is convenient.
  String _nowLine(AppLocalizations l10n) {
    final prefs = _prefs;
    if (!prefs.quietHoursEnabled) return l10n.notificationPrefsQuietOffState;
    final reaches = NotificationDelivery.shouldDeliver(
      NotificationTier.nonCritical,
      prefs,
      TimeOfDay.fromDateTime((widget.now ?? DateTime.now)()),
    );
    return reaches
        ? l10n.notificationPrefsQuietNowOutside
        : l10n.notificationPrefsQuietNowInside;
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
    Widget? footnote,
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
            if (footnote != null) ...[const SizedBox(height: 10), footnote],
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
    final prefs = _prefs;
    final blocked = _blockedReason(l10n);
    final duration = _durationLine(l10n);

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
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth > _maxContentWidth
                      ? _maxContentWidth
                      : constraints.maxWidth;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width,
                      child: Column(
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
                                const SizedBox(height: 10),
                                Wrap(
                                  key: NotificationPrefsKeys.provenance,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Tag(
                                      label: _serverBacked
                                          ? l10n.notificationPrefsStoredInFamily
                                          : l10n.notificationPrefsStoredLocally,
                                      variant: _serverBacked
                                          ? TagVariant.g
                                          : TagVariant.a,
                                    ),
                                    Tag(
                                      label: l10n.notificationPrefsNoDeliveryYet,
                                      variant: TagVariant.p,
                                    ),
                                  ],
                                ),
                                if (_unavailable) ...[
                                  const SizedBox(height: 12),
                                  BannerNote(
                                    key: const Key('notif_prefs_unavailable'),
                                    variant: BannerVariant.a,
                                    message: l10n.errorLocalSaveMessage,
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: PrimaryBtn(
                                      key: NotificationPrefsKeys.retry,
                                      label: l10n.errorRetryCta,
                                      variant: PrimaryBtnVariant.sec,
                                      onPressed: _bootstrapLocal,
                                    ),
                                  ),
                                ],
                                if (!canEdit) ...[
                                  const SizedBox(height: 12),
                                  BannerNote(
                                    variant: BannerVariant.t,
                                    message: l10n.notificationPrefsChildReadOnly,
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
                                  footnote: Text(
                                    l10n.notificationPrefsAlwaysArrive,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.45,
                                      fontWeight: FontWeight.w700,
                                      color: colors.p700,
                                    ),
                                  ),
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
                                      value: prefs.childRequestsEnabled,
                                      enabled: canEdit,
                                      switchKey:
                                          NotificationPrefsKeys
                                              .childRequestsSwitch,
                                      successMessage:
                                          l10n.notificationPrefsSaveToast,
                                      errorMessage: l10n.settingsPersistError,
                                      onPersist: _persistChildRequests,
                                    ),
                                    const SizedBox(height: 8),
                                    SettingsPersistToggle(
                                      title: l10n.notificationPrefsAnalysisNotices,
                                      subtitle:
                                          l10n
                                              .notificationPrefsAnalysisNoticesHint,
                                      value: prefs.analysisNoticesEnabled,
                                      enabled: canEdit,
                                      switchKey:
                                          NotificationPrefsKeys
                                              .analysisNoticesSwitch,
                                      successMessage:
                                          l10n.notificationPrefsSaveToast,
                                      errorMessage: l10n.settingsPersistError,
                                      onPersist: _persistAnalysisNotices,
                                    ),
                                    const SizedBox(height: 8),
                                    SettingsPersistToggle(
                                      title: l10n.notificationPrefsQuietHours,
                                      subtitle:
                                          l10n.notificationPrefsQuietHoursHint,
                                      value: prefs.quietHoursEnabled,
                                      enabled: canEdit,
                                      switchKey:
                                          NotificationPrefsKeys.quietHoursSwitch,
                                      successMessage:
                                          l10n.notificationPrefsSaveToast,
                                      errorMessage: l10n.settingsPersistError,
                                      onPersist: _persistQuietHours,
                                    ),
                                    const SizedBox(height: 8),
                                    _nowStrip(
                                      l10n: l10n,
                                      colors: colors,
                                      radii: radii,
                                    ),
                                    if (blocked != null || _saveFailed) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        key: NotificationPrefsKeys.quietValidation,
                                        blocked ??
                                            l10n.notificationPrefsSaveFailedDraft,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: colors.amberDeep,
                                        ),
                                      ),
                                    ],
                                    if (prefs.quietHoursEnabled) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _TimeChip(
                                              key: NotificationPrefsKeys.quietStart,
                                              label: l10n.notificationPrefsStart,
                                              value: formatFamilyClockOrUnset(
                                                context,
                                                prefs.quietStart,
                                              ),
                                              enabled: canEdit,
                                              colors: colors,
                                              radii: radii,
                                              earlierKey:
                                                  NotificationPrefsKeys
                                                      .quietStartEarlier,
                                              laterKey:
                                                  NotificationPrefsKeys
                                                      .quietStartLater,
                                              earlierTooltip:
                                                  l10n
                                                      .notificationPrefsEarlierStep,
                                              laterTooltip:
                                                  l10n.notificationPrefsLaterStep,
                                              tapHint:
                                                  l10n
                                                      .notificationPrefsTapTimeHint,
                                              onTap: () => _pick(isStart: true),
                                              onEarlier: () => _bumpQuiet(
                                                isStart: true,
                                                direction: -1,
                                              ),
                                              onLater: () => _bumpQuiet(
                                                isStart: true,
                                                direction: 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _TimeChip(
                                              key: NotificationPrefsKeys.quietEnd,
                                              label: l10n.notificationPrefsEnd,
                                              value: formatFamilyClockOrUnset(
                                                context,
                                                prefs.quietEnd,
                                              ),
                                              enabled: canEdit,
                                              colors: colors,
                                              radii: radii,
                                              earlierKey:
                                                  NotificationPrefsKeys
                                                      .quietEndEarlier,
                                              laterKey:
                                                  NotificationPrefsKeys
                                                      .quietEndLater,
                                              earlierTooltip:
                                                  l10n
                                                      .notificationPrefsEarlierStep,
                                              laterTooltip:
                                                  l10n.notificationPrefsLaterStep,
                                              tapHint:
                                                  l10n
                                                      .notificationPrefsTapTimeHint,
                                              onTap: () => _pick(isStart: false),
                                              onEarlier: () => _bumpQuiet(
                                                isStart: false,
                                                direction: -1,
                                              ),
                                              onLater: () => _bumpQuiet(
                                                isStart: false,
                                                direction: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (duration != null || _crossesMidnight) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          key: NotificationPrefsKeys.quietSummary,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (duration != null)
                                              Text(
                                                duration,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: colors.ink2,
                                                ),
                                              ),
                                            if (_crossesMidnight)
                                              Text(
                                                l10n
                                                    .notificationPrefsQuietCrossesMidnight,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: colors.ink2,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
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
                                      subtitle:
                                          l10n.notificationPrefsSummaryDigestHint,
                                      value: prefs.summaryDigestEnabled,
                                      enabled: canEdit,
                                      switchKey:
                                          NotificationPrefsKeys
                                              .summaryDigestSwitch,
                                      successMessage:
                                          l10n.notificationPrefsSaveToast,
                                      errorMessage: l10n.settingsPersistError,
                                      onPersist: _persistSummaryDigest,
                                    ),
                                    const SizedBox(height: 8),
                                    SettingsPersistToggle(
                                      title: l10n.notificationPrefsEveningDigest,
                                      value: prefs.eveningDigestEnabled,
                                      enabled: canEdit,
                                      switchKey:
                                          NotificationPrefsKeys
                                              .eveningDigestSwitch,
                                      successMessage:
                                          l10n.notificationPrefsSaveToast,
                                      errorMessage: l10n.settingsPersistError,
                                      onPersist: _persistEveningDigest,
                                    ),
                                    if (prefs.eveningDigestEnabled) ...[
                                      const SizedBox(height: 10),
                                      _TimeChip(
                                        key:
                                            NotificationPrefsKeys
                                                .eveningDigestTime,
                                        label: l10n
                                            .notificationPrefsEveningDigestTime,
                                        value: formatFamilyClockOrUnset(
                                          context,
                                          prefs.eveningDigestTime ??
                                              NotificationPrefs
                                                  .defaultEveningDigest,
                                        ),
                                        enabled: canEdit,
                                        colors: colors,
                                        radii: radii,
                                        earlierTooltip:
                                            l10n.notificationPrefsEarlierStep,
                                        laterTooltip:
                                            l10n.notificationPrefsLaterStep,
                                        tapHint: l10n.notificationPrefsTapTimeHint,
                                        onTap: _pickEvening,
                                        onEarlier: () => _bumpEvening(-1),
                                        onLater: () => _bumpEvening(1),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_dirty) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          key: NotificationPrefsKeys.draftBadge,
                                          l10n.notificationPrefsDraftBadge,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: colors.amberDeep,
                                          ),
                                        ),
                                      ),
                                      PrimaryBtn(
                                        key: NotificationPrefsKeys.undo,
                                        label: l10n.notificationPrefsUndo,
                                        variant: PrimaryBtnVariant.ghost,
                                        onPressed: _undoDraft,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                PrimaryBtn(
                                  key: NotificationPrefsKeys.save,
                                  label: _dirty
                                      ? l10n.notificationPrefsSaveTimes
                                      : l10n.notificationPrefsSave,
                                  onPressed: _canSave ? _save : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _nowStrip({
    required AppLocalizations l10n,
    required FamilyColors colors,
    required FamilyRadii radii,
  }) {
    final inside = _insideQuietNow;
    return DecoratedBox(
      key: NotificationPrefsKeys.quietNowState,
      decoration: BoxDecoration(
        color: inside ? colors.p50 : colors.surface,
        borderRadius: BorderRadius.circular(radii.pill),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              inside
                  ? Icons.do_not_disturb_on
                  : Icons.notifications_active_outlined,
              size: 16,
              color: inside ? colors.p700 : colors.ink2,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _nowLine(l10n),
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: colors.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A time the parent can nudge without a dialog and open in a wheel when they want precision.
///
/// The chip is the whole control: tap it for the picker, or take the two steps for quarter hours.
/// A read-only chip drops its affordances instead of showing buttons that refuse — a control that
/// looks pressable and is not is how a screen teaches someone to distrust it.
class _TimeChip extends StatelessWidget {
  const _TimeChip({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.colors,
    required this.radii,
    required this.onTap,
    required this.onEarlier,
    required this.onLater,
    required this.earlierTooltip,
    required this.laterTooltip,
    required this.tapHint,
    this.earlierKey,
    this.laterKey,
  });

  final String label;
  final String value;
  final bool enabled;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onTap;
  final VoidCallback onEarlier;
  final VoidCallback onLater;
  final String earlierTooltip;
  final String laterTooltip;
  final String tapHint;
  final Key? earlierKey;
  final Key? laterKey;

  @override
  Widget build(BuildContext context) {
    // Name and reading go in the two slots assistive tech has for them, rather than one string
    // joined by a hand-typed separator: a separator invented in code is copy that no translator
    // owns, and it is exactly what the hardcoded-string guard exists to catch.
    return Semantics(
      label: label,
      value: value,
      hint: enabled ? tapHint : null,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(radii.btn),
            child: Ink(
              decoration: BoxDecoration(
                color: colors.p50,
                borderRadius: BorderRadius.circular(radii.btn),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
          ),
          if (enabled) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepBtn(
                  key: earlierKey,
                  tooltip: earlierTooltip,
                  icon: Icons.expand_less,
                  colors: colors,
                  radii: radii,
                  onTap: onEarlier,
                ),
                _StepBtn(
                  key: laterKey,
                  tooltip: laterTooltip,
                  icon: Icons.expand_more,
                  colors: colors,
                  radii: radii,
                  onTap: onLater,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.colors,
    required this.radii,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: colors.ink2,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.pill),
            side: BorderSide(color: colors.border),
          ),
        ),
      ),
    );
  }
}
