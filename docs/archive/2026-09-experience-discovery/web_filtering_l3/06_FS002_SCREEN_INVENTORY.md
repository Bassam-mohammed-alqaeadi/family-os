# 06 — FS-002 Screen Inventory (L3.7)

**Authority:** Flows F01–F24 · IA · Role matrix  
**Rule:** Inventory derived from L3 design. Stage-1 SCR-* / FAT-* are **evidence hints only**, not completeness or target authority.

Logical IDs use `WF-*`.

---

## Parent screens

### WF-P-OVERVIEW — Web Filtering Overview

| Field | Content |
|---|---|
| **Purpose** | Composite honesty + shortcuts (policy vs enforcement vs ack) |
| **Role** | All parents (edit CTAs gated) |
| **Entry** | Settings / Safety hub |
| **Required info** | Enforcement state · policy presence · pending ack · Mode chip · Safe Search capability summary · unlock pending count |
| **Actions** | Open Family · Per-child · Inbox · Status · Router add-on · SOS |
| **Allowed states** | policy_* · enf_* · mode_* · ss_* summary |
| **Exit** | Child screens below |
| **L2** | WF-OD-04 · SF-10 · OD-01 |

---

### WF-P-FAMILY — Family Baseline Policy

| Field | Content |
|---|---|
| **Purpose** | Author/view family default |
| **Role** | Edit: Primary+Full · View: all parents |
| **Entry** | Overview |
| **Required info** | Version · categories summary · lists counts · Safe Search · read-only banner if needed |
| **Actions** | Open Categories/Lists/SafeSearch/Private · Save |
| **States** | policy_* |
| **Exit** | Editors · Overview |
| **L2** | WF-OD-01/02 |

---

### WF-P-CHILD — Per-Child Hub

| Field | Content |
|---|---|
| **Purpose** | Select child; show effective = baseline vs override |
| **Role** | All parents view; edit gated |
| **Entry** | Overview · Kids hub |
| **Required info** | Child context · effective source badge · device status strip |
| **Actions** | Create/open override · open Status · Inbox filtered |
| **States** | family_active / child_override_active · enf_* |
| **Exit** | Override · Status |
| **L2** | WF-OD-01 |

---

### WF-P-OVERRIDE — Child Override Editor

| Field | Content |
|---|---|
| **Purpose** | Create/edit/remove per-child override |
| **Role** | Primary+Full |
| **Entry** | Per-child hub |
| **Required info** | Diff vs baseline (summary) · same editors as family |
| **Actions** | Edit · Save · Remove override |
| **States** | draft · saving · override_active · pending_ack |
| **Exit** | Child hub |
| **L2** | WF-OD-01/02 |

---

### WF-P-CATEGORIES — Category Configuration

| Field | Content |
|---|---|
| **Purpose** | Toggle large normative categories (labels TBD T-WF-02) |
| **Role** | Primary+Full edit; others view summary only |
| **Entry** | Family or Override |
| **Required info** | Category list placeholders · enabled set · honesty: taxonomy TBD |
| **Actions** | Toggle · Save |
| **States** | dirty · saving · saved |
| **Exit** | Parent policy |
| **L2** | WF-OD-05 |

---

### WF-P-ALLOW — Allowlist Manager

| Field | Content |
|---|---|
| **Purpose** | Manage allowlist entries |
| **Role** | Primary+Full |
| **Entry** | Family/Override lists |
| **Required info** | Entries · empty · precedence note (below blocklist & temp allow) |
| **Actions** | Add/remove · Save |
| **States** | empty · ready · saving |
| **Exit** | Policy |
| **L2** | WF-OD-08 |

---

### WF-P-BLOCK — Blocklist Manager

| Field | Content |
|---|---|
| **Purpose** | Manage blocklist (highest deny) |
| **Role** | Primary+Full |
| **Entry** | Lists |
| **Required info** | Entries · precedence note |
| **Actions** | Add/remove · Save |
| **States** | empty · ready · saving |
| **Exit** | Policy |
| **L2** | WF-OD-08 |

---

### WF-P-DICT — Keyword Dictionary

| Field | Content |
|---|---|
| **Purpose** | Custom keyword denies |
| **Role** | Primary+Full |
| **Entry** | Lists |
| **Required info** | Keywords · empty |
| **Actions** | Add/remove · Save |
| **States** | empty · ready · saving |
| **Exit** | Policy |
| **L2** | WF-OD-08 |

---

### WF-P-SAFESEARCH — Safe Search Settings

| Field | Content |
|---|---|
| **Purpose** | Policy intent + capability honesty |
| **Role** | Edit Primary+Full; view all parents |
| **Entry** | Family/Override |
| **Required info** | On/off intent · ss_* capability |
| **Actions** | Toggle intent · explain unsupported |
| **States** | ss_* |
| **Exit** | Policy |
| **L2** | WF-OD-06 |

---

### WF-P-PRIVATE — Private Browsing Capability

| Field | Content |
|---|---|
| **Purpose** | Platform honesty matrix only |
| **Role** | All parents view |
| **Entry** | Family / Overview |
| **Required info** | pb_* · coverage note · no fake success |
| **Actions** | View / dismiss |
| **States** | pb_* |
| **Exit** | Back |
| **L2** | WF-OD-07 |

---

### WF-P-STATUS — Enforcement & Device Status

