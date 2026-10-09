# 09 — Child Experience (Target)

**Date:** 2026-09-23  
**Tone:** Calm, clear, never punitive (S-4)  
**Currency:** Minutes only

---

## CURRENT child reality

| Need | Today |
|---|---|
| Remaining | CHD-004 via PolicySyncBus |
| Why restricted | Weak — CHD-021 calm copy |
| Request more | CHD-020 local mock — parent may never see it |
| Wallet | CHD-019 fixture ≠ ledger |
| Warning | No S-3 pipeline |
| SOS / chat / Quran | Preserved at expiry |

---

## TARGET — Before expiry (AVAILABLE)

Child understands:

1. **How much remains** — large Minutes remaining + simple progress.
2. **When it ends** — clock time if schedule; else “about X min left”.
3. **What is consuming** — “Games count · Quran doesn’t”.
4. **What is protected** — Chat, Quran, SOS always listed as safe exits.

Surfaces: CHD-004 primary; optional mirror widget.

---

## TARGET — Near expiry (WARNING / LOW_TIME)

| Spec | Value |
|---|---|
| Timing | **5 minutes** before countable exhaustion (Register S-3) |
| Messaging | Calm: “5 minutes left · you can ask for more or open Quran/Chat” |
| Actions | Request more · Open Quran · Open Chat · (no dark patterns) |
| Duplicate warning | Throttle; don’t spam every second unless platform requires |

---

## TARGET — Expired (EXPIRED / RESTRICTED)

| Available | Unavailable |
|---|---|
| Family chat | Countable entertainment |
| Quran | Permanently blocked apps (always) |
| **SOS (always — including during active mode / lock / expiry)** | Entertainment apps denied by active mode (unless ModeException) |
| Non-countable edu (per S-1) | Instant-locked device entertainment |
| Request more time CTA | — |

> **Freeze correction (2026-09-23):** SOS is never made unavailable by smart mode. See `screen_time_final/05_PRECEDENCE_FINAL.md`.

**Why copy:** “Entertainment time for today is finished. Chat, Quran, and SOS stay with you.”

CHD-021 keeps calm bedtime aesthetic (S-4) — not a punishment wall.

---

## TARGET — Request more time

| Field | Spec |
|---|---|
| Amount | Presets + custom; positive Minutes only |
| Reason | Optional short reason / trade suggestion (prototype has trade keys) |
| Submit | Calls **same** `TimeRequestService.createRequest` as parent inbox |
| Pending | Show REQUEST_PENDING; disable duplicate submit while pending (`OWNER` allow one pending per child) |
| Approved | Show granted Minutes + updated remaining; confirm toast |
| Denied | Show parent reason (UF-05) — never silent |
| Timeout | `OWNER` — e.g. auto-expire pending after N hours |
| Mother/Father | Child does not choose approver |

---

## TARGET — Earned Minutes & wallet

- CHD-019 reads **per-app wallets** from ledger projection (ADR-036).
- Show channel source (“Quran portion · Father approved”).
- Explain overflow: “These Minutes open apps only if Father allows past the daily cap.”
- Never show points/XP/badges-as-currency (badges may exist as non-currency stickers if prototype requires — not spendable).

---

## SOS & communication exemptions

Non-negotiable: SOS hold-to-fire, chat, Quran remain reachable under expiry and instant lock surfaces defined in policy. Child must never need Minutes to call for help.

---

## States the child may perceive (UI labels)

Map to formal machines in [11_STATE_MACHINE.md](11_STATE_MACHINE.md) — do not collapse into one enum in code.

See: [10_REQUEST_AND_EXCEPTION_MODEL.md](10_REQUEST_AND_EXCEPTION_MODEL.md).
