# Completeness & Loops — Pillars P11–P12

Incomplete settings and half-closed services keep a product in “prototype forever.” The harness treats them as **defects**.

## Authority (execute, do not reinvent)

| Artifact | Role |
|---|---|
| [`GAP_LOG.md`](../GAP_LOG.md) | Living SET-001…024 + UI-001…018 status |
| [`docs/project-plan/08-gap-closure-specs.md`](../docs/project-plan/08-gap-closure-specs.md) | Full closures: owner, storage, **cross-role propagation**, notification, acceptance |
| [`docs/project-plan/09-ui-ux-gap-analysis.md`](../docs/project-plan/09-ui-ux-gap-analysis.md) | UI completeness gaps |
| Constitution Rules 23–24 | Data dynamism; settings real; **loop closure** |

## P11 — Settings & control fitness

**Done means:** every setting binds to state, persists, and is enforced through policy/repos. The **control type matches the service capability**.

| Service need | Wrong (reject) | Right (accept) |
|---|---|---|
| Install / open external app | Toggle that changes nothing | Deep link / store link / open + status |
| Upload / attach file | Toggle or text-only | File picker + progress + stored ref |
| Download / export | Decorative button | Real export + share + empty/error |
| Schedule window | Static label | Time-range controls → TimeEngine |
| Approve child request | Display-only row | Approve/deny → effect + confirmation |
| Capability unavailable (e.g. iOS) | Looks fully enabled | Honesty badge / disabled with truth (G1) |

**Additive rule:** closures complete frozen behavior; they do not redesign for fun. If the prototype control is wrong for the real service, fix fitness and update GAP_LOG; if law is ambiguous → QUESTIONS.md.

## P12 — Cross-role loop closure

**Done means** the full circle exists and is test-proven:

```text
Father configures → Persist (repo/policy)
       → Child UI reflects
       → Child acts / experiences
       → Father feedback (inbox / badge / audit / notification)
       → LOOP CLOSED
```

Any missing arrow → status `GAP` → **LoopClosure** agent owns it before Ship.

### Proof required on Ship (when card touches a parent-configured service)

1. Persist path named (repository / policy method)  
2. Child screen/ID that reflects the change  
3. Child action (if any)  
4. Father feedback channel  
5. Offline / edge note (per 08-spec)  
6. At least one automated test or acceptance scenario step covering the circle  

## Agents

- **Completeness** — walk settings vs GAP_LOG + 08-specs; reject VISUAL-only  
- **ControlFit** — reject wrong control types  
- **LoopClosure** — prove P12; write failing tests first when missing  

## Screen cards vs gap cards

- A **ScreenBuild** card lists linked SET/UI IDs. It cannot Ship while those remain `CONVERSION-BACKLOG` unless Bassam deferred them in QUESTIONS.md.  
- **GapClose** cards close one SET or UI ID and update GAP_LOG status to `CLOSED` with date + evidence.  
