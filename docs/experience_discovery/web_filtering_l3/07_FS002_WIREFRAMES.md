# 07 — FS-002 Wireframes (L3.8)

**Fidelity:** Low/mid — structure, hierarchy, honesty, RTL/LTR.  
**Language:** Arabic-first labels shown; EN in parentheses.  
**No** implementation mechanism claims (no VPN/DNS/DO as product UI).  
**T-WF** values shown as `〔TBD〕`.

Wireframes use ASCII. RTL = primary; LTR = mirror.

---

## WF-01 Overview (RTL)

```
┌─────────────────────────────────────┐
│ ☰  حماية الويب              🆘 SOS │
├─────────────────────────────────────┤
│ ▓ حالة التنفيذ: محدودة / غير مؤكد │  ← honesty strip (not “محمي بالكامل”)
│ ▓ بانتظار إقرار جهاز الطفل          │
│ ▓ وضع الوضع (Modes): تشديد نشط  → │
├─────────────────────────────────────┤
│ السياسة العائلية          [فتح]    │
│ تجاوز لكل طفل             [فتح]    │
│ طلبات الاستثناء (٢)       [صندوق] │
│ حالة الجهاز والتنفيذ      [فتح]    │
├─────────────────────────────────────┤
│ إضافات اختيارية                     │
│ موجّه المنزل (DNS) — ليس بديلاً    │
│ عن الحماية على الجهاز      [فتح]    │
└─────────────────────────────────────┘
```

**LTR mirror:** SOS left; chevrons flip; same blocks.

---

## WF-02 Family Baseline (RTL)

```
┌─────────────────────────────────────┐
│ ←  السياسة العائلية (الأساس)        │
├─────────────────────────────────────┤
│ [للمشاهدة فقط] إن Partner/Observer  │
├─────────────────────────────────────┤
│ الفئات                      →       │
│ القائمة البيضاء             →       │
│ القائمة السوداء             →       │
│ قاموس الكلمات               →       │
│ البحث الآمن          [مفعّل] 〔قدرة: مدعوم/غير مدعوم〕 │
│ التصفح الخاص         〔شفافية القدرة فقط〕 → │
├─────────────────────────────────────┤
│ إصدار السياسة: ١٢ · بانتظار الإقرار │
│              [حفظ]                  │
└─────────────────────────────────────┘
```

Clear title: **Family baseline** ≠ child override.

---

## WF-03 Per-Child + Override badge (RTL)

```
┌─────────────────────────────────────┐
│ ←  طفل: 〔اسم مستعار〕               │
├─────────────────────────────────────┤
│ السارية الآن: تجاوز خاص بهذا الطفل  │
│ (الأساس العائلي متجاهل بوجود التجاوز)│
│ التنفيذ: نشط على الجهاز ✓ / معلّق… │
├─────────────────────────────────────┤
│ [تعديل التجاوز]  [إزالة التجاوز]   │
│ [حالة الجهاز]                       │
└─────────────────────────────────────┘
```

---

## WF-04 Lists — Blocklist example (RTL)

```
┌─────────────────────────────────────┐
│ ←  القائمة السوداء                  │
├─────────────────────────────────────┤
│ ⓘ لها أولوية أعلى من الاستثناء     │
│   المؤقت والقائمة البيضاء           │
├─────────────────────────────────────┤
│ • example.blocked                   │
│ • …                                 │
│ [+ إضافة]                           │
├─────────────────────────────────────┤
│                         [حفظ]       │
└─────────────────────────────────────┘
```

Allowlist / Dictionary same pattern with their precedence notes.

---

## WF-05 Unlock Ticket — Approve temporary (RTL)

```
┌─────────────────────────────────────┐
│ ←  طلب استثناء                      │
├─────────────────────────────────────┤
│ الهدف: 〔ملخص آمن〕                 │
│ السبب: فئة / قائمة / كلمة …         │
│ مصدر المنع: حماية الويب             │
│ (إن وُجد منع تطبيقات → لا يُزال هنا)│
├─────────────────────────────────────┤
│ الموافقة = سماح مؤقت لمدة 〔TBD〕   │
│ ⚠ لن تُضاف للقائمة البيضاء تلقائياً │
├─────────────────────────────────────┤
│ [رفض]              [سماح مؤقت]     │
└─────────────────────────────────────┘
```

Observer: buttons hidden; “عرض فقط”.

---

## WF-06 Device Status honesty (RTL)

```
┌─────────────────────────────────────┐
│ ←  حالة التنفيذ                     │
├─────────────────────────────────────┤
│ السياسة: محفوظة ✓                   │
│ إقرار الجهاز: بانتظار…              │
│ مستوى التنفيذ: غير مدعوم / محدود    │
├─────────────────────────────────────┤
│ لا تُعرض «محمي بالكامل» هنا         │
│ البحث الآمن: 〔ss_*〕                │
│ التصفح الخاص: 〔pb_*〕               │
└─────────────────────────────────────┘
```

---

## WF-07 Child Interstitial (RTL) — block + request + transient feedback

**Single child destination for unlock feedback (Q-WF-15).** No separate unlock-result screen.

### A — Blocked (request available)

