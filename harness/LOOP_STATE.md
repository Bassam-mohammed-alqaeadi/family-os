# LOOP_STATE

```
status: RUNNING
current_card: WIR-01 (n07_advisor A — 6 شاشات) قيد التنفيذ عبر worker؛ المدير = Orchestrator (Second Brain). القائمة الكاملة في harness/13_SCREEN_WIRING_QUEUE.md
blocked_by: (none)
last_tick: 2026-09-25 (Zero-Mocks loop opened · 57/131 مربوطة · 74 باقية)
resume_hint: Zero-Mocks loop 2026-09-25 — المالك طلب لووب ربط كل الشاشات بلا أخطاء وبلا تدخّل، والمدير هو الـOrchestrator: يكتب brief للـworker، ثم يُعيد تشغيل البوابات بنفسه (analyze --fatal-infos · check_hardcoded_strings · flutter test الكامل · عدّ الشاشات المربوطة)، ويصلح أو يُعيد الإرسال عند أي فشل، ولا يدفع إلا أخضر. القائمة والبطاقات في `harness/13_SCREEN_WIRING_QUEUE.md` (WIR-01…WIR-13، 74 شاشة: n02_day 21 · n01_linking 12 · n07_advisor 12 · n03_screen_time 5 · shared_onboarding 5 · n05_lock 4 · n08_platform 3 · n12_devices 3 · n07_privacy 2 · shared_templates 2 · والمفردات 1+1+1+1+1). الأصوات (SCR-CHD-035) فراغ عقدي معلن. القاعدة: نقلة واحدة = بطاقة واحدة، السويت الكامل كل بطاقة، والدفع في نهاية كل بطاقة خضراء. آخر شحنات: DEV-6d دفعة ٢ عند 740424a/8800645 (57/131 · سويت 1648/1648). NOTE `*.g.dart` يبقى متجاهَلًا — CI يجب أن يشغّل `dart run build_runner build` قبل `flutter test`.
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
