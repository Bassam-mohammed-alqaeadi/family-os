# 09 — FS-003 L3 Cross-System UX

**Authority:** L2 Cross-System · WF-OD-12 · ST Final · Modes · SOS  
**Master:** [11_FS003_L3_MASTER_CONTRACT.md](11_FS003_L3_MASTER_CONTRACT.md)

---

## 1. Ownership in UX (what screens may edit)

| Concern | Editable in App Control? | Deep link |
|---|---|---|
| Allow / Block / Exempt / Lock Now / Install / Exception | **Yes** | — |
| Limit / Unlimited / Countable / Temporary Grant | **No** | Screen Time |
| URL categories / WF unlock | **No** | Web Filtering |
| Schedules / lifestyle modes | **No** | FS-005 Modes |
| Instant Device Lock | **No** | Lock system |
| Uninstall resistance | **No** | Anti-tamper |
| SOS | Never gated | SOS |

---

## 2. Source-of-deny UX contract

When access fails, interstitial / parent SOD must distinguish:

| Source | Child CTA pattern |
|---|---|
| App Control only | Exception Request (if eligible) |
| Web Filter only | WF unlock path (not App Exception) |
| Both | Show both; CTAs that cannot relieve the other source stay disabled with explanation |
| Screen Time only | ST minutes request |
| Mode only | No child schedule edit; message Mode active |
| Instant Lock | No App Exception reopen of device lock |

**No cross-system silent mutation** when any CTA succeeds.

---

## 3. Browser package vs URL

| UX copy | Placement |
|---|---|
| “Allowing this browser app does not allow all websites” | App detail when package is browser-class |
| “Allowing a site does not open a blocked app” | WF surfaces (consumed) |

---

## 4. Modes chip

Parent hub/detail: chip “Mode tightening app access” → FS-005.  
No App Control control to weaken Mode or reopen Permanent Block via Mode.

---

## 5. Screen Time panel on app detail

Read-only summary optional (“limits managed in Screen Time”) + button Open ST.  
Never inline editors for Unlimited/Limit/Countable in AC wireframes.

---

## 6. Separations always visible where relevant

On Exception sheets and app detail:

- Exception ≠ Temporary Grant ≠ Unlimited  
- Exempt ≠ Unlimited  
- Lock Now ≠ Permanent Block ≠ Instant Device Lock  

---

## 7. SOS / protected

Every parent and child chrome retains SOS.  
Protected rows never show Block.  
Copy: remain reachable and cannot be denied by App Control.

---

## 8. Notifications ownership

App Control **emits** events; Notifications **delivers** (T-APP-10).  
UX lists notification *types*, not transport.
