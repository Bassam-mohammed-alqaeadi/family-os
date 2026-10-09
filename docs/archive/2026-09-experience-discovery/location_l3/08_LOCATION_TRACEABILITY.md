# 08 — Location Traceability (L3 ↔ L2)

**Purpose:** Every L3 surface/flow maps to frozen L2 law — no silent law change.

| L3 ID | Flow / Screen | L2 refs | Frozen Q / OD |
|---|---|---|---|
| F01 / LOC-P-LIVE | Live View | Policy · Offline · Role | L-S1 · LOC-OD-03 · Q-LOC-03 states |
| F02 | Elevated live | Master · OD-23 | Q-LOC-03=B |
| F03 / LOC-P-HIST | History | Retention · Role | Q-LOC-01 · LOC-OD-05/06 |
| F04–F06 / LOC-P-ZONE-* | Create/Edit/Assign | Geo-Fence · OD-20/21/24 | Q-LOC-12=B · Q-LOC-11 · Q-LOC-06=A · Q-LOC-18=A |
| F07 / LOC-P-EVENT | Zone events | Event Lifecycle · OD-21 | Q-LOC-18=A · Q-LOC-06=A |
| F08 / LOC-C-CHECKIN · LOC-P-CI-CARD | Check-In | Child Silent · OD-13 | Q-LOC-16 |
| F09 / LOC-P-SLR | Silent Request | Child Silent · OD-08 | Q-LOC-08 |
| F10 | Integrity warning | Policy §7 · OD-22 | Q-LOC-07=C |
| F11–F12 | Offline / sync | Offline contract · OD-16/17 | — |
| F13 | SOS handoff | SOS Handoff · OD-09/10 | Q-LOC-09 · Q-LOC-10 |
| LOC-C-DISCLOSURE | Disclosure | Child Silent | Q-LOC-14 |
| LOC-C-SOS-STATUS | Status words | SOS Handoff | Q-LOC-09 |
| Band honesty | Parent chips only | OD-25 | Q-LOC-04=A |
| Export/Archive | History Primary | Role · Retention | Q-LOC-02 |

### Explicit exclusions traced

| Exclusion | L2 law | L3 handling |
|---|---|---|
| Family-all silent create | Q-LOC-12=B | Save disabled until multi-select |
| Movement/driving alerts | Q-LOC-18=A | Not in F07 / inventory |
| Kernel punish / spoof-proof | Q-LOC-07=C | Soft warning only |
| Invented refresh ms | Q-LOC-03 | States only in W1 |
| Invented sampling seconds | Q-LOC-04 | Band names only |
| Child location UI | Silent contract | Check-In + disclosure + SOS status only |
| Break-glass Find | Q-LOC-10 | F13 forbidden path |
| Map SDK choice | Q-LOC-15 | Agnostic placeholder |
