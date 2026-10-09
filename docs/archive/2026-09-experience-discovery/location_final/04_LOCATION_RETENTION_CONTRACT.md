# 04 — Location Retention Contract (FROZEN)

**System:** #4 Location & Safe Zones  
**Status:** FROZEN — 2026-09-23  
**Authority:** Q-LOC-01 · LOC-OD-01/02/07/16 · SOS Final evidence retention (handoff)

---

## 1. Retention classes (distinct)

| Class | Retention | Contents | Authority |
|---|---|---|---|
| **A — Normal location trail** | **90 days** then prune/delete per policy job | Routine `location_ping` / trail samples used for Live history & peace-of-mind | This package (Q-LOC-01) |
| **B — SOS operational evidence samples** | **90 days** (SOS Final RD-03 / Q-SOS-RD-03A) | Location samples **attached to SOS incidents**, delivery/device/battery/connectivity samples, etc. | **SOS Final** (not redefined here) |
| **C — Core SOS lifecycle audit** | **Indefinite** | Incident identity, actors, ack/escalate/resolve, Break-glass audit | **SOS Final** |
| **D — Location config / access audit** | **Indefinite** (append-only; no update/delete APIs) | Zone CRUD, rule changes, Export/Archive, Silent Request authorization, sensitive history opens | Constitution R-10 / this package |

**Law:** Class A and Class B are **both** ~90 days but are **distinct stores/purposes**. SOS evidence must not be “just trail.” Trail prune must not erase Class C/D.

---

## 2. What Q-LOC-01 closed

| Decision | Frozen |
|---|---|
| Normal trail baseline | **90 days** |
| 24h as product baseline | **Rejected** |
| Core safety location existence gated by subscription | **Forbidden** |
| Free-plan “24h + 1 zone” commercial text in old decision log | **Superseded for product baseline** — commercial packaging may still exist elsewhere but **must not** redefine trail law or core availability without a new Owner OD |

---

## 3. Authority of history after sync (LOC-OD-16)

| Store | Role |
|---|---|
| Child device | **Bounded operational cache** only (numbers OPEN — Q-LOC-17) |
| Cloud (post successful sync) | **Authoritative historical** trail for Class A |
| Parent device local | May cache views; must reconcile to cloud authority after sync; no fake “complete history” when offline |

---

## 4. Export / Archive (LOC-OD-05/06/07)

- Export & Archive = **Primary only**.  
- Every Export/Archive attempt (success or deny) → **audit**.  
- Archived copies follow **Primary custody** rules; they are not a Co-Parent entitlement.  
- Retention of *exported files outside the system* is a legal/ops concern — product must warn honesty; exact legal text is L3/compliance, not invented here.

---

## 5. Check-In & Silent Request evidence

- Check-In acknowledgement may attach a **location evidence snapshot** (Domain fact).  
- Classification: treat as **trail-adjacent evidence** retained with Class A unless the Check-In is bound into an SOS incident (then Class B rules apply).  
- Silent Request results retain honest state + optional fix per Class A unless elevated into SOS.

---

## 6. Honesty

- UI may state “kept for 90 days, then deleted automatically” for Class A (already present in Stage-1 copy — aligns with freeze).  
- Must not claim indefinite trail storage.  
- Must not claim wipe of Class C/D when user toggles collection prefs (privacy honesty: retention ≠ live collection — existing privacy pattern).

---

## 7. Open (no invention)

- Exact prune job timing/timezone edge cases → **technical**  
- Bounded cache size/TTL → **Q-LOC-17**  
- Cloud storage density of points inside the 90-day window → **Q-LOC-05**
