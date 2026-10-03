# 07 — Location Wireframes (L3.6)

**Status:** Low/mid-fidelity structural wireframes (docs only)  
**Language:** Arabic-first **RTL** primary; **LTR** mirror defined  
**Map:** Provider-agnostic placeholder  
**No:** invented ms · child map · family-all silent assign · FAT-077 · spoof-proof

---

## Global layout rules

| | RTL (primary) | LTR |
|---|---|---|
| Reading | Right → left | Left → right |
| Back/chevron | Leading = right | Leading = left |
| Primary CTA | Bottom full-bleed or end-aligned | Same mirror |
| Chips/row trailing actions | Visual trailing flips | Mirror |
| Map | Full-bleed content; controls overlay respect safe area | Same |
| Sheets | Bottom sheet; drag handle centered | Same |

Touch targets ≥ 48dp (constitution). Semantics on every control.

---

## W1 — LOC-P-LIVE (RTL)

```
┌────────────────────────────────────────┐
│ [SOS]          أين أبنائي؟      [رجوع] │
│              (طفل ١ ▾)                 │
├────────────────────────────────────────┤
│ ⚠ ثقة الموقع منخفضة (اختياري)         │  ← soft integrity only
├────────────────────────────────────────┤
│ [● متابعة عادية]  [○ بث مرتفع]         │  ← Standard / Elevated
├────────────────────────────────────────┤
│  حالة: جاهز | جارٍ التحديد | آخر ظهور  │
│  | قديم | غير متاح   ·  غير متصل/مزامنة │
├────────────────────────────────────────┤
│                                        │
│         ┌──────── mapscape ────────┐   │
│         │   (provider-agnostic)    │   │
│         │    ○ منطقة   ● دبوس      │   │
│         └──────────────────────────┘   │
│                                        │
├────────────────────────────────────────┤
│ [طلب موقع صامت] [السجل] [المناطق]     │
└────────────────────────────────────────┘
```

**LTR:** Title/back flip; chip row order mirrors; CTA row mirrors; map unchanged.

---

## W2 — LOC-P-HIST (RTL)

```
┌────────────────────────────────────────┐
│ [خريطة]     سجل المواقع         [رجوع] │
├────────────────────────────────────────┤
│ يُحفظ ٩٠ يوماً ثم يُحذف تلقائياً        │
├────────────────────────────────────────┤
│ اليوم                                  │
│  │ ● المنزل —— الآن                    │
│  │ ○ المدرسة —— صباحاً                 │
│ أمس                                    │
│  │ …                                   │
├────────────────────────────────────────┤
│ [تصدير] [أرشفة]   ← Primary only      │
│ Co-Parent: controls omitted            │
└────────────────────────────────────────┘
```

---

## W3 — LOC-P-ZONE-LIB (RTL)

```
┌────────────────────────────────────────┐
│ [+]          المناطق الآمنة      [رجوع] │
├────────────────────────────────────────┤
│ ○ المنزل · طفل١، طفل٢ · تنبيهات ON    │
│ ○ المدرسة · طفل١ · تنبيهات OFF         │
├────────────────────────────────────────┤
│ Observer/Partner: [وضع قراءة فقط]      │
│ [إضافة منطقة] ← Primary/Full           │
└────────────────────────────────────────┘
```

---

## W4 — LOC-P-ZONE-EDIT Create (RTL) — Q-LOC-12=B critical

```
┌────────────────────────────────────────┐
│           إنشاء منطقة آمنة       [إلغاء] │
├────────────────────────────────────────┤
│ الشكل: (● دائرة) (○ مضلع)              │
│ ┌──────────── canvas ────────────┐     │
│ │  رسم هندسي (بدون SDK مسمّى)   │     │
│ └────────────────────────────────┘     │
│ الاسم: [________________]              │
│ تنبيهات: [دخول] [خروج] [عدم وصول]     │
├────────────────────────────────────────┤
│ الأبناء المشمولون *مطلوب                 │
│ [ ] طفل١   [ ] طفل٢   [ ] طفل٣         │
│ (لا حفظ إن لم يُختر أحد)                │
├────────────────────────────────────────┤
│ [حفظ]  disabled until ≥1 child         │
└────────────────────────────────────────┘
```

**Forbidden UI:** “Applies to all children” as default without selection.

---

## W5 — LOC-P-SLR sheet (RTL)

```
┌────────────────────────────────────────┐
│         طلب موقع صامت                  │
│ سيتم التنفيذ على جهاز الابن دون واجهة.  │
│ [تأكيد الطلب]                          │
├────────────────────────────────────────┤
│ النتيجة: جارٍ… / نجح / قديم / غير متاح  │
│ / في الطابور / فشل / رفض النظام        │
│ [إغلاق]                                │
└────────────────────────────────────────┘
```

---

## W6 — LOC-P-EVENT (RTL)

```
┌────────────────────────────────────────┐
│ تنبيه منطقة                            │
│ خروج · المدرسة · طفل١ · الوقت          │
│ [فتح الخريطة] [السجل] [حسناً]           │
└────────────────────────────────────────┘
```

Kinds only: دخول / خروج / عدم وصول.

---

## W7 — LOC-C-CHECKIN (RTL) — Child Safety

```
┌────────────────────────────────────────┐
│           أنا وصلت                     │
│     (تحت سلامة الابن — بلا خريطة)      │
├────────────────────────────────────────┤
│  [ المدرسة ]     [ المنزل ]            │
│   اسم فقط · لا إحداثيات · لا خريطة      │
├────────────────────────────────────────┤
│ لا بطاقة «موقعك الحي»                   │
└────────────────────────────────────────┘
```

---

## W8 — Parent offline strip (shared)

```
│ ☁ غير متصل — آخر بيانات ظاهرة بصدق     │
│ ↻ جارٍ المزامنة…                        │
│ ⚠ فشلت المزامنة — إعادة المحاولة        │
```

Never: “تم الحفظ على السحابة” without ack.

---

## W9 — SOS → Live handoff (parent)

```
SOS board … [فتح الموقع الحي] → LOC-P-LIVE (child focused)
Child SOS: status words only (SOS surface) — no map
```

---

## Accessibility / RTL checklist

- [ ] Semantics labels AR + EN via ARB (implementation later)  
- [ ] Elevated/Standard as segmented control, not numeric slider  
- [ ] Integrity warning not a destructive confirm  
- [ ] Multi-select children announced as required  
- [ ] Map is decorative/provider-agnostic; not the only info channel (chips carry honesty)
