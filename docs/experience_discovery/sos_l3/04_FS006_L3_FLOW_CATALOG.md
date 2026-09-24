# 04 — FS-006 L3 Flow Catalog

**Authority:** Full SOS Final + L2  
**Master:** [13_FS006_L3_MASTER_CONTRACT.md](13_FS006_L3_MASTER_CONTRACT.md)

Each flow: actor · entry · preconditions · state · visible · allowed · forbidden · confirm · success · queued/offline · pending · degraded · unavailable · failure · audit · notification · child consequence · nav.

---

## F01 — Child hold activate

| Field | Spec |
|---|---|
| Actor | Child |
| Entry | SOS FAB / entry (always reachable) |
| Preconditions | IDLE |
| Transition | IDLE → HOLDING → (complete) FIRING → ACTIVE |
| Visible | Hold progress |
| Allowed | Hold; release early |
| Forbidden | Break-glass; claim delivery |
| Success | Local ACTIVE incident durable |
| Offline | Still create local; delivery `offline_queued` |
| Audit | `sos.hold` / `sos.fired` / `sos.active` |
| Notification | Attempts per channel honesty — not auto “delivered” |
| Nav | Active SOS surface |

---

## F02 — Firing feedback

| Field | Spec |
|---|---|
| Actor | Child (+ system) |
| State | FIRING |
| Visible | “Creating emergency…” · location acquiring/unavailable OK |
| Forbidden | “Parents received” |
| Success | ACTIVE |
| Failure | Retry local persist; never silent abandon |

---

## F03 — Child active + Panic Quiet

| Field | Spec |
|---|---|
| Actor | Child |
| Visible | Status · delivery honesty · location honesty · contact · cancel |
| Forbidden | Entertainment chrome that suppresses SOS; admin |
| Always | Chat · Quran |

---

## F04 — Child false-alarm cancel

| Field | Spec |
|---|---|
| Actor | Child |
| Confirm | **Required** multi-step |
| Allowed | Cancel own open SOS |
| Forbidden | Silent dismiss; break-glass |
| Success | Terminal false-alarm; parents informed; auditable |
| Audit | `sos.cancel.false_alarm` |
| Nav | Exit active → IDLE |

---

## F05 — Parent open incident console

| Field | Spec |
|---|---|
| Actor | Primary/Full/Partner/Observer |
| Visible | Lifecycle · delivery matrix · location · readiness · role actions |
| Observer | No ack/escalate/resolve CTAs |
| Forbidden | Fake delivered; mutate other systems' permanent policy |

---

## F06 — Acknowledge

| Field | Spec |
|---|---|
| Actor | Primary / Full / Partner |
| Transition | ACTIVE → ACKNOWLEDGED (or stay ack from escalating context per Final) |
| Forbidden | Observer; treat as resolved |
| Audit | `sos.acknowledged` |
| Child | May see “a parent acknowledged” only if product discloses — not delivery claim |

---

## F07 — Escalate trusted

| Field | Spec |
|---|---|
| Actor | Primary / Full / Partner | auto-timer |
| Transition | → ESCALATING |
| Visible | Verified rung · delivery honesty · no national numbers |
| Forbidden | Unverified contact; emergency-service dial |
| Audit | `sos.escalating` |
| Degraded | Show unavailable channel honestly |

---

## F08 — Resolve

| Field | Spec |
|---|---|
| Actor | Primary / Full / Partner |
| Confirm | Soft/required per UX |
| Transition | → RESOLVED |
| Forbidden | Delete history; Observer |
| Success | Closed; audit+evidence retained |
| Audit | `sos.resolved` |

---

## F09 — Break-glass

| Field | Spec |
|---|---|
| Actor | Primary / Full only |
| Transition | START → REASON → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT |
| Visible | Scope allowlist · expiry · not permanent |
| Forbidden | Partner/Observer/Child; unlock-everything copy; permanent mutation CTAs |
| Audit | Full BG trail |

---

## F10 — Setup ladder / Panic Quiet

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Visible | ≤5 backups · priority · verify states · Panic Quiet toggle |
| Forbidden | Partner/Observer edit; national numbers |

---

## F11 — Offline queue / retry

| Field | Spec |
|---|---|
| Actor | System + parents view |
| Visible | `offline_queued` · retry honesty |
| Forbidden | Cloud success fake |
| Success | Delivery class updates only when proven |

---

## F12 — Multi-device divergence

| Field | Spec |
|---|---|
| Actor | Parents |
| Visible | Per-device incident/delivery view |
| Forbidden | Single-device greenwash |

---

## F13 — Evidence pack browse

| Field | Spec |
|---|---|
| Actor | Authorized parents |
| Visible | Ops samples · retention honesty · **no A/V** |
| Forbidden | Audio/video capture CTAs |

---

## F14 — Location attach

| Field | Spec |
|---|---|
| Actor | System |
| Visible | READY/ACQUIRING/STALE/UNAVAILABLE |
| Forbidden | Block SOS activation; edit geofences in SOS |
| Nav | Deep-link FS-001 for maps/zones |

---

## F15 — AI suggest (config)

| Field | Spec |
|---|---|
| Actor | Advisor → Primary/Full approve |
| Forbidden | Autonomous fire/escalate/resolve/break-glass |

---

## F16 — Safety under all gates

| Field | Spec |
|---|---|
| Actor | Child |
| Visible | SOS entry despite Mode/ST/lock/filter/camera restrict |
| Forbidden | Hide SOS behind paywall/quiet hours |

---

## Index

F01 Hold · F02 Fire · F03 Active · F04 Cancel · F05 Console · F06 Ack · F07 Escalate · F08 Resolve · F09 Break-glass · F10 Setup · F11 Offline · F12 Multi-device · F13 Evidence · F14 Location · F15 AI · F16 Safety reachability
