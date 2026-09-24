# 04 — FS-002 User Flows (L3.4)

**Authority:** L2 contracts 02–09 · IA · State matrix · Role matrix  
**Format per flow:** `entry → preconditions → states → actions → result → audit/event → notification → offline/error`

Unlock duration values = **T-WF-01 TBD** (placeholder only).

---

## F01 — Create family filter policy

| Step | Content |
|---|---|
| **Entry** | Web Filtering Overview empty CTA |
| **Preconditions** | Primary or Full; `policy_none` |
| **States** | `policy_none` → `policy_saving` → `policy_saved` → `policy_pending_ack` |
| **Actions** | Set initial categories / Safe Search intent · Save |
| **Result** | Family baseline exists (`policy_family_active`) |
| **Audit** | Policy created + version |
| **Notification** | Optional parent confirm; devices pending ack |
| **Offline/error** | Queue save; show `policy_sync_degraded`; no fake enforced |

---

## F02 — Edit family baseline

| Step | Content |
|---|---|
| **Entry** | Family Baseline editor |
| **Preconditions** | Primary/Full; baseline exists |
| **States** | editing → `policy_saving` → `policy_saved` / `policy_pending_ack` |
| **Actions** | Change categories/lists/Safe Search · Save |
| **Result** | New `policyVersion`; children without override inherit |
| **Audit** | Policy mutation |
| **Notification** | Pending ack honesty on devices |
| **Offline/error** | Queued; stale chip if ack overdue (TTL TBD) |

---

## F03 — Create child override

| Step | Content |
|---|---|
| **Entry** | Per-child → Create override |
| **Preconditions** | Primary/Full; child selected; may copy from baseline as draft |
| **States** | draft → saving → `policy_child_override_active` + pending ack |
| **Actions** | Edit override fields · Save |
| **Result** | Effective policy = override for that child |
| **Audit** | Override created |
| **Notification** | Device pending ack |
| **Offline/error** | Queued; effective on device only after ack |

---

## F04 — Remove child override

| Step | Content |
|---|---|
| **Entry** | Override editor → Remove |
| **Preconditions** | Primary/Full; override exists |
| **States** | confirm → saving → `policy_family_active` for child |
| **Actions** | Confirm remove |
| **Result** | Child reverts to family baseline |
| **Audit** | Override removed |
| **Notification** | Pending ack |
| **Offline/error** | Queued remove |

---

## F05 — Configure categories

| Step | Content |
|---|---|
| **Entry** | Baseline or Override → Categories |
| **Preconditions** | Primary/Full; taxonomy labels from T-WF-02 (placeholder list OK in UX) |
| **States** | dirty → saving → saved/pending ack |
| **Actions** | Toggle categories · Save |
| **Result** | Category denies update per precedence |
| **Audit** | Category mutation |
| **Notification** | Ack pending |
| **Offline/error** | Queued |

---

## F06 — Manage allowlist

| Step | Content |
|---|---|
| **Entry** | Lists → Allowlist |
| **Preconditions** | Primary/Full |
| **States** | list ready / empty / saving |
| **Actions** | Add / remove entries · Save |
| **Result** | Allowlist hits → ALLOW (after blocklist & temp allow checks) |
| **Audit** | List mutation |
| **Notification** | Ack pending |
| **Offline/error** | Queued; no silent unlock approve→allowlist |

---

## F07 — Manage blocklist

| Step | Content |
|---|---|
| **Entry** | Lists → Blocklist |
| **Preconditions** | Primary/Full |
| **States** | list ready / empty / saving |
| **Actions** | Add / remove · Save |
| **Result** | Blocklist → DENY (highest) |
| **Audit** | List mutation |
| **Notification** | Ack pending |
| **Offline/error** | Queued |

---

## F08 — Manage keyword dictionary

| Step | Content |
|---|---|
| **Entry** | Lists → Dictionary |
| **Preconditions** | Primary/Full |
| **States** | list ready / empty / saving |
| **Actions** | Add / remove keywords · Save |
| **Result** | Dictionary hit → DENY |
| **Audit** | Dictionary mutation |
| **Notification** | Ack pending |
| **Offline/error** | Queued |

---

## F09 — Configure Safe Search

| Step | Content |
|---|---|
| **Entry** | Baseline/Override → Safe Search |
| **Preconditions** | Primary/Full |
| **States** | `ss_*` capability + policy on/off |
| **Actions** | Enable/disable policy intent · view capability honesty |
| **Result** | Where `ss_enforced` possible → mandatory enforcement intent honored; else honesty |
| **Audit** | Safe Search policy change |
| **Notification** | If unsupported, parent honesty — no false success |
| **Offline/error** | Capability `ss_unknown` / unavailable |

---

## F10 — View private-browsing capability

