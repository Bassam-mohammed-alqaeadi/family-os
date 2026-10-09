# 05 — FS-003 App Identity Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · APP-OD-08/09/18 · **T-APP-01/07/08 OPEN**  
**Non-authority:** Stage-1 slugs (`minecraft`, `youtube`)  

```
OWNER DECISIONS: FROZEN
```

---

## 1. What is an application? (FROZEN)

An **Application** in FS-003 is a controllable software unit identified by a **platform-stable application identifier** on an enrolled child device, plus display metadata.

| Field class | Required? | Notes |
|---|---|---|
| Platform package / application ID | **Yes** | **Sole policy key** |
| Human-readable label | **Yes** (display) | Not the policy key |
| Version / versionCode | **Yes** (observational) | Update detection |
| Install state | **Yes** | installed / uninstalled / pending / unknown |
| Signing identity (where available) | Recommended | Spoof/replace — T-APP |
| Category / class tags | Optional | Must not replace package key |
| Stage-1 marketing slug | **Forbidden as policy identity** | Display alias map only (technical) |

---

## 2. Unknown / unrecognized (APP-OD-08)

| Concept | Definition |
|---|---|
| **Unknown** | Package with no explicit allow/block/exempt and no applicable class default |
| **Pending** | Awaiting parent decision |
| **Default before decision** | **Deny-until-approved** when no applicable class default exists |

---

## 3. System apps & protected (APP-OD-09)

| Class | Handling |
|---|---|
| **Protected — cannot be denied by App Control** | **SOS · Family OS · Required Family Chat · Quran** |
| **Controllable system / OEM** | Explicit protected/controllable matrix (non-core rows = **T-APP-08**) |
| **Preinstalled OEM** | Treated as packages; class defaults via matrix |
| **Family OS** | Protected |

Do **not** rely on mock “free/tools/edu” categories as law.

**SOS / Required Family Chat / Quran remain reachable and cannot be denied by App Control.**

---

## 4. Multiple packages ↔ one product

| Principle | Law |
|---|---|
| Policy keys remain **package IDs** | Always |
| Product grouping | Optional UX/metadata (**T-APP-07**) |
| Silent multi-package approve | **Forbidden** without explicit grouped approval UX |

---

## 5. Install / uninstall / update

| Event | Effect |
|---|---|
| Install detected | Enter pending; deny-until-approved if no class default |
| Uninstall detected | Inventory update; rules may remain for reinstall |
| Update same package | Usually keep decision; signing change may re-pend (**T-APP**) |
| Install approval scope | **Child-scoped by default** (APP-OD-18) — no silent family-wide |

---

## 6. Browser vs app boundary

| Plane | Identity |
|---|---|
| **FS-003** | Browser **package** allow/block |
| **FS-002** | **URL/host/category** inside allowed browsers |

WF-OD-12 stricter intersection. Approving a browser package ≠ allowing all URLs. Allowing a URL ≠ launching a blocked app package.
