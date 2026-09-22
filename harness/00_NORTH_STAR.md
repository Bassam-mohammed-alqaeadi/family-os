# North Star — Family OS Agent Harness

**Workspace:** `D:\special projects\family`  
**Loop contract:** keep working until a QUESTION; stop; resume after answer.

## Why the harness exists

Bassam should not babysit each card. The harness is a **self-driving loop**:

1. Take the next backlog card  
2. Build / verify / ship under pillars P1–P12  
3. Immediately take the next card  
4. **Only** if product law is ambiguous → write `QUESTIONS.md` → **halt**  
5. After Bassam answers → **resume** automatically  

State lives in [`LOOP_STATE.md`](LOOP_STATE.md). Tick text: [`04_LOOP_PROMPT.md`](04_LOOP_PROMPT.md). Resume: [`09_RESUME_PROTOCOL.md`](09_RESUME_PROTOCOL.md).

## Ambition

Develop Family OS into a **world-class family digital-wellbeing OS**: real services, closed loops, premium design/UX — commercially capable of the **~$900k/year** revenue class (Gulf family SaaS / subscription + forever-free safety core).

Revenue is a **destination metric**. The harness produces a trustworthy product that can earn it — not fake MRR in markdown.

## What “giant real services” means here

| Capability | Bar |
|---|---|
| Parent sovereignty | Father configures; AI **suggests only**; approve/reject ends every AI action |
| Economy | **Minutes only**; all earning via PolicyEngine; no points/XP/coins |
| Safety forever-free | SOS, location, family chat — never subscription-gated |
| Completeness | Settings bind → persist → enforce; wrong controls fixed; father↔child loops closed |
| Fidelity | Flutter matches frozen prototype (`prototype/family_os_app.html`) |
| Trust | RoleGuard, append-only audit, iOS honesty badges, parametric children |

## Authority order (never invent product law)

1. [`handoff/04_POLICY_REGISTER_EN.md`](../handoff/04_POLICY_REGISTER_EN.md)  
2. Frozen prototype [`prototype/family_os_app.html`](../prototype/family_os_app.html)  
3. [`handoff/`](../handoff/) + registries + schema  
4. On ambiguity → [`QUESTIONS.md`](../QUESTIONS.md) — **stop, do not guess**

## Stages

| Stage | Outcome |
|---|---|
| **0 · Harness** | Docs + Cursor wiring + continuous loop OS |
| **1 · App body** | F0–F7 Flutter screens (ScreenBuild wave) — mock-first · Rule 25 |
| **1.5 · Service UX completeness** | After **all** SCR ScreenBuilds: domain review with [`docs/project-plan/10-service-ux-completeness-rubric.md`](../docs/project-plan/10-service-ux-completeness-rubric.md) → GapClose packs → ControlFit. Gate: [`11_PHASE_15_UX_COMPLETENESS_GATE.md`](11_PHASE_15_UX_COMPLETENESS_GATE.md). **No Stage 3 before this gate.** |
| **2 · Trust polish** | S1–S5, a11y, perf, store packaging (may overlap late 1.5) |
| **3 · Real services** | API seams, uploads, AI gateways, billing; SOS free forever — **only after Phase 1.5** |
| **4 · Revenue engine** | Pricing, onboarding, Gulf GTM — after Stage 3 |

**Owner sequence (2026-09-21):** Screens → Phase 1.5 UX completeness (father/child user lens) → Stage 3 backend. Do not start live APIs early.

## Owner vs agents

- **Bassam:** answer QUESTIONS; optional phase demos; money/store/legal; merge when ready  
- **Harness:** everything else — continuous ticks until BLOCKED  

## Read next

1. [`01_OPERATING_MODEL.md`](01_OPERATING_MODEL.md)  
2. [`LOOP_STATE.md`](LOOP_STATE.md)  
3. [`04_LOOP_PROMPT.md`](04_LOOP_PROMPT.md) — run / arm loop  
4. [`09_RESUME_PROTOCOL.md`](09_RESUME_PROTOCOL.md)  
5. [`BACKLOG.md`](BACKLOG.md)  
6. [`06_QUALITY_PILLARS.md`](06_QUALITY_PILLARS.md) · [`07_COMPLETENESS_AND_LOOPS.md`](07_COMPLETENESS_AND_LOOPS.md)  
7. [`08_SKILLS_MAP.md`](08_SKILLS_MAP.md)  
8. [`docs/project-plan/10-service-ux-completeness-rubric.md`](../docs/project-plan/10-service-ux-completeness-rubric.md) · [`11_PHASE_15_UX_COMPLETENESS_GATE.md`](11_PHASE_15_UX_COMPLETENESS_GATE.md) 