| Step | Content |
|---|---|
| **Entry** | Overview or Baseline → Private browsing honesty |
| **Preconditions** | Any parent viewer role |
| **States** | `pb_*` |
| **Actions** | View only (no fake toggle success) |
| **Result** | Platform honesty matrix shown |
| **Audit** | None (view) |
| **Notification** | None |
| **Offline/error** | `pb_unknown` |

---

## F11 — View enforcement / device status

| Step | Content |
|---|---|
| **Entry** | Overview or Per-child device status |
| **Preconditions** | Parent viewer |
| **States** | `enf_*` + `policy_*` ack |
| **Actions** | Refresh status · open explain sheet |
| **Result** | Honest composite protection headline |
| **Audit** | Optional plane-degraded event when reported |
| **Notification** | Degraded alerts per Notifications system |
| **Offline/error** | Show unknown/unavailable — never “full” |

---

## F12 — Child opens blocked content

| Step | Content |
|---|---|
| **Entry** | Child navigation hits deny |
| **Preconditions** | `enf_enforced` (or plane that can interrupt); effective policy denies |
| **States** | `v_blocked` / specific verdict |
| **Actions** | Interstitial shown; SOS still reachable |
| **Result** | Navigation stopped; filter-active disclosure may appear in compliance area |
| **Audit** | Deny event (WF-OD-14) |
| **Notification** | Not required per deny by default (avoid spam); parent may see in Decisions |
| **Offline/error** | If plane unavailable → no fake block success; honesty on parent |

---

## F13 — Child submits unlock request

| Step | Content |
|---|---|
| **Entry** | Interstitial CTA “Request unlock” |
| **Preconditions** | Deny source is Web Filter (not App-Control-only); child role |
| **States** | Same `WF-C-INTERSTITIAL` → `ticket_pending` (or queued) feedback |
| **Actions** | Submit request (optional short reason — no lists shown) |
| **Result** | Ticket created; interstitial shows **pending** (transient) |
| **Audit** | Unlock request lifecycle start |
| **Notification** | Parent unlock inbox |
| **Offline/error** | `ticket_queued_offline`; no fake approved |

**Q-WF-15:** Child unlock feedback stays on `WF-C-INTERSTITIAL`. **No** persistent unlock-result child screen.

**Note:** If source-of-deny is App Control only → do **not** offer Web Filter unlock; route honesty to App Control path (F21).

---

## F14 — Parent receives unlock request

| Step | Content |
|---|---|
| **Entry** | Notification → Unlock Inbox |
| **Preconditions** | Primary/Partner/Full (Observer view-only) |
| **States** | `ticket_pending` |
| **Actions** | Open ticket · see target summary · source-of-deny |
| **Result** | Ready to approve/deny |
| **Audit** | View may be unaudited; open optional |
| **Notification** | Consumed |
| **Offline/error** | Show queued child request when sync arrives |

---

## F15 — Parent approves temporary exception

| Step | Content |
|---|---|
| **Entry** | Ticket → Approve |
| **Preconditions** | Primary/Partner/Full; not Observer |
| **States** | `ticket_approved_pending_ack` → `ticket_active` |
| **Actions** | Confirm **timed temporary allow** (duration T-WF-01 TBD UI) — **not** add to allowlist |
| **Result** | Temporary allow object created; App Control / SOS unchanged |
| **Audit** | Approve decision |
| **Notification** | Parent ticket update · **Child:** transient “approved temporary” feedback on `WF-C-INTERSTITIAL` (not a separate destination); device ack |
| **Offline/error** | Decision queued; no early “active on device” |

---

## F16 — Parent denies request

| Step | Content |
|---|---|
| **Entry** | Ticket → Deny |
| **Preconditions** | Primary/Partner/Full |
| **States** | `ticket_denied` |
| **Actions** | Confirm deny |
| **Result** | Base deny remains |
| **Audit** | Deny decision |
| **Notification** | Parent ticket · **Child:** transient “denied” feedback on `WF-C-INTERSTITIAL` only |
| **Offline/error** | Queued decision |

---

## F17 — Temporary exception expires

| Step | Content |
|---|---|
| **Entry** | Timer / Domain expiry (duration TBD) |
| **Preconditions** | `ticket_active` |
| **States** | → `ticket_expired` / `v_temp_allow_expired` |
| **Actions** | System ends exception; no silent allowlist write |
| **Result** | Baseline/override resumes |
| **Audit** | Expiry event in unlock lifecycle |
| **Notification** | Optional parent; **Child:** transient expired feedback on interstitial if/when child re-encounters block — **no** admin / result screen |
| **Offline/error** | Device applies on next sync/ack |

---

## F18 — Policy change + child acknowledgement

