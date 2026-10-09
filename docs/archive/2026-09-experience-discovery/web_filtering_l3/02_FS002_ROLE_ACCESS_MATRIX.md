# 02 — FS-002 Role & Access Matrix (L3.2)

**Authority:** L2 Role Access · WF-OD-02 · WF-OD-03 · WF-SF-05 · WF-SF-06 · WF-OD-15  
**Vocabulary:** Primary Parent · Co-Parent Observer · Partner · Full · Child  
**RBAC only** — never infer authority from “who holds the device” (WF-SF-05).

Legend: ✅ allowed · 👁 view-only · ⛔ forbidden · — N/A

---

## 1. Action × role matrix

| Action | Primary | Partner | Full | Observer | Child |
|---|:-:|:-:|:-:|:-:|:-:|
| **View family baseline summary** | ✅ | ✅ | ✅ | ✅ | ⛔ |
| **Edit family baseline policy** | ✅ | ⛔ | ✅ | ⛔ | ⛔ |
| **View effective policy for a child** | ✅ | ✅ | ✅ | ✅ | ⛔ |
| **Create / edit child override** | ✅ | ⛔ | ✅ | ⛔ | ⛔ |
| **Remove child override** | ✅ | ⛔ | ✅ | ⛔ | ⛔ |
| **Change categories** | ✅ | ⛔ | ✅ | ⛔ | ⛔ |
| **Manage allowlist** | ✅ | ⛔ | ✅ | ⛔ | ⛔ |
| **Manage blocklist** | ✅ | ⛔ | ✅ | ⛔ | ⛔ |
| **Manage keyword dictionary** | ✅ | ⛔ | ✅ | ⛔ | ⛔ |
| **Configure Safe Search (where applicable)** | ✅ | ⛔ | ✅ | ⛔ | ⛔ |
| **View Safe Search capability honesty** | ✅ | ✅ | ✅ | ✅ | ⛔ |
| **View private/incognito capability honesty** | ✅ | ✅ | ✅ | ✅ | ⛔ |
| **View enforcement / device status** | ✅ | ✅ | ✅ | ✅ | disclosure only* |
| **Approve temporary exception** | ✅ | ✅ | ✅ | ⛔ | ⛔ |
| **Deny unlock request** | ✅ | ✅ | ✅ | ⛔ | ⛔ |
| **View unlock decisions / ticket history** | ✅ | ✅ | ✅ | 👁 | ⛔ |
| **View deny-event summaries (audit scope)** | ✅ | ✅ | ✅ | 👁 | ⛔ |
| **Export audit/evidence bundle** | ✅† | ⛔ | ⛔† | ⛔ | ⛔ |
| **Preview interstitial (parent tool)** | ✅ | ✅ | ✅ | ✅ | — |
| **Request unlock (from interstitial)** | — | — | — | — | ✅ |
| **See block interstitial** | — | — | — | — | ✅ |
| **Non-interactive filter-active disclosure** | — | — | — | — | ✅ |
| **See policy lists / categories / admin** | ✅ | 👁 summary | ✅ | 👁 summary | ⛔ |
| **Configure Modes schedule** | via FS-005 | via FS-005 | via FS-005 | via FS-005 | ⛔ |
| **Claim router as core on-device protection** | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| **Optional router add-on (honest setup)** | ✅‡ | 👁 | ✅‡ | 👁 | ⛔ |

\* Child sees only “family filter active” disclosure — not device diagnostics.  
† WF-SF-06: evidence **export** remains Primary-leaning unless a later Owner Decision expands it. Full may **view** audit in-app; export = Primary.  
‡ Router add-on configure follows same editors as policy (Primary+Full) with mandatory honesty labeling (WF-OD-11).

---

## 2. Frozen laws preserved

| Law | Matrix reflection |
|---|---|
| **Q-WF-02 / WF-OD-02** | Partner + Observer cannot edit core filter policy / lists / categories / Safe Search |
| **Q-WF-03 / WF-OD-03** | Observer cannot approve/deny; Partner can decide unlocks |
| **WF-SF-05** | All cells are role-level RBAC |
| **WF-SF-06** | Full ≠ Primary on evidence export class |
| **WF-OD-15** | Child has no administrative cells |

---

## 3. Read-only banners (UX)

When Partner/Observer open FAMILY BASELINE or lists:

- Show **read-only** banner: “يمكن للولي الأساسي أو الشريك كامل الصلاحية التعديل”
- Hide save / add / delete controls
- Unlock Inbox: Observer sees tickets without Approve/Deny; Partner/Full/Primary see decision CTAs

---

## 4. Explicit non-roles

Do not use legacy Father-only edit as target. Do not invent Guardian-as-filter-admin without Owner Decision.
