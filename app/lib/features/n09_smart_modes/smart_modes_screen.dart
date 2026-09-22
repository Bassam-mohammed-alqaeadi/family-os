import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/core/policy/smart_mode_prefs_repository.dart';
import 'package:family_os/core/policy/smart_modes.dart';

/// Optional time-picker override for widget tests.
typedef SmartModeTimePicker = Future<TimeOfDay?> Function(
  BuildContext context,
  TimeOfDay initial,
);

/// Widget keys for SCR-FAT-085 / SET-018 acceptance.
abstract final class SmartModesKeys {
  static const honestyBanner = Key('smart_modes_honesty_banner');
  static const modesList = Key('smart_modes_list');

  static Key modeTile(BuiltInModeId id) => Key('smart_mode_tile_${id.name}');

  static Key modeSwitch(BuiltInModeId id) =>
      Key('smart_mode_switch_${id.name}');

  static Key schoolStart = const Key('smart_mode_school_start');
  static Key schoolEnd = const Key('smart_mode_school_end');
}

/// SCR-FAT-085 — الأوضاع الذكية (SET-018 school on FAT-085 only).
///
/// Service host map (T-1):
/// - **S-SEC-058** جدول وضع المدرسة → this screen (not SCR-FAT-039)
/// - **S-SEC-059** التفعيل التلقائي بالموقع → this screen (not SCR-FAT-039)
///
/// Never navigates to tombstone SCR-FAT-039 (ADR-034).
class SmartModesScreen extends StatefulWidget {
  const SmartModesScreen({
    super.key,
    this.childId = SmartModePrefs.defaultChildId,
    this.repository,
    this.activationBus,
    this.pickTime,
  });

  final String childId;

  /// Rule 25 seam — null → prefs-backed Stage-1 store.
  final SmartModePrefsRepository? repository;

  /// SET-019 P12 — null → [stage1SmartModeActivationBus].
  final SmartModeActivationBus? activationBus;

  /// Test seam — when null, uses [showTimePicker].
  final SmartModeTimePicker? pickTime;

  @override
  State<SmartModesScreen> createState() => _SmartModesScreenState();
}

class _SmartModesScreenState extends State<SmartModesScreen> {
  late final SmartModePrefsRepository _repository;
  late final SmartModeActivationBus _activationBus;
  late SmartModePrefs _prefs;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? PrefsSmartModePrefsRepository(stage1SmartModePrefsStore);
    _activationBus = widget.activationBus ?? stage1SmartModeActivationBus;
    _prefs = SmartModePrefs.defaults(childId: widget.childId);
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repository.load(widget.childId);
    if (!mounted) return;
    setState(() {
      _prefs = loaded;
      _loading = false;
    });
    // Hydrate child stream from prefs so CHD-004 sees last activation offline.
    _publishActivation(loaded, DateTime.now().toUtc());
  }

  Future<void> _persist(SmartModePrefs next) async {
    setState(() => _prefs = next);
    await _repository.save(next);
    _publishActivation(next, DateTime.now().toUtc());
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

  Future<void> _onToggle(BuiltInModeId id, bool active) async {
    var row = _prefs.row(id).copyWith(active: active);
    if (active && id == BuiltInModeId.school) {
      row = row.seedSchoolScheduleIfNeeded();
    }
    await _persist(_prefs.withRow(row));
  }

  Future<void> _pickSchoolBound({required bool isStart}) async {
    final school = _prefs.row(BuiltInModeId.school);
    final initial = isStart
        ? (school.scheduleStart ?? SmartModeRow.defaultSchoolStart)
        : (school.scheduleEnd ?? SmartModeRow.defaultSchoolEnd);

    final TimeOfDay? picked;
    if (widget.pickTime != null) {
      picked = await widget.pickTime!(context, initial);
    } else {
      picked = await showTimePicker(context: context, initialTime: initial);
    }
    if (picked == null || !mounted) return;

    final next = school.copyWith(
      scheduleStart: isStart ? picked : school.scheduleStart,
      scheduleEnd: isStart ? school.scheduleEnd : picked,
    );
    await _persist(_prefs.withRow(next));
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
    final school = _prefs.row(BuiltInModeId.school);

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
                const SizedBox(height: 12),
                Text(
                  l10n.smartModesSubtitle,
                  style: TextStyle(fontSize: 13, color: colors.ink2, height: 1.5),
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
                          active: _prefs.row(id).active,
                          onChanged: (v) => _onToggle(id, v),
                          colors: colors,
                        ),
                        if (id == BuiltInModeId.school) ...[
                          const SizedBox(height: 8),
                          _SchoolScheduleCard(
                            startLabel: l10n.smartModeSchoolStart,
                            endLabel: l10n.smartModeSchoolEnd,
                            startValue: _formatTod(school.scheduleStart),
                            endValue: _formatTod(school.scheduleEnd),
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
  final ValueChanged<bool> onChanged;
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
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colors.ink2),
            ),
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
