# 09 — FS-004 L3 Enforcement Honesty UX

**Authority:** SC-OD-09 · Enforcement Contract L2 · iOS honesty  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

---

## Claim rule

Parent/child may claim **enforced** for a pillar only when:

1. Intent is on for that pillar, **and**
2. Policy version is **acknowledged** on the device, **and**
3. Capability plane for that pillar is **`enforced`**.

Otherwise show the honesty state — never fake Android parity on iOS.

---

## Per-state UX (all pillars)

| State | Parent strip | Child | Allowed claim | Actions |
|---|---|---|---|---|
| `enforced` | Green/ok honesty | Status reflects control | Full for that pillar | Normal |
| `degraded` | Warning + residual risk | Limited wording | “Limited / partial” | Explain gaps; no overclaim |
| `pending_policy` | Waiting for device | Last-acked behavior | None for new intent | Wait / retry sync |
| `unavailable` | Can’t run control | May show unavailable | None | Remediation if known |
| `unsupported` | Not on this platform | Honest unavailable | None | No fake success |
| `unknown` | Checking… | Neutral | None | Wait / refresh |
| `disabled_by_permission` | Permission needed | May mirror | None | Deep-link OS settings if product allows |

Planes may **differ by pillar** (camera vs prevention vs monitor vs protect) on the same device.

---

## Forbidden honesty anti-patterns

| Anti-pattern | Status |
|---|---|
| “Fully protected” with any pillar unsupported | Forbidden |
| Claiming capture prevention = all screenshots blocked worldwide | Forbidden |
| Claiming package Camera blocked = hardware off | Forbidden |
| Fake observation list when plane unsupported | Forbidden |
| Pending shown as live-enforced | Forbidden |
| Offline queued shown as “on child already” | Forbidden |
| Mic / ambient audio as FS-004 plane | Forbidden |

---

## Multi-device divergence UX

```
Child effective policy: cam_restrict ON (override)
Device A: enforced · ack v12
Device B: unsupported
Device C: pending_policy (v12 not acked)
```

Parent device panel lists each. Hub summary: “Mixed device capability.”

---

## Offline honesty

| Side | UX |
|---|---|
| Parent offline save | `offline_queued` badge — not “enforcing” |
| Child offline | Last-acked intents + last-acked transparency |
| Sync recover | Replay; plane refresh; audit delivery/ack |

---

## Remediation patterns (UX only)

- Permission missing → guide to grant (platform TBD — **T-SC***)  
- Unsupported → educational empty state; configure intent still visible as family rule for capable devices  
- Degraded → residual risk disclosure required  

No API selection in L3.
