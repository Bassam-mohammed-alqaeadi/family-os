# 09 — FS-002 Cross-System Boundaries (L2 Target) — FROZEN

**Status:** FROZEN · WF-OD-10…13 · WF-OD-11 · WF-SF-01/02

---

## 1. Boundary table

| System | Frozen boundary |
|---|---|
| **Screen Time** | Independent gate; unlock ≠ grant/wallet |
| **SOS** | Never disabled by filter |
| **FS-005 Modes** | Owns scheduling; filter consumes context; Modes **tighten only** (WF-OD-10/13) |
| **FS-003 App/System Control** | **Stricter intersection**; clear source-of-deny (WF-OD-12) |
| **FAT-078 Router** | Optional honest add-on; not core on-device claim (WF-OD-11) |
| **FS-001 Location** | Independent |
| **Anti-tamper** | May support plane integrity; not a substitute for WF-OD-04 verification |
| **Notifications / Audit** | Deliver/store Kernel/Domain outputs per contracts 08 |
| **AI** | Suggest only |

---

## 2. Precedence (access)

```
SOS / required Chat / Quran exemptions
  → Stricter intersection( App Control , Web Filter(effective + Mode tighten) )
  → Minutes economy remains independent for time budget
```

If App Control DENY or Web Filter DENY → DENY.  
Permissive side cannot override the other deny.

---

## 3. Source-of-deny UX

Parent and child interstitial copy must distinguish:

- Denied by **Web Filter**  
- Denied by **App/System Control**  
- Denied by **both**

---

## 4. Discovery contradictions resolved by Owner

| Former conflict | Resolution |
|---|---|
| Father-only configure | WF-OD-02 Primary+Full |
| Permanent allow | WF-OD-09 timed temporary |
| 6 vs 29 categories | WF-OD-05 large normative; taxonomy technical |
| FAT-078 mock | WF-OD-11 optional honest add-on |
| Capability table “full” | WF-OD-04 verified hybrid only |

---

## 5. Remaining ambiguity (technical only)

Which concrete OS mechanism implements the on-device agent / fallbacks — **T-WF-03** after verification, without changing product hybrid law.