```
┌─────────────────────────────────────┐
│         هذا المحتوى محظور           │
│     فلتر العائلة يمنع هذه الصفحة    │
├─────────────────────────────────────┤
│ سبب مبسّط: غير مناسب / محظور …     │
│ المصدر: حماية الويب                 │
│   أو: تحكم التطبيقات                │
│   أو: كلاهما (الأشد)                │
├─────────────────────────────────────┤
│ [طلب فتح مؤقت]   (إن مصدر الويب)   │
│ [عودة]                              │
│                                     │
│ 🆘 الطوارئ متاحة دائماً             │
└─────────────────────────────────────┘
```

### B — Request pending (same surface)

```
┌─────────────────────────────────────┐
│         هذا المحتوى محظور           │
├─────────────────────────────────────┤
│ تم إرسال الطلب — بانتظار موافقة الولي│
│ (رسالة عابرة داخل نفس الشاشة)       │
├─────────────────────────────────────┤
│ [عودة]          🆘 الطوارئ          │
└─────────────────────────────────────┘
```

### C — Approved / denied / expired (transient feedback — same surface)

```
┌─────────────────────────────────────┐
│ سماح مؤقت 〔TBD〕 / رُفض / انتهى     │
│ (تغذية راجعة عابرة — ليست وجهة دائمة)│
├─────────────────────────────────────┤
│ [حسناً] → يعود لسياق الحظر/التنقّل  │
│ بلا قوائم · بلا إعدادات · بلا تشخيص │
└─────────────────────────────────────┘
```

No lists, categories admin, integrity, or persistent child unlock-result destination.

---

## WF-08 Child disclosure (non-interactive)

```
┌─────────────────────────────────────┐
│ فلتر العائلة نشط                    │
│ (للشفافية — بلا إعدادات)            │
└─────────────────────────────────────┘
```

---

## WF-09 Source-of-deny (parent deny detail)

```
┌─────────────────────────────────────┐
│ ←  لماذا حُظر؟                      │
├─────────────────────────────────────┤
│ حماية الويب: قائمة سوداء / فئة …   │
│ تحكم التطبيقات: 〔إن وُجد〕          │
│ تشديد الوضع (Modes): 〔إن وُجد〕    │
│ النتيجة: الأشد يمنع الوصول          │
├─────────────────────────────────────┤
│ مسار الاستثناء: حماية الويب فقط     │
│ لا يغيّر تحكم التطبيقات أو SOS      │
└─────────────────────────────────────┘
```

---

## WF-10 Router add-on (honesty)

```
┌─────────────────────────────────────┐
│ ←  إضافة موجّه المنزل (اختياري)    │
├─────────────────────────────────────┤
│ ⚠ ليست بديلاً عن التنفيذ على الجهاز │
│ الحالة: غير مُتحقق / غير مُعدّ      │
│ (لا تُحسب ضمن «التنفيذ الأساسي»)   │
└─────────────────────────────────────┘
```

---

## LTR note

Every frame mirrors: leading edge = start (left in LTR); SOS remains ungated; honesty strips keep top priority; Family vs Override labels stay explicit in both locales.

---

## Wireframe coverage (inventory → wireframe)

Every screen in `06_FS002_SCREEN_INVENTORY.md` is either covered by a dedicated wireframe below or **explicitly inherits** a documented structural pattern. No new UX invented.

| Inventory ID | Coverage | Wireframe / pattern |
|---|---|---|
| WF-P-OVERVIEW | Dedicated | **WF-01** |
| WF-P-FAMILY | Dedicated | **WF-02** |
| WF-P-CHILD | Dedicated | **WF-03** |
| WF-P-OVERRIDE | Inherits | **WF-02** structure (same editor stack) + **WF-03** override badge / remove |
| WF-P-CATEGORIES | Inherits | List/toggle editor pattern from **WF-04** (toggles instead of host entries) + save bar from **WF-02** |
| WF-P-ALLOW | Inherits | **WF-04** list pattern (allowlist precedence note) |
| WF-P-BLOCK | Dedicated | **WF-04** |
| WF-P-DICT | Inherits | **WF-04** list pattern (keywords) |
| WF-P-SAFESEARCH | Inherits | Row + capability honesty on **WF-02** |
| WF-P-PRIVATE | Inherits | Capability-only row/panel on **WF-02** (view honesty; no fake success) |
| WF-P-STATUS | Dedicated | **WF-06** |
| WF-P-INBOX | Inherits | Ticket list → opens **WF-05**; Overview shortcut on **WF-01** |
| WF-P-TICKET | Dedicated | **WF-05** |
| WF-P-DECISIONS | Inherits | List → detail pattern; detail = **WF-09** |
| WF-P-DENY-DETAIL | Dedicated | **WF-09** |
| WF-P-ROUTER | Dedicated | **WF-10** |
| WF-P-PREVIEW | Inherits | Parent-labeled variant of **WF-07-A** (preview badge; not child admin) |
| WF-C-INTERSTITIAL | Dedicated | **WF-07** A/B/C (block · pending · approved/denied/expired transient) |
| WF-C-DISCLOSURE | Dedicated | **WF-08** |

**Explicit non-screen:** former `WF-C-UNLOCK-RESULT` is **not** in inventory — feedback is **WF-07-B/C** only (Q-WF-15).
