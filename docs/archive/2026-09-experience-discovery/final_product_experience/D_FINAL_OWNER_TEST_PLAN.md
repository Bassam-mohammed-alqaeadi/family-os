# D-FINAL — Owner Device Test Plan & Report Sheet

**Program:** FINAL VISUAL · UX · JOURNEY VERIFICATION  
**Gate:** FINAL DEVICE PASS (D-FINAL)  
**Authority:** Program §13 + Execution Plan D-FINAL + deferred PENDING-DEVICE from VX-B1…B7  
**Tester:** Bassam (Owner) — Cursor does **not** run the phone  
**Date started:** _______________  
**Date finished:** _______________

---

## 0. Session header (fill first)

| Field | Device A (small ≤360 dp if possible) | Device B (normal phone) |
|---|---|---|
| Model | | |
| Android version | | |
| Screen width (approx dp / “Small display” on?) | | |
| Build / how installed (debug APK / run from IDE) | | |
| App language at start | AR / EN | AR / EN |

**Result codes (use everywhere):**
- **P** = PASS  
- **F** = FAIL (write note + Screen ID)  
- **NA** = not applicable on this device  
- **BN** = BLOCKED-NATIVE (honest closed state still OK)  
- **BR** = BLOCKED-REMOTE (honest closed state still OK)

**Rule:** one **F** → note it; do **not** stop the whole plan unless the app crashes. Finish the sheet, then send Cursor the Fail log.

---

## 1. Core Program §13 (run on BOTH devices)

| # | Check | What “PASS” looks like | A | B | Notes |
|---|---|---|---|---|---|
| 1 | Cold start → Welcome → Login → Today | No crash; no debug toast; Today opens for father | | | |
| 2 | Parent tabs + Back | Today / Kids / Family / Studio / Settings switch cleanly; drill-down Back returns to origin (not exit app) | | | |
| 3 | Keyboard / forms | Add child, safe zone name, chat send, task fields: keyboard does not permanently hide Save/Send | | | |
| 4 | Touch targets | Login forgot + invite link, chips, steppers, hub tiles: easy to hit | | | |
| 5 | Kill & relaunch | After adding/editing: child name on Kids, family chat message, language, settings choices still there | | | |
| 6 | Role switch SHR-008 | Father → child (Settings → switch user): lands on child home; father’s prior change visible where expected | | | |
| 7 | SOS actor | SOS from child screen → alert names that child; SOS from parent while viewing a child → correct child | | | |
| 8 | Contrast outdoors | Secondary grey text (`ink2`) readable in daylight / bright room | | | |
| 9 | Small vs normal layout | Maps, hub strip, SOS/AI FABs do **not** cover primary content; no yellow/black overflow stripes | | | |

---

## 2. Parent shell tour (Device A **or** B — mark which: ___)

Do in order. Mark P/F per row.

### 2.1 Identity & onboarding smoke
| Step | Screen | Action | P/F | Note |
|---|---|---|---|---|
| 2.1.1 | SHR-001 Welcome | Open app cold | | |
| 2.1.2 | SHR-003 Login | Empty submit → validation; honesty “saved on this device”; forgot/invite tappable | | |
| 2.1.3 | SHR-003 | Fingerprint → honest “coming later”, stays on login | | |
| 2.1.4 | FAT-010 Today | Loads; honesty / local-save line visible if shown | | |

### 2.2 Today & decisions (VX-B5)
| Step | Screen | Action | P/F | Note |
|---|---|---|---|---|
| 2.2.1 | FAT-010 | Pending card shows real waiting items if any (time / app / friend) — not only learning | | |
| 2.2.2 | FAT-010 | Quick action Quran / Lock / Map → opens **with** child context; system Back returns to Today | | |
| 2.2.3 | FAT-019 Alerts | Hub not always empty after SOS or known local events | | |
| 2.2.4 | FAT-025 Settings | “Other” has device switch only — **no** Accept invite / SOS alert shortcuts | | |

### 2.3 Kids & add child (VX-B6)
| Step | Screen | Action | P/F | Note |
|---|---|---|---|---|
| 2.3.1 | FAT-012 Kids | List readable; new child without device shows “device not linked” style line (not empty `📍 ·`) | | |
| 2.3.2 | FAT-003 Add child | Type Arabic name + age + character + colour → Continue | | |
| 2.3.3 | Kill app → relaunch | Same name appears on Kids / Today / profile | | |
| 2.3.4 | FAT-013 Profile | Open one child; tools keep that child | | |

### 2.4 Chat (VX-B6 / OD-09)
| Step | Screen | Action | P/F | Note |
|---|---|---|---|---|
| 2.4.1 | FAT-021 Family | Family thread exists (not empty forever); honesty “saved on this device only” | | |
| 2.4.2 | FAT-022 | Send a message | | |
| 2.4.3 | Kill → relaunch | Message still there | | |
| 2.4.4 | Switch to child → CHD-007/008 | Child can see family thread / message | | |

