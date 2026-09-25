# LOOP_STATE

```
status: RUNNING
current_card: WIR-03 (n02_day A) — SCR-FAT-012 أُنجزت؛ المتبقّي في البطاقة: day_board · alerts_hub · alert_detail · request_inbox · friend_approval · outer_circle (٦ شاشات). ثم WIR-02 (المرشد B، ٦ شاشات)
blocked_by: (none)
last_tick: 2026-09-25 (WIR-01 + WIR-03a مدفوعتان عند f9ecd94 · 64/131 مربوطة بالمقياس · ٦٩ مؤكَّدة حقيقية مع ٥ شاشات n01_linking المخدومة عبر globals)
resume_hint: Zero-Mocks loop — القائمة الكاملة في `harness/13_SCREEN_WIRING_QUEUE.md`. عقد الإدارة: العامل يكتب الكود ويشغّل البوابات، والـOrchestrator يُعيدها بنفسه ثم يدفع (لا دفع أحمر). **درس تشغيلي مهم:** `/tmp` ممتلئ (3.9G · ٢١٥M حرة) فتشغيل السويت بدون ضبط `TMPDIR` يفشل بـ`Creation of temporary directory failed … No space left on device` — شغّل دائمًا `TMPDIR=/var/tmp/flutter-tmp flutter test` (الجذر فيه 16G). المنجَز: WIR-01 (٦ شاشات مرشد عبر `advisor_followup_bridge.dart` + ستّة getters في `Stage1ReportsRuntime`؛ `ai_suggestion` للاقتراحات مع `applied_at`/`dismissed_at`، و`ai_event` لتغذية الأم مع همسة idempotent، والمحتوى/المرحلة/الشرائح فراغات معلنة) وWIR-03a (SCR-FAT-012 عبر `day_followup_bridge.dart` + `Stage1DayRuntime`: `child` + `device`/`device_health` + `geofence_event`/`geofence`؛ وورقة السياسات المشتركة فراغ معلن). القياس: analyze صفر · البوابة 338 · السويت 1660/1660 · 64/131 بالمقياس (+٥ شاشات n01_linking Drift عبر globals = ٦٩ مؤكَّدة) · المرآة تحتاج تحديثًا بعد الدفع (`f9ecd94`).
```

## Field meanings

| Field | Values |
|---|---|
| `status` | `RUNNING` — keep working · `BLOCKED` — unanswered QUESTIONS · `STOPPED` — human stopped the loop |
| `current_card` | Backlog id being worked or next to work |
| `blocked_by` | Question id(s), e.g. `Q-PREFLIGHT-001`, or `(none)` |
| `last_tick` | Date of Orchestrator tick |
| `resume_hint` | One line for the next wake |

## Rules

- Unanswered QUESTIONS → must set `status: BLOCKED` and stop `/loop`.
- After Bassam answers → resume protocol sets `RUNNING` and clears `blocked_by`.
- Never leave `RUNNING` while an unanswered QUESTION exists.
