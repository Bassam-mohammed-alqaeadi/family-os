# Auto UX Polish — Family Entry (no-mock guard)

> **Status:** Delivered. This file was a 12-line plan; it is now a record of what
> actually shipped, corrected against the code on **2026-10-06**.

**Scope:** CreateFamily (SCR-FAT-001) + AddChild (SCR-FAT-003) only.
**Rule:** same screens, same brand, real states only. No fake success.

## What shipped

| Planned | State |
|---|---|
| CreateFamily: live character counter (x/120), inline over-limit hint, submit disabled when empty / over-limit / submitting | ✅ `create_family_screen.dart` gates submit on `_nameLength <= 120` |
| CreateFamily: SHR-005 error mapping untouched | ✅ unchanged |
| AddChild: server error mapping kept | ✅ unchanged |
| AddChild: inline name counter | ✅ `add_child_screen.dart` builds a `$currentLength / 120` counter and gates the CTA on `_canContinue` |
| Both: 48dp targets, semantics labels, RTL-safe counters, no raw errors | ✅ rune-based counters (`text.runes.length`), so they stay correct in Arabic; semantics present (3 and 11 occurrences); the 48dp target is enforced by the design system, not per screen — `tokens.dart` sets `minimumSize: Size(48, 48)` for UI-015 / Rule 16 and `primary_btn.dart` re-asserts it |

## Corrected claim — emoji and theme are not local display-only

The plan said to keep emoji and theme *"as local display-only until backend contract
admits them."* That was wrong by the time it was written, in two directions:

- **Not local.** `backend/db/migrations/006_family_child_presentation.sql` added durable
  `avatar_emoji` and `theme_color` columns with `CHECK` constraints, `validation.js`
  requires both and rejects unknown fields, and the typed client
  (`foundation_gate/children_roster_api_client.dart`) validates and sends them.
- **Not display-only.** They are the persisted identity of the child's card and the server
  returns them on every roster read.

The prototype screen already carried a real picker: five emoji (`kAddChildCharacters`) and
six colour tokens (`_colorIndex`), sent to the server. The binding contract is
[`03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md`](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md)
§6.

## The one gap that remains

The real client's form in `foundation_gate/children_control_centre.dart` passes the
constants `'🧒'` and `'purple'` instead of offering the choice the prototype already
offers. A guardian on the real path therefore gets a valid, server-persisted profile but
cannot choose how it looks. This is a **UI gap, not a contract gap** — no server, schema,
validation or transport change is needed to close it. Recorded in
[`03` §7](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md).

