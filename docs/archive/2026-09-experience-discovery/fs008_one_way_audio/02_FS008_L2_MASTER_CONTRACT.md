# FS-008 — One-Way Audio — L2 Master Contract

**Canonical ID:** `FS_008_One_Way_Audio`  
**Date:** 2026-09-25  
**Status:** L2 DRAFT FROM DOMAIN 1 (18 controls) — Gate 7 conflicts marked OPEN  
**Implementation:** NOT AUTHORIZED  

---

## 1. Responsibility

Own the **ambient one-way audio listen** capability: father-initiated, time-boxed capture on child device, transparent to child/mother, audited, geo-gated, non-routine.

## 2. Domain ownership

| Fact | Owner |
|------|--------|
| Ambient mic session lifecycle | **FS-008** |
| Capture plane (OS mic) | Native (contract only) |
| Screen capture / Screen Viewer | FS-004 / S-PAR-028–029 — **not FS-008** |
| SOS incident evidence audio | **Forbidden** (FS-006) — FS-008 must not write SOS evidence audio |
| Location facts (reason “unfamiliar place”) | FS-001 **consumer** only |
| Safe-zone exit as Gate 7 trigger | FS-001 fact → FS-008 **interpretation OPEN** (AUD-C2) |
| Audit append | Audit authority (FAT-060 / append-only) — FS-008 emits facts |
| Identity / RBAC (father-only) | Identity |

## 3. Inputs / outputs

**Inputs:** Father auth + reason enum; child device enrollment; geo/store market flag; optional FS-001 presence/zone facts (if Gate 7 binding is later confirmed).  

**Outputs:** Session record (metadata); encrypted audio blob (Local/Remote TBD); child notification; mother notification; indelible audit row; child-visible history row.

## 4. Invariants (from Domain 1 — frozen product intent)

1. Off by default.  
2. Father-only (no mother activation, even with delegation).  
3. Re-auth every start.  
4. No schedule / no auto-repeat.  
5. Mandatory reason from fixed list (+ other+text).  
6. Clip duration: **60s** (Domain primary; Gate 7 10 min = OPEN AUD-C1).  
7. Max 3/day/child unless emergency exception (Domain).  
8. 15 min cooldown between clips.  
9. Auto-stop if device in a call.  
10. Visible mic indicator — never hide.  
11. Child notified after each clip.  
12. Child can view full history.  
13. Setup acknowledgment for child 13+.  
14. Mother notified each use.  
15. Auto-delete after 7 days (manual export before delete for emergency evidence).  
16. E2E encryption — server cannot read.  
17. In-app listen only — no download/share; block screenshots where platform allows.  
18. Indelible audit — even father cannot delete.

**Geo:** Gulf store markets ON; EU/UK fully OFF; US by state — by **store market**, not user toggle.

## 5. State transitions (L2)

```
DISABLED_DEFAULT
  → ENABLED_MARKET (geo allows + father signed legal warning)
    → IDLE
      → AUTH_CHALLENGE → REASON_CAPTURE → RECORDING(≤60s)
        → UPLOADING/ENCRYPTING → LISTENABLE
          → EXPIRED_OR_PURGED (7d)
      → DENIED (role/geo/quota/cooldown/in-call)
```

## 6. Persistence ownership

| Data | Owner store (target) | Honesty today |
|------|----------------------|---------------|
| Session metadata + reasons | FS-008 Local | MISSING |
| Audio blob | FS-008 Local sealed + optional REMOTE E2E | MISSING |
| Child history projection | FS-008 / child UI | MISSING |
| Audit rows | Audit Log (append-only) | Local audit exists; no FS-008 emitter yet |

## 7. Offline behavior

- Start attempt may queue metadata Local-first; **capture still requires Native mic**.  
- If Native unavailable → honest **NOT IMPLEMENTED / UNAVAILABLE**.  
- Listen may work offline on Local sealed blob if already captured.  
- Geo kill-switch evaluated from Local market config (bundled), not user prefs.

## 8. Cross-system dependencies

| Peer | Relation |
|------|----------|
| FS-004 | **Hard boundary** — mic not SC plane |
| FS-006 | Must not feed SOS evidence audio; reason may reference worry without attaching SOS A/V |
| FS-001 | May supply zone/exit facts if AUD-C2 resolved toward Gate 7 |
| Identity | Father-only RBAC |
| Notifications | Mother + child notify |
| Anti-tamper | Indicator hide attempts → AT / audit (future) |

## 9. Authority boundary

OWNER = FS-008 for ambient listen sessions.  
CONSUMERS = Father listen UI, Child history UI, Mother notify, Audit.  
No second ambient-mic engine under FS-004/006/COM.

## 10. OPEN decisions (block L2 freeze of conflicting fields only)

| ID | Decision needed |
|----|-----------------|
| AUD-C1 | Clip max = 60s (Domain) vs 10 min (Gate 7)? |
| AUD-C2 | Any-time + reason vs SOS-active / zone-exit only? |
| AUD-C3 | Interaction with active SOS incident |
| AUD-C6 | iOS support: Domain silent vs Gate Android-only |
| AUD-C7 | Registry: insert `S-PAR-030` + screens/journeys |

These are **DECISION REQUIRED LATER** for final freeze; Discovery/L2 documentation may proceed with Domain 18-controls as **working baseline**.

## 11. L2 acceptance

```text
FS-008 L2 POLICY: DRAFT COMPLETE (Domain-1 baseline)
OPEN CONFLICTS: AUD-C1…C3, C6–C7
IMPLEMENTATION: NOT AUTHORIZED
```
