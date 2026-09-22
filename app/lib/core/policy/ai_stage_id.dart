/// Lean AI stage ids for SET-014 (charter stages 2–4 subset).
///
/// Charter: محلل / مستشار / مساعد — server feature flags only (Rule 26).
/// Stages 1 (monitor) and 5 (agent) stay out of this lean control surface.
enum AiStageId {
  /// المرحلة ٢ — المحلل
  analyze,

  /// المرحلة ٣ — المستشار (suggest-only gateway)
  suggest,

  /// المرحلة ٤ — المساعد التفاعلي (coach Q&A; still suggest-only in Stage-1)
  coach,
}

extension AiStageIdX on AiStageId {
  String get storageKey => name;
}
