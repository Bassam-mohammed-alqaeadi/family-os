# LOOP_STATE — Family OS Agentic Harness

> **هذا الملف هو ذاكرة الحلقة.** أي جلسة جديدة — إنسان أو وكيل — تقرأه فتعرف موقعها في ثانية،
> بلا سؤال للمالك وبلا إعادة عمل. وهو على GitHub، فلا يضيع بفقدان مساحة عمل.
>
> **القاعدة:** لا تُعدّل الحالة يدوياً وتتركها متأخرة. إن كان الملف يكذب، فالحلقة معطّلة.
> `tools/harness/harness_check.sh` يتحقّق من اتساقه.

<!-- HARNESS-STATE:BEGIN -->
```yaml
status: REAL_ENGINE
active_system: 37 — Devices (M1)
wave: M1
stage: REAL_ENGINE — G1 closed end to end; G2/G3 shipped as a pure module; G4 partial; G5 partial
card: docs/harness/cards/M1-37-002-device-lifecycle-cover.md
owns: device lifecycle — the derivation, the revocation, and the client's ability to read both. Built entirely inside this branch's own range; the shared store files are untouched.
blocked_by: —
owner_question: —
last_tick: 2026-10-06
last_locked: "SPINE-001 — 2026-10-06, owner-approved; M0 — 2026-10-05 on 3d7ff18"
next_locked_gate: "M1 exit — every exit criterion in the card checked with evidence, and the device condition visible in the real roster"
evidence: "c9def70 guard green; 8ae2103 device-lifecycle.v1 + migration 101; cedd1b7 revocation live with 25 new tests; d07de3d client parses and renders the server verdict; backend 132/132, npm run check clean, migration range guard exit 0, Harness Guard / Backend CI / Credential Guard / Foundation Gate CI / Flutter CI all green on d07de3d (Flutter's enforcement step skipped = true pass)"
```
<!-- HARNESS-STATE:END -->

---

## الحالة بالعربية

**النظام النشط:** M1 — الأجهزة (النظام 37)، مصرَّح به بقفل M0.
**المرحلة:** Cover — عقد دورة حياة الجهاز.
**البطاقة الجارية:** `M1-37-002` — من الإقران إلى القطع الآمن.

**المُقفَل للتوّ:** `SPINE-001` — دستور الروابط الخمسة، أقرّه المالك 2026-10-06.
**وهو مُلزِم من الآن:** كل بطاقة من M1 إلى M10 تحمل §6 مُجاباً، ونظام لا يجيب **لا يعبر Cover**.
وهذه البطاقة أول من يخضع له فعلياً.

**الفراغات المرصودة في نظام الأجهزة — متحقَّق منها لا مُفترَضة:**
- **G1 🔴 لا توجد عملية قطع** — العمود `credential_revoked_at` موجود في المخطط ولا مسار يُستخدمه. **جهاز ضائع لا يمكن قطعه.**
- **G2 🔴 لا مفهوم «القدرة»** — لا شيء يسجّل ما يستطيع الجهاز فعله. الأب لا يعرف أن الحماية معطّلة.
- **G3 🟠 لا اشتقاق للحالة** — البطارية و`lastSeenAt` خامّان بلا «غير متصل» أو «بيانات قديمة».
- **G4 🟠 لا رحلة إصلاح**، **G5 🟠 لا سطح جهاز في العميل الحقيقي**.

**حدّ الملكية (صفر تعارض):** الجلسة المتوازية على `arena/01a10887-family-os` تنفّذ كود الإقران
(`family_device_api_client.dart`, `native_device_pairing_screens.dart`, `foundation_gate_models.dart`, `009`).
هذه البطاقة **لا تلمس كوداً** — تكتب العقد الذي يُقاس عليه ذلك التنفيذ. لا ملف مشترك.

**ما يمنع التقدّم:** لا شيء.

---

## سجل الموجات

| الموجة | الحالة | الدليل |
|---|---|---|
| SPINE | ✅ **مقفول** 2026-10-06 | [`cards/SPINE-001`](cards/SPINE-001-experience-bindings.md) — أقرّه المالك |
| M0 — Setup + Family | ✅ **مقفولة** 2026-10-05 | [`../real_platform/05_M0_LOCK_RECORD.md`](../real_platform/05_M0_LOCK_RECORD.md) — كل بوابة خضراء على `3d7ff18` |
| M1 — Devices | 🟢 **مفتوحة — Cover** | [`cards/M1-37-002`](cards/M1-37-002-device-lifecycle-cover.md) |
| M2–M10 | ⬜ مغلقة | تُفتح بقفل الموجة السابقة |

---

## سياسة الإيقاف (Halt Policy)

تُوقف الحلقة وتُعلَن في هذا الملف **فقط** عند:

1. **غموض في قانون المنتج** — قرار يخصّ المالك: نطاق، أولوية، التزام، أو مقايضة أخلاقية.
2. **تعارض بين وكيلين** على ملف أو نظام.
3. **بوابة ترفض العبور** ولا حلّ لها داخل النطاق.
4. **قرار عالي المخاطر** حسب `AGENTS.md` §5: إطلاق عام، توسّع بيانات حقيقية، قدرة جهاز اجتياحية، مزوّد خارجي.

**وما ليس عذراً للإيقاف:** غموض التنفيذ، أو تعقيد تقني، أو فشل اختبار، أو شبكة محجوبة،
أو رُندر لم يُحجز. كلها تُدار وتُسجَّل — لا تُوقف الحلقة.

عند الإيقاف: `status: BLOCKED_ON_OWNER` و`owner_question:` بسؤال واحد محدَّد وقابل للجواب.

---

## كيف تُحدَّث هذه الحالة

في نهاية كل وحدة عمل، قبل الدفع:

1. `stage:` إلى المرحلة الجديدة — **فقط** إذا عُبرت بوابتها.
2. `card:` إلى البطاقة الجارية التالية.
3. `last_tick:` بتاريخ اليوم.
4. `evidence:` بدليل مُنفَّذ (أرقام تشغيل)، لا بوصف.
5. إن توقّفت الحلقة: `status:` و`owner_question:`.

ثم `tools/harness/harness_check.sh` قبل الدفع. **ملف حالة متأخر أخطر من ملف غائب** — لأنه يُضلّل.
