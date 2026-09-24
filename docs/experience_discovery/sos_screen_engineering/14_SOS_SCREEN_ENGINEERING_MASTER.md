# 14 — SOS Screen Engineering Master

# SCREEN ENGINEERING STATUS: COMPLETE (docs only)

**Authority:** Frozen SOS Product Contract  
[`docs/experience_discovery/sos_final/13_SOS_FINAL_MASTER_CONTRACT.md`](../sos_final/13_SOS_FINAL_MASTER_CONTRACT.md)

**This pack:** Flutter-ready UI/UX engineering specification.  
**Does not:** modify application code · implement backend · implement OS emergency services · start another system.

---

## 1. Document index

| # | File |
|---|---|
| 01 | [01_SCREEN_ARCHITECTURE.md](01_SCREEN_ARCHITECTURE.md) |
| 02 | [02_CHD_005_ENGINEERING.md](02_CHD_005_ENGINEERING.md) |
| 03 | [03_CHD_006_ENGINEERING.md](03_CHD_006_ENGINEERING.md) |
| 04 | [04_FAT_018_ENGINEERING.md](04_FAT_018_ENGINEERING.md) |
| 05 | [05_FAT_028_ENGINEERING.md](05_FAT_028_ENGINEERING.md) |
| 06 | [06_ROLE_VARIANTS.md](06_ROLE_VARIANTS.md) |
| 07 | [07_PANIC_QUIET_MODE_UX.md](07_PANIC_QUIET_MODE_UX.md) |
| 08 | [08_BREAK_GLASS_UX.md](08_BREAK_GLASS_UX.md) |
| 09 | [09_FAILURE_DEGRADED_UX.md](09_FAILURE_DEGRADED_UX.md) |
| 10 | [10_COMPONENT_SPECIFICATION.md](10_COMPONENT_SPECIFICATION.md) |
| 11 | [11_SOS_WIREFLOW.md](11_SOS_WIREFLOW.md) |
| 12 | [12_SOS_ACCESSIBILITY_RTL.md](12_SOS_ACCESSIBILITY_RTL.md) |
| 13 | [13_SOS_SCREEN_TRACEABILITY.md](13_SOS_SCREEN_TRACEABILITY.md) |

---

## 2. Contract → screen map (summary)

| Contract theme | Primary screens / components |
|---|---|
| 3s hold trigger + OD-14 reachability | CHD-005 |
| Active critical-only + cancel | CHD-006, Panic Quiet, SosCancelConfirmation |
| Incident center ACK≠RESOLVE + delivery honesty | FAT-018, SosActionBar, SosDeliveryStatus |
| Observer contact-only | FAT-018 + SosRoleGuard |
| Trusted contacts ≤5 verify priority | FAT-028 |
| Break-glass Primary/Full | FAT-018 + SosBreakGlassSheet |
| No audio / no national number | All (explicit absences) |
| Degraded/offline honesty | 09 + location/delivery components |
| Traceability | 13 |

---

## 3. Final verification checklist

| Check | Pass |
|---|---|
| Four primary SOS screens fully specified | YES |
| Observer cannot resolve/escalate/configure | YES (06, 04, 05) |
| ACK ≠ RESOLVE | YES (04) |
| Child cancellation explicit + auditable | YES (03, 11) |
| Panic Quiet Mode specified | YES (07) |
| Break-glass Primary + Full only | YES (08) |
| No audio/video | YES |
| No national emergency number | YES |
| SOS bypasses time/lock/subscription | YES (02, 01, OD-14) |
| Delivery states separate from incident | YES (04, 09) |
| Location states honest | YES (03, 04, 09) |
| Offline/degraded explicit | YES (09) |
| Max 5 backups / priority 1..5 | YES (05) |
| Verification lifecycle | YES (05) |
| Existing design system preserved | YES (01, 12) |
| Application code modified | **NO** |
| Backend implementation started | **NO** |
| Other system started | **NO** |

---

## 4. Next phase (out of scope here)

Authorized Flutter implementation cards may consume this pack screen-by-screen, with `verify_ship` and role widget tests proving Observer/Partner/Full/Primary matrices.
