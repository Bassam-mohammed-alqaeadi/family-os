# 03 — Location Role Access Contract (FROZEN)

**System:** #4 Location & Safe Zones  
**Status:** FROZEN — 2026-09-23  
**Authority:** Q-LOC-02 / LOC-OD-03…07 · Mother permissions (doc 20) · Role matrix · SOS RBAC for Break-glass boundary  
**Roles:** Primary (Father/Owner) · Mother `observer` | `partner` | `full` · Guardian (pinned observer-class) · Child

---

## 1. Hard equalities and inequalities

| Rule | Frozen |
|---|---|
| Mother location **reassurance** (Live) | Does **not** grade by MotherLevel (existing law) |
| **Mother Full ≠ Primary** | Full is operational co-parent, **not** owner-equivalent |
| Export / Archive | **Primary only** |
| Co-Parent ≠ automatic Primary history powers | **Forbidden** to treat Full as Primary for sensitive history actions |
| Sensitive history access/actions | **Auditable** |

---

## 2. Capability matrix (frozen layer)

| Capability | Primary | Mother ① Observer | Mother ② Partner | Mother ③ Full | Guardian | Child |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| View **Live Location** | ✅ | ✅ | ✅ | ✅ | ✅ (view) | ⛔ silent (except SOS status) |
| View **operational Location History** (in-app trail) | ✅ | ✅* | ✅* | ✅* | ✅* view | ⛔ |
| **Export** history | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| **Archive** / long-term sensitive archive actions | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Configure geofences / geometry / assignments | ✅ | ⛔ | ⛔ | ✅ | ⛔ | ⛔ |
| Toggle zone alert enablement (rules surface) | ✅ | ⛔ | ⛔ | ✅ | ⛔ | ⛔ |
| Initiate **Silent Location Request** | ✅ | ⛔ | ✅† | ✅† | ⛔ | ⛔ |
| Receive Silent Request **result** | ✅ | ✅ (view result if family shared) | ✅ | ✅ | ✅ view | ⛔ |
| Child Check-In ack | — | — | — | — | — | ✅ Safety ack only |
| See Check-In / evidence on parent side | ✅ | ✅ | ✅ | ✅ | ✅ view | — |
| SOS Break-glass | ✅ | ⛔ | ⛔ | ✅ (SOS Final) | ⛔ | ⛔ |
| Use Break-glass as Find-My-Child | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Disable/weaken location safety from child UI | — | — | — | — | — | ⛔ |

\* **Operational history read (closure reading of Q-LOC-02):** Mother/Guardian may view the **in-app operational trail** as reassurance (aligned with “seeing does not grade”), but **cannot** Export/Archive and are **not** Primary-equivalent. Any future tightening of Observer/Guardian history depth is a **documentation amendment**, not silent code invention — L3 must implement audit on sensitive opens if product later restricts further.

† **Silent Request initiation:** Partner + Full + Primary may initiate (safety action, not nuclear config). Observer/Guardian/Child cannot initiate. *(If Owner later restricts initiation to Primary/Full only, amend this row explicitly.)*

---

## 3. Sensitive actions (Primary + audit)

The following are **Primary-only** and **must write audit**:

- Export location history  
- Archive / retrieve archive  
- Bulk download / external share of trail  
- Any future Emergency Find product (not created here; separate OD)

Mother Full performing zone edits **must** also audit (config change), but that does **not** grant Export/Archive.

---

## 4. Child role

- No live map, history, coordinates, geofence library/rules UI, location diagnostics, alert-rule visibility, or disable/weaken controls.  
- Check-In: acknowledgement under **Child Safety** only.  
- SOS ACTIVE: location **status** words only ([07_CHILD_SILENT_LOCATION_CONTRACT.md](07_CHILD_SILENT_LOCATION_CONTRACT.md)).

---

## 5. AuthZ rules

1. Authorization is **RBAC** (role + MotherLevel) — never inferred from “who holds the phone.”  
2. APIs/repos must reject Export/Archive for non-Primary.  
3. RoleGuard / composition must omit child location tooling surfaces.  
4. Break-glass remains SOS Final RBAC; **cannot** authorize general locate outside SOS response override.

---

## 6. Residual before L3 (product — not invented here)

If Owner wants Observer/Guardian **denied** operational history (live-only), that is a **single-line amendment** to §2 — currently frozen as view-allowed for reassurance without Primary-equivalent powers.
