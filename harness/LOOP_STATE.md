# LOOP_STATE

```
status: RUNNING
current_card: WIR-03 (n02_day A) — SCR-FAT-012 أُنجزت (WIR-03a)؛ المتبقّي في البطاقة: day_board · alerts_hub · alert_detail · request_inbox · friend_approval · outer_circle (٦ شاشات). ثم WIR-04/05 (يوم العائلة B/C) ← WIR-06/07 (الربط) ← WIR-08 → WIR-13
blocked_by: (none)
last_tick: 2026-09-25 (WIR-02 مدفوعة عند 3063773 · 70/131 مربوطة بالمقياس · ٧٥ مؤكَّدة حقيقية مع ٥ شاشات n01_linking المخدومة عبر globals)
resume_hint: Zero-Mocks loop — القائمة الكاملة في `harness/13_SCREEN_WIRING_QUEUE.md`. عقد الإدارة: العامل يكتب الكود ويشغّل البوابات، والـOrchestrator يُعيدها بنفسه ثم يدفع (لا دفع أحمر). **درس تشغيل مهم:** `/tmp` ممتلئ (3.9G) فتشغيل السويت بلا ضبط `TMPDIR` يفشل بـ`Creation of temporary directory failed … No space left on device` — شغّل دائمًا `TMPDIR=/var/tmp/flutter-tmp flutter test`. المنجَز: WIR-01 (٦ شاشات مرشد A) وWIR-03a (SCR-FAT-012) وWIR-02 (٦ شاشات مرشد B عبر إلحاق `advisor_followup_bridge.dart`: الخطّ الزمني من `learn_session`+`geofence_event`، أنماط العائلة من `learn_skill_gap` المفتوحة، خرائط المعرفة من `quran_plan`/`quran_memorization`+`learning_path`، مقارنة الأقران من `child`، سجلّ الأفعال من أختام `ai_suggestion` مع `bless`/`gentleUndo` حقيقيين (ADR-042)، لحظات العائلة مجمّعة من صفوف الأسبوع؛ الفراغات المعلنة: شرائح المشاركة/أسئلة العشاء/الألبوم/المقاييس/الدقائق والأهداف). القياس: analyze صفر · البوابة 338 · السويت 1666/1666 · 70/131 بالمقياس (+٥ = ٧٥ مؤكَّدة).
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
