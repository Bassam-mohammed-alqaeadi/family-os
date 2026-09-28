# LOCAL DATA REALITY — EXECUTION PLAN

**Date:** 2026-09-26  
**Owner decisions:** **1C** (REAL_LOCAL only; closed caps empty/honest) · **2A** (campaign authorized now; D-FINAL waits)  
**Type:** Authorized frontend/local campaign — production code allowed  
**KEEP + REFINE** UI. Schema/bind/repo/default changes authorized when required for long-term correctness.

---

## 0. Governance

| Field | Value |
|---|---|
| CURRENT PHASE | Frontend closed; VX-B0…B7 PASSED; UX verification pack ready |
| TASK PHASE | **LOCAL DATA REALITY (LDR)** — bind + seed REAL_LOCAL |
| STATUS | **ALIGNED** — Owner-authorized 2026-09-26 |
| REQUIRED GATE | Owner-run analyze/tests per batch; campaign exit → hand off UX verification → D-FINAL |
| PRODUCTION CODE | **YES** |
| Native / Backend | **NOT AUTHORIZED** — remain empty/honest or unavailable |

**Pause:** Final Device Pass (D-FINAL) and end-to-end UX verification execution **wait** until LDR exit criteria pass.

**Resume after LDR:** `user_experience_verification/` pack → D-FINAL.

Companions:

- [LOCAL_DATA_REALITY_GAP_REGISTER.md](./LOCAL_DATA_REALITY_GAP_REGISTER.md)
- [LOCAL_DATA_REALITY_SEED_CONTRACT.md](./LOCAL_DATA_REALITY_SEED_CONTRACT.md)
- [LOCAL_DATA_REALITY_DECISIONS.md](./LOCAL_DATA_REALITY_DECISIONS.md)

---

## 1. Goal

Every **locally supportable** screen/domain:

1. Reads and writes through the real local store (`family_os_fs.db` / `kv_store` / domain tables) via Rule-25 repository seams.  
2. Is seeded with **coherent REAL_LOCAL** family data (generic labels; no Register §10 person names in production UI).  
3. Never fabricates Native/Backend truth (GPS tracks, battery telemetry, AI inference, calls, FCM, billing).  
4. Cross-screen consistency: same family, same children, same local facts everywhere.

Then hand off to final UX verification against a **populated, connected** local app.

---

## 2. Capability classes (law)

| Class | Meaning | Seed / bind |
|---|---|---|
| **REAL_LOCAL** | Product state owned on-device | Bind + seed + persist + relaunch |
| **STATIC_ARB** | Copy-only (welcome, explainers) | No DB required |
| **NATIVE_CLOSED** | Needs OS/native | Empty / unavailable honesty — **no fake rows** |
| **REMOTE_CLOSED** | Needs Backend/AI Gateway/FCM | Empty / unavailable honesty — **no planted “live” AI/calls** |

---

## 3. Database practices (mandatory)

1. **Single session** — `FsSessionKernel` only; no second SQLite file.  
2. **Single owner per fact** — Screen Time `st_*`, AC `ac_*`, Modes `mode_*`, Location `loc_*`, etc. No duplicate authorities.  
3. **Composition root** — all production binds in [`app/lib/main.dart`](../../../app/lib/main.dart) (+ `FsCompositionRuntime`); screens stay repo-interface only.  
4. **Migrations** — versioned `FamilyLocalSchema`; additive migrations; document in Decisions log.  
5. **KV namespaces** — named, owned, documented; no anonymous keys.  
6. **Honesty on Memory fallback** — if SQLite→Memory, do not claim restart-safe durability.  
7. **Seed idempotent** — `ensureSeeded` once; never overwrite user mutations.  
8. **Empty-first for closed** — Advisor/Insights/Tutor/Calls/GPS trails default **empty** in production boot (Mock kept for explicit tests).  
9. **Provenance** — roster/chat seeds carry envelope provenance (`REAL_LOCAL_SEEDED` / prior `LOCAL_DEMO_SEEDED` migrated).  
10. **Blast radius** — every bind change: related screens + focused tests + cross-screen check.

