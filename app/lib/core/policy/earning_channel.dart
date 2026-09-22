/// Constitutionally protected earning channels (Policy Register E-3).
///
/// Changes may only be additive. Minutes flow only through these channels
/// for child assignees (E-4: mother tasks never earn minutes).
enum EarningChannel {
  /// Quran daily portion (FAT-072 ⇄ CHD-025).
  quranPortion,

  /// Athkar (CHD-027).
  athkar,

  /// Learning challenges (FAT-049 ⇄ CHD-015).
  learningChallenge,

  /// Family tasks assigned to children (FAT-054/055).
  familyTaskChild,

  /// Conditional app unlocking.
  conditionalAppUnlock,
}
