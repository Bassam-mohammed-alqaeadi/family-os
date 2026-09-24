# 03 — Competitive Screen Time Analysis

**Date:** 2026-09-23  
**Sources:** Official help / support docs (Google Family Link, Apple Support, Qustodio Help, Bark Support)  
**Method:** Competitor facts vs Family OS current vs proposed — **no ranking**, no blind copy.

Labels: `COMPETITOR FACT` · `CURRENT FACT` · `PROPOSED DESIGN`

---

## Capability matrix

| Capability | Qustodio | Google Family Link | Apple Screen Time | Bark | Current Family OS | Proposed Family OS |
|---|---|---|---|---|---|---|
| Daily device / entertainment limit | Yes — per weekday; Lock navigation / Lock device / Alert (`COMPETITOR FACT`) | Yes — Daily limit + weekly schedule; per-device allotment (`COMPETITOR FACT`) | App Limits + Downtime; not always a single “device minutes” wallet (`COMPETITOR FACT`) | Daily limits strongest on Bark Phone; routines elsewhere (`COMPETITOR FACT`) | Cap in `ScreenTimePolicy`; mock `used` (`CURRENT FACT`) | Entertainment-only daily cap with real metering + honest platform badges (`PROPOSED`) |
| Schedules / routines / downtime | Routines + restricted times; pause overrides (`COMPETITOR FACT`) | Downtime + School time (2025 expansion) (`COMPETITOR FACT`) | Downtime schedule; Always Allowed (`COMPETITOR FACT`) | Bedtime / School / Free / Default routines (`COMPETITOR FACT`) | Sleep/prayer/study windows + Smart Modes FAT-085 (`CURRENT FACT`) | Unify Schedule + Smart Modes in one IA; keep Islamic prayer/study kinds (`PROPOSED`) |
| App / category limits | Games & Apps: block / allow / limit; categories + exceptions (`COMPETITOR FACT`) | Per-app limits; Unlimited apps (`COMPETITOR FACT`) | App Limits by app or category (`COMPETITOR FACT`) | Category/app block in routines; daily app limits on Bark Phone (`COMPETITOR FACT`) | FAT-034 mock; TimeEngine permanentBlock not wired to inventory (`CURRENT FACT`) | Wire FAT-034 → policy store → TimeEngine (`PROPOSED`) |
| Allowed / Always Allowed / unlimited | Always Allowed on Android during Lock Navigation; still counts to daily (`COMPETITOR FACT`) | Unlimited apps skip Daily Limit; optional during Downtime/School; unavailable on manual lock by default (`COMPETITOR FACT`) | Always Allowed apps/contacts during Downtime (`COMPETITOR FACT`) | Allowed apps per routine (`COMPETITOR FACT`) | S-1 non-countable edu/Quran/calls; chat/SOS lock-exempt (`CURRENT FACT` + law) | Keep constitutional exempt triad; map “unlimited entertainment” as distinct father switch (`PROPOSED`) |
| Extra / bonus time | Add extra time (same day); child request iOS Kids App (`COMPETITOR FACT`) | Bonus time without changing schedules (`COMPETITOR FACT`) | Ask For More Time / One More Minute → parent approval (`COMPETITOR FACT`) | Temporary limit adjustments (`COMPETITOR FACT`) | TimeGrant on approve; **not** applied to wallet/cap (`CURRENT FACT`) | TemporaryGrant credits remaining for today; optional wallet deposit rule (`OWNER`) (`PROPOSED`) |
| Child request flow | iOS request near limit; parent accept/deny; deny may not notify child (`COMPETITOR FACT`) | Parent-initiated bonus primary; child request less central (`COMPETITOR FACT`) | Child Ask For More Time (`COMPETITOR FACT`) | Parent-centric schedule edits (`COMPETITOR FACT`) | CHD-020 **disconnected** from FAT-033 (`CURRENT FACT`) | Single request pipeline + child-visible deny reason (UF-05 already) (`PROPOSED`) |
| Warnings before expiry | ~5 min (Android minute ticks); 15+5 on some iOS paths; schedule may skip (`COMPETITOR FACT`) | Platform lock UX (`COMPETITOR FACT`) | ~5 min before Downtime (`COMPETITOR FACT`) | ~2 min before daily limit (Bark Phone) (`COMPETITOR FACT`) | Register S-3 = 5 min; **no pipeline in code** (`CURRENT FACT`) | Implement S-3 warning + CHD soft banner (`PROPOSED`) |
| Expiry experience | Lock nav / lock device / alert (`COMPETITOR FACT`) | Device locks when limit hit (`COMPETITOR FACT`) | Apps dim/block; Always Allowed remain (`COMPETITOR FACT`) | Apps gray out; Phone remains (`COMPETITOR FACT`) | Calm CHD-021; chat/Quran/SOS remain (`CURRENT FACT`) | Keep calm expiry; never weaken SOS/chat/Quran (`PROPOSED`) |
| Instant pause / lock | Pause internet overrides schedules (`COMPETITOR FACT`) | Manual lock device (`COMPETITOR FACT`) | Screen Time lock / Downtime block (`COMPETITOR FACT`) | Pause internet / routine (`COMPETITOR FACT`) | FAT-037 DeviceLockService top of ladder (`CURRENT FACT`) | Keep lock > modes > caps; father supersedes mother (`PROPOSED`) |
| Multi-device | Cross-platform agent (`COMPETITOR FACT`) | Daily limit **per device** (explicit tip) (`COMPETITOR FACT`) | Syncs across Family Sharing devices (`COMPETITOR FACT`) | Per device + Bark Home Wi-Fi (`COMPETITOR FACT`) | Same-process bus only (`CURRENT FACT`) | Owner must choose per-device vs shared pool (`OWNER`) (`PROPOSED`) |
| Earned / economy currency | Extra time parent grant — not earn-from-chores OS (`COMPETITOR FACT`) | Bonus time — not chore economy (`COMPETITOR FACT`) | Ask for more — not chore economy (`COMPETITOR FACT`) | Temporary adjustments (`COMPETITOR FACT`) | **Differentiator:** Minutes earned via PolicyEngine channels (`CURRENT FACT` / law) | Preserve Minutes economy as Family OS wedge; never XP (`PROPOSED`) |
| Platform honesty | Documents iOS limits / compatible apps (`COMPETITOR FACT`) | Android-first depth (`COMPETITOR FACT`) | Native OS — deepest on Apple (`COMPETITOR FACT`) | Bark Phone deeper than BYOD (`COMPETITOR FACT`) | FAT-067/068 honesty badges exist (`CURRENT FACT`) | Expand honesty to every enforcement claim (`PROPOSED`) |

