# 02 — Location Role & Access Matrix (L3.3)

**Authority:** L2 [`03_LOCATION_ROLE_ACCESS_CONTRACT.md`](../location_final/03_LOCATION_ROLE_ACCESS_CONTRACT.md) · Child Silent · LOC-OD-20…25  
**Companion:** [01_LOCATION_IA.md](01_LOCATION_IA.md)

Legend: ✅ allow · 👁 view-only · ⛔ deny · — N/A · 🔇 silent (no surface)

---

## 1. Surfaces × roles

| Surface / action | Primary | Mother Observer | Mother Partner | Mother Full | Guardian | Child |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Open Live Map | ✅ | ✅ | ✅ | ✅ | ✅ | 🔇 |
| Switch Standard watch / Elevated live | ✅ | ✅ | ✅ | ✅ | ✅ | 🔇 |
| View pin / zone overlay (no child coords UI) | ✅ | ✅ | ✅ | ✅ | ✅ | 🔇 |
| View freshness / offline / sync chips | ✅ | ✅ | ✅ | ✅ | ✅ | 🔇 |
| Soft integrity warning (low confidence) | ✅ | ✅ | ✅ | ✅ | ✅ | 🔇 |
| Open History | ✅ | ✅ | ✅ | ✅ | ✅ | 🔇 |
| Export history | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | 🔇 |
| Archive history | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | 🔇 |
| Open Zone Library | ✅ | 👁 | 👁 | ✅ | 👁 | 🔇 |
| Create / edit zone geometry | ✅ | ⛔ | ⛔ | ✅ | ⛔ | 🔇 |
| Assign children (multi-select) | ✅ | ⛔ | ⛔ | ✅ | ⛔ | 🔇 |
| Toggle ENTER/EXIT/NO_SHOW alerts | ✅ | ⛔ | ⛔ | ✅ | ⛔ | 🔇 |
| Receive zone event notify | ✅ | ✅ | ✅ | ✅ | ✅ | 🔇 |
| Initiate Silent Location Request | ✅ | ⛔ | ✅ | ✅ | ⛔ | 🔇 |
| View Silent Request result | ✅ | ✅ | ✅ | ✅ | ✅ | 🔇 |
| Child Check-In ack | — | — | — | — | — | ✅ |
| View Check-In on parent side | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| Non-interactive disclosure | — | — | — | — | — | ✅ (static) |
| SOS location **status** words | — | — | — | — | — | ✅ ACTIVE only |
| Child map / history / zones / coords | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Disable/weaken location safety (child) | — | — | — | — | — | ⛔ |
| Break-glass as Find | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Open Live from SOS board | ✅ | ✅ | ✅ | ✅ | ✅ | ⛔ |

---

## 2. Primary-only actions (audited)

1. Export location history  
2. Archive / retrieve archive  
3. Bulk download / external share of trail  

Zone configure by Mother Full is audited as **config**, not Primary export power.

---

## 3. Child silent behavior (summary)

| Allowed | Forbidden |
|---|---|
| Check-In named-place acknowledgement | Map, coordinates, history, geofence UI |
| Non-interactive compliance disclosure | Disable/weaken / diagnostics / alert rules |
| SOS ACTIVE status: acquiring / located / stale·last-known / unavailable | Interactive Silent Request response |

---

## 4. AuthZ enforcement notes (design)

- RBAC by role + MotherLevel — never “who holds device.”  
- Save Zone disabled until ≥1 child selected (Q-LOC-12=B).  
- RoleGuard omits parent Location surfaces for child role.  
- Soft integrity warning is informational — not a punish control.
