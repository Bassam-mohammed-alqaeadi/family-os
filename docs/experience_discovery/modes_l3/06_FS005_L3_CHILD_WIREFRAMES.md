# 06 — FS-005 L3 Child Wireframes

**Authority:** MODE-OD-10 · MODE-OD-14 · MODE-SF-04  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

Child never authors Modes. Stage-1 CHD-004 tint = evidence only.

---

## W-C01 — Active Mode card (single)

```
┌──────────────────────────────────────────┐
│ 🏫 School Mode is on                     │
│ Some apps and sites are limited now      │
│ [SOS] [Family Chat] [Quran]              │
└──────────────────────────────────────────┘
```

---

## W-C02 — Multi-mode card

```
┌──────────────────────────────────────────┐
│ Modes on: School · Study                 │
│ Stricter rules apply while both are on   │
│ [SOS] [Family Chat] [Quran]              │
└──────────────────────────────────────────┘
```

**Forbidden:** “Only one Mode” · deactivate buttons · edit schedule.

---

## W-C03 — Grace banner (scheduled activation)

```
┌──────────────────────────────────────────┐
│ ⏳ Finish what’s in hand — Mode starting │
│ Parent set a short grace · then School   │
│ (No control that permanently cancels Mode)│
│ [SOS] [Family Chat] [Quran]              │
└──────────────────────────────────────────┘
```

**Rejected:** Prototype “أنهيت ✓” that clears grace as policy cancel.  
Optional future “I’m ready” may only acknowledge UX — **must not** deactivate Mode (**MODE-OD-10**).

Manual activation: **no** grace banner (skipped).

---

## W-C04 — Mode restriction interstitial

```
┌──────────────────────────────────────────┐
│ Not available during School Mode         │
│ Source: Mode (not Permanent Block)       │
│ Still available: SOS · Chat · Quran      │
│ [Open SOS] [Family Chat] [Quran]         │
└──────────────────────────────────────────┘
```

If deny is actually Permanent Block / Web / Camera / Instant Lock — **different source label** (cross-system UX). Child cannot mutate wrong system.

---

## W-C05 — Offline / last-acked

```
┌──────────────────────────────────────────┐
│ Mode status from last sync               │
│ (honest offline — not “live cloud”)      │
│ [SOS] …                                  │
└──────────────────────────────────────────┘
```
