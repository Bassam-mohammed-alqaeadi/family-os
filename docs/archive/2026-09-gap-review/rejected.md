# Rejected Gap Findings — Permanent Archive

Per gap-hunter runbook: rejected findings are archived here, never deleted. Each entry keeps the original claim, the verification evidence, and the rejection rationale so future hunter sessions do not resubmit them.

| ID | Batch | Original claim | Verification evidence | Rejection rationale | Salvage |
|---|---|---|---|---|---|
| GAP-A-AIC-002 | GH-1 (all-domains) | Undo window shows «متبقي ٥:٤٢» — violates the 10-minute undo spec | `family_os_app.html` L4524: «متبقي ٥:٤٢» is a mid-countdown snapshot of a live 10-minute timer, not a shortened window | Countdown snapshots are not spec violations; hunter read a frozen mock timer as a policy value | Conversion note adopted: `undo_window=600s` must be an explicit constant in the Flutter spec |

## Batch GH-2 (CHILD-APP)
Zero rejections. 18 merged as-is, 2 revised-then-merged (A-012 count correction ٢٤٤ vs ~٢٢٩; D-005 reframed — father widget does render battery/sentLove; the true gap is the unrendered child-side received-love promise).

## Batch GH-3 (SEC pass 2)
Zero rejections. 21 merged as-is, 1 revised-then-merged (A-SEC-008: audio IS named in CHD-006's desktop-only documentation aside `note:` field, hidden on mobile — the child's in-app screen body remains location-only, so the disclosure gap holds at P0 with the nuance recorded).
