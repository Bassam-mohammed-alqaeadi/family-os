# 05 — FS-003 L3 Parent Wireframes

**Status:** UX/behavior specification — **not** Flutter code  
**Authority:** L2 · IA · Role · State · Flows  
**RTL/LTR:** Mirrored; SOS always reachable in chrome  
**Master:** [11_FS003_L3_MASTER_CONTRACT.md](11_FS003_L3_MASTER_CONTRACT.md)

Wireframes are ASCII structural — implementation-ready regions, not pixel design.

---

## W-P01 — AC-P-HUB Overview

```
┌─────────────────────────────────────────┐
│ [←]  App Control              [SOS]     │
├─────────────────────────────────────────┤
│ HONESTY STRIP                           │
│ Plane: enforced|degraded|…  Ack: v12    │
│ [Mode tightening] [Offline queued]      │
├─────────────────────────────────────────┤
│ Pending installs (3)  Pending except (1)│
│ [Open install inbox] [Open exceptions]  │
├─────────────────────────────────────────┤
│ Family baseline          [Open]         │
│ Children                                │
│  • Child A  override·on  acked 2/2      │
│  • Child B  baseline     pending 1/2    │
├─────────────────────────────────────────┤
│ [Audit]  [Devices]                      │
└─────────────────────────────────────────┘
```

| Element | Rules |
|---|---|
| Honesty strip | Mandatory; no “fully protected” if not `enforced`+acked |
| Pending counts | Hidden if zero |
| Child rows | Tap → AC-P-CHILD |
| Partner | Sees inboxes; no baseline edit CTA |
| Observer | Counts visible; decide CTAs hidden |

---

## W-P02 — AC-P-FAMILY Baseline

```
┌─────────────────────────────────────────┐
│ [←]  Family baseline          [SOS]     │
├─────────────────────────────────────────┤
│ Protected (cannot deny):                │
│ SOS · Family OS · Required Chat · Quran │
├─────────────────────────────────────────┤
│ Class defaults (optional)               │
│ [Games …] [Social …]  (labels TBD)      │
├─────────────────────────────────────────┤
│ Unknown packages: Deny-until-approved   │
│ (when no class default)                 │
├─────────────────────────────────────────┤
│ [Save baseline]   (Primary/Full only)   │
└─────────────────────────────────────────┘
```

| Forbidden | ST Limit/Unlimited editors · schedule editor · block protected |

---

## W-P03 — AC-P-CHILD Effective + override

```
┌─────────────────────────────────────────┐
│ [←]  {Child} App Control      [SOS]     │
├─────────────────────────────────────────┤
│ Effective: OVERRIDE | BASELINE          │
│ Honesty: device mix summary             │
├─────────────────────────────────────────┤
│ [Installed apps]  [Override editor]     │
│ [Restore baseline] (Primary/Full)       │
│ Copy: does not reopen Permanent Blocks  │
├─────────────────────────────────────────┤
│ Deep links: [Screen Time] [Modes] [WF]  │
└─────────────────────────────────────────┘
```

Restore confirm sheet: lists what clears (overrides, exceptions, Lock Now) vs what remains (Permanent Blocks).

---

## W-P04 — AC-P-INV Inventory

```
┌─────────────────────────────────────────┐
│ [←]  Installed apps           [SOS]     │
├─────────────────────────────────────────┤
│ Filter: All | Blocked | Pending | …     │
├─────────────────────────────────────────┤
│ 📦 com.example.game                     │
│    Display Name · Allowed               │
│ 📦 com.social.app                       │
│    Display · Permanent Block            │
│ 📦 com.new.app                          │
│    Display · Pending (deny until OK)    │
│ 🔒 SOS / Chat / Quran                   │
│    Protected · reachable                │
└─────────────────────────────────────────┘
```

| Rule | Package ID visible (or accessible detail); label secondary; no slug-as-key |

---

## W-P05 — AC-P-APP Detail

