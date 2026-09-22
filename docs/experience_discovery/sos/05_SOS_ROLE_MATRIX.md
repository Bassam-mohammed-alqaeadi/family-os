# 05 — SOS Role Matrix

**C** = CURRENT FACT · **T** = PROPOSED TARGET · **?** = OWNER DECISION REQUIRED

---

## Capability matrix

| Capability | Primary (Father) | Mother Observer | Mother Partner | Mother Full | Child |
|---|---|---|---|---|---|
| Configure SOS / ladder | **C:** yes FAT-028 · **T:** yes | **C:** UI open · **T:** ? | **C:** UI open · **T:** ? | **C:** UI open · **T:** likely yes | **C/T:** no |
| Manage emergency contacts | **C:** backups (no phone) · **T:** full contacts | **C:** same · **T:** ? | same | **T:** likely yes | no |
| Trigger SOS | no (lean) | no | no | no | **C/T:** yes |
| Receive SOS | **C:** sim · **T:** push+siren | **C:** sim always · **T:** same | same | same | N/A |
| Acknowledge | **C:** resolve conflates · **T:** distinct ACK | **C:** can resolve · **T:** ? | **T:** yes | **T:** yes | N/A |
| Call child | **C:** snackbar · **T:** real call | same | same | same | Call father → chat (**C**); real call (**T** ?) |
| Call emergency contact | **C:** escalate stub · **T:** real | same · **T:** ? | **T:** yes | **T:** yes | no |
| Escalate | **C:** counter · **T:** ladder+national | same · **T:** ? | **T:** yes | **T:** yes | no |
| View live location | **C:** stylized / FAT-014 · **T:** live | same | same | same | self broadcast honesty |
| View evidence | **C:** absent · **T:** ? | absent · **T:** ? | **T:** ? | **T:** ? | limited / none (**OWNER**) |
| Resolve | **C:** yes | **C:** yes · **T:** ? | **T:** yes | **T:** yes | confirm-safe (**C**=resolve) |
| Cancel | via resolve | — | — | — | confirm-safe sheet |
| Change delivery settings | quiet hours only; SOS unmutable | same | same | same | no |
| Change quiet-hour behavior for SOS | cannot mute SOS | cannot | cannot | cannot | N/A |

---

## Notes

### CURRENT FACTS that are strong

- All MotherLevels receive SOS in simulation (SET-021).
- No role may see mute-SOS control.
- Child alone triggers via CHD-005.
- FAT-018 allows mother Observer to resolve (widget test).

### OWNER DECISIONS that unblock the matrix

1. Observer: receive-only vs full action parity with Full.
2. Who may edit FAT-028 (Father only vs Father+Full vs any mother).
3. Whether ACK is a first-class capability separate from Resolve.
4. Whether child cancel after ACTIVE requires parent notification as false-alarm.
5. Evidence visibility by role.

Until decided, engineering must not silently narrow or widen Observer powers beyond CURRENT tests without QUESTIONS.md.