---

## 4. Batch map

| Batch | Scope | Exit |
|---|---|---|
| **LDR-B0** | Markers, this plan, gap register, seed contract, decisions | Docs + markers |
| **LDR-B1** | Honest roster seed; Quran KV boot; location map/history → domain; profile roster bind; empty Advisor boot | Owner TG-1 |
| **LDR-B2** | Child apps UI ← AC+`st_app_axes`; safe-zones always domain; location seed zones (prefs only) | Owner TG-2 |
| **LDR-B3** | Family ops seed (tasks/calendar/circle); chat local sample messages (device-local only) | Owner TG-3 |
| **LDR-B4** | Day board / alerts / ST time requests from local producers only | Owner TG-4 |
| **LDR-B5** | Studio + child-learn: local edu/quran binds; Tutor/generation empty-honest | Owner TG-5 |
| **LDR-B6** | Calls empty-honest; device health empty-honest (remove Fake demo as production default) | Owner TG-6 |
| **LDR-B7** | Invite/device-mgmt local where owned; remaining unbound stage1 audit | Owner TG-7 |
| **LDR-B8** | Cross-screen consistency harness + Matrix `data_source` refresh | Owner TG-8 |
| **LDR-EXIT** | Campaign acceptance → unlock UX verification + D-FINAL | Owner EXIT |

One batch at a time. No Native/Backend implementation.

---

## 5. REAL_LOCAL domain checklist (must all be bound + seeded or empty-by-design)

- [x] Identity family context / members (pre-LDR)  
- [x] Roster children — honest fields (B1)  
- [x] Prefs-misc / locale / screen time KV (pre-LDR)  
- [x] SOS prefs + SOS final tables (pre-LDR)  
- [x] AC / WF / Modes / SC / Offline AI safety tables (pre-LDR)  
- [x] Location UX map/history ← `loc_*` (B1)  
- [x] Safe zones domain path (pre-LDR; lock list always domain in B2)  
- [x] Quran `quran_local` boot hydrate (B1)  
- [x] Family chat thread (pre-LDR); sample local messages (B3)  
- [x] Tasks / calendar / outer circle / arrival / media / focus (pre-LDR; seed B3)  
- [x] Education assignment/result (pre-LDR; deepen B5)  
- [x] Audit log (pre-LDR)  
- [x] Day board / alerts from local only (B4)  
- [x] Child apps inventory from AC (B2)  
- [x] Advisor/Insights/Tutor production empty (B1/B5/B7)  
- [x] Calls production empty (B6)  
- [x] Device health production empty (B6)  
- [x] Matrix data_source refresh + cross-screen harness (B8)  

---

## 6. Explicit non-goals

- Real GPS, OS enforcement, camera, biometrics  
- AI Gateway inference, FCM, billing, multi-device chat relay  
- Redesign / new screens / resurrect OTP/role-picker  
- Planting Register §10 names in production widgets  

---

## 7. Owner test gates (focused)

Per batch:

```text
cd app
flutter analyze
flutter test <paths listed in batch .verify note>
```

Campaign exit / before D-FINAL:

```text
flutter test test/goldens/vx_b7_system_homes_render_test.dart
python .cursor/hooks/verify_ship.py verify --full
```

---

## 8. Exit criteria → handoff

LDR is complete when:

1. Gap register: every REAL_LOCAL row CLOSED; every NC/RC row EMPTY-HONEST.  
2. No production boot path serves MockAdvisor planted suggestions or FakeDeviceHealth as “live”.  
3. Kill→relaunch preserves REAL_LOCAL seeds and user mutations.  
4. Cross-screen: same children/family on Today, Kids, Profile, Chat, Zones, Tasks.  
5. Decisions log lists every changed technical default.  
6. Owner marks **LDR-EXIT PASSED**.

Then: execute `user_experience_verification/` → **D-FINAL**.