| Field | Content |
|---|---|
| **Purpose** | Separate policy vs ack vs plane |
| **Role** | All parents |
| **Entry** | Overview · Per-child |
| **Required info** | enf_* · pending_ack · coverage honesty · Mode chip |
| **Actions** | Refresh · open explain · link Modes · link App Control if intersection issues |
| **States** | enf_* · policy_pending_ack · stale |
| **Exit** | Overview |
| **L2** | WF-OD-04 · SF-04/10 |

---

### WF-P-INBOX — Unlock Inbox

| Field | Content |
|---|---|
| **Purpose** | Pending + recent unlock tickets |
| **Role** | Decide: P/Partner/Full · Observer view-only |
| **Entry** | Notification · Overview |
| **Required info** | Child · target summary · source-of-deny · status |
| **Actions** | Open ticket |
| **States** | ticket_* |
| **Exit** | Ticket |
| **L2** | WF-OD-03/09 |

---

### WF-P-TICKET — Unlock Ticket Detail

| Field | Content |
|---|---|
| **Purpose** | Approve timed temporary allow or deny |
| **Role** | Decide: P/Partner/Full · Observer view |
| **Entry** | Inbox |
| **Required info** | Target · Web Filter reason class · source-of-deny · duration placeholder (T-WF-01) · explicit “will not add to allowlist” |
| **Actions** | Approve temporary · Deny · (no App Control mutate) |
| **States** | pending · approved_pending_ack · active · denied |
| **Exit** | Inbox · Decisions |
| **L2** | WF-OD-09/03/12 |

---

### WF-P-DECISIONS — Decisions / Audit (scoped)

| Field | Content |
|---|---|
| **Purpose** | Deny events + unlock lifecycle history (not full browse trail) |
| **Role** | View: parents · Export: Primary only (WF-SF-06) |
| **Entry** | Overview |
| **Required info** | Event list · filters by child/date · source-of-deny |
| **Actions** | Open detail · Export (Primary) |
| **States** | empty · loading · ready · offline partial |
| **Exit** | Ticket / deny detail |
| **L2** | WF-OD-14 · SF-06/07 |

---

### WF-P-DENY-DETAIL — Deny Event Detail

| Field | Content |
|---|---|
| **Purpose** | Why blocked — family-safe reason + source |
| **Role** | Parents |
| **Entry** | Decisions |
| **Required info** | Verdict class · source-of-deny · policy version · Mode/App Control tags |
| **Actions** | Optional navigate to lists (editors only) · open App Control if needed |
| **States** | v_* |
| **Exit** | Decisions |
| **L2** | WF-OD-12/14 · Filtering Model |

---

### WF-P-ROUTER — Optional Router Add-on

| Field | Content |
|---|---|
| **Purpose** | Honest optional home-router DNS add-on |
| **Role** | Config Primary+Full · view others |
| **Entry** | Overview Optional Add-ons |
| **Required info** | Explicit “not core on-device enforcement” · router_* honesty |
| **Actions** | Configure / disconnect · never merge into enf_enforced |
| **States** | router_* |
| **Exit** | Overview |
| **L2** | WF-OD-11 |

---

### WF-P-PREVIEW — Interstitial Preview (parent tool)

| Field | Content |
|---|---|
| **Purpose** | Preview child block UX (labeled preview) |
| **Role** | All parents |
| **Entry** | Family / Override |
| **Required info** | Preview badge · sample reason |
| **Actions** | Dismiss |
| **States** | preview |
| **Exit** | Back |
| **L2** | Policy honesty |

---

## Child screens

### WF-C-INTERSTITIAL — Block Interstitial (+ unlock request feedback)

| Field | Content |
|---|---|
| **Purpose** | Polite block + optional unlock request + **transient** pending/approved/denied/expired feedback |
| **Role** | Child |
| **Entry** | Deny interrupt; re-entry when request status changes (same surface) |
| **Required info** | Family-safe reason · source-of-deny (simple) · SOS reachable · no lists · no admin |
| **Actions** | Request unlock (if WF-eligible) · dismiss feedback · SOS · go back |
| **States** | `v_*` → `ticket_pending` → transient `approved` / `denied` / `expired` feedback **inside this surface** |
| **Exit** | Back · SOS |
| **L2** | WF-OD-15 · WF-OD-09 · SF-02 · OD-12 |

**Q-WF-15 clarification:** There is **no** persistent child unlock-result destination and **no** `WF-C-UNLOCK-RESULT` screen. Approved / denied / expired honesty is a **transient feedback state** of `WF-C-INTERSTITIAL` only (toast/inline message within the interstitial/request flow). Child still has no admin, lists, categories, diagnostics, or configuration.

---

### WF-C-DISCLOSURE — Filter Active Disclosure

| Field | Content |
|---|---|
| **Purpose** | Non-interactive “family filter active” |
| **Role** | Child |
| **Entry** | Transparency / compliance area |
| **Required info** | Short disclosure only |
| **Actions** | None (non-interactive) |
| **States** | active / inactive honest |
| **Exit** | Back |
| **L2** | WF-OD-15 |

---

## Non-screens (owned elsewhere)

| Concern | Owner surface |
|---|---|
| Mode schedule | FS-005 |
| App Control policy | FS-003 |
| SOS | System #1 |
| Minutes grant | Screen Time |

---

## Legacy evidence (non-authority)

Stage-1 web filter / FAT-036 / FAT-078 screens may inform layout habits only. Target inventory above supersedes them.
