# 02 — FS-002 Policy Contract (L2 Target) — FROZEN

**Status:** FROZEN with Owner decisions WF-OD-01…15  
**Authority:** [01_FS002_L2_OWNER_DECISIONS.md](01_FS002_L2_OWNER_DECISIONS.md)

---

## 1. Mission

FS-002 protects children from unwanted web content under authorized family policy, with honest enforcement availability, Primary/Co-Parent/Child authority, local evaluation on verified planes, auditable timed exceptions, and no interference with SOS / required chat / Quran paths.

---

## 2. Non-goals

- Claiming filtering without a verified active capability plane (WF-SF-10 · WF-OD-04)  
- Full browse-history surveillance (WF-OD-14)  
- Permanent allow on unlock approve (WF-OD-09)  
- Independent Web Filter scheduler (WF-OD-10)  
- Router DNS as core on-device claim (WF-OD-11)  
- Modes weakening base filter (WF-OD-13)  
- Stage-1 six-category freeze (WF-OD-05)  
- AI execute without approval (WF-SF-08)

---

## 3. Domain vs Policy Kernel (WF-SF-03)

| Web Filter Domain | Policy Kernel |
|---|---|
| Effective policy resolution (family + child override) | Notify/action from canonical events |
| List data; evaluation results; ticket facts; plane capability reports | Precedence outcomes with Modes/App Control per frozen law |
| Must not fake OS/cloud success | Must not invent deny facts |

---

## 4. Policy scope (WF-OD-01)

**Family default + optional per-child overrides.**

**Precedence:** Family baseline applies **unless** a child-specific override exists for that child — then the **child override** is effective for that child.

Effective policy resolution is a Domain responsibility before evaluation.

---

## 5. Policy document (normative concepts)

| Concept | Law |
|---|---|
| Family baseline policy | Required |
| Optional per-child override | Optional; when present, wins for that child |
| `policyVersion` | Required; bump on save |
| Large category model | Direction frozen (WF-OD-05); content taxonomy = technical contract (T-WF-02) |
| Allowlist / Blocklist / Dictionary | First-class (WF-OD-08) |
| Safe Search flag | In-scope mandatory where enforceable (WF-OD-06) |
| Private-browse posture | Platform honesty matrix (WF-OD-07) |
| Mode context input | Consumed from FS-005 (WF-OD-10); may only tighten (WF-OD-13) |

---

## 6. Evaluation principles

1. Resolve **effective policy** (WF-OD-01) then evaluate.  
2. Apply **deterministic list/category precedence** (see Filtering Model).  
3. Output typed decision + reason + policyVersion + enforcement availability state.  
4. Deny → polite interstitial when plane can interrupt (WF-OD-15).  
5. App Control ∩ Web Filter = **stricter intersection** (WF-OD-12).

---

## 7. Independence & safety (structural)

| System | Rule |
|---|---|
| Minutes / grants | Independent (WF-SF-01); unlock ≠ Temporary Grant |
| SOS / chat / Quran | Never disabled by filter (WF-SF-02) |

---

## 8. Honesty law

Never claim device filtering when plane is unsupported, permission-denied, pending-ack, or unverified (WF-SF-10 · WF-OD-04).  
Preview tools must label **preview** vs **device-enforced**.
