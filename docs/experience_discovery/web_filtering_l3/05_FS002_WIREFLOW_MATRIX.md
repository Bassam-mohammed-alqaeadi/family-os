# 05 — FS-002 Wireflow Matrix (L3.4 companion)

Maps each required flow to screens, states, roles, and L2 refs.

| Flow | Primary screens | Key states | Actor | L2 ref |
|---|---|---|---|---|
| F01 Create family policy | WF-P-OVERVIEW → WF-P-FAMILY | policy_none→saved→pending_ack | Primary/Full | WF-OD-01 |
| F02 Edit baseline | WF-P-FAMILY (+ editors) | saving→pending_ack | Primary/Full | WF-OD-01/02/05/08 |
| F03 Create override | WF-P-CHILD → WF-P-OVERRIDE | override_active | Primary/Full | WF-OD-01 |
| F04 Remove override | WF-P-OVERRIDE | confirm→family_active | Primary/Full | WF-OD-01 |
| F05 Categories | WF-P-CATEGORIES | dirty→saved | Primary/Full | WF-OD-05 |
| F06 Allowlist | WF-P-ALLOW | list_* | Primary/Full | WF-OD-08 |
| F07 Blocklist | WF-P-BLOCK | list_* | Primary/Full | WF-OD-08 |
| F08 Dictionary | WF-P-DICT | list_* | Primary/Full | WF-OD-08 |
| F09 Safe Search | WF-P-SAFESEARCH | ss_* | Primary/Full edit; all view | WF-OD-06 |
| F10 Private browse | WF-P-PRIVATE | pb_* | All parents view | WF-OD-07 |
| F11 Device status | WF-P-STATUS | enf_* · pending_ack | All parents view | WF-OD-04 · SF-10 |
| F12 Child blocked | WF-C-INTERSTITIAL | v_blocked* | Child | WF-OD-15 · SF-02 |
| F13 Unlock request | WF-C-INTERSTITIAL | ticket_pending | Child | WF-OD-09/15 |
| F14 Parent receives | WF-P-INBOX → WF-P-TICKET | ticket_pending | P/Partner/Full (+Obs view) | WF-OD-03 |
| F15 Approve temp | WF-P-TICKET | approved→active | P/Partner/Full | WF-OD-09 |
| F16 Deny | WF-P-TICKET | ticket_denied | P/Partner/Full | WF-OD-03 |
| F17 Expiry | system → WF-P-DECISIONS | expired | System | WF-OD-09 |
| F18 Ack | WF-P-STATUS | pending_ack→acked | Device+Parent | SF-04 |
| F19 Offline/stale | any editor / STATUS | sync_degraded/stale | Parent | SF-04 · T-WF-04 |
| F20 Degraded | WF-P-STATUS / OVERVIEW | enf_degraded/unsupported | Parent | WF-OD-04 |
| F21 Intersection | WF-C-INTERSTITIAL + source | v_stricter_* | Child/Parent | WF-OD-12 |
| F22 Mode tighten | OVERVIEW chip → FS-005 | mode_tighten_active | Parent | WF-OD-10/13 |
| F23 SOS | SOS surfaces | any | Child/Parent | WF-SF-02 |
| F24 Router add-on | WF-P-ROUTER | router_* | Primary/Full config | WF-OD-11 |

---

## Cross-flow constraints

| Constraint | Applies |
|---|---|
| Partner/Observer cannot enter save on F01–F09 | Role matrix |
| Observer cannot Approve/Deny on F15–F16 | WF-OD-03 |
| F15 never writes allowlist | WF-OD-09 |
| F21 unlock CTA suppressed if App Control still denies | WF-OD-12 |
| F22 no schedule editor inside WF | WF-OD-10 |
| F24 never sets enf_enforced alone | WF-OD-11 |
