# 05 — FS-005 L3 Parent Wireframes

**Authority:** IA · Role matrix · Flows  
**Form:** Structural wireframes (ASCII) — not visual design tokens invent  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

Stage-1 FAT-085 layout = **non-authority**.

---

## W-P01 — Modes Overview

```
┌──────────────────────────────────────────┐
│ Modes                          [SOS]     │
├──────────────────────────────────────────┤
│ Honesty: last-acked · N devices · …      │
│ Stack: School · Study  → Effective:strict│
│ Upcoming: Sleep tonight 21:00 (grace)    │
├──────────────────────────────────────────┤
│ [ Catalog ] [ Scheduler ] [ Exceptions ] │
│ [ Devices ] [ Audit ]                    │
├──────────────────────────────────────────┤
│ Built-in                                 │
│  Sleep      [active] [detail]            │
│  School     [scheduled]                  │
│  Study      …                            │
│  Ramadan · Vacation · Family Time        │
│ Custom                                   │
│  + Create custom Mode                    │
│  MyFridayFocus …                         │
├──────────────────────────────────────────┤
│ Deep links: Location · App · Web · SC ·ST│
└──────────────────────────────────────────┘
```

**Forbidden on W-P01:** ScheduleWindow twin · loosen Vacation · minute editors · geofence draw.

---

## W-P02 — Mode Detail (configure roles)

```
┌──────────────────────────────────────────┐
│ ← School Mode              [Preview]     │
├──────────────────────────────────────────┤
│ Identity: name · icon                    │
│ Scope: ○ All children  ● Selected [edit] │
│   ✓ Child A  ✓ Child B  (explicit)       │
├──────────────────────────────────────────┤
│ Overlays (tighten-only)                  │
│  App access context → [configure intent] │
│  Web filter tighten → [intent]           │
│  Screen/Camera tighten → [intent]        │
│  Location context → consume FS-001       │
│  ST context → Kernel only (no wallets)   │
│ Banner: cannot reopen Permanent Block    │
├──────────────────────────────────────────┤
│ Schedule: [Open unified scheduler]       │
│ Grace: parent-defined (manual skips)     │
│ ModeExceptions: [Manage]                 │
├──────────────────────────────────────────┤
│ [Activate now] [Deactivate] [Delete]     │
│ Partner/Observer: controls hidden/disabled│
└──────────────────────────────────────────┘
```

---

## W-P03 — Unified Scheduler

```
┌──────────────────────────────────────────┐
│ ← Scheduler · School                     │
├──────────────────────────────────────────┤
│ Channels (one Mode · one authority)      │
│ ☑ Manual override available              │
│ ☑ Clock / weekly                         │
│ ☐ Seasonal                               │
│ ☑ Location-derived (FS-001 facts)        │
├──────────────────────────────────────────┤
│ Weekly: Sun–Thu  07:00–13:45             │
│ Seasonal: [dates]                        │
│ Location: when ENTER [School zone]*      │
│   * zones managed in Location → [Open]   │
├──────────────────────────────────────────┤
│ Upcoming activations                     │
│ Conflicts: see composition if overlap    │
│ [Preview] [Save]                         │
└──────────────────────────────────────────┘
```

**Copy rule:** Never label a panel “Screen Time schedules” as Mode authority.

---

## W-P04 — Active Stack / Composition

```
┌──────────────────────────────────────────┐
│ Active Modes (this child)                │
│ 1. School (location)                     │
│ 2. Study (manual)                        │
│ Effective = stricter intersection        │
│ [Explain]                                │
├──────────────────────────────────────────┤
│ Planes tightened: App · Web · Camera …   │
│ Still reachable: SOS · Chat · Quran      │
│ Not changed: Permanent Blocks · URL lists│
└──────────────────────────────────────────┘
```

---

## W-P05 — Preview-before-apply

```
┌──────────────────────────────────────────┐
│ Preview                                  │
│ Children affected: A, B                  │
│ Stack after apply: School + Study        │
│ Stricter result: …                       │
│ Devices: pending ack expected            │
│ [Cancel] [Apply]                         │
└──────────────────────────────────────────┘
```

---

## W-P06 — ModeException sheet

```
┌──────────────────────────────────────────┐
│ ModeException (Mode overlay only)        │
│ Child · Mode · resource                  │
│ Notice: does NOT edit App Control store  │
│ Notice: does NOT create minutes          │
│ Notice: does NOT rewrite Web lists       │
│ [Need package exception? → App Control]  │
│ [Need minutes? → Screen Time]            │
│ [Confirm] [Cancel]                       │
└──────────────────────────────────────────┘
```

---

## W-P07 — Devices / Ack honesty

```
┌──────────────────────────────────────────┐
│ Devices · Child A                        │
│ Device 1: acked v12 · enforced? (plane)  │
│ Device 2: pending ack                    │
│ Device 3: stale                          │
│ Offline: showing last-acked              │
└──────────────────────────────────────────┘
```

---

## W-P08 — Partner / Observer

Same Overview **read-only**; configure CTAs absent; ticket activate only if granted (Partner).

---

## W-P09 — Audit

Append-only list: created · updated · activated · deactivated · composition · exception · ack — browse, no edit/delete.
