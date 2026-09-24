import 'package:flutter/material.dart' show TimeOfDay;

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/modes/modes.dart';
import 'package:family_os/core/policy/smart_modes.dart';

/// Maps Stage-1 FAT-085 ids ↔ FS-005 catalog (MODE-OD-03).
abstract final class ModesUxBridge {
  static ModeCatalogId catalogOf(BuiltInModeId id) => switch (id) {
    BuiltInModeId.sleep => ModeCatalogId.sleep,
    BuiltInModeId.school => ModeCatalogId.school,
    BuiltInModeId.study => ModeCatalogId.study,
    BuiltInModeId.exams => ModeCatalogId.study, // not a separate built-in
    BuiltInModeId.ramadan => ModeCatalogId.ramadan,
    BuiltInModeId.vacation => ModeCatalogId.vacation,
    BuiltInModeId.custom => ModeCatalogId.custom,
  };

  static String modeDocumentId(BuiltInModeId id) =>
      'builtin_${catalogOf(id).wireName}';

  static ModeClockWindow? clockFromTod({
    required TimeOfDay? start,
    required TimeOfDay? end,
  }) {
    if (start == null || end == null) return null;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    if (e <= s) return null;
    return ModeClockWindow(startMinutes: s, endMinutes: e);
  }

  static TimeOfDay? todFromMinutes(int? minutes) {
    if (minutes == null) return null;
    final clamped = minutes.clamp(0, 24 * 60 - 1);
    return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
  }

  static ModeDefinition draftFor({
    required BuiltInModeId id,
    required FamilyId familyId,
    TimeOfDay? start,
    TimeOfDay? end,
    bool enabled = true,
  }) {
    final catalog = catalogOf(id);
    return ModeDefinition(
      id: modeDocumentId(id),
      familyId: familyId,
      catalogId: catalog,
      customLabel: catalog == ModeCatalogId.custom ? 'Custom' : null,
      clockWindow: clockFromTod(start: start, end: end),
      overlay: _defaultOverlay(catalog),
      enabled: enabled,
    );
  }

  static ModeOverlay _defaultOverlay(ModeCatalogId catalog) =>
      switch (catalog) {
        ModeCatalogId.sleep => const ModeOverlay(
          tightenAppAccess: true,
          tightenWebFilter: true,
        ),
        ModeCatalogId.school || ModeCatalogId.study => const ModeOverlay(
          tightenAppAccess: true,
          tightenWebFilter: true,
        ),
        ModeCatalogId.ramadan => const ModeOverlay(tightenWebFilter: true),
        ModeCatalogId.vacation => const ModeOverlay(tightenAppAccess: true),
        ModeCatalogId.familyTime => const ModeOverlay(),
        ModeCatalogId.custom => const ModeOverlay(tightenAppAccess: true),
      };

  static bool isActive(ModesEvaluation evaluation, BuiltInModeId id) {
    return evaluation.applicableModeIds.contains(modeDocumentId(id));
  }
}
