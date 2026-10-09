# LOCAL DATA REALITY — SEED CONTRACT

**Owner:** 1C REAL_LOCAL · no fabricated Native/Backend data  
**Rule 23:** Generic labels only in production seeds (ابن 1 / Child 1). Register §10 names stay in `mock/` for tests only.

---

## 1. Family + children (Identity / roster)

| Field | Seed? | Notes |
|---|---|---|
| child id, displayName, emoji, swatch, ageYears | YES | Stable IDs `demo-child`, `child_b`, `child_c` |
| locationLabel | NO — empty / honesty “unavailable” | Was fake GPS — **removed in LDR-B1** |
| lastSeenLabel | NO — empty | Was fake heartbeat |
| batteryLabel | NO — empty | Was fake telemetry |
| timeLeftLabel | OPTIONAL from Screen Time local | Else empty |
| health / warnRing | Derived only from real local signals | Else excellent/neutral without fake risk |

**Provenance:** `REAL_LOCAL_SEEDED` (migrate away from implying GPS demo).

**Families:** `fam_stage1` (2 children), `fam_stage2` (1 child) — unchanged IDs for Stage-1 alignment.

---

## 2. Safe zones (`loc_*`)

Seed **definitions only** (name, geometry placeholder, assigned children, alerts flags).  
**Do not** seed `loc_trail_sample` GPS fixes or presence as “live location.”

---

## 3. Family chat

- Thread seed: keep family thread (OD-09).  
- LDR-B3: allow **1–3 device-local sample messages** in `family_chat` KV — REAL_LOCAL single-device; honesty “saved on this device”; never claim multi-device delivery.

---

## 4. Tasks / calendar / outer circle

Seed a small coherent set tied to roster child IDs (one open task, one calendar event, one circle contact) — all Local KV.

---

## 5. Education / Quran local

- Assignments/results: optional sample metadata rows.  
- Quran bridge: hydrate empty or prior flags; **no** licensed verse fabrication.

---

## 6. Forbidden seeds

- GPS trails / live map “at school now” claims  
- Battery % / last-seen minutes as telemetry  
- Advisor / Insights / Tutor suggestion bodies as live AI  
- Call logs as completed PSTN/VoIP calls  
- FCM delivered / billing active claims  
- Device health Fake.demo as production default  

---

## 7. Idempotency

`ensureSeeded` writes only when namespace/family empty. Never clobber user edits after first run.
