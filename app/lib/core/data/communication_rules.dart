/// PERS-2d — the rules the communication, AI and audit tables are held to.
///
/// Pure Dart, like `geofence_engine.dart`: no drift, no clock of its own. These
/// are the contract's own rules, and each one is a promise made to a parent or
/// to a child — so each is a function that can be tested, not a comment that can
/// be forgotten.
library;

import 'dart:convert';

// ==== constants ====
/// S-COM-006 — "تعديل الرسالة": an edit is allowed for fifteen minutes.
const Duration kMessageEditWindow = Duration(minutes: 15);

/// `ai_suggestion.undone_at` — "تراجع ١٠ دقائق".
const Duration kSuggestionUndoWindow = Duration(minutes: 10);

/// `ai_event.domain` — the contract's "SEC | COM | EDU | ADM".
const Set<String> kAiDomains = {'SEC', 'COM', 'EDU', 'ADM'};

/// `ai_event.severity` — `CHECK (severity BETWEEN 1 AND 5)`.
const int kMinSeverity = 1;
const int kMaxSeverity = 5;

/// `ai_event.payload` — S-AIC-006 "مقتطف التنبيه لا الأرشيف": an excerpt, not an
/// archive. The contract says it with a comment, so the store says it with a
/// limit on the one field that could quietly become an archive.
const int kMaxPayloadChars = 4000;

/// `call_log.kind` and `call_log.outcome` — `text` with a CHECK, so the value
/// sets live here and are enforced on write.
const Set<String> kCallKinds = {'AUDIO', 'VIDEO'};
const Set<String> kCallOutcomes = {'ANSWERED', 'MISSED', 'DECLINED'};

// ==== message rules ====
/// A message may be edited for [kMessageEditWindow] after it was sent.
///
/// The window is measured from the original send, never from the last edit —
/// otherwise a message could be kept editable forever by editing it.
bool messageIsEditable({
  required DateTime sentAt,
  required DateTime now,
  bool deleted = false,
}) {
  if (deleted) return false;
  return now.difference(sentAt) < kMessageEditWindow;
}

/// Whether [actorKey] may edit this message: the author, and only inside the
/// window. A parent does not edit a child's words, and a child does not edit a
/// parent's — the audit trail is the only thing that speaks about a message.
bool senderMayEdit({
  required String senderKey,
  required String actorKey,
  required DateTime sentAt,
  required DateTime now,
  bool deleted = false,
}) =>
    senderKey == actorKey &&
    messageIsEditable(sentAt: sentAt, now: now, deleted: deleted);

/// "حذف للجميع" (S-COM-007) leaves a tombstone, never a hole: the row survives
/// with only its body gone, so a reply that points at it still resolves.
bool messageIsVisible({required bool deleted}) => !deleted;

// ==== suggestion rules ====
/// A suggestion can be undone for [kSuggestionUndoWindow] after it was applied,
/// and only while it is neither already undone nor dismissed.
///
/// The contract's "تراجع ١٠ دقائق" is a promise about a mistake the family can
/// take back — which is only meaningful if it actually expires.
bool suggestionIsUndoable({
  required DateTime appliedAt,
  required DateTime now,
  bool undone = false,
  bool dismissed = false,
}) {
  if (undone || dismissed) return false;
  return now.difference(appliedAt) < kSuggestionUndoWindow;
}

// ==== value-set rules ====
/// `ai_suggestion` carries exactly one action — `action_label` + `action_kind`,
/// never a list. The contract's "زر واحد فقط" is therefore structural: the table
/// has no column that could hold a menu. What is checked here is that the single
/// action is actually filled in.
void requireAction({required String label, required String kind}) {
  if (label.trim().isEmpty) {
    throw ArgumentError.value(
      label,
      'actionLabel',
      'زر واحد فقط — ولا يكون فارغًا',
    );
  }
  if (kind.trim().isEmpty) {
    throw ArgumentError.value(kind, 'actionKind', 'نوع الإجراء مطلوب');
  }
}

/// Rule 13/23 — the AI layer addresses a child by `alias`, never by name. The
/// contract makes that structural (`child_alias` is its only child column); this
/// is the check the store applies on the way in.
void requireAlias(String alias) {
  if (alias.trim().isEmpty) {
    throw ArgumentError.value(
      alias,
      'alias',
      'الذكاء يخاطب بالاسم المستعار لا بالاسم',
    );
  }
}

/// A `jsonb` column cannot hold text that is not JSON — the contract's own type
/// is the rule. Checked on the way in rather than trusted, because a malformed
/// payload would otherwise travel to the server before anyone noticed.
void requireJson(String raw) {
  try {
    jsonDecode(raw);
  } on FormatException {
    throw ArgumentError.value(raw, 'json', 'ليس JSON صالحًا');
  }
}

void requireDomain(String domain) {
  if (!kAiDomains.contains(domain)) {
    throw ArgumentError.value(domain, 'domain', 'allowed: $kAiDomains');
  }
}

void requireSeverity(int severity) {
  if (severity < kMinSeverity || severity > kMaxSeverity) {
    throw ArgumentError.value(
      severity,
      'severity',
      'المدى $kMinSeverity..$kMaxSeverity',
    );
  }
}