```
┌─────────────────────────────────────────┐
│ [←]  {label}                  [SOS]     │
├─────────────────────────────────────────┤
│ Package ID: com.example.game            │
│ Version: … (observational)              │
│ Disposition: Permanent Block            │
│ Overlays: Exception active 02:14 left*  │
│          Lock Now: off                  │
│ *duration display TBD (T-APP-06)        │
├─────────────────────────────────────────┤
│ Access (Primary/Full):                  │
│ [Allow] [Permanent Block] [Exempt]      │
│ [Reopen Permanent Block] ← Primary only │
│ [Lock Now] [Clear Lock Now]             │
├─────────────────────────────────────────┤
│ Time (Screen Time — deep link):         │
│ Limit / Unlimited / Countable → [Open]  │
│ Copy: authored in Screen Time only      │
├─────────────────────────────────────────┤
│ Separations:                            │
│ Exception ≠ Grant ≠ Unlimited           │
│ Exempt ≠ Unlimited                      │
└─────────────────────────────────────────┘
```

| Full | Reopen control disabled + explanation |
| Partner/Observer | Access buttons hidden; deep links ok |

Permanent Block confirm:

```
┌──────────────────────────────┐
│ Permanently block this app?  │
│ Minutes, Temporary Grant, and│
│ Unlimited cannot open it.    │
│ [Cancel] [Block]             │
└──────────────────────────────┘
```

---

## W-P06 — AC-P-INSTALL Inbox

```
┌─────────────────────────────────────────┐
│ [←]  New installs             [SOS]     │
├─────────────────────────────────────────┤
│ Pending for {Child}                     │
│ com.new.app · first seen …              │
│ Child cannot open until decided         │
│ [Review]                                │
└─────────────────────────────────────────┘
```

---

## W-P07 — AC-P-INSTALL-D Decision

```
┌─────────────────────────────────────────┐
│ [←]  Install decision         [SOS]     │
├─────────────────────────────────────────┤
│ Package ID + label + child              │
│ Scope: THIS CHILD ONLY (default)        │
│ [Approve for this child] [Deny]         │
│ Note: does not change Web Filter lists  │
│ Note: does not grant Minutes            │
└─────────────────────────────────────────┘
```

Actors: Primary + Partner + Full.

---

## W-P08 — AC-P-EXCEPT Inbox + detail

```
┌─────────────────────────────────────────┐
│ Exception request                       │
│ Child · package · reason                │
│ Underlying: Permanent Block (unchanged) │
│ Duration: [picker TBD T-APP-06]         │
│ [Approve timed access] [Deny]           │
│ Copy: temporary override only; does NOT │
│ remove Permanent Block.                 │
│ ≠ Temporary Grant ≠ Unlimited           │
└─────────────────────────────────────────┘
```

Active ticket: [Revoke].

---

## W-P09 — AC-P-DEVICE Honesty

```
┌─────────────────────────────────────────┐
│ Devices — {Child}                       │
│ Device A: enforced · acked v12          │
│ Device B: pending_policy · v12 saved    │
│ Device C: unsupported · no claim        │
│ [Remediation] when disabled_by_permission│
│ Anti-tamper: [Open separate system]     │
└─────────────────────────────────────────┘
```

---

## W-P10 — AC-P-AUDIT

```
┌─────────────────────────────────────────┐
│ Decisions & audit                       │
│ Filters: Policy | Install | Exception | │
│          Deny | Plane                   │
│ — no “all opens” surveillance feed —    │
└─────────────────────────────────────────┘
```

Export: Primary-leaning.

---

## W-P11 — AC-P-SOD Source-of-deny

```
┌─────────────────────────────────────────┐
│ Why access was denied                   │
│ ☑ App Control (Permanent Block)         │
│ ☐ Web Filter                            │
│ ☐ Screen Time                           │
│ ☐ Mode                                  │
│ Actions offered only for owning system  │
└─────────────────────────────────────────┘
```

---

## Sheets (shared)

| Sheet | Content |
|---|---|
| Offline queued | “Saved on this device — waiting to reach child. Not confirmed enforced.” |
| Mode chip | “Modes tightened access — schedules in Modes” → FS-005 |
| Unsupported | “Cannot claim protection on this device” |
