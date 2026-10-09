# 05 — FS-002 Filtering Model Contract (L2 Target) — FROZEN

**Status:** FROZEN · WF-OD-01 · WF-OD-05 · WF-OD-08 · WF-OD-10 · WF-OD-12 · WF-OD-13

---

## 1. Effective policy resolution (WF-OD-01)

```
effective(child) =
  child_override(child)   if present
  else family_default
```

Then apply Mode tightening context (WF-OD-10/13) — Modes may **only add restriction**, never remove base denies/allows that weaken baseline.

---

## 2. Category model (WF-OD-05)

Large **normative** category direction.  
Exact taxonomy/content = **technical/content contract (T-WF-02)**.  
Stage-1 six keys and arbitrary registry counts are **non-final**.

---

## 3. First-class lists (WF-OD-08)

- Allowlist  
- Blocklist  
- Custom keyword dictionary  

### Deterministic precedence (normative)

Evaluate in this order against the navigation target (host/URL/text signals as available to the plane):

1. **Blocklist hit** → **DENY**  
2. **Active timed temporary allow** matching target (WF-OD-09) → **ALLOW**  
3. **Allowlist hit** → **ALLOW**  
4. **Dictionary / keyword hit** → **DENY**  
5. **Category model hit** (enabled category) → **DENY**  
6. **Safe Search / restricted-search** obligations when the platform can enforce them (WF-OD-06); otherwise honest skip  
7. Else **ALLOW**

Then apply **App Control ∩ Web Filter** stricter intersection (WF-OD-12 / §5).

**Rationale:** Explicit blocklist always beats temporary unlock and allowlist. Unlock approval never mutates allowlist (WF-OD-09); it creates a timed exception object only.

---

## 4. Mode context (WF-OD-10 / WF-OD-13)

No Web Filter–owned scheduler.  
Consume FS-005 Mode policy context.  
Modes may only **tighten** (additional denies / stricter posture) — never weaken baseline.

---

## 5. Intersection with App Control (WF-OD-12)

Final access = **stricter intersection** of App/System Control gate and Web Filter gate.  
If either denies → DENY.  
UX must expose **source-of-deny** (app-control vs web-filter) for parent clarity and child interstitial messaging.

---

## 6. Classification

Production classifier/vendor = T-WF-02.  
Fixture heuristics = non-normative.
