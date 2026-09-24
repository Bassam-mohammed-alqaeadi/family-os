import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/capability_honesty_badge.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/modes/modes.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/core/policy/smart_mode_prefs_repository.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n09_smart_modes/modes_ux_bridge.dart';

/// Optional time-picker override for widget tests.
typedef SmartModeTimePicker =
    Future<TimeOfDay?> Function(BuildContext context, TimeOfDay initial);

/// Widget keys for SCR-FAT-085 / SET-018 / FS-005-UX acceptance.
abstract final class SmartModesKeys {
  static const honestyBanner = Key('smart_modes_honesty_banner');
  static const ownershipBanner = Key('smart_modes_ownership_banner');
  static const wakeHonesty = Key('smart_modes_wake_honesty');
  static const modesList = Key('smart_modes_list');
  static const examsHint = Key('smart_modes_exams_hint');

  static Key modeTile(BuiltInModeId id) => Key('smart_mode_tile_${id.name}');

  static Key modeSwitch(BuiltInModeId id) =>
      Key('smart_mode_switch_${id.name}');

  static Key schoolStart = const Key('smart_mode_school_start');
  static Key schoolEnd = const Key('smart_mode_school_end');
}

/// SCR-FAT-085 — الأوضاع الذكية (SET-018 + FS-005-UX KEEP/REFINE).
///
/// When [modes] is set, or Stage-1 Modes runtime binds (no prefs repo),
/// lifestyle schedule/activation writes FS-005 domain. Otherwise prefs path.
///
/// Never navigates to tombstone SCR-FAT-039 (ADR-034).
class SmartModesScreen extends StatefulWidget {
  const SmartModesScreen({
    super.key,
    this.childId = SmartModePrefs.defaultChildId,
    this.repository,
    this.modes,
    this.activationBus,
    this.pickTime,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
  });

  final String childId;

  /// Rule 25 seam — null → prefs Stage-1 **or** Modes auto-bind when no [modes].
  final SmartModePrefsRepository? repository;

  /// FS-005 domain seam — when set, FAT-085 is Modes ownership host.
  final ModesService? modes;

  /// SET-019 P12 — null → [stage1SmartModeActivationBus].
  final SmartModeActivationBus? activationBus;

  final SmartModeTimePicker? pickTime;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;

  @override
  State<SmartModesScreen> createState() => _SmartModesScreenState();
}

class _SmartModesScreenState extends State<SmartModesScreen> {
  SmartModePrefsRepository? _repository;
  ModesService? _modes;
  late final SmartModeActivationBus _activationBus;
  late SmartModePrefs _prefs;
  ModesEvaluation? _evaluation;
  TimeOfDay? _schoolStart;
  TimeOfDay? _schoolEnd;
  var _loading = true;
  var _busy = false;
  var _usingModes = false;

  ChildId get _childId => ChildId(widget.childId);

  ModesActor get _actor {
    final role = widget.roleOverride ?? AppRole.father;
    if (role == AppRole.father) return const ModesActor.father();
    return ModesActor.mother(widget.motherLevel);
  }

  bool get _canConfigure {
    if (!_usingModes) return true;
    return _actor.canConfigure || _actor.canTicketActivate;
  }

  @override
  void initState() {
    super.initState();
    _activationBus = widget.activationBus ?? stage1SmartModeActivationBus;
    _prefs = SmartModePrefs.defaults(childId: widget.childId);
    _schoolStart = SmartModeRow.defaultSchoolStart;
    _schoolEnd = SmartModeRow.defaultSchoolEnd;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final injected = widget.modes;
    if (injected != null) {
      _modes = injected;
      _usingModes = true;
      await _loadModes();
      return;
    }
    if (widget.repository != null) {
      _repository = widget.repository;
      _usingModes = false;
      await _loadPrefs();
      return;
    }
    // Production Stage-1: Modes domain is sole Mode authority (Slice 01 / OD-C).
    // Prefs path remains only via explicit widget.repository inject (tests).
    try {
      await Stage1ModesRuntime.ensureOpen();
      _modes = Stage1ModesRuntime.service;
      _usingModes = true;
      await _loadModes();
    } catch (e, st) {
      debugPrint(
        'AUTH-FS005: Modes ensureOpen failed — no Prefs fallback: $e\n$st',
      );
      if (!mounted) return;
      setState(() {
        _usingModes = true;
        _modes = null;
        _loading = false;
      });
    }
  }

  Future<void> _loadPrefs() async {
    final repo = _repository!;
    final loaded = await repo.load(widget.childId);
    if (!mounted) return;
    setState(() {
      _prefs = loaded;
      _schoolStart = loaded.row(BuiltInModeId.school).scheduleStart;
      _schoolEnd = loaded.row(BuiltInModeId.school).scheduleEnd;
      _loading = false;
    });
    _publishActivation(loaded, DateTime.now().toUtc());
  }