| Step | Content |
|---|---|
| **Entry** | After any policy save |
| **Preconditions** | Device enrolled |
| **States** | `policy_pending_ack` → acked (enforced only if plane OK) |
| **Actions** | Parent watches status; device acks version |
| **Result** | Acked version matches; may enter `enf_enforced` |
| **Audit** | Ack fact (Domain) |
| **Notification** | Optional when stale |
| **Offline/error** | Remain pending/stale — never claim current version enforced |

---

## F19 — Offline / stale policy behavior

| Step | Content |
|---|---|
| **Entry** | Parent edits offline or ack overdue |
| **Preconditions** | Offline or T-WF-04 stale condition |
| **States** | `policy_sync_degraded` / `policy_stale` |
| **Actions** | Queue mutations; show honesty |
| **Result** | Device keeps last acked policy |
| **Audit** | Sync failure facts as available |
| **Notification** | Stale/degraded parent honesty |
| **Offline/error** | Core of this flow |

---

## F20 — Degraded / unsupported enforcement

| Step | Content |
|---|---|
| **Entry** | Overview honesty or capability assess |
| **Preconditions** | Plane not verified / unsupported |
| **States** | `enf_degraded` / `enf_unsupported` / `enf_unavailable` / `enf_unknown` |
| **Actions** | Explain sheet · optional deep link to device permissions (platform-agnostic) |
| **Result** | Parent understands no full claim |
| **Audit** | Plane degraded event |
| **Notification** | Parent honesty channel |
| **Offline/error** | Same |

---

## F21 — Web Filter ∩ App Control stricter intersection

| Step | Content |
|---|---|
| **Entry** | Child navigation; both gates evaluate |
| **Preconditions** | FS-003 + FS-002 both apply |
| **States** | `v_stricter_app_control` and/or Web Filter deny |
| **Actions** | Interstitial shows **source-of-deny**; unlock CTA only if Web Filter can grant relief **and** App Control does not still deny |
| **Result** | Final DENY if either denies |
| **Audit** | Deny with source tags |
| **Notification** | Per owning system |
| **Offline/error** | Honest if either plane unknown |

**Law:** Temporary Web Filter exception must **not** silently alter App Control.

---

## F22 — Web Filter + FS-005 Mode tightening

| Step | Content |
|---|---|
| **Entry** | Mode becomes active (owned by FS-005) |
| **Preconditions** | Mode context published; filter consumes |
| **States** | `mode_tighten_active` |
| **Actions** | Parent sees chip “Mode tightening active” + link to Modes; **no** local schedule editor |
| **Result** | Additional restriction only; cannot weaken baseline |
| **Audit** | Deny may tag Mode if Mode caused extra deny |
| **Notification** | Modes system may notify; filter does not own schedule alerts |
| **Offline/error** | Last known Mode context honesty |

---

## F23 — SOS access during active filtering

| Step | Content |
|---|---|
| **Entry** | Child or parent SOS entry |
| **Preconditions** | Filter may be active |
| **States** | Any `enf_*` |
| **Actions** | SOS always available (WF-SF-02) |
| **Result** | SOS path not blocked / not gated by filter |
| **Audit** | SOS owned by SOS system |
| **Notification** | SOS ladder |
| **Offline/error** | SOS offline rules unchanged |

---

## F24 — Optional router add-on (separated)

| Step | Content |
|---|---|
| **Entry** | Optional Add-ons → Home router |
| **Preconditions** | Primary/Full to configure; all parents may view honesty |
| **States** | `router_*` — **never** merged into core `enf_enforced` |
| **Actions** | Configure optional DNS add-on with explicit “not a substitute for on-device enforcement” copy |
| **Result** | Optional add-on record; FAT-078-style mock must show unverified honesty |
| **Audit** | Optional config change |
| **Notification** | None implied as “family protected” |
| **Offline/error** | Unverified / not configured honesty |

---

## Filtering Decision UX (L3.5) — embedded rules

Parent decision detail and child interstitial use a shared **source-of-deny** model:

| Source | Parent label (concept) | Unlock path |
|---|---|---|
| Web Filter (list/category/dictionary) | Filter reason class | Web Filter temporary exception (F15) |
| App/System Control | App Control | App Control flow — **not** WF unlock |
| Both | Stricter intersection | Both must clear; WF approve alone insufficient |
| Mode tightening | Mode + Filter | No Mode bypass from WF unlock; exception still WF-scoped |

Do not create conflicting unlock paths.

---

## Honesty / Capability UX (L3.6) — embedded rules

Overview always separates:

1. **Policy configured?** (`policy_*`)  
2. **Device acknowledged?** (`policy_pending_ack` / acked)  
3. **Enforcement plane verified?** (`enf_*`)  
4. **Safe Search / private browse capability?** (`ss_*` / `pb_*`)

Only when (2)+(3) support it may UX claim active on-device filtering for the current policy version.
