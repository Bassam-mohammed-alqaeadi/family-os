# 16 — UX Information Architecture

**Date:** 2026-09-23  
**Goal:** One place per job — avoid duplicate settings surfaces.

---

## Placement map

| Concern | Belongs in | Does **not** belong in |
|---|---|---|
| Child remaining + active rule | **Child Profile → Screen Time Overview** | Global settings dump |
| Family-wide defaults (optional later) | **Global family settings** (shared templates) | Per-child Today |
| Lock now / add bonus / open requests | **Quick Actions** on Overview + day board | Buried only in History |
| Sleep/prayer/study + mode schedules | **Schedule / Routines** (FAT-032 section + FAT-085 entry) | App Rules |
| Block/allow/limit/countable | **App / Category Rules** (FAT-034) | Minutes Economy |
| Wallets, earns, overflow | **Minutes Economy** | App install approval |
| Pending asks | **Request Inbox** (FAT-033) | History only |
| Temporary grants & mode exceptions | **Exceptions** | Silent into cap field |
| Usage + decisions timeline | **History** | Overview clutter |
| Sync, permissions, platform honesty | **Policy Health** | Child-facing primary |

---

## Role-specific IA

| Role | Primary landing | Hidden / alternate |
|---|---|---|
| Father | Full tree | — |
| Mother Full | Overview → Schedule → Apps → Requests → Lock | Anti-tamper, billing, mother level |
| Mother Partner | Overview (read) → Requests → Today | Schedule edit, Apps mutate, Lock |
| Mother Observer | Overview read + History read | All mutations |
| Child | Day board remaining → Request → Wallet → Expiry | Parent Policy Health details |

---

## Navigation rules

1. Child Profile is the **hub** for per-child Screen Time (Register G-5 spirit).
2. Smart Modes (FAT-085) linked from Schedule — not a second competing “screen time home”.
3. Web Filter (FAT-036) linked as **adjacent safety**, not a Minutes tab.
4. Instant Lock is Quick Action + FAT-037 detail — not inside Economy.
5. Education earn appears in Economy history with deep link to attribution — not a second wallet.

---

## Copy system

- Always say **Minutes**.
- Rename legacy “نقاط” surfaces per ADR-036 when touching copy.
- Policy Health uses honest verbs: “Simulated in app” vs “Enforced on device”.

See: [17_SCREEN_TIME_EXPERIENCE_GAPS.md](17_SCREEN_TIME_EXPERIENCE_GAPS.md).
