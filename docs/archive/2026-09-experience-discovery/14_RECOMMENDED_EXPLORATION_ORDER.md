# 14 — Recommended Exploration Order (Family OS)

**Date:** 2026-09-23  
**Purpose:** Order for the **next phase** (system-by-system experience closure).  
**Not** an implementation plan or redesign.

---

## Principles

1. Safety & honesty before expansion.  
2. Close **wiring lies** (placeholders / false capability) before new features.  
3. Father → Mother → Child loops for each system.  
4. Prefer systems with existing policy cores (faster truth) then hard platform systems.

---

## Recommended order

### Phase E0 — Orientation (1 pass)
1. Read `15_MASTER_DISCOVERY_SUMMARY.md` + this package.  
2. Diff `router.dart` builders vs `features/***_screen.dart` (resolve XD-006 inventory).  
3. Re-read `GAP_LOG.md` open rows + `harness/LOOP_STATE.md`.

### Phase E1 — Trust & safety spine
4. **SOS** — document real vs mock; required external deps (XD-005).  
5. **RoleGuard / mother levels** — map every approve path.  
6. **Notification critical path** — what “deliver” means without FCM.

### Phase E2 — Enforcement truth
7. **Screen time** — TimeEngine vs Android/iOS enforcement gap (XD-002).  
8. **Web filter** — evaluator vs VPN/DNS.  
9. **Instant lock / anti-tamper** — DeviceLockService vs MDM.  
10. **Platform capability honesty** — extend honesty pattern to other domains.

### Phase E3 — Identity & sync foundation
11. **Auth / family / pairing** — schema tables vs mock onboarding.  
12. **Persistence** — memory prefs → durable store decision exploration.  
13. **Sync buses** — what must become real outbox.

### Phase E4 — Family communication & location
14. Chat mock → messaging requirements.  
15. Calls UI → LiveKit (or chosen) requirements.  
16. Location/geofence UI → GPS + geofence_event pipeline.

### Phase E5 — Co-parent completeness
17. Mother journeys screen-by-screen (U-007).  
18. Invite/accept → member.perm_level server story.

### Phase E6 — Child day-to-day
19. Child day board + expiry + wallet honesty.  
20. Child mode lock / second key real semantics.  
21. Wire or explicitly mark learn placeholders (XD-006).

### Phase E7 — Education loop
22. Close exploration of P15-EDU-006/007 (submit→FAT-050).  
23. Studio assign → minutes reward → child wallet.

### Phase E8 — Advisor / insights
24. MockAdvisor surfaces vs AI Gateway seams (Rule 26).  
25. Mother AI feed vs father brain control boundaries.

### Phase E9 — Growth / monetization
26. Billing mock vs store entitlements; re-verify safety ungated.  
27. Coming-soon catalog honesty audit.

---

## What not to do in exploration yet

- Redesign visual system.  
- Rewrite constitution.  
- Assume Firebase.  
- Batch multi-system “fixes” without per-system evidence.

---

## Success criterion for exploration phase

For each system: a short **truth sheet** stating Parent / Mother / Child journeys with A–H statuses and explicit **device effect = none|mock|OS**.