---

## Lessons (not copies)

1. **Separate daily cap vs schedule vs app limit** — all four competitors make this distinction explicit in UI. Family OS must not bury them in one scroll without status chips.
2. **Bonus/extra time is same-day and reversible** — do not conflate with earned wallet without owner rule.
3. **Always Allowed still needs counting policy** — Qustodio counts Always Allowed toward daily; Family Link Unlimited does not. Family OS already has S-1 countable switch — make it visible.
4. **Child request + parent reason** — Apple/Qustodio prove request UX; Family OS UF-05 (child-visible reject reason) is already stronger than Qustodio’s “deny silent” — keep it.
5. **Multi-device semantics must be explicit** — Family Link’s “per device” tip avoids silent double budgets; Owner decision required for Family OS.
6. **Minutes economy is the wedge** — competitors do not ship Quran/task→wallet loops; do not dilute into points.

---

## Sources

- [Family Link — Manage screen time](https://support.google.com/families/answer/7103340)
- [Family Link — App limits](https://support.google.com/families/answer/15957417)
- [Apple — Screen Time for child](https://support.apple.com/en-us/108806)
- [Qustodio — Daily time limits](https://help.qustodio.com/hc/en-us/articles/360005216797-How-to-set-time-limits-with-Qustodio)
- [Qustodio — Extra time](https://help.qustodio.com/hc/en-us/articles/360016761958-What-is-extra-time-and-how-can-I-use-it)
- [Bark — Screen time schedules](https://support.bark.us/en/articles/13461206-manage-your-kid-s-screen-time-schedule)
- [Bark — Daily limits (Bark Phone)](https://support.bark.us/en/articles/13461110-set-daily-time-limits-for-apps-on-the-bark-phone)
