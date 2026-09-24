# 10 — FS-005 L3 Enforcement Honesty UX

**Authority:** MODE-SF-14 · MODE-SF-20 · Offline contract · sibling honesty patterns  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

**T-MODE-02…05 remain TBD** — honesty must not invent mechanisms or TTLs.

---

## 1. Claim rules

| Parent action | May claim |
|---|---|
| Saved Mode definition | Saved / queued — **not** “enforced on child” |
| Activated Mode | Activation recorded — enforced only if `enf_enforced` |
| Device pending ack | “Awaiting acknowledgement” |
| Offline | “Using last-acked Mode state” |
| Unsupported plane on overlay target | “This plane unsupported on device” for that system |
| Stage-1 toggle | **Never** cite as proof of product enforcement |

---

## 2. Honesty strip (parent)

Always visible classes:

- Sync: online / offline / queued  
- Ack: acked / pending / stale (TTL number not shown as invented constant)  
- Stack: N Modes active  
- Plane: enforced / degraded / unsupported / unknown for relevant overlays  
- Multi-device divergence summary  

---

## 3. Per-device matrix

Show each enrolled child device:

| Column | Content |
|---|---|
| Device | Label |
| Mode policy version ack | pending / acked / stale |
| Active stack (acked) | Names |
| Overlay plane honesty | per FS-002/003/004 as known |

Forbidden: green “fully protected” from Modes alone.

---

## 4. Degraded / unsupported / failure recovery

| State | UX | Recovery |
|---|---|---|
| Offline | Queue mutations | Auto/retry when online (algo TBD) |
| Pending ack | Wait honesty | Open Devices |
| Stale | Stale chip | Retry / check device (no invented minutes) |
| Unsupported | Clear unsupported copy | Deep-link device health / capability |
| Conflict composition | Explain sheet | Parent adjusts Modes |
| Failure save | Error + retry | Keep draft |

---

## 5. Child honesty

- Do not claim “live cloud Mode” when offline last-acked  
- Do not show admin enforcement diagnostics  
- Always keep SOS/Chat/Quran  

---

## 6. AI honesty

Suggestions labeled as suggestions; require Primary/Full approval before write.
