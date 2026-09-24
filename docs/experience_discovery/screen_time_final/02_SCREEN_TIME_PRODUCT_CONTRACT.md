# 02 — Screen Time Product Contract (FROZEN)

**Status:** **SCREEN TIME PRODUCT CONTRACT STATUS: FROZEN**  
**Date:** 2026-09-23  
**Entry companion:** [13_SCREEN_TIME_FINAL_MASTER_CONTRACT.md](13_SCREEN_TIME_FINAL_MASTER_CONTRACT.md)

---

## Product definition

Family OS Screen Time governs **entertainment** access for a child using:

1. Policy rules (caps, schedules, modes, blocks, unlimited, overflow)  
2. Minutes economy (daily allowance, temporary grants, per-app earned wallets)  
3. Role-authorized decisions (requests, locks, edits)  
4. Device enforcement (future platform) + honest Stage-1 simulation until then  

**Currency:** Minutes only — never points/XP/coins.

---

## What Screen Time is / is not

| Is | Is not |
|---|---|
| Entertainment digital-wellbeing control | Subscription gate for SOS/chat/location |
| Child-level shared daily entertainment budget (ST-OD-001) | Silent per-device budget multiplication |
| Calm child experience at expiry (S-4) | Punitive lock wall |
| Distinct Daily / Grant / Wallet | One unexplained “points” number |
| Policy + economy product | Claim of OS metering before it exists |

---

## Frozen user promises

### Primary Parent
Can configure child-level caps, schedules, app rules, overflow, unlimited flags, mode exceptions; decide all grants; own mother ceiling rules; see Policy Health honesty.

### Mother
Level-specific (see Role Contract) — not a hidden-button clone of Father UI.

### Child
Sees remaining (three-part model), warnings at 5 minutes, calm expiry, request loop, protected Chat/Quran/SOS — without fake metering claims.

---

## Frozen request loop (desired — not implemented in this phase)

```
Child → createRequest() → REQUEST_PENDING
  → Parent/Mother decision → approved | denied
  → Temporary Grant (if approved) → child feedback → remaining update
```

---

## Frozen child experience beats

| Phase | Must show / allow |
|---|---|
| Before expiry | Remaining Minutes, when it ends, what consumes, what is protected |
| At 5 minutes (WARNING) | Calm warning · Request More Time · Quran · Chat · SOS |
| At expiry (EXPIRED) | Calm restricted UX · Request More Time · Quran · Chat · SOS · no punitive wall |

---

## Honesty law (FROZEN)

Never claim, unless implemented and proven:

- real usage metering  
- OS enforcement  
- real multi-device synchronization  
- actual notification delivery  

Stage-1 may claim: in-app policy save, in-process mirror, simulated enforcement state.

---

## SOS compatibility (FROZEN — non-negotiable)

SOS remains available regardless of:

- time expiry  
- screen-time restriction  
- smart mode  
- instant lock  
- subscription  

Any discovery wording that could be misread as “SOS unavailable during mode” is **void**. Correct freeze: SOS is **outside** the entertainment ladder (P0).

---

## Out of scope for this freeze

- Flutter / backend / Android / iOS implementation  
- Screen Engineering pack  
- Numeric stale-policy TTL  
- Travel-timezone UX detail beyond “explicit + auditable”  
- Consumption API implementation  

Discovery evidence remains in `docs/experience_discovery/screen_time/` (non-authoritative vs this freeze).
