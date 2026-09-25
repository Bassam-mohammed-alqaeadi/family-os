/// Stage-1 row vocabulary for the beyond-wave-1 contract (ADR-054).
///
/// The screens speak a small ARB vocabulary — `childOne` … `childThree`, the
/// `DIN/OCC/SCH/ACT` tracks, the task status words — while rows store
/// mechanical values. This file is the single place where the two meet, so no
/// screen learns a new dialect and no Arabic string is ever planted
/// (Law 12 · Rule 23).
library;

/// The row values written to `task.kind`, `task.status`, `task_submission.status`,
/// `calendar_event.category` / `calendar_type` and `calendar_event.who_ref`.
abstract final class Stage1RowVocabulary {
  // ── task.kind ────────────────────────────────────────────────────────────
  static const taskKindChore = 'CHORE';
  static const taskKindHomework = 'HOMEWORK';
  static const taskKindHelp = 'HELP';

  // ── task.status ──────────────────────────────────────────────────────────
  static const statusAssigned = 'ASSIGNED';
  static const statusPendingApproval = 'PENDING_APPROVAL';
  static const statusCompleted = 'COMPLETED';
  static const statusOpen = 'OPEN';
  static const statusDone = 'DONE';

  // ── task_submission.status ───────────────────────────────────────────────
  static const submissionSubmitted = 'SUBMITTED';
  static const submissionApproved = 'APPROVED';
  static const submissionRejected = 'REJECTED';

  // ── calendar_event.category ──────────────────────────────────────────────
  static const categoryDin = 'DIN';
  static const categoryOcc = 'OCC';
  static const categorySch = 'SCH';
  static const categoryAct = 'ACT';

  // ── calendar_event.calendar_type ─────────────────────────────────────────
  static const calendarHijri = 'HIJRI';
  static const calendarGregorian = 'GREGORIAN';

  // ── calendar_event.who_ref, when the whole family is meant ───────────────
  static const whoFamily = 'FAMILY';
  static const whoParents = 'PARENTS';

  /// A child's position in the family becomes the screen's ordinal key —
  /// `childOne` is «الطفل الأول», a label, never a name (Rule 23).
  static String childKeyFor(int ordinal) => switch (ordinal) {
    0 => 'childOne',
    1 => 'childTwo',
    2 => 'childThree',
    _ => 'child${ordinal + 1}',
  };

  /// The reverse: `childOne` → 0. Null when the key is not ordinal at all
  /// (`mother`, `everyone`, a hand-written value).
  static const _ordinalWords = <String, int>{
    'one': 0,
    'two': 1,
    'three': 2,
    'four': 3,
    'five': 4,
    'six': 5,
    'seven': 6,
    'eight': 7,
    'nine': 8,
    'ten': 9,
  };

  static int? childOrdinalFor(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return null;
    final tail = trimmed.replaceFirst('child', '').toLowerCase();
    final word = _ordinalWords[tail];
    if (word != null) return word;
    final parsed = int.tryParse(tail);
    if (parsed == null || parsed < 1) return null;
    return parsed - 1;
  }

  /// `everyone` / `parents` survive as the two shared lanes; a child key
  /// resolves by ordinal; anything else is handed back untouched so the screen
  /// shows the stored value verbatim instead of a different fact.
  static String whoRefFor(String nameKey, List<String> childIds) {
    final key = nameKey.trim();
    if (key.isEmpty || key == whoFamily || key == 'everyone') return whoFamily;
    if (key == whoParents || key == 'parents') return whoParents;
    final ordinal = childOrdinalFor(key);
    if (ordinal == null) return key;
    if (ordinal >= childIds.length) return key;
    return childIds[ordinal];
  }

  static String whoKeyFor(String whoRef, List<String> childIds) {
    final ref = whoRef.trim();
    if (ref.isEmpty || ref == whoFamily) return 'everyone';
    if (ref == whoParents) return 'parents';
    final ordinal = childIds.indexOf(ref);
    if (ordinal == -1) return ref;
    return childKeyFor(ordinal);
  }

  /// A relative time line for the task rows — derived from the row's own
  /// timestamps, never invented. Older than yesterday keeps its date so the
  /// screen cannot claim «اليوم» for last week.
  static String timeKeyFor(DateTime when, DateTime now) {
    final day = DateTime(when.year, when.month, when.day);
    final today = DateTime(now.year, now.month, now.day);
    final deltaDays = today.difference(day).inDays;
    if (deltaDays <= 0) {
      return now.difference(when) < const Duration(hours: 1)
          ? 'tenMinAgo'
          : 'today';
    }
    if (deltaDays == 1) return 'yesterday';
    return _isoDay(when);
  }

  /// The calendar's «متى» line: clock time for today, date + clock otherwise.
  static String whenKeyFor(DateTime when, DateTime now) {
    final time = '${_two(when.hour)}:${_two(when.minute)}';
    final sameDay =
        when.year == now.year && when.month == now.month && when.day == now.day;
    return sameDay ? time : '${_isoDay(when)} $time';
  }

  /// The month card's key carries the real first-of-month; the screen formats
  /// it, and the frozen prototype key stays valid for fixtures.
  static String monthKeyFor(DateTime month) =>
      '${month.year}-${_two(month.month)}-01';

  // ── learn_* rows (ADR-054 §11.2) ─────────────────────────────────────────

  /// `learn_assignment.status` / `learn_progress` states.
  static const learnAssigned = 'ASSIGNED';
  static const learnDone = 'DONE';
  static const learnOpen = 'OPEN';
  static const learnClosed = 'CLOSED';
  static const learnMastered = 'MASTERED';

  /// `learn_session.kind` — a sitting's discriminator.
  static const learnKindLesson = 'LESSON';
  static const learnKindQuiz = 'QUIZ';
  static const learnKindHomework = 'HOMEWORK';
  static const learnKindReview = 'REVIEW';
  static const learnKindChallenge = 'CHALLENGE';

  /// `learn_streak.kind` — stage 1 keeps one aggregate row per child.
  static const learnStreakAll = 'ANY';

  /// `wallet_ledger.reason` — earned by learning, never by a tap (ع-١).
  static const walletEarned = 'EARNED';

  /// `learn_achievement.kind`.
  static const achievementBadge = 'BADGE';

  /// `learn_assignment` has no source column, so the publishing host travels
  /// inside `request_id` as `<source>:<token>` — and survives the round trip.
  static String learnRequestIdFor(String sourceName, DateTime at) =>
      '$sourceName:${stage1RowId('req', at)}';

  static String? learnSourceOf(String requestId) {
    final at = requestId.indexOf(':');
    if (at <= 0) return null;
    return requestId.substring(0, at);
  }

  static String _isoDay(DateTime when) =>
      '${when.year}-${_two(when.month)}-${_two(when.day)}';

  static String _two(int value) => value < 10 ? '0$value' : '$value';
}

/// A stage-1 row id: readable prefix, the clock, and a process counter — so two
/// rows written inside the same millisecond still get distinct keys.
var _stage1RowSeq = 0;

String stage1RowId(String prefix, DateTime at) =>
    '$prefix-${at.microsecondsSinceEpoch}-${_stage1RowSeq++}';
