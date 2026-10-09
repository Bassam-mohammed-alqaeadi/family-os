# Task card template

Copy for each new backlog item. Keep one card = one system or one screen or one SET/UI id.

```markdown
## CARD <ID>

| Field | Value |
|---|---|
| id | e.g. F0-A / SET-001 / SCR-FAT-032 / UI-004 |
| lane | Foundation \| GapClose-SET \| GapClose-UI \| GlobalGap \| Screen-W1/W2/W3 \| Later |
| workflow | ScreenBuild \| GapClose \| LoopClose \| ControlFit |
| status | ready \| blocked \| blocked_until_stage1 \| blocked_until_factory \| done \| deferred |
| screen_ids | SCR-… (if any) |
| linked_gaps | SET-… UI-… G-… |
| phase | F0…F7 / Stage3+ |
| sources | paths to handoff / 08-spec / prototype notes |

### Goal
<one paragraph>

### Acceptance criteria
- [ ] …

### Pillars checklist
| Pillar | Applicable? | Pass? |
|---|---|---|
| P1 Visual fidelity | Y/N/NA | |
| P2 Design system | | |
| P3 UX completeness | | |
| P4 Journey quality | | |
| P5 Accessibility | | |
| P6 i18n | | |
| P7 Policy & economy | | |
| P8 Trust & safety | | |
| P9 Engineering quality | | |
| P10 Performance feel | | |
| P11 Settings & control fitness | | |
| P12 Cross-role loop closure | | |

### Control-fit notes (P11)
| Control / action | Service need | Control type OK? | Fix if not |
|---|---|---|---|

### Loop proof (P12)
| Step | Artifact |
|---|---|
| Father configures | |
| Persist path | |
| Child reflects (screen) | |
| Child acts | |
| Father feedback | |
| Test / acceptance ref | |

### Evidence (Ship)
- CONVERSION_LOG line:
- Screenshots:
- Tests:
```
