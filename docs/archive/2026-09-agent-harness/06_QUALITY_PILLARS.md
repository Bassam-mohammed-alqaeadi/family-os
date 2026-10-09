# Quality Pillars P1–P10

Ship is **forbidden** if any **applicable** pillar fails. Mark `N/A` only when the card truly has no UI / no strings / no policy surface.

| ID | Pillar | Done means | Fail examples | Primary agents |
|---|---|---|---|---|
| **P1** | Visual fidelity | Layout, spacing, hierarchy match frozen prototype for that screen | Freestyle redesign; wrong density; missing sections | Fidelity, Design |
| **P2** | Design system | Colors/shadows/radii/fonts from tokens; components from `core/design/components/` | Raw `Color(0x…)`, local duplicate buttons | Design, Verifier |
| **P3** | UX completeness | Empty, loading, one-item, many-items, error states; no deaf buttons | Spinner forever; button with null action; missing SHR-005/006 | UX |
| **P4** | Journey quality | Screen advances its journey; cross-links work | Orphan screen; dead nav; wrong tab shell | Planner, UX |
| **P5** | Accessibility | Semantics on interactives; touch ≥48dp; RTL correct | Missing labels; 32dp hit targets; LTR Arabic | A11y |
| **P6** | i18n | User strings from ARB; Arabic-first; EN skeleton | Hardcoded Arabic/English in widgets | Verifier |
| **P7** | Policy & economy | Minutes value object; earn via PolicyEngine; AI suggest≠execute; SOS/chat/Quran not paywalled | Raw int rewards; points/XP; AI auto-apply | Policy, Trust |
| **P8** | Trust & safety | RoleGuard; owner-only surfaces; iOS honesty; child = `f(ChildId)` | Child opens billing; fake iOS “full control”; Khaled hardcoded | Trust |
| **P9** | Engineering quality | `analyze` clean; unit + widget tests; data from providers/repos | Sample numerals in widgets; no tests; analyzer warnings | Verifier |
| **P10** | Performance feel | Lists/gallery smooth; no obvious jank (formal 60fps gate in F7) | Rebuild storms; giant unbounded lists | Perf (Stage 2+), Verifier |

## Related pillars (see 07)

- **P11** Settings & control fitness  
- **P12** Cross-role loop closure  

## Sources

- [`handoff/01_CURSOR_CONSTITUTION.md`](../handoff/01_CURSOR_CONSTITUTION.md)  
- [`handoff/05_ACCEPTANCE_SCENARIOS.md`](../handoff/05_ACCEPTANCE_SCENARIOS.md)  
- [`handoff/06_DESIGN_TOKENS.md`](../handoff/06_DESIGN_TOKENS.md)  
- [`handoff/07_GLOBAL_GAPS.md`](../handoff/07_GLOBAL_GAPS.md)  
