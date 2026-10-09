# Competitive lens — settings & control fitness

**Owner directive (2026-09-20):** Close open SET/UI settings gaps on services and father/child boards. If a control is unfit for the service, replace it with a better UX (P11 ControlFit). Benchmark against competitors — not feature-copy for its own sake.

Authority still wins: Policy Register → prototype → handoff. Competitors inform **control fitness and honesty**, never invent product law.

## Primary competitors (use on every GapClose / settings ScreenBuild)

| Competitor | What they do well (steal the UX pattern) | What we must not copy blindly |
|---|---|---|
| **Qustodio** | Clear parent dashboard; **routines / bedtime / schedules** as real time windows; per-app limits; web filter that actually enforces; activity reports | Desktop sprawl before Gulf mobile core |
| **Bark** | **Alert-first** safety (flag risk, don’t dump full transcripts); AI suggests, parent decides | Account-linked 30-platform monitoring before device core ships |
| **Google Family Link** | Free-grade clarity: app **approve/deny**, daily limits, bedtime, location — controls that bind | Android/Google-only ceiling; weak content AI |
| **Apple Screen Time** | System-honest limits; Family Sharing basics | No message reading — our SOS/location forever-free must stay clearer than both OS tools |
| **Life360** | Places + arrival; driving/crash as safety adjacent | Not a screen-time/filter suite — don’t pretend location alone is parental control |
| **Net Nanny / Canopy** | Strong web filtering mental model | Niche; don’t over-index before SET-004…006 closed |

Frozen analysis (Arabic+EN): [`prototype/03_COMPETITIVE_PARITY.md`](../prototype/03_COMPETITIVE_PARITY.md) — still valid: security ≥ Qustodio on paper; Bark content gap; education content is the strategic moat (Saudi curriculum), not Duolingo clone.

## ControlFit cheat-sheet (settings)

| Need | Reject (prototype smell) | Prefer (competitor-grade) |
|---|---|---|
| Sleep / prayer / study | Decorative toggle | **Time-range schedule** → TimeEngine (Qustodio routines / Family Link bedtime) — **SET-001** |
| Category filter | CSS-only row | Persist + enforce + child block page (Qustodio/Net Nanny) — **SET-004…006** |
| Platform capability | Toggle looks ON on iOS when unavailable | Disabled + honesty badge (Screen Time honesty) — **SET-016/017** |
| SOS / quiet hours | Mute-all including SOS | Quiet hours **exclude** critical (no competitor mutes panic) — **SET-010/021** |
| AI brain | Local “enable inference” toggle | Server-flag stages; mother never opens control — Bark “you decide” — **SET-014/015** |
| Approve app / unlock | Display-only | Approve/deny → effect + ack (Family Link) — **UI-015**, **SET-006** |
| Father / child boards | Static sample cards | Live bind to mode/status streams — **SET-019**, **UI-004/005/017** |

## GapClose order (owner priority)

1. **SET-001 → SET-024** (Lane 2) — service settings real  
2. **UI-008** settings spine feedback (loading/success/error)  
3. Board hosts: **UI-004** (FAT-010), **UI-005** (CHD-004), **UI-017**  
4. Resume ScreenBuild waves only when linked SET/UI for that host are closed or owner-deferred in QUESTIONS

## Agent rule

Before shipping any settings-related card: name the competitor pattern you matched (one line in CONVERSION_LOG or ship report). If ControlFit changes the prototype control type, note it in GAP_LOG closure text — do not silently redesign unrelated screens.