  Future<void> _loadModes() async {
    final modes = _modes!;
    final list = await modes.listModes();
    ModeDefinition? school;
    for (final m in list) {
      if (m.id == ModesUxBridge.modeDocumentId(BuiltInModeId.school)) {
        school = m;
        break;
      }
    }
    final eval = await modes.evaluateChild(_childId);
    if (!mounted) return;
    setState(() {
      if (school?.clockWindow != null) {
        _schoolStart = ModesUxBridge.todFromMinutes(
          school!.clockWindow!.startMinutes,
        );
        _schoolEnd = ModesUxBridge.todFromMinutes(
          school.clockWindow!.endMinutes,
        );
      }
      _evaluation = eval;
      _loading = false;
    });
    _publishFromEvaluation(eval);
  }

  void _publishActivation(SmartModePrefs prefs, DateTime at) {
    final activeId = prefs.activeModeId;
    DateTime? expiresAt;
    if (activeId != null) {
      final end = prefs.row(activeId).scheduleEnd;
      if (end != null) {
        final local = at.toLocal();
        expiresAt = DateTime(
          local.year,
          local.month,
          local.day,
          end.hour,
          end.minute,
        ).toUtc();
      }
    }
    _activationBus.publish(
      SmartModeActivation(
        childId: prefs.childId,
        modeId: activeId,
        active: activeId != null,
        updatedAt: at,
        expiresAt: expiresAt,
      ),
    );
  }

  void _publishFromEvaluation(ModesEvaluation eval) {
    BuiltInModeId? primary;
    for (final id in BuiltInModeId.values) {
      if (ModesUxBridge.isActive(eval, id)) {
        primary = id == BuiltInModeId.exams ? BuiltInModeId.study : id;
        break;
      }
    }
    DateTime? expiresAt;
    if (_schoolEnd != null &&
        primary == BuiltInModeId.school &&
        ModesUxBridge.isActive(eval, BuiltInModeId.school)) {
      final local = DateTime.now();
      expiresAt = DateTime(
        local.year,
        local.month,
        local.day,
        _schoolEnd!.hour,
        _schoolEnd!.minute,
      ).toUtc();
    }
    _activationBus.publish(
      SmartModeActivation(
        childId: widget.childId,
        modeId: primary,
        active: primary != null,
        updatedAt: DateTime.now().toUtc(),
        expiresAt: expiresAt,
      ),
    );
  }

  Future<void> _persistPrefs(SmartModePrefs next) async {
    setState(() => _prefs = next);
    await _repository!.save(next);
    _publishActivation(next, DateTime.now().toUtc());
  }

