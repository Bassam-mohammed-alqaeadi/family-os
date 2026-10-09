# 08 — FS-002 L2 ↔ L3 Traceability (L3.9)

Map: **L2 law → IA → State → Flow → Screen → Wireframe**

---

## Structural freezes

| L2 | IA | State | Flow | Screen | Wire |
|---|---|---|---|---|---|
| WF-SF-01 Minutes independence | Unlock ≠ grant (IA non-placement) | ticket_* only WF | F15–F16 | WF-P-TICKET | WF-05 |
| WF-SF-02 SOS ungated | SOS in IA + child interstitial | any enf_* | F23 | WF-C-INTERSTITIAL · SOS | WF-07 |
| WF-SF-03 Domain vs Kernel | Decisions vs policy editors | verdict + audit | F12/F14 | WF-P-DECISIONS | WF-09 |
| WF-SF-04 Offline honesty | Status / editors | pending_ack/stale/sync | F18–F19 | WF-P-STATUS | WF-06 |
| WF-SF-05 RBAC | Role IA | — | all gated | Role matrix | banners |
| WF-SF-06 Primary ≠ Full export | Decisions export | — | Decisions | WF-P-DECISIONS | — |
| WF-SF-07 Append-only audit | Decisions | — | F12/F15–17 | WF-P-DECISIONS | — |
| WF-SF-08 AI no execute | Non-placement | — | — | — | — |
| WF-SF-09 Vocabulary | All docs | — | — | — | AR/EN |
| WF-SF-10 No false claim | Overview honesty | enf_* | F11/F20 | WF-P-OVERVIEW/STATUS | WF-01/06 |

---

## Owner decisions

| L2 | Choice | IA | State | Flow | Screen | Wire |
|---|---|---|---|---|---|---|
| WF-OD-01 | C family+override | Family + Per-child | policy_family / override | F01–F04 | WF-P-FAMILY/CHILD/OVERRIDE | WF-02/03 |
| WF-OD-02 | B Primary+Full configure | Editors gated | — | F01–F09 | Role matrix | read-only banner |
| WF-OD-03 | B unlock decide | Inbox | ticket_* | F14–F16 | WF-P-INBOX/TICKET | WF-05 |
| WF-OD-04 | D hybrid | Status honesty | enf_* | F11/F20 | WF-P-STATUS | WF-06 |
| WF-OD-05 | B large categories | Categories | category verdict | F05 | WF-P-CATEGORIES | — |
| WF-OD-06 | A Safe Search | Safe Search | ss_* | F09 | WF-P-SAFESEARCH | WF-02 |
| WF-OD-07 | D private honesty | Private panel | pb_* | F10 | WF-P-PRIVATE | WF-02 |
| WF-OD-08 | C lists+dict | Lists IA | allow/block/dict verdicts | F06–F08 | WF-P-ALLOW/BLOCK/DICT | WF-04 |
| WF-OD-09 | B timed temp | Ticket copy | temp_allow_* | F15/F17 | WF-P-TICKET | WF-05 |
| WF-OD-10 | C Modes schedule | Cross-link Modes | mode_* | F22 | OVERVIEW chip | WF-01 |
| WF-OD-11 | D router optional | Add-ons | router_* | F24 | WF-P-ROUTER | WF-10 |
| WF-OD-12 | C stricter ∩ | Source-of-deny | v_stricter_* | F21 | INTERSTITIAL · DENY-DETAIL | WF-07/09 |
| WF-OD-13 | B Modes tighten only | No weaken control | mode_tighten | F22 | chip only | WF-01 |
| WF-OD-14 | B audit scope | Decisions | deny+unlock | F12/F14–17 | WF-P-DECISIONS | WF-09 |
| WF-OD-15 | B child UX | Child IA: interstitial + disclosure only | interstitial + transient pending/approved/denied/expired | F12–F13 · F15–F17 child branch | WF-C-INTERSTITIAL · WF-C-DISCLOSURE only | WF-07 A/B/C · WF-08 |

---

## Technical TBDs (must remain TBD in L3)

| ID | L3 treatment |
|---|---|
| T-WF-01 duration | Placeholder 〔TBD〕 on ticket / result |
| T-WF-02 taxonomy | Placeholder category list; no Stage-1 six freeze |
| T-WF-03 mechanism | No VPN/DNS/DO product UI as “the” mechanism |
| T-WF-04 stale TTL | `policy_stale` without numeric threshold |
| T-WF-05 sync algo | Queued/failed honesty only |

---

## Coverage check

Every WF-SF-01…10 and WF-OD-01…15 has ≥1 L3 representation above. **PASS.**
