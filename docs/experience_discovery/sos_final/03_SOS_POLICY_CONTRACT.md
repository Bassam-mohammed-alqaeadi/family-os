# 03 — SOS Policy Contract

**Status:** FROZEN POLICY CONTRACT  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**Authority chain:** Owner decisions (01) → Policy Register P-4/P-5 (interpreted by OD-*) → this contract  
**Owner decisions remaining:** NONE.

---

## 1. Permanent exemptions (OD-14)

SOS **MUST** remain reachable and fireable regardless of:

| Gate | Policy |
|---|---|
| Subscription / plan expiry | Never gates fire, receipt, or incident UI |
| Quiet hours | Never suppress critical SOS delivery |
| Screen-time / time expiry | SOS surface exempt |
| Entertainment lock | SOS surface exempt |
| Device lock / instant lock | SOS surface exempt |

Implementation note (current codebase already leans this way): keep structural exclusion in fire path, delivery tier, lock/expiry exempt lists. This contract forbids regressing those laws.

---

## 2. Activation policy

| Rule | Spec |
|---|---|
| Primary trigger | Child 3-second hold (CHD-005 / FAB) |
| Accidental protection | Release before 3s cancels hold; does not create incident |
| Offline | Create incident locally first (OD-17) |
| Location | Failure does not cancel activation (OD-16) |
| Break-glass | Parent temporary override to respond (RD-02); not child trigger |

---

## 3. Role policy (OD-01…04)

| Action | Primary | Mother Full | Mother Partner | Mother Observer | Child |
|---|---|---|---|---|---|
| Trigger SOS | — | — | — | — | Yes |
| Receive | Yes | Yes | Yes | Yes | — |
| View essential incident | Yes | Yes | Yes | Yes | Own incident |
| Contact child | Yes | Yes | Yes | Yes | Contact parent |
| Acknowledge | Yes | Yes | Yes | **No** | — |
| Respond (call/map actions) | Yes | Yes | Yes | Contact only (no ack/resolve/escalate) | — |
| Escalate (trusted) | Yes | Yes | Yes | **No** | — |
| Resolve | Yes | Yes | Yes* | **No** | Cancel only (false-alarm path) |
| Configure settings/contacts/ladder | Yes | Yes | **No** | **No** | **No** |
| Panic Quiet Mode config | Yes | Yes | No | No | Effect only on active UI |
| Break-glass invoke | Yes | Yes | **No** | **No** | **No** |

Break-glass AuthZ = **RBAC** (Primary or Mother Full). Never inferred from device ownership (Q-SOS-RD-02A).

\* Partner may resolve (respond capability includes closing after help). Observer may not.

**Nuclear configuration** = SOS settings, trusted/emergency contacts (incl. verify/priority), escalation delays/enablement, Panic Quiet Mode config. Primary + Mother Full only.  

**Break-glass** = response override for Primary + Mother Full only (not nuclear config, not Partner).

---

## 4. Lifecycle policy (OD-05, OD-06, OD-18)

```
IDLE → HOLDING → FIRING → ACTIVE → ACKNOWLEDGED → ESCALATING → RESOLVED
```

| Transition | Who | Rules |
|---|---|---|
| → ACTIVE | Child (or break-glass) | Durable incident created |
| → ACKNOWLEDGED | Primary / Full / Partner | Separate from resolve; does not close |
| → ESCALATING | Primary / Full / Partner OR auto-timer | Trusted contacts only; never emergency services |
| → RESOLVED | Primary / Full / Partner | Does not delete; audit retained |
| ACTIVE/ACK/ESCALATING → cancelled | Child via confirm | Emits **cancellation/false-alarm**; parents informed; auditable; incident closed as cancelled subtype or RESOLVED with reason `FALSE_ALARM` (see event contract) |

Observer cannot drive ACK / ESCALATE / RESOLVE.

---

## 5. Escalation policy (OD-07, OD-15, OD-08)

1. Rung-1 parents remain immovable (SET-020 / P-5).  
2. Backups: max **5**, priority **1…5** (RD-05); only **VERIFIED** participate in trusted escalation (RD-04).  
3. Auto-call targets **family/trusted**, never national emergency.  
4. **No** national/local emergency number field, default, or hardcode in this design.  
5. Future emergency-service dialing requires a **new** owner-approved capability pack.  
6. Phone/MSISDN change on a backup → re-verification required (RD-04).

---

## 6. Delivery policy (OD-09, OD-20)

| Channel | Policy |
|---|---|
| In-app / push | Primary critical path; quiet hours cannot mute |
| SMS | Fallback where technically supported |
| Call | Fallback / auto-call to family-trusted where supported |
| Success claim | Only after **confirmed** delivery or confirmed dial initiation result |
| Failure | Mark DELIVERY_FAILED; incident stays ACTIVE |

Mother Observer **always receives** (cannot mute).

---

## 7. Location policy (OD-16)

| State | Meaning |
|---|---|
| READY | Fresh fix meeting freshness SLA |
| ACQUIRING | Attempting fix after trigger |
| STALE | Last-known older than freshness SLA |
| UNAVAILABLE | No fix and no usable last-known |

SOS activates in all four. UI must not imply live tracking when UNAVAILABLE/STALE without label.

---

## 8. Offline policy (OD-17)

1. Create incident locally.  
2. Persist durably.  
3. Queue sync.  
4. Retry with backoff.  
5. Use SMS/call fallbacks if available.  
6. UI: PENDING / QUEUED — never “sent” until confirmed.

---

## 9. Evidence & audit policy (OD-10, OD-11, OD-18, RD-03, Q-SOS-RD-03A) — FROZEN

- Capture evidence categories in OD-10 only — **no audio/video**.  
- **Operational SOS evidence samples — 90 days:** location samples; delivery attempts/results; device state snapshots; battery/connectivity samples; escalation events; communication state. Purge/archive must be policy-driven and auditable.  
- **Core incident header + immutable lifecycle audit — indefinite:** incident identity; family/child references; trigger timestamp; acknowledgement; escalation; resolution/cancellation; actor identity; Break-glass audit; core lifecycle events.  
- Resolve/cancel must **not** erase the indefinite audit layer (R10 + OD-18).  
- Break-glass and Panic Quiet Mode changes are audit events.  
- Verification attempts/failures for backups are audit events (RD-04).

## 9b. Break-glass policy (Q-SOS-RD-02A/02B) — FROZEN

See Product Contract §6 and Role Contract. Allowlist / forbidden list / lifecycle are normative. Auto-revoke on expiry. No permanent policy mutation.

---

## 10. Privacy & child-visible policy

- Child sees own incident progress and honest delivery/location states (no fabricated “father saw” without receipts).  
- Observer sees **essential** incident info (who, when, location honesty, connection/battery summary, contact actions) — not configuration surfaces.  
- No child names planted in defaults (Rule 23); parametric ChildId.

---

## 11. Conflicts with prior discovery proposals

| Prior open item | Now |
|---|---|
| Observer resolve (was tested in Stage-1 UI) | **FORBIDDEN** by OD-01 — UI must be corrected in future implementation |
| National escalate CTA copy implying emergency services | **FORBIDDEN** as auto/national — reword to trusted-contact escalate |
| Audio from P-4 text | **EXCLUDED** by OD-11 for this product generation |
| Schema ACKNOWLEDGED | **REQUIRED** — app must align later |
