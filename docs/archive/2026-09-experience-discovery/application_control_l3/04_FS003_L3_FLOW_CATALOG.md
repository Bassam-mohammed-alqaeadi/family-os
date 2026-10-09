# 04 — FS-003 L3 Flow Catalog

**Authority:** L2 contracts 02–09 · APP-OD-*  
**Master:** [11_FS003_L3_MASTER_CONTRACT.md](11_FS003_L3_MASTER_CONTRACT.md)

Each flow: entry · actor · preconditions · visible state · allowed/forbidden · success · failure/degraded · offline · pending/ack · audit · notify · navigation.

---

## F01 — Open App Control hub

| Field | Spec |
|---|---|
| Entry | Parent shell → App Control |
| Actor | Any parent role |
| Preconditions | Family context |
| Visible | Honesty strip; pending install/exception counts; shortcuts |
| Allowed | Navigate per role matrix |
| Forbidden | Claim “fully protected” if plane not `enforced`+acked |
| Success | Hub rendered |
| Degraded | Banner for `degraded`/`unsupported`/… |
| Offline | Show last-known honesty; queue badge if pending outbox |
| Audit | none |
| Notify | none |
| Nav | → FAMILY / CHILD / INSTALL / EXCEPT / AUDIT / DEVICE |

---

## F02 — Edit family baseline

| Field | Spec |
|---|---|
| Entry | AC-P-FAMILY |
| Actor | Primary, Full |
| Preconditions | Configure rights |
| Visible | Baseline rules; protected legend |
| Allowed | Save class defaults / baseline access rules |
| Forbidden | Partner/Observer edit; deny protected packages; invent ST limits |
| Success | `policyVersion++`; outbox; pending_delivery |
| Failure | AuthZ deny; validation |
| Offline | offline_queued — no fake success |
| Audit | `app_policy.saved` |
| Notify | optional plane/policy pending |
| Nav | Stay / back hub |

---

## F03 — Create / edit child override

| Field | Spec |
|---|---|
| Entry | AC-P-CHILD |
| Actor | Primary, Full |
| Visible | Effective = override wins when set |
| Allowed | Upsert override access rules |
| Forbidden | Partner edit |
| Success | Child doc versioned; devices pending ack |
| Offline | queued |
| Audit | `app_policy.saved` (override) |
| Nav | → INV / APP |

---

## F04 — Browse inventory

| Field | Spec |
|---|---|
| Entry | AC-P-INV |
| Actor | All parents (mutate per role) |
| Visible | Package ID + label + disposition badges + pending |
| Allowed | Open app detail; Partner/Observer view only |
| Forbidden | Slug-only identity as truth; edit ST Unlimited here |
| Success | List from device inventory facts |
| Degraded | Inventory incomplete honesty if discovery TBD |
| Offline | Last-known inventory + honesty |
| Audit | none (view) |
| Nav | → AC-P-APP |

---

## F05 — Allow package

| Field | Spec |
|---|---|
| Entry | AC-P-APP |
| Actor | Primary, Full |
| Preconditions | Not protected; configure rights |
| Transition | → `allowed` |
| Forbidden | Silent WF allowlist mutation |
| Success | Saved; pending ack |
| Audit | `app_rule.allowed` |
| Nav | Stay detail |

---

## F06 — Set Permanent Block

| Field | Spec |
|---|---|
| Entry | AC-P-APP confirm sheet |
| Actor | Primary, Full |
| Transition | → `permanent_blocked` |
| Visible | Warning: Minutes/Grant/Unlimited cannot open |
| Forbidden | Blocking protected surfaces |
| Success | Block set; Lock Now irrelevant while blocked unless cleared separately |
| Audit | `app_rule.blocked` |
| Notify | optional |
| Nav | Detail shows Primary-only reopen for Primary; Full sees disabled reopen |

---

## F07 — Reopen Permanent Block

| Field | Spec |
|---|---|
| Entry | AC-P-APP |
| Actor | **Primary only** |
| Preconditions | `permanent_blocked` |
| Transition | → `allowed` or prior non-block disposition |
| Forbidden | Full/Partner/Observer/Child |
| Success | Block cleared (policy rewrite — this is reopen, not Exception) |
| Audit | Permanent Block reopen event |
| Nav | Stay |

---

## F08 — Set / clear App Access Exempt

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Visible | Copy: Exempt ≠ Unlimited; does not bypass Instant Lock / SOS |
| Transition | ↔ `exempt` |
| Audit | `app_rule.exempt_set` |
| Forbidden | Presenting as ST Unlimited |

---

## F09 — Lock Now / clear

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Transition | ↔ `lock_now_active` |
| Visible | Distinct from Permanent Block + Instant Device Lock; duration placeholder **T-APP-06** |
| Forbidden | Partner; claiming permanent |
| Audit | `app_lock_now.set` / `.cleared` |
| Success | Temporary deny overlay |

---

## F10 — Restore Baseline