  Future<void> _onToggle(BuiltInModeId id, bool active) async {
    if (_busy || !_canConfigure) return;
    if (!_usingModes) {
      var row = _prefs.row(id).copyWith(active: active);
      if (active && id == BuiltInModeId.school) {
        row = row.seedSchoolScheduleIfNeeded();
      }
      await _persistPrefs(_prefs.withRow(row));
      return;
    }
    if (_modes == null) return;

    setState(() => _busy = true);
    try {
      final modes = _modes!;
      final docId = ModesUxBridge.modeDocumentId(id);
      var existing = await modes.listModes();
      final has = existing.any((m) => m.id == docId);
      if (!has) {
        await modes.saveMode(
          draft: ModesUxBridge.draftFor(
            id: id,
            familyId: modes.familyId,
            start: id == BuiltInModeId.school
                ? (_schoolStart ?? SmartModeRow.defaultSchoolStart)
                : null,
            end: id == BuiltInModeId.school
                ? (_schoolEnd ?? SmartModeRow.defaultSchoolEnd)
                : null,
          ),
          actor: const ModesActor.father(),
        );
      }
      if (active) {
        await modes.activateManual(
          modeId: docId,
          childId: _childId,
          actor: _actor,
        );
      } else {
        await modes.deactivateManual(
          modeId: docId,
          childId: _childId,
          actor: _actor,
        );
      }
      await _loadModes();
    } catch (_) {
      // Partner configure fails honestly — leave UI.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickSchoolBound({required bool isStart}) async {
    if (_busy || !_canConfigure) return;
    final initial = isStart
        ? (_schoolStart ?? SmartModeRow.defaultSchoolStart)
        : (_schoolEnd ?? SmartModeRow.defaultSchoolEnd);

    final TimeOfDay? picked;
    if (widget.pickTime != null) {
      picked = await widget.pickTime!(context, initial);
    } else {
      picked = await showTimePicker(context: context, initialTime: initial);
    }
    if (picked == null || !mounted) return;

    final nextStart = isStart ? picked : _schoolStart;
    final nextEnd = isStart ? _schoolEnd : picked;
    setState(() {
      _schoolStart = nextStart;
      _schoolEnd = nextEnd;
    });

    if (!_usingModes) {
      final school = _prefs
          .row(BuiltInModeId.school)
          .copyWith(scheduleStart: nextStart, scheduleEnd: nextEnd);
      await _persistPrefs(_prefs.withRow(school));
      return;
    }

    setState(() => _busy = true);
    try {
      final modes = _modes!;
      await modes.saveMode(
        draft: ModesUxBridge.draftFor(
          id: BuiltInModeId.school,
          familyId: modes.familyId,
          start: nextStart ?? SmartModeRow.defaultSchoolStart,
          end: nextEnd ?? SmartModeRow.defaultSchoolEnd,
        ),
        actor: _actor,
      );
      await _loadModes();
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isActive(BuiltInModeId id) {
    if (!_usingModes) return _prefs.row(id).active;
    final eval = _evaluation;
    if (eval == null) return false;
    return ModesUxBridge.isActive(eval, id);
  }

  String _modeLabel(AppLocalizations l10n, BuiltInModeId id) => switch (id) {
    BuiltInModeId.sleep => l10n.smartModeSleep,
    BuiltInModeId.school => l10n.smartModeSchool,
    BuiltInModeId.study => l10n.smartModeStudy,
    BuiltInModeId.ramadan => l10n.smartModeRamadan,
    BuiltInModeId.exams => l10n.smartModeExams,
    BuiltInModeId.vacation => l10n.smartModeVacation,
    BuiltInModeId.custom => l10n.smartModeCustom,
  };

  String _formatTod(TimeOfDay? tod) {
    if (tod == null) return '—';
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.smartModesTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
              children: [
                BannerNote(
                  key: SmartModesKeys.honestyBanner,
                  message: l10n.smartModesHostBanner,
                ),
                if (_usingModes) ...[
                  const SizedBox(height: 10),
                  BannerNote(
                    key: SmartModesKeys.ownershipBanner,
                    variant: BannerVariant.t,
                    message: l10n.fs005ModesOwnershipBanner,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    key: SmartModesKeys.wakeHonesty,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.fs005OsWakeHonestyHint,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                      ),
                      const CapabilityHonestyBadge(
                        status: CapabilityStatus.mockRemote,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  l10n.smartModesSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.ink2,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.smartModesListHeading,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                KeyedSubtree(
                  key: SmartModesKeys.modesList,
                  child: Column(
                    children: [
                      for (final id in BuiltInModeId.values) ...[
                        _ModeTile(
                          modeId: id,
                          label: _modeLabel(l10n, id),
                          active: _isActive(id),
                          onChanged: _canConfigure
                              ? (v) => _onToggle(id, v)
                              : null,
                          colors: colors,
                        ),
                        if (id == BuiltInModeId.exams && _usingModes) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              key: SmartModesKeys.examsHint,
                              l10n.fs005ExamsMapsToStudyHint,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                          ),
                        ],
                        if (id == BuiltInModeId.school) ...[
                          const SizedBox(height: 8),
                          _SchoolScheduleCard(
                            startLabel: l10n.smartModeSchoolStart,
                            endLabel: l10n.smartModeSchoolEnd,
                            startValue: _formatTod(_schoolStart),
                            endValue: _formatTod(_schoolEnd),
                            onPickStart: () => _pickSchoolBound(isStart: true),
                            onPickEnd: () => _pickSchoolBound(isStart: false),
                            colors: colors,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.modeId,
    required this.label,
    required this.active,
    required this.onChanged,
    required this.colors,
  });

  final BuiltInModeId modeId;
  final String label;
  final bool active;
  final ValueChanged<bool>? onChanged;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: SmartModesKeys.modeTile(modeId),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? colors.p500 : colors.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ),
          Switch(
            key: SmartModesKeys.modeSwitch(modeId),
            value: active,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SchoolScheduleCard extends StatelessWidget {
  const _SchoolScheduleCard({
    required this.startLabel,
    required this.endLabel,
    required this.startValue,
    required this.endValue,
    required this.onPickStart,
    required this.onPickEnd,
    required this.colors,
  });

  final String startLabel;
  final String endLabel;
  final String startValue;
  final String endValue;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.p50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimeChip(
              key: SmartModesKeys.schoolStart,
              label: startLabel,
              value: startValue,
              onTap: onPickStart,
              colors: colors,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TimeChip(
              key: SmartModesKeys.schoolEnd,
              label: endLabel,
              value: endValue,
              onTap: onPickEnd,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: colors.ink2)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