/// S-AIC-006 — the payload is an excerpt. A row that would become an archive is
/// refused rather than trimmed, because silent trimming hides the mistake.
void requireExcerpt(String payload) {
  if (payload.length > kMaxPayloadChars) {
    throw ArgumentError.value(
      payload.length,
      'payload',
      'مقتطف لا أرشيف — الحدّ $kMaxPayloadChars حرفًا',
    );
  }
}

void requireCallKind(String kind) {
  if (!kCallKinds.contains(kind)) {
    throw ArgumentError.value(kind, 'kind', 'allowed: $kCallKinds');
  }
}

void requireCallOutcome(String outcome) {
  if (!kCallOutcomes.contains(outcome)) {
    throw ArgumentError.value(outcome, 'outcome', 'allowed: $kCallOutcomes');
  }
}

// ==== chat rules (ADR-053 — «خطّ واتساب المعتدل») ====
/// The reader of a message is one identity held in two columns; these are the
/// kinds the contract allows, exactly as `reader_kind`'s CHECK says.
const Set<String> kReaderKinds = {'ACCOUNT', 'CHILD'};

/// `chat_preference.bubble_theme` — the three themes the visual reference
/// offers. A family chat does not need a theme store.
const Set<String> kBubbleThemes = {'p', 'rose', 'teal'};

/// `chat_preference.wallpaper` — the four backgrounds the reference offers.
const Set<String> kWallpapers = {'light', 'rose', 'mint', 'violet'};

/// WhatsApp's two mute presets; "دائمًا" is [kMuteForeverUntil].
const Duration kMuteEightHours = Duration(hours: 8);
const Duration kMuteOneWeek = Duration(days: 7);

/// "دائمًا" is a real instant far outside any window, never `null`: a null mute
/// and "بلا كتم" would be the same stored value, and the two must not be
/// confused. Expiry is a property of the value, not of a cleanup job.
///
/// Local, not UTC, on purpose: every other instant in this schema is a local
/// `DateTime` (a drift `int` of epoch seconds), so a UTC sentinel would come
/// back out of the database shifted by the offset and stop being itself.
final DateTime kMuteForeverUntil = DateTime(9999, 12, 31);

/// A mute is a window, so it ends by itself instead of needing to be switched
/// back — which is what "٨ ساعات / أسبوع / دائمًا" actually promises.
bool chatIsMuted({required DateTime? mutedUntil, required DateTime now}) =>
    mutedUntil != null && mutedUntil.isAfter(now);

DateTime muteUntilFor({required Duration? preset, required DateTime now}) =>
    preset == null ? kMuteForeverUntil : now.add(preset);

/// ADR-053 — read receipts can be switched off between peers, but not in a
/// thread that has a parent in it: "قرأتُ رسالتك" is what a parent's peace of
/// mind is made of, and S-COM-005 is a P0 promise rather than a preference.
bool receiptsMayBeDisabled({required bool hasParentMember}) => !hasParentMember;

/// The two ticks, each earned by a row rather than assumed.
///
/// There is deliberately no third state: WhatsApp's grey ✓✓ means "delivered",
/// which is a transport fact this device cannot observe. A tick we cannot back
/// is exactly the promise ADR-044 forbids — so it is not drawn.
enum MessageTick { sent, read }

MessageTick tickFor({required int readerCount}) =>
    readerCount > 0 ? MessageTick.read : MessageTick.sent;

/// In a group the blue double tick means "everyone has read it", the sender
/// excluded — so [otherMemberCount] counts the others, not the room.
bool readByAll({required int otherMemberCount, required int readerCount}) =>
    otherMemberCount > 0 && readerCount >= otherMemberCount;

/// S-COM-008 — a tombstone cannot be pinned: a pin is a promise at the top of
/// the thread, and a deleted message is no longer there to keep it.
bool mayPin({required bool deleted}) => !deleted;

/// The pin's three columns are one fact: "مثبّتة، وهذه من ثبّتها" or "ليست
/// مثبّتة". A timestamp with no pinner, or a pinner with no timestamp, is a row
/// nobody can read — the contract says it with a CHECK, and so does this.
void requirePinState({
  required DateTime? pinnedAt,
  required String? byAccount,
  required String? byChild,
}) {
  final pinners = (byAccount != null ? 1 : 0) + (byChild != null ? 1 : 0);
  if (pinnedAt == null ? pinners != 0 : pinners != 1) {
    throw ArgumentError.value(
      pinnedAt,
      'pinnedAt',
      'التثبيت حقيقة واحدة: وقتٌ ومُثبِّت واحد، أو لا شيء',
    );
  }
}

void requireReaderKind(String kind) {
  if (!kReaderKinds.contains(kind)) {
    throw ArgumentError.value(kind, 'readerKind', 'allowed: $kReaderKinds');
  }
}

/// `chat_preference.owner_kind` carries the same two kinds as a reader: the
/// person who opens a thread is the same person who reads in it.
void requireOwnerKind(String kind) => requireReaderKind(kind);

void requireBubbleTheme(String theme) {
  if (!kBubbleThemes.contains(theme)) {
    throw ArgumentError.value(theme, 'bubbleTheme', 'allowed: $kBubbleThemes');
  }
}

void requireWallpaper(String wallpaper) {
  if (!kWallpapers.contains(wallpaper)) {
    throw ArgumentError.value(wallpaper, 'wallpaper', 'allowed: $kWallpapers');
  }
}