### 2.5 Location / safe zone residue (VX-B6)
| Step | Screen | Action | P/F | Note |
|---|---|---|---|---|
| 2.5.1 | FAT-017 Create zone | Name field **empty** (hint only); cannot save blank name | | |
| 2.5.2 | Save zone | Emoji is 📍 (not karate); toast OK | | |
| 2.5.3 | Map screens | At small width: map art not clipped; FABs not covering content | | |

### 2.6 Settings / language / honesty
| Step | Screen | Action | P/F | Note |
|---|---|---|---|---|
| 2.6.1 | FAT-061 Language | Switch AR ↔ EN; UI language updates | | |
| 2.6.2 | Hub labels | Tabs/hub text follow language (no stuck English in AR) | | |
| 2.6.3 | FAT-027 Members | Opens; role labels readable | | |
| 2.6.4 | SHR-008 Switch user | Profiles listed (not empty forever if family exists) | | |

---

## 3. Child shell tour (after role switch)

| Step | Screen | Action | P/F | Note |
|---|---|---|---|---|
| 3.1 | CHD-004 My Day | Opens for child; no parent-only leakage | | |
| 3.2 | CHD-012 Learn | Level card no overflow at small width / large text | | |
| 3.3 | CHD-007 Chats | Family thread reachable | | |
| 3.4 | CHD-010 What is collected | Opens; honest transparency | | |
| 3.5 | Child SOS | Fire SOS → parent alert side shows this child | | |
| 3.6 | Tabs | My Day / Learn / Family / Me switch + Back OK | | |

---

## 4. Father↔child loop mini-checks (from VX-B2 / B5 / B6)

| Loop | Steps | P/F | Note |
|---|---|---|---|
| L1 Child context | As father, open child **B** profile → Web filter or Lock → change → switch to child B → change visible | | |
| L2 Time request | Child requests time → father Today/inbox shows it → approve → child minutes update | | |
| L3 Chat round-trip | Father sends family message → child reads after relaunch | | |
| L4 Add-child name | Arabic name survives kill/relaunch on Kids + Today | | |

---

## 5. Visual / RTL spot checks (both languages)

Run once in **AR**, once in **EN** (FAT-061). Mark overall P/F.

| Spot | AR | EN | Note |
|---|---|---|---|
| Chevrons point reading-forward | | | |
| FABs on the “end” side (not wrong corner) | | | |
| Western digits on Arabic UI (OD-05) | | | |
| Toasts not hidden behind tab/FAB | | | |
| No English badge/hub leakage in AR | | | |

---

## 6. Explicit “do NOT expect” (honest closed — mark BN/BR if UI claims otherwise)

| Capability | Honest expectation | OK? |
|---|---|---|
| Live GPS / battery | Demo / closed — banners honest | |
| Fingerprint login | Toast “coming later” — no fake success | |
| Multi-device chat delivery | Local only — glossary line | |
| Calls / camera / QR camera | Native closed or mock | |
| Push / FCM / email | Remote closed | |
| AI Gateway | Suggest only / coming-soon where designed | |

If UI **claims** live GPS/FCM/fingerprint success → **F** (honesty fail).

---

## 7. Fail log (copy every F here)

| ID | Device | Screen ID | § / Step | What you saw | Screenshot? Y/N |
|---|---|---|---|---|---|
| F1 | | | | | |
| F2 | | | | | |
| F3 | | | | | |

---

## 8. Session verdict (Owner)

| Question | Answer |
|---|---|
| §13 items 1–9 on Device A | All P / Has F |
| §13 items 1–9 on Device B | All P / Has F / Only one device |
| Critical loops L1–L4 | All P / Has F |
| Honesty closed states (§6) | All OK / Has F |
| Ready to mark D-FINAL PASSED? | YES / NO — needs fixes first |

**Owner signature / initials:** _______________  
**Send to Cursor:** paste §0 header + §7 Fail log + §8 verdict (and screenshots of F rows).

---

## 9. After D-FINAL (so nothing is forgotten in the program)

| Next gate | Who | What |
|---|---|---|
| Cursor records `.verify/VX-DEVICE-FINAL.json` | Cursor | From your paste |
| Matrix `PD` → PASS (or FAIL→fix) | Cursor | After evidence |
| **Final Product Re-Audit** | Cursor + your OK | Docs/matrix/findings consistency |
| **Final Frontend Certification** | **You** run analyze + full `flutter test` + `verify --full` | Broad gate |
| Optional VX-B8 mock tidy | Owner authorize | Not required for STOP |
| Phase 5 Native / Backend | Separate `CHANGE PHASE` | **Not** part of D-FINAL |

---

## 10. Suggested time box

| Block | ~Time |
|---|---|
| §0 + §1 on Device A | 25–40 min |
| §2–§4 parent/child/loops | 45–75 min |
| §5 language + §6 honesty | 15–25 min |
| Repeat §1 critical on Device B (or font/size stress) | 20–30 min |
| Write Fail log + verdict | 10 min |
| **Total** | **~2–3 hours** careful pass |

If you only have **one** phone: run full plan once, then repeat §1 + §2.5.3 + §5 with **Display size / Font size** increased in Android settings (simulates “small + large text”).
