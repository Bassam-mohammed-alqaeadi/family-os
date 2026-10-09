# PHASE 4 — Journey Traceability (04)

**Date:** 2026-09-25  
**Journeys:** 73  

## Schema

`journey_id` · `name` · `owner_systems` · `screen_count` · `readiness`

| journey_id | name | owner_systems | screen_count | readiness |
|---|---|---|---:|---|
| `JRN-FAT-01` | التسجيل وإنشاء العائلة | `ADM:أ, ADM:ب` | 7 | READY FOR IMPLEMENTATION |
| `JRN-FAT-02` | ربط جهاز الابن الأول | `ADM:أ, ADM:ج` | 5 | READY FOR IMPLEMENTATION |
| `JRN-FAT-03` | تجربة التطبيق قبل الربط | `ADM:أ` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-04` | دعوة الأم وتحديد صلاحيتها | `ADM:ب` | 3 | READY FOR IMPLEMENTATION |
| `JRN-FAT-05` | نظرة الصباح على العائلة | `ADM:ز` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-06` | متابعة ابن بعينه | `ADM:ز, AIC:أ, SEC:د` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-07` | معرفة موقع ابنه الآن | `SEC:د` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-08` | ضبط منطقة آمنة | `SEC:د` | 3 | READY FOR IMPLEMENTATION |
| `JRN-FAT-09` | استقبال بلاغ استغاثة | `SEC:هـ` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-10` | استقبال تنبيه أمني | `AIC:أ` | 3 | READY FOR IMPLEMENTATION |
| `JRN-FAT-11` | محادثة العائلة | `COM:أ` | 2 | BLOCKED BY POLICY |
| `JRN-FAT-12` | مكالمة بابنه | `COM:ب` | 2 | BLOCKED BY NATIVE |
| `JRN-FAT-13` | إدارة أجهزة العائلة | `ADM:ج` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-14` | معالجة انقطاع جهاز | `ADM:ج` | 2 | READY FOR IMPLEMENTATION |
| `JRN-MOT-01` | الانضمام بدعوة الأب | `ADM:ب` | 2 | READY FOR IMPLEMENTATION |
| `JRN-MOT-02` | نظرة الصباح | `ADM:ز` | 1 | READY FOR IMPLEMENTATION |
| `JRN-MOT-03` | متابعة ابن بعينه | `ADM:ز, AIC:أ, SEC:د` | 2 | READY FOR IMPLEMENTATION |
| `JRN-MOT-04` | التواصل مع الأبناء | `COM:أ, COM:ب` | 3 | BLOCKED BY POLICY |
| `JRN-MOT-05` | استقبال بلاغ استغاثة | `SEC:هـ` | 1 | READY FOR IMPLEMENTATION |
| `JRN-MOT-06` | متابعة موقع ابنها | `SEC:د` | 1 | READY FOR IMPLEMENTATION |
| `JRN-CHD-01` | ربط جهازي وفهم القواعد | `ADM:أ` | 4 | READY FOR IMPLEMENTATION |
| `JRN-CHD-02` | يومي في لمحة | `ADM:ز, SEC:د` | 1 | READY FOR IMPLEMENTATION |
| `JRN-CHD-03` | طلب النجدة | `SEC:هـ` | 2 | READY FOR IMPLEMENTATION |
| `JRN-CHD-04` | التواصل مع عائلتي | `COM:أ, COM:ب` | 3 | BLOCKED BY POLICY |
| `JRN-CHD-05` | معرفة ما يُجمع عني | `ADM:أ` | 2 | READY FOR IMPLEMENTATION |
| `JRN-SHR-01` | معالجة خطأ أو انقطاع شبكة | `ADM:ج` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-15` | ضبط وقت الشاشة لابن | `SEC:أ` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-16` | إدارة تطبيقات الابن | `SEC:ب` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-17` | ضبط فلترة الإنترنت | `SEC:ج` | 1 | READY FOR IMPLEMENTATION |
| `JRN-FAT-18` | قفل فوري لحظة العشاء | `SEC:ط` | 1 | READY FOR IMPLEMENTATION |
| `JRN-FAT-19` | معالجة محاولة تحايل | `SEC:ح` | 1 | READY FOR IMPLEMENTATION |
| `JRN-FAT-20` | ضبط وضع المدرسة | `SEC:ل` | 1 | READY FOR IMPLEMENTATION |
| `JRN-FAT-21` | صناعة محتوى في الاستوديو | `EDU:ط` | 6 | READY FOR IMPLEMENTATION |
| `JRN-FAT-22` | الاستفادة من مكتبة المجتمع | `EDU:ط` | 1 | READY FOR IMPLEMENTATION |
| `JRN-FAT-23` | إدارة تعليم ابنه | `EDU:أ, EDU:ب, EDU:ج, EDU:ط` | 5 | BLOCKED BY REMOTE |
| `JRN-FAT-24` | تنظيم التقويم العائلي | `COM:هـ` | 2 | DEFERRED |
| `JRN-FAT-25` | إسناد مهمة بمكافأة | `COM:و` | 2 | DEFERRED |
| `JRN-FAT-26` | إدارة الاشتراك | `ADM:د` | 2 | BLOCKED BY REMOTE |
| `JRN-FAT-27` | ضبط الإشعارات | `ADM:هـ` | 1 | READY FOR IMPLEMENTATION |
| `JRN-FAT-28` | الخصوصية والبيانات | `ADM:و, AIC:ج` | 2 | BLOCKED BY REMOTE |
| `JRN-FAT-29` | مراجعة أنماط العقل | `AIC:ب, AIC:ج` | 3 | BLOCKED BY REMOTE |
| `JRN-FAT-30` | اللغة والمساعدة | `ADM:ح` | 1 | READY FOR IMPLEMENTATION |
| `JRN-MOT-07` | الموافقة على طلب وقت إضافي | `SEC:أ` | 1 | READY FOR IMPLEMENTATION |
| `JRN-MOT-08` | متابعة التقويم والمهام | `COM:هـ, COM:و` | 2 | DEFERRED |
| `JRN-CHD-06` | طلب وقت إضافي | `SEC:أ` | 2 | READY FOR IMPLEMENTATION |
| `JRN-CHD-07` | يوم دراسي كامل | `EDU:أ, EDU:ب, EDU:ج` | 5 | BLOCKED BY REMOTE |
| `JRN-CHD-08` | سؤال المعلم الذكي | `EDU:د` | 1 | BLOCKED BY REMOTE |
| `JRN-CHD-09` | جلسة تركيز للمذاكرة | `EDU:ح, SEC:ل` | 1 | READY FOR IMPLEMENTATION |
| `JRN-CHD-10` | نقاطي ومكافآتي | `EDU:و` | 1 | READY FOR IMPLEMENTATION |
| `JRN-CHD-11` | مشاركة لحظة مع العائلة | `COM:ج, COM:ز` | 2 | DEFERRED |
| `JRN-CHD-12` | مهامي المنزلية | `COM:و` | 1 | DEFERRED |
| `JRN-FAT-31` | استقبال تنبيه ذكي والتصرف بحوار | `AIC:د, SEC:و` | 2 | BLOCKED BY POLICY |
| `JRN-FAT-32` | ضبط الرقابة الذكية والمنصات | `SEC:ز, SEC:و` | 2 | READY FOR IMPLEMENTATION |
| `JRN-FAT-33` | مراجعة تقرير الاستخدام | `SEC:ي` | 2 | BLOCKED BY POLICY |
| `JRN-FAT-34` | إدارة الدائرة الخارجية | `COM:د` | 2 | DEFERRED |
| `JRN-FAT-35` | متابعة حفظ القرآن | `EDU:ز` | 1 | BLOCKED BY REMOTE |
| `JRN-FAT-36` | قراءة التقرير الأسبوعي بتوصية | `AIC:د, SEC:ي` | 1 | BLOCKED BY POLICY |
| `JRN-FAT-37` | سؤال العقل بلغة طبيعية | `AIC:هـ` | 2 | BLOCKED BY REMOTE |
| `JRN-FAT-38` | استكشاف الميزات القادمة | `AIC:د, AIC:هـ, AIC:و, COM:و, EDU:ز, EDU:ط, SEC:ج, SEC:ك, SEC:ي` | 1 | BLOCKED BY POLICY |
| `JRN-MOT-09` | استقبال إخطارات التحليلات | `AIC:هـ` | 1 | BLOCKED BY REMOTE |
| `JRN-CHD-13` | طلب إضافة صديق | `COM:د` | 2 | DEFERRED |
| `JRN-CHD-14` | وردي اليومي — قرآن وأذكار | `EDU:ز` | 3 | BLOCKED BY REMOTE |
| `JRN-CHD-15` | خطتي الذكية ومراجعة اليوم | `AIC:د, EDU:هـ` | 2 | BLOCKED BY POLICY |
| `JRN-CHD-16` | استكشاف المرح القادم | `COM:ب, COM:ج, EDU:ح, EDU:د, EDU:و` | 1 | BLOCKED BY NATIVE |
| `JRN-FAT-39` | متابعة السلامة على الطريق | `SEC:ك` | 1 | OUT OF SCOPE |
| `JRN-FAT-40` | حماية شبكة المنزل | `SEC:ج` | 1 | READY FOR IMPLEMENTATION |
| `JRN-FAT-41` | تفويض الوكيل الذكي | `AIC:و` | 2 | BLOCKED BY REMOTE |
| `JRN-FAT-42` | توزيع المهام بذكاء | `COM:و` | 1 | DEFERRED |
| `JRN-FAT-43` | إطلاق مشروع تعليمي بمراحل | `EDU:ط` | 1 | READY FOR IMPLEMENTATION |
| `JRN-CHD-17` | مرح وإبداع متقدم | `COM:ب, COM:ج, EDU:ح, EDU:د, EDU:و` | 5 | BLOCKED BY NATIVE |
| `JRN-CHD-18` | تلاوتي الذكية | `AIC:د, EDU:ز` | 1 | BLOCKED BY POLICY |
| `JRN-FAT-44` | ضبط وضع ذكي بلمسة | `ADM:هـ, SEC:أ` | 1 | READY FOR IMPLEMENTATION |
| `JRN-FAT-45` | لحظة الفخر الأسبوعية | `AIC:د, COM:ج, EDU:و` | 1 | BLOCKED BY POLICY |

## Critical path journeys (P0 examples)

| Journey family | Planning note |
|----------------|---------------|
| Onboarding / identity (FAT-01…04, MOT-01, CHD-01) | W0 deepen — READY candidacy |
| Location / zones (FAT-06…08) | W2 Local deepen; live GPS BLOCKED BY NATIVE |
| SOS (FAT-09, MOT-05, CHD-03) | W2 Local deepen; delivery BLOCKED BY REMOTE |
| ST / AC / WF / Modes | W2 Local deepen; enforcement NAT |
| Chat (FAT-11, MOT-04, CHD-04) | W4 POLICY_GATE |
| AI Advisor journeys | W7 REMOTE |
