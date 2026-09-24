# 01 — SOS Screen Architecture

**Status:** SCREEN ENGINEERING SPEC (docs only)  
**Authority:** [`docs/experience_discovery/sos_final/13_SOS_FINAL_MASTER_CONTRACT.md`](../sos_final/13_SOS_FINAL_MASTER_CONTRACT.md)  
**Entry:** [14_SOS_SCREEN_ENGINEERING_MASTER.md](14_SOS_SCREEN_ENGINEERING_MASTER.md)

**Hard rules:** No app code · no `tokens.dart` changes · no audio/video · no national emergency numbers · preserve coral emergency language · 3s hold · Break-glass is parent-only on FAT-018 (not CHD-005).

---

## 1. Primary SOS screens

| Screen ID | Title | Engineering decision | Widget (Stage-1) | Route |
|---|---|---|---|---|
| SCR-CHD-005 | Child SOS Trigger | **MODIFY** | `ChildSosButtonScreen` | `/scr-chd-005` |
| SCR-CHD-006 | Child SOS Active | **EXTEND** | `ChildSosInProgressScreen` | `/scr-chd-006` |
| SCR-FAT-018 | Parent SOS Incident Center | **EXTEND** | `SosAlertScreen` | `/scr-fat-018` |
| SCR-FAT-028 | Emergency & Trusted Contacts | **EXTEND** | `EmergencySetupScreen` | `/scr-fat-028` |

No new Screen IDs. Panic Quiet mounts as CHD-006 presentation + FAT-028 config. Break-glass mounts as FAT-018 sheet (Primary + Mother Full).

---

## 2. Supporting surfaces (link-only)

| Surface | SOS use | Engineering |
|---|---|---|
| SCR-FAT-014 | Live / last-known map from FAT-018 | Reuse; deep-link with `childId` |
| SCR-FAT-058 | Quiet hours honesty — SOS never muted | Keep; no mute-SOS control |
| SCR-CHD-021 | SOS CTA when time expired | Keep CTA → CHD-005 (OD-14) |
| SCR-CHD-007 | Child “contact parent” / family chat | Reuse from CHD-006 |
| Family Shell FAB | Child SOS FAB → CHD-005 | Keep; hide on CHD-005/006 |
| Shell shortcut | Parent → FAT-018 | Keep |
| Audit log (FAT-060) | Lifecycle / Break-glass visibility | Append-only; no SOS redesign |
| Device lock / expiry overlays | Must not block SOS (OD-14) | Exempt `sos` surface — no visual redesign |

---

## 3. Information architecture placement rules

| Placement | Use for |
|---|---|
| **Hero / status area** | Lifecycle chip, piercing headline, Panic Quiet critical status |
| **Cards** | Location, delivery, device/battery/connectivity, contact rows |
| **Timeline** | Incident events (ack, escalate, deliveries) on FAT-018 |
| **Bottom sheet** | Cancel confirm; Break-glass; verification start; escalate confirm |
| **Modal** | Rare destructive confirm only (e.g. remove backup) |
| **Inline state** | Chips: location/delivery/offline classes |
| **Snackbar** | Non-blocking success/failure after action |
| **Full screen** | Active coral boards (FAT-018 / CHD-006); CHD-005 hold |

Avoid modal overload: prefer sheets for Break-glass and cancel.

---

## 4. Capability display classes (global)

Every channel/capability chip uses exactly one:

`SUCCESS` · `PARTIAL` · `DEGRADED` · `UNAVAILABLE` · `NOT_CONFIGURED`

Never optimistic “sent/delivered” without confirmation.

---

## 5. Navigation skeleton

```
Child:  Shell FAB / CHD-021 → CHD-005 → (hold) → CHD-006 ⇄ CHD-007
                                              ↓ cancel confirm
                                           CHD-004 (day)

Parent: Push / shell shortcut → FAT-018 ⇄ FAT-014
                              ↘ FAT-028 (Primary/Full)
                              ↘ Break-glass sheet (Primary/Full)
```

---

## 6. Design system

- Colors/radii/shadows from existing `tokens.dart` only (coral for danger/SOS).  
- Reuse `BannerNote`, `AppEmptyState`, `AppErrorState`, existing buttons.  
- New visual components later go to `core/design/components/` once — specified in [10_COMPONENT_SPECIFICATION.md](10_COMPONENT_SPECIFICATION.md), **not implemented here**.
