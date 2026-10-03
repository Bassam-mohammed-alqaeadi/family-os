# 04 — FS-007 Flow Catalog (L3)

**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

| ID | Flow | Actors | Outcome |
|---|---|---|---|
| F01 | Enable Search/Image tool | Primary/Full | Tool configured; child card updates; model required for `active` |
| F02 | Apply signed model update | Primary/Full | Version activates on devices after ack path; audit |
| F03 | Rollback model | Primary/Full | Prior signed version; honesty |
| F04 | Local classify input | Device | Signal with category/certainty/severity/provenance |
| F05 | Notify on completed classify | System → Primary/Full/Partner | Safety notification |
| F06 | Open ticket if gate passes | System | Ticket + metadata + preview if available |
| F07 | Review ticket | Primary/Full/Partner | FP / resolve / suggest |
| F08 | Suggest WF/AC/Mode change | Reviewer | Suggestion pending human approve in owning system |
| F09 | Purge preview on close | System | Preview deleted; audit kept |
| F10 | Child opens transparency | Child | Permanent card honesty |
| F11 | Degraded/missing model | System | State matrix honesty; no fake hits |
| F12 | Offline classify + queue sync | Device | Local signal; outbox to parents |
| F13 | Integrity failure | System | Refuse execute; notify configure roles |

**Forbidden flows:** auto SOS; silent list/package/Mode mutation; plant fixture alerts; fake cloud classify.
