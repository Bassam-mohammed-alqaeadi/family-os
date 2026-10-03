# 05 — Location Wireflow Matrix (L3.4)

**Companion:** [04_LOCATION_USER_FLOWS.md](04_LOCATION_USER_FLOWS.md)  
Compact machine-readable wireflow table for engineering.

| Flow | Entry | Happy path | Primary branches | Terminal | Offline/error |
|---|---|---|---|---|---|
| F01 Live | Hub/Profile | Open Live → see freshness + map | Child switch; History; Zones; SLR; Elevated; SOS | Stay / navigate out | offline + last_seen/stale/unavailable |
| F02 Elevated | Live control | Standard → Elevated | Back to Standard; SLR; SOS | Mode set | Elevated + offline honesty |
| F03 History | Live/Profile | Open History → days/stops | Export/Archive (Primary) | Back Live | partial_offline; export fail honest |
| F04 Create Zone | Library CTA | Geometry → name → alerts → **children multi-select** → Save | Circle vs Polygon; cancel | Library with new zone | block if 0 children; queue sync |
| F05 Edit Zone | Library row | Edit fields → Save | Change assignment/alerts/geometry | Library updated | queue; validation |
| F06 Assign | Inside F04/F05 | Select ≥1 child | Explicit select-all user action | Valid draft | invalid draft if empty |
| F07 Zone event | Push/inbox | Open event → Live focus | History; dismiss | Event read | delayed outbox delivery |
| F08 Check-In | Child Safety | Named place → ack | — | Toast; parent card queued | local ack + queue |
| F09 SLR | Live action | Authorize → pending → result | — | Result card | queued/denied/failed |
| F10 Integrity | Live signal | Show soft warning | Dismiss | confidence_normal or remains low | no punish |
| F11 Offline | Loss of net | Chips offline | Continue local | — | no fake synced |
| F12 Sync | Net restore | syncing → synced | Retry | synced | sync_failed |
| F13 SOS handoff | FAT-018-like SOS CTA | SOS → Live focus child | Return SOS; optional Elevated | Dual context | honesty on both |

### Global guards

| Guard | Applies |
|---|---|
| RoleGuard child lean | All parent Location surfaces |
| Save requires ≥1 child | F04/F05/F06 |
| No FAT-077 kinds | F07 |
| No child SLR UI | F09 |
| No Break-glass Find | F13 |
| No invented numbers in labels | F01/F02/F10/bands |
