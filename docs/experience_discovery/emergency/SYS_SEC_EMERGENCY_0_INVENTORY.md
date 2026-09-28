# SYS-SEC-EMERGENCY-0 — Emergency Setup inventory (Owner)

**Date:** 2026-09-27  
**Screen:** SCR-FAT-028 · إعداد الطوارئ وسلّم التصعيد  
**Route:** `/scr-fat-028` · `EmergencySetupScreen`  
**Method:** Compare → Cover → Compete → Polish · platform cohesion mandatory  
**Status:** **INVENTORY COMPLETE** · **EMERGENCY-1 Cover + dashboard desk** · **EMERGENCY-COMPETE code ready — Owner verify pending** (2026-09-27)  
**Native / Backend:** NOT AUTHORIZED (honesty only · UI-complete now / wire later)

### Desk freeze (Owner plan FAT-028 desk reality)

| Decision | Item |
|----------|------|
| **STAY** | Truth banners · readiness honesty · rung-1 parents · ≤5 backups · Panic Quiet · per-child outside escalation |
| **NEVER** | National number on Setup · mute SOS · A/V SOS settings · second inbox · fake SMS/GPS greenwash |
| **MOVE** | Live incident → FAT-018 · receipts → FAT-019/020 · entry → FAT-025 hub only |

### Compete Local closes (2026-09-27)

| Seam | Status |
|------|--------|
| Per-child prefs consumed on escalate (`SosEscalationResolver`) | Wired |
| Unverified hard-skip (`verifiedEscalationBackups`) | Wired |
| Priority up/down on backup cards | Wired |
| Mother Partner read-only ladder summary | Wired |
| FAT-018 incomplete-readiness CTA | Wired |
| Craft: status-first readiness · verify primary · honesty once | Wired |

---

## 1. Plain picture

**إعداد الطوارئ** is the family’s **calm readiness desk** — not the panic moment.

| Who | Job on this screen |
|-----|--------------------|
| Father (Primary) | Build who gets help first: parents locked, then trusted backups |
| Mother Full | Same configure rights |
| Mother Partner / Observer | View-only / lean — must not silently edit the ladder |
| Child | Does not configure; their SOS button *uses* this ladder |

Emotional job: **trust before fear**. A parent should leave this screen knowing “if my child cries for help, the right people are ready” — without feeling they configured a fake 911 robot.

---

## 1b. Phase gap mission — Father control completeness

Owner law for **this phase on every system** (not only Emergency):

| Need | Meaning on FAT-028 |
|------|--------------------|
| Full control | Father configures the whole escalation desk — parents locked by Policy, backups, delays, verify, Panic Quiet, readiness truth |
| Flexible / mood | Strict day: shorter delays, more verified backups on. Calm day: Panic Quiet, longer delays — **without** muting SOS (sanctity) |
| Real enforcement | Phone + verify + persist actually change who can escalate; no decorative switches |
| Retention | Father feels he need not bolt to Life360/another app for “serious” SOS setup |

Mother Full may configure; Partner/Observer lean. Child never owns this desk.  
**EMERGENCY-1 Cover must be judged against this bar**, not against “match thin prototype.”

---

## 2. Compare — Prototype vs Flutter

| Piece | Prototype (web) | Flutter today | Verdict |
|-------|-----------------|---------------|---------|
| Protocol banner (parents first) | Yes | Yes (`sosLadderProtocolBanner`) | Present |
| SOS cannot be muted banner | Implicit in product law | Yes (`sosReceiptCannotDisableBanner`) | Present (stronger than prototype) |
| Rung 1 father + mother locked | Yes (“إلزامي”) | Yes — SET-020; disabled switches; no remove | Present |
| Backup contacts list | Yes (name, relation, phone, delay, enable, remove) | Partial — name/relation/delay label, enable, remove; **phone not entered in UI** | Partial |
| Add trusted contact | Sheet with real fields | One-tap add with **default ARB name/relation**, delay 60s, unverified | Thin |
| Verification lifecycle | “verified” flag in sample | Enum exists + label shown; **no Start verify / Pending / Revoke UI** | Domain yes · UX missing |
| Escalation delay edit | Shown (“بعد N ثانية”) | Label only; **no editor** | Partial |
| Priority reorder 1…5 | Implicit by list order | `priority` stored; **no reorder UI** | Partial |
| Max 5 backups | Product intent | Enforced + banner | Present |
| Panic Quiet | Not clear in frozen FAT-028 HTML | Toggle persists via SosSettings | Flutter ahead of thin prototype |
| Readiness summary | Weak / absent in HTML | Card with **static** title/body — evaluator exists but **not wired to live rows** | Honesty gap |
| National 911 row on setup | Prototype shows “جاهز دائماً” on FAT-028 | **Correctly omitted** on setup (OD-08 / no national config) — belongs as manual act on FAT-018 | Policy win (do not copy prototype mistake) |
| Mother level gate | Soft in web | Lean empty when `!canConfigure` | Present in screen; **router does not pass live MotherLevel from Identity** (roleOverride defaults) |
| Persist across restart | In-memory `S.emergencyContacts` | Local KV via `SosPrefsRuntime.ladder` | Flutter stronger if bind succeeds |

---

## 3. Prototype incomplete (Owner law — not the ceiling)

The frozen FAT-028 is a **thin ladder list**, not a great readiness experience:

- No guided “are we ready?” checklist with real capability honesty  
- Add-contact is a demo sheet, not a trust-building verification journey  
- National 911 on the **setup** page teaches the wrong mental model (auto readiness vs manual break-glass on the alert board)  
- No emotional copy for “unverified backups will not escalate”  
- No link clarity to “test that the mailbox will ring” (FAT-019 Critical)  
- No empty-to-action path from parent SOS board when setup is incomplete  

**EMERGENCY-1 must cover Flutter gaps and lift past this thin model** — without inventing Native call/SMS/GPS.

---

## 4. Missing for a complete **local** core (EMERGENCY-1 candidates)

Priority for gap **cover** (local only):

| ID | Gap | Why it matters | Cohesion seam |
|----|-----|----------------|---------------|
| E1-01 | Wire `SosReadinessEvaluator` into FAT-028 card (honest rows) | Parent sees truth, not a wallpaper card | Feeds FAT-018 empty CTA |
| E1-02 | Add/edit backup sheet: name, relation, **phone**, delay | Ladder without phone is theater | Escalation later |
| E1-03 | Verification actions: Start verify → Pending → Verified / Failed / Revoke (local sim OK) | Unverified must not look “armed” | Matches domain `canEscalate` |
| E1-04 | Pass live `MotherLevel` / role from Identity into screen (router or scope) | Close SOS-G14 class risk | RoleGuard cohesion |
| E1-05 | Persist Panic Quiet + ladder — prove restart; show save/error honesty | Dead settings forbidden | PrefsMisc / SosPrefs |
| E1-06 | Deep link: incomplete readiness → clear CTA from FAT-018 empty (copy only if already wired) | Closed loop | FAT-018 ↔ FAT-028 |
| E1-07 | Copy: unverified backups skipped in escalation (ARB) | Psychology — no false safety | Policy honesty |

**Defer to Native / later (do not fake in EMERGENCY-1):**

- Real SMS / voice verify codes  
- Real push piercing  
- Live GPS readiness as “available” (keep degraded / notConfigured)  
- Automatic timer worker that calls backups (SOS-G03)  

---

## 5. Native-closed / never fake

| Claim | Status |
|-------|--------|
| Live phone call / VoIP | Closed — snackbar/stub only on FAT-018 |
| SMS to backups | Closed |
| FCM critical channel | Closed — mailbox local projection only |
| Live GPS on setup | Closed — readiness must say notConfigured/degraded |
| Audio SOS broadcast | Closed — Owner decision still open historically |
| National auto-dial from setup | **Forbidden** by product law |

---

## 6. Cohesion map

```
FAT-025 Settings ──► FAT-028 Setup (ladder + Panic Quiet + readiness)
                         │
                         ▼
              CHD-005 hold fire ──► Critical kind `sos`
                         │              │
                         ▼              ▼
                   CHD-006 live    FAT-019 Hub → FAT-020 Detail
                         │
                         ▼
                   FAT-018 parent board
                         │
                         └── empty / not ready ──► back to FAT-028
```

| Seam | Required behavior |
|------|-------------------|
| Notifications | `sos` already **live** Critical — never muted; Setup does not invent a second inbox |
| Identity | Configure = Primary + Mother Full only |
| FAT-018 | Empty / not-ready points here; resolve stays on alert board |
| CHD-005/006 | Consume ladder + settings; do not re-implement contacts |
| Policy | SET-020/021 already closed — do not regress |

---

## 7. Recommended EMERGENCY-1 build order

1. **E1-01** Readiness card ← live evaluator (honesty first — psychology of trust)  
2. **E1-04** Live MotherLevel / role wiring  
3. **E1-02 + E1-03** Backup sheet + verification actions (local sim)  
4. **E1-07 + E1-05** Copy + persist/restart proof  
5. **E1-06** FAT-018 empty ↔ Setup CTA check  

Then Owner scoped verify (Owner runs; agent decides from paste).

**After green cover:** EMERGENCY-COMPETE (Life360 / Family Link / Find My / peer panic settings) → EMERGENCY-POLISH → SOS-LOOP deepen if still needed → Location pack.

---

## 8. Verification (after EMERGENCY-1 — Owner runs)

```powershell
cd "D:\special projects\family\app"
flutter analyze lib/features/n10_emergency/emergency_setup_screen.dart lib/core/sos_final/
flutter test test/features/n10_emergency/emergency_setup_screen_test.dart

cd "D:\special projects\family"
python .cursor/hooks/verify_ship.py verify --scoped
```

Paste EXIT + output. Agent does not run the suite as the normal path.

---

## 9. Evidence sources

- Prototype: `family-os/family_os_app.html` FAT-028  
- Screen: `app/lib/features/n10_emergency/emergency_setup_screen.dart`  
- Domain: `app/lib/core/policy/sos_ladder.dart` · `sos_readiness.dart` · `sos_prefs_local_persistence.dart`  
- Gaps: `docs/experience_discovery/sos/10_SOS_EXPERIENCE_GAPS.md` (SOS-G03/G04/G14/G16…)  
- Engineering: `docs/experience_discovery/sos_screen_engineering/05_FAT_028_ENGINEERING.md`  
- Mailbox: `docs/experience_discovery/notifications/SYS_SEC_NOTIF_0_INVENTORY.md`