| Field | Spec |
|---|---|
| Entry | AC-P-CHILD confirm |
| Actor | Primary, Full |
| Effect | Clear child overrides + temporary overlays (exceptions, Lock Now, pending holds as applicable) |
| **Does not** | Reopen Permanent Block (needs F07 / Primary) |
| Audit | `app_baseline.restored` |
| Nav | Child effective refreshes |

---

## F11 — New install observed → inbox

| Field | Spec |
|---|---|
| Entry | System event → AC-P-INSTALL |
| Actor | Domain |
| Child state | `pending_unknown` deny-until-approved (no class default) |
| Notify | Decide-capable parents |
| Audit | `install.observed` / `.pending` |

---

## F12 — Approve / deny install

| Field | Spec |
|---|---|
| Entry | AC-P-INSTALL-D |
| Actor | Primary, Partner, Full |
| Approve | Child-scoped allow (APP-OD-18); **not** family-wide silent |
| Deny | Deny/block disposition |
| Offline | Queue decision |
| Audit | `install.approved` / `.denied` |
| Notify | Child local + parents |
| Forbidden | Mint Grant/Unlimited; mutate WF |

Detail: [07_FS003_L3_INSTALL_EXCEPTION_FLOWS.md](07_FS003_L3_INSTALL_EXCEPTION_FLOWS.md)

---

## F13 — Child Exception Request

| Field | Spec |
|---|---|
| Entry | AC-C-DENY → AC-C-REQ |
| Actor | Child |
| Preconditions | Blocked or pending (not protected); Exception enabled |
| Transition | `exception_pending` |
| Forbidden | Admin; request on protected |
| Audit | `app_exception.requested` |
| Notify | Primary+Partner+Full |
| Nav | Back to deny with “request sent” |

---

## F14 — Approve / deny / revoke Exception

| Field | Spec |
|---|---|
| Entry | AC-P-EXCEPT-D |
| Actor | Primary, Partner, Full |
| Approve | `active` timed overlay; **Permanent Block row unchanged** |
| Deny | ticket denied |
| Revoke | end active early |
| Expiry | auto → underlying block resumes |
| Duration | UI placeholder; value **T-APP-06** |
| Copy mandatory | Exception ≠ Grant ≠ Unlimited; does not remove Permanent Block |
| Audit | approve/deny/activate/expire/revoke |
| Notify | Child + parents |

---

## F15 — Source-of-deny (parent + child)

| Field | Spec |
|---|---|
| Entry | AC-P-SOD / AC-C-DENY |
| Visible | App / Web / both / Mode / ST / Instant Lock as applicable |
| Forbidden | Unlock CTA that mutates the wrong system |
| Nav | Deep link only to owning system’s allowed action |

---

## F16 — Enforcement honesty review

| Field | Spec |
|---|---|
| Entry | AC-P-DEVICE / hub strip |
| Visible | Plane state per device; ack version; remediation if permission |
| Forbidden | “Protected” when unsupported/unknown/unavailable |
| Audit | `app_plane.state_changed` on transitions |
| Detail | [08_FS003_L3_ENFORCEMENT_HONESTY_UX.md](08_FS003_L3_ENFORCEMENT_HONESTY_UX.md) |

---

## F17 — Offline parent edit

| Field | Spec |
|---|---|
| Visible | offline_queued badge |
| Forbidden | Fake “saved to cloud / on child now” |
| Success | Local durable outbox |
| On reconnect | Replay; pending_delivery → acked |

---

## F18 — Offline child

| Field | Spec |
|---|---|
| Enforce | Last-acked policy |
| Unknown | Deny-until-approved if no class default |
| Exception request | Queue locally if enabled |
| Protected | Always reachable |

---

## F19 — Modes interaction (consume)

| Field | Spec |
|---|---|
| Visible | Mode tighten chip when active |
| Nav | Deep link FS-005 |
| Forbidden | App Control schedule editor; Mode control that reopens Permanent Block |

---

## F20 — Screen Time deep link

| Field | Spec |
|---|---|
| From | App detail “Time limits” |
| Goes to | ST surfaces for Limit/Unlimited/Countable/Grant |
| Forbidden | Editing those fields inside AC |

---

## F21 — Web Filter ∩ App Control

| Field | Spec |
|---|---|
| Visible | Source-of-deny both/app/web |
| Exception approve | Must not write WF allow |
| WF unlock | Must not clear Permanent Block |
| Browser package allow | Still subject to WF URLs |

---

## F22 — Audit browse

| Field | Spec |
|---|---|
| Entry | AC-P-AUDIT |
| Actor | Parents (export Primary-leaning) |
| Visible | Mutations, installs, exceptions, relevant denies, plane changes |
| Forbidden | Full open-app timeline as default product |

---

## F23 — Observer path

| Field | Spec |
|---|---|
| Actor | Observer |
| Allowed | View hub/inventory/honesty/audit summary |
| Forbidden | All mutate/decide; show controls disabled or hidden |

---

## F24 — Protected package attempt

| Field | Spec |
|---|---|
| Actor | Configure roles |
| Visible | Row locked; explanation reachable-cannot-deny |
| Forbidden | Block/Lock Now/pending deny on SOS/Family OS/Required Chat/Quran |
