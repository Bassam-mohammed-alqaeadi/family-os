# PHASE 3 — Screen Map (05)

**Date:** 2026-09-25  
**Counts:** 130 screen rows (129 live + tombstone)  

## Schema

`screen_id` · `journey` · `services` · `owner_system` · `notes` · `class`

## Integrity summary

| Check | Result | class |
|-------|--------|-------|
| Screens with empty services | 0 | VERIFIED EXISTING |
| Screens with empty journey | 0 | VERIFIED EXISTING |
| Unknown service on screen | 0 | VERIFIED EXISTING |
| Unknown journey on screen | 0 | VERIFIED EXISTING |
| SCR-FAT-039 tombstone | Present — ADR-034 | CLOSED |
| FS-008 screens | **none** | DESIGN GAP |
| FS-009 screens | SCR-FAT-069 · 073 · 086 (per Phase 2) | VERIFIED EXISTING |
| FS-010 screens | SCR-FAT-021/022 · SCR-CHD-007/008 (per Phase 2) | VERIFIED EXISTING |

## Full screen registry map

| screen_id | journey | services | owner_system | notes | class |
|---|---|---|---|---|---|
| `SCR-SHR-001` | `JRN-FAT-01` | `S-ADM-001` | `ADM:أ` | ثلاث شرائح تعريفية + زر بدء | VERIFIED EXISTING |
| `SCR-SHR-002` | `JRN-FAT-01` | `S-ADM-001` | `ADM:أ` | بريد + كلمة مرور — لا OTP | VERIFIED EXISTING |
| `SCR-SHR-003` | `JRN-FAT-01;JRN-MOT-01` | `S-ADM-001` | `ADM:أ` | مع استعادة كلمة المرور | VERIFIED EXISTING |
| `SCR-FAT-001` | `JRN-FAT-01` | `S-ADM-002;S-ADM-008` | `ADM:أ, ADM:ب` | اسم العائلة + عدد الأبناء | VERIFIED EXISTING |
| `SCR-FAT-002` | `JRN-FAT-02;JRN-FAT-03` | `S-ADM-002;S-ADM-005;S-ADM-007` | `ADM:أ` | خطوات متدرجة قابلة للتأجيل | VERIFIED EXISTING |
| `SCR-FAT-003` | `JRN-FAT-02` | `S-ADM-002;S-ADM-012` | `ADM:أ, ADM:ب` | اسم + عمر + صورة | VERIFIED EXISTING |
| `SCR-FAT-004` | `JRN-FAT-02` | `S-ADM-003;S-ADM-014` | `ADM:أ, ADM:ج` | رمز متغير بمهلة | VERIFIED EXISTING |
| `SCR-FAT-005` | `JRN-FAT-02` | `S-ADM-004` | `ADM:أ` | فيديو عربي قصير | VERIFIED EXISTING |
| `SCR-FAT-006` | `JRN-FAT-02` | `S-ADM-005;S-SEC-019` | `ADM:أ, SEC:د` | أول قيمة — موقع الابن الآن | VERIFIED EXISTING |
| `SCR-FAT-007` | `JRN-FAT-03` | `S-ADM-006` | `ADM:أ` | بيانات تجريبية موسومة بوضوح | VERIFIED EXISTING |
| `SCR-FAT-008` | `JRN-FAT-04` | `S-ADM-009;S-ADM-010` | `ADM:ب` | من الإعدادات لا من الإعداد الأول · الأب يحدد مستوى الصلاحية | VERIFIED EXISTING |
| `SCR-FAT-009` | `JRN-MOT-01` | `S-ADM-011` | `ADM:ب` | الأم تدخل عبر SCR-SHR-007 ثم تسجل دخولها — لا تختار دورها | VERIFIED EXISTING |
| `SCR-FAT-010` | `JRN-FAT-05;JRN-MOT-02` | `S-ADM-036;S-ADM-038;S-ADM-037;S-ADM-039` | `ADM:ز` | الشاشة الرئيسية — بطاقة لكل ابن | VERIFIED EXISTING |
| `SCR-FAT-011` | `JRN-FAT-05` | `S-ADM-039;S-AIC-003` | `ADM:ز, AIC:أ` | ثلاث ضغطات جاهزة | VERIFIED EXISTING |
| `SCR-FAT-012` | `JRN-FAT-06;JRN-MOT-03` | `S-ADM-038;S-ADM-015` | `ADM:ج, ADM:ز` | مؤشر لوني لكل ابن | VERIFIED EXISTING |
| `SCR-FAT-013` | `JRN-FAT-06;JRN-MOT-03` | `S-ADM-038;S-SEC-019;S-SEC-025;S-AIC-003` | `ADM:ز, AIC:أ, SEC:د` | كل شيء عن ابن واحد في مكان واحد | VERIFIED EXISTING |
| `SCR-FAT-014` | `JRN-FAT-07;JRN-MOT-06` | `S-SEC-019;S-SEC-025` | `SEC:د` | موقع لحظي + بطارية | VERIFIED EXISTING |
| `SCR-FAT-015` | `JRN-FAT-07` | `S-SEC-020;S-SEC-023` | `SEC:د` | خط زمني للأماكن + الأماكن المتكررة | VERIFIED EXISTING |
| `SCR-FAT-016` | `JRN-FAT-08` | `S-SEC-021;S-SEC-022` | `SEC:د` | إدارة المناطق المحفوظة | VERIFIED EXISTING |
| `SCR-FAT-017` | `JRN-FAT-08` | `S-SEC-021;S-SEC-022;S-SEC-024` | `SEC:د` | خريطة + نصف قطر + تنبيهات | VERIFIED EXISTING |
| `SCR-FAT-018` | `JRN-FAT-09;JRN-MOT-05` | `S-SEC-026;S-SEC-027;S-SEC-028;S-SEC-030` | `SEC:هـ` | تخترق الكتم — أعلى أولوية بصرية | VERIFIED EXISTING |
| `SCR-FAT-028` | `JRN-FAT-08;JRN-FAT-09` | `S-SEC-029;S-SEC-030;S-SEC-026` | `SEC:هـ` | جهات اتصال الطوارئ خارج العائلة + الرقم الوطني | VERIFIED EXISTING |
| `SCR-FAT-019` | `JRN-FAT-10` | `S-AIC-002;S-AIC-003;S-AIC-006` | `AIC:أ` | مجمّعة بدرجات الإلحاح | VERIFIED EXISTING |
| `SCR-FAT-020` | `JRN-FAT-10` | `S-AIC-006;S-AIC-001;S-AIC-003` | `AIC:أ` | مقتطف لا أرشيف | VERIFIED EXISTING |
| `SCR-FAT-021` | `JRN-FAT-11;JRN-MOT-04` | `S-COM-001;S-COM-002;S-COM-003` | `COM:أ` | محادثات مثبتة أعلى | VERIFIED EXISTING |
| `SCR-FAT-022` | `JRN-FAT-11;JRN-MOT-04` | `S-COM-001;S-COM-002;S-COM-004;S-COM-005;S-COM-006;S-COM-007;S-COM-008` | `COM:أ` | تعديل 15 دقيقة + حذف للجميع | VERIFIED EXISTING |
| `SCR-FAT-023` | `JRN-FAT-12;JRN-MOT-04` | `S-COM-010;S-COM-011;S-COM-012` | `COM:ب` | صوت وفيديو — LiveKit | VERIFIED EXISTING |
| `SCR-FAT-024` | `JRN-FAT-12` | `S-COM-013` | `COM:ب` | واردة وصادرة وفائتة | VERIFIED EXISTING |
| `SCR-FAT-025` | `JRN-FAT-13;JRN-FAT-14` | `S-ADM-015;S-ADM-016;S-ADM-018` | `ADM:ج` | مؤشر صحة لكل جهاز | VERIFIED EXISTING |
| `SCR-FAT-026` | `JRN-FAT-13;JRN-FAT-14` | `S-ADM-016;S-ADM-017;S-ADM-018` | `ADM:ج` | الصلاحيات الناقصة + إصلاحها | VERIFIED EXISTING |
| `SCR-FAT-027` | `JRN-FAT-04` | `S-ADM-008;S-ADM-010;S-ADM-012;S-ADM-013` | `ADM:ب` | الأدوار والوصي البديل | VERIFIED EXISTING |
| `SCR-FAT-029` | `JRN-FAT-10` | `S-AIC-004;S-AIC-005;S-AIC-002;S-AIC-003;S-ADM-033` | `ADM:و, AIC:أ` | مستوى العقل لكل ابن + نطاق الرصد | VERIFIED EXISTING |
| `SCR-CHD-001` | `JRN-CHD-01` | `S-ADM-003` | `ADM:أ` | بلغة مناسبة لعمره | VERIFIED EXISTING |
| `SCR-CHD-002` | `JRN-CHD-01` | `S-ADM-003;S-ADM-014` | `ADM:أ, ADM:ج` | مسح QR من جهاز الوالد | VERIFIED EXISTING |
| `SCR-CHD-003` | `JRN-CHD-01;JRN-CHD-05` | `S-ADM-004` | `ADM:أ` | ماذا يرى والداك — بتوقيع الابن | VERIFIED EXISTING |
| `SCR-CHD-004` | `JRN-CHD-02` | `S-ADM-036;S-SEC-025` | `ADM:ز, SEC:د` | وقتي ونقاطي — لا لوحة عقوبات | VERIFIED EXISTING |
| `SCR-CHD-005` | `JRN-CHD-03` | `S-SEC-026;S-SEC-027;S-SEC-031` | `SEC:هـ` | يعمل دائمًا — بلا إنترنت وبلا اشتراك | VERIFIED EXISTING |
| `SCR-CHD-006` | `JRN-CHD-03` | `S-SEC-027;S-SEC-028` | `SEC:هـ` | بث الموقع + اتصال تلقائي | VERIFIED EXISTING |
| `SCR-CHD-007` | `JRN-CHD-04` | `S-COM-001;S-COM-002` | `COM:أ` | محادثات العائلة | VERIFIED EXISTING |
| `SCR-CHD-008` | `JRN-CHD-04` | `S-COM-001;S-COM-002;S-COM-004;S-COM-005;S-COM-006;S-COM-007;S-COM-009` | `COM:أ` | لا تُقفل أبدًا حتى بنفاد الوقت | VERIFIED EXISTING |
| `SCR-CHD-009` | `JRN-CHD-04` | `S-COM-010;S-COM-011;S-COM-014` | `COM:ب` | الاتصال بالوالدين يعمل دائمًا | VERIFIED EXISTING |
| `SCR-CHD-010` | `JRN-CHD-05` | `S-ADM-004;S-ADM-035` | `ADM:أ, ADM:و` | فئات البيانات — لا الملف السلوكي | VERIFIED EXISTING |
| `SCR-SHR-005` | `JRN-SHR-01` | `S-ADM-017` | `ADM:ج` | رسالة واضحة + إعادة محاولة | VERIFIED EXISTING |
| `SCR-SHR-006` | `JRN-SHR-01` | `S-ADM-017` | `ADM:ج` | قالب موحد لكل القوائم | VERIFIED EXISTING |
| `SCR-SHR-007` | `JRN-FAT-01` | `S-ADM-001` | `ADM:أ` | خياران متساويان: وليّ الأمر / ابني · الدور يحدده الأب لاحقًا لا المستخدم | VERIFIED EXISTING |
| `SCR-SHR-008` | `JRN-FAT-01` | `S-ADM-002` | `ADM:أ` | الأب/الأم/معاينة الابن · كلمة مرور للتبديل بين الوالدين | VERIFIED EXISTING |
| `SCR-CHD-011` | `JRN-CHD-01` | `S-ADM-002` | `ADM:أ` | ضغطة 10 ثوان + كلمة مرور + موافقة جهاز الأب · 3 محاولات = قفل 24 ساعة | VERIFIED EXISTING |
| `SCR-FAT-030` | `JRN-FAT-01` | `S-ADM-002` | `ADM:أ` | سماح 10 دقائق أو رفض · كل محاولة تُخطر الأب | VERIFIED EXISTING |
| `SCR-FAT-031` | `JRN-FAT-04` | `S-ADM-010` | `ADM:ب` | ثلاثة مستويات: مطّلعة / مشاركة / كاملة · الأب يغيرها متى شاء · الاتصال والاستغاث | VERIFIED EXISTING |
| `SCR-FAT-032` | `JRN-FAT-15` | `S-SEC-001;S-SEC-002;S-SEC-003;S-SEC-006;S-SEC-007` | `SEC:أ` | حد يومي + جداول + نوم + حد لكل تطبيق + التعليم لا يُحتسب | VERIFIED EXISTING |
| `SCR-FAT-033` | `JRN-FAT-15;JRN-MOT-07` | `S-SEC-004;S-SEC-005` | `SEC:أ` | موافقة/رفض + مكافأة وقت بالإنجاز — للمشاركة فما فوق | VERIFIED EXISTING |
| `SCR-FAT-034` | `JRN-FAT-16` | `S-SEC-008;S-SEC-009;S-SEC-012;S-SEC-013` | `SEC:ب` | حظر/سماح + قواعد فئات + بطاقة معلومات التطبيق | VERIFIED EXISTING |
| `SCR-FAT-035` | `JRN-FAT-16` | `S-SEC-010;S-SEC-011` | `SEC:ب` | تنبيه تثبيت + قرار خلال بطاقة واحدة | VERIFIED EXISTING |
| `SCR-FAT-036` | `JRN-FAT-17` | `S-SEC-014;S-SEC-015;S-SEC-016;S-SEC-017` | `SEC:ج` | ٢٩ فئة + استثناءات + بحث آمن + حجب التصفح الخفي | VERIFIED EXISTING |
| `SCR-FAT-037` | `JRN-FAT-18` | `S-SEC-047;S-SEC-048;S-SEC-049` | `SEC:ط` | قفل كامل أو إنترنت فقط أو بمؤقت — بنبرة لطيفة للابن | VERIFIED EXISTING |
| `SCR-FAT-038` | `JRN-FAT-19` | `S-SEC-042;S-SEC-043;S-SEC-044;S-SEC-045;S-SEC-046` | `SEC:ح` | VPN · تعطيل أذونات · تغيير وقت · وضع آمن — إشارة حوار لا محاكمة | VERIFIED EXISTING |
| `SCR-FAT-039` | `JRN-FAT-20` | `S-SEC-058;S-SEC-059;S-SEC-060` | `SEC:ل` | Tombstone ADR-034 — جدول أسبوعي + تفعيل تلقائي بالموقع + حالة Focus | CLOSED |
| `SCR-FAT-040` | `JRN-FAT-21` | `S-EDU-064` | `EDU:ط` | اقتراحات العقل اليوم + آخر المحتوى + زر إنشاء كبير | VERIFIED EXISTING |
| `SCR-FAT-041` | `JRN-FAT-21` | `S-EDU-048;S-EDU-049;S-EDU-050;S-EDU-051;S-EDU-052;S-EDU-053` | `EDU:ط` | الكاميرا أولًا · رابط · ملف · موضوع · صوت · مكتبة المجتمع | VERIFIED EXISTING |
| `SCR-FAT-042` | `JRN-FAT-21` | `S-EDU-048` | `EDU:ط` | تصوير صفحة الكتاب — أول بوابة | VERIFIED EXISTING |
| `SCR-FAT-043` | `JRN-FAT-21` | `S-EDU-054;S-EDU-055;S-EDU-056;S-EDU-057;S-EDU-058;S-EDU-059;S-EDU-060;S-AIC-021` | `AIC:د, EDU:ط` | مصدر واحد ← ٩ مخرجات · قفل التوليد الآلي للمحتوى الديني | VERIFIED EXISTING |
| `SCR-FAT-044` | `JRN-FAT-21` | `S-EDU-054;S-EDU-056;S-AIC-021` | `AIC:د, EDU:ط` | قاعدة ٩٠ ثانية — الأب يعتمد ولا يؤلف | VERIFIED EXISTING |
| `SCR-FAT-045` | `JRN-FAT-21` | `S-EDU-065;S-EDU-058` | `EDU:ط` | إسناد لابن + مكافأة نقاط/وقت + موعد | VERIFIED EXISTING |
| `SCR-FAT-046` | `JRN-FAT-22` | `S-EDU-053;S-EDU-063` | `EDU:ط` | استيراد ونشر بالضوابط الستة | VERIFIED EXISTING |
| `SCR-FAT-047` | `JRN-FAT-23` | `S-EDU-061` | `EDU:ط` | سلسلة دروس مرتبة لهدف | VERIFIED EXISTING |
| `SCR-FAT-048` | `JRN-FAT-23` | `S-EDU-001;S-EDU-002;S-EDU-003;S-EDU-005;S-EDU-006` | `EDU:أ` | إضافة مادة ودرس واستيراد خارجي | VERIFIED EXISTING |
| `SCR-FAT-049` | `JRN-FAT-23` | `S-EDU-007;S-EDU-013;S-EDU-017` | `EDU:ب, EDU:ج` | توليد أسئلة من الدرس | VERIFIED EXISTING |
| `SCR-FAT-050` | `JRN-FAT-23` | `S-EDU-010;S-EDU-011;S-EDU-012;S-EDU-015;S-EDU-018` | `EDU:ب, EDU:ج` | تصحيح تلقائي + حالة الواجبات + فجوات المهارات | VERIFIED EXISTING |
| `SCR-FAT-051` | `JRN-FAT-23` | `S-EDU-046` | `EDU:ح` | جلسات التركيز أسبوعيًا | VERIFIED EXISTING |
| `SCR-FAT-052` | `JRN-FAT-24;JRN-MOT-08` | `S-COM-026;S-COM-027;S-COM-028;S-COM-029;S-COM-030;S-COM-031` | `COM:هـ` | هجري+ميلادي · مواقيت الصلاة · ألوان الأفراد · ملخص | VERIFIED EXISTING |
| `SCR-FAT-053` | `JRN-FAT-24` | `S-COM-026;S-COM-028;S-COM-029;S-COM-030` | `COM:هـ` | تاريخ هجري أو ميلادي + ربط بمواقيت الصلاة | VERIFIED EXISTING |
| `SCR-FAT-054` | `JRN-FAT-25;JRN-MOT-08` | `S-COM-032;S-COM-033;S-COM-034;S-COM-035` | `COM:و` | مهام كل فرد + تأكيد الإنجاز | VERIFIED EXISTING |
| `SCR-FAT-055` | `JRN-FAT-25` | `S-COM-032;S-COM-033;S-COM-035` | `COM:و` | إسناد + مكافأة نقاط أو وقت | VERIFIED EXISTING |
| `SCR-FAT-056` | `JRN-FAT-26` | `S-ADM-019;S-ADM-020;S-ADM-021;S-ADM-022` | `ADM:د` | ٣ باقات + سنوي · أرقام مؤقتة · SOS لا يُحجب أبدًا | VERIFIED EXISTING |
| `SCR-FAT-057` | `JRN-FAT-26` | `S-ADM-023;S-ADM-024` | `ADM:د` | ترقية/تخفيض + استرجاع مشتريات | VERIFIED EXISTING |
| `SCR-FAT-058` | `JRN-FAT-27` | `S-ADM-025;S-ADM-026;S-ADM-027;S-ADM-028;S-ADM-029` | `ADM:هـ` | قنوات + جدولة + ٣ درجات إلحاح + ملخص بدل تكرار | VERIFIED EXISTING |
| `SCR-FAT-059` | `JRN-FAT-28` | `S-ADM-030;S-ADM-031;S-ADM-032;S-AIC-017` | `ADM:و, AIC:ج` | خصوصية الطفل + تصدير/حذف + زر النسيان | VERIFIED EXISTING |
| `SCR-FAT-060` | `JRN-FAT-28` | `S-ADM-034` | `ADM:و` | append-only — يُقرأ ولا يُمس | VERIFIED EXISTING |
| `SCR-FAT-061` | `JRN-FAT-30` | `S-ADM-040;S-ADM-041;S-ADM-042` | `ADM:ح` | عربي/إنجليزي + مركز مساعدة + دعم | VERIFIED EXISTING |
| `SCR-FAT-062` | `JRN-FAT-29` | `S-AIC-007;S-AIC-008;S-AIC-009;S-AIC-010;S-AIC-011` | `AIC:ب` | خط الأساس + شذوذ النوم/التواصل/التعليم + مؤشر الثقة | VERIFIED EXISTING |
| `SCR-FAT-063` | `JRN-FAT-29` | `S-AIC-012;S-AIC-013;S-AIC-016` | `AIC:ج` | خط موحد + ملف الأنماط + الربط عبر المجالات | VERIFIED EXISTING |
| `SCR-FAT-064` | `JRN-FAT-29` | `S-AIC-014;S-AIC-015` | `AIC:ج` | المسار التعليمي + الشبكة الاجتماعية (P1) | VERIFIED EXISTING |
| `SCR-CHD-012` | `JRN-CHD-07` | `S-EDU-002;S-EDU-033;S-EDU-034` | `EDU:أ, EDU:و` | موادي + XP + سلسلة الأيام | VERIFIED EXISTING |
| `SCR-CHD-013` | `JRN-CHD-07` | `S-EDU-004;S-EDU-005` | `EDU:أ` | عرض الدرس بأشكاله | VERIFIED EXISTING |
| `SCR-CHD-014` | `JRN-CHD-07` | `S-EDU-008;S-EDU-009;S-EDU-010;S-EDU-011;S-AIC-020` | `AIC:د, EDU:ب` | إرسال + تصحيح تلقائي + الحالة | VERIFIED EXISTING |
| `SCR-CHD-015` | `JRN-CHD-07` | `S-EDU-014;S-EDU-016` | `EDU:ج` | أداء الاختبار + تحديد المستوى | VERIFIED EXISTING |
| `SCR-CHD-016` | `JRN-CHD-07` | `S-EDU-015;S-AIC-020` | `AIC:د, EDU:ج` | الخطأ لا يُعاقب — تشجيع دائم | VERIFIED EXISTING |
| `SCR-CHD-017` | `JRN-CHD-08` | `S-EDU-019;S-EDU-020;S-EDU-021;S-EDU-022;S-EDU-023;S-AIC-018` | `AIC:د, EDU:د` | يشرح بالتدرج ولا يعطي الجواب — نموذج Khanmigo | VERIFIED EXISTING |
| `SCR-CHD-018` | `JRN-CHD-09` | `S-EDU-042;S-EDU-043;S-EDU-044;S-EDU-045;S-SEC-060;S-SEC-007` | `EDU:ح, SEC:أ, SEC:ل` | مؤقت + لا مشتتات + وقت التعليم مجاني | VERIFIED EXISTING |
| `SCR-CHD-019` | `JRN-CHD-10` | `S-EDU-030;S-EDU-031;S-EDU-032;S-EDU-033;S-EDU-034;S-EDU-035;S-SEC-005` | `EDU:و, SEC:أ` | نقاط + شارات + مستويات + استبدال بوقت | VERIFIED EXISTING |
| `SCR-CHD-020` | `JRN-CHD-06` | `S-SEC-004` | `SEC:أ` | طلب مهذب بسبب — يصل الوالدين | VERIFIED EXISTING |
| `SCR-CHD-021` | `JRN-CHD-06` | `S-SEC-001;S-SEC-003` | `SEC:أ` | «انتهى وقت اللعب 🌙» + المحادثة لا تقفل + طلب المزيد | VERIFIED EXISTING |
| `SCR-CHD-022` | `JRN-CHD-12` | `S-COM-032;S-COM-034;S-COM-035` | `COM:و` | إنجاز + تأكيد + مكافأة | VERIFIED EXISTING |
| `SCR-CHD-023` | `JRN-CHD-11` | `S-COM-016;S-COM-017;S-COM-018;S-COM-019` | `COM:ج` | صور وملفات وصوت + تفريغ نصي | VERIFIED EXISTING |
| `SCR-CHD-024` | `JRN-CHD-11` | `S-COM-037;S-COM-038;S-COM-039` | `COM:ز` | زر «أنا وصلت» + الرد على طلب موقع | VERIFIED EXISTING |
| `SCR-FAT-065` | `JRN-FAT-31` | `S-SEC-032;S-SEC-033;S-SEC-034;S-SEC-035;S-SEC-036;S-AIC-022` | `AIC:د, SEC:و` | كهرماني لا أحمر + يصف السلوك لا الطفل + كشف عربيزي وعامية | VERIFIED EXISTING |
| `SCR-FAT-066` | `JRN-FAT-31` | `S-SEC-032;S-SEC-033;S-AIC-022` | `AIC:د, SEC:و` | السياق كامل + خطوة حوار مقترحة — حوار لا عقاب | VERIFIED EXISTING |
| `SCR-FAT-067` | `JRN-FAT-32` | `S-SEC-037` | `SEC:و` | قائمة مراقبة جهات الاتصال — والابن يعلم بمبدأ الشفافية | VERIFIED EXISTING |
| `SCR-FAT-068` | `JRN-FAT-32` | `S-SEC-038;S-SEC-039;S-SEC-040;S-SEC-041` | `SEC:ز` | حالتان معلنتان: كاملة (أندرويد) / تقارير فقط (iOS) — البوابة ٢ | VERIFIED EXISTING |
| `SCR-FAT-069` | `JRN-FAT-33` | `S-SEC-050;S-SEC-051;S-SEC-052` | `SEC:ي` | احتفاظ ٣٠ يومًا + يحترم زر النسيان | VERIFIED EXISTING |
| `SCR-FAT-070` | `JRN-FAT-34` | `S-COM-021;S-COM-023;S-COM-024;S-COM-025` | `COM:د` | أقارب وأصدقاء معتمدون + حظر المجهولين افتراض لا يُعطَّل | VERIFIED EXISTING |
| `SCR-FAT-071` | `JRN-FAT-34;JRN-CHD-13` | `S-COM-022;S-COM-023` | `COM:د` | بطاقة واحدة قرار واحد | VERIFIED EXISTING |
| `SCR-FAT-072` | `JRN-FAT-35` | `S-EDU-037;S-EDU-039` | `EDU:ز` | خطة الورد والتقدم — تشجيع لا إثقال | VERIFIED EXISTING |
| `SCR-FAT-073` | `JRN-FAT-36` | `S-AIC-019;S-SEC-053;S-AIC-028` | `AIC:د, AIC:هـ, SEC:ي` | توصية واحدة قابلة للتنفيذ + نسخة بريدية + اقتراحات استباقية | VERIFIED EXISTING |
| `SCR-FAT-074` | `JRN-FAT-37` | `S-AIC-024;S-AIC-025;S-AIC-026` | `AIC:هـ` | مدخل الذكاء الموحد — زر ✨ عائم بنمط Gemini/ChatGPT + «لا أعلم» عند نقص البيانات | VERIFIED EXISTING |
| `SCR-FAT-076` | `JRN-MOT-09` | `S-AIC-029` | `AIC:هـ` | حسب مستواها الثلاثي — اطلاع دون إغراق | VERIFIED EXISTING |
| `SCR-FAT-075` | `JRN-FAT-38` | `S-SEC-018;S-SEC-054;S-SEC-055;S-SEC-056;S-SEC-057;S-COM-036;S-EDU-040;S-EDU-062;S-AIC-023;S-AIC-027;S-AIC-030;S-AIC-031;S-AIC-032;S-AIC-033;S-AIC-034` | `AIC:د, AIC:هـ, AIC:و, COM:و, EDU:ز, EDU:ط, SEC:ج, SEC:ك, SEC:ي` | فهرس يقود للشاشات الحية لخدمات ٣ب (ADR-023) — التنفيذ البرمجي بعد الإطلاق | VERIFIED EXISTING |
| `SCR-CHD-025` | `JRN-CHD-14` | `S-EDU-037;S-EDU-038` | `EDU:ز` | مصحف مرخّص لا توليد — تحت قفل المراجعة الدينية | VERIFIED EXISTING |
| `SCR-CHD-026` | `JRN-CHD-14` | `S-EDU-039` | `EDU:ز` | خريطة السور + المراجعات المستحقة | VERIFIED EXISTING |
| `SCR-CHD-027` | `JRN-CHD-14` | `S-EDU-041` | `EDU:ز` | صباح ومساء — تذكير لطيف لا إلزام | VERIFIED EXISTING |
| `SCR-CHD-028` | `JRN-CHD-15` | `S-EDU-025;S-EDU-026;S-EDU-027;S-EDU-029` | `EDU:هـ` | تكيفي + مسار بصري + كشف المفهوم المفقود | VERIFIED EXISTING |
| `SCR-CHD-029` | `JRN-CHD-15` | `S-EDU-028` | `EDU:هـ` | مراجعة متباعدة — ٥ دقائق ذكية يوميًا | VERIFIED EXISTING |
| `SCR-CHD-030` | `JRN-CHD-13` | `S-COM-022;S-COM-023` | `COM:د` | طلب الإضافة يمر بموافقة الأب — لا مجهولين أبدًا | VERIFIED EXISTING |
| `SCR-CHD-031` | `JRN-CHD-16` | `S-COM-015;S-COM-020;S-EDU-024;S-EDU-036;S-EDU-047` | `COM:ب, COM:ج, EDU:ح, EDU:د, EDU:و` | فهرس مرِح يقود لشاشات المرح الحية (ADR-023) | VERIFIED EXISTING |
| `SCR-FAT-077` | `JRN-FAT-39` | `S-SEC-055;S-SEC-056;S-SEC-057` | `SEC:ك` | كشف حوادث + تقرير قيادة + تنبيه جوال أثناء القيادة — أندرويد أولًا وبصدق معلن | VERIFIED EXISTING |
| `SCR-FAT-078` | `JRN-FAT-40` | `S-SEC-018` | `SEC:ج` | حماية كل أجهزة البيت — إعداد مرة واحدة | VERIFIED EXISTING |
| `SCR-FAT-079` | `JRN-FAT-41` | `S-AIC-030` | `AIC:و` | قواعد تفويض صريحة — الوكيل لا يتجاوزها أبدًا | VERIFIED EXISTING |
| `SCR-FAT-080` | `JRN-FAT-41` | `S-AIC-031;S-AIC-032;S-AIC-033;S-AIC-034` | `AIC:و` | تنفيذ ضمن التفويض + إشعار فوري + تراجع ١٠ دقائق + سجل دائم لا يُحذف | VERIFIED EXISTING |
| `SCR-FAT-081` | `JRN-FAT-33` | `S-SEC-054` | `SEC:ي` | مجهولة الهوية ومطمئنة — لا تشهير ولا أحكام | VERIFIED EXISTING |
| `SCR-FAT-082` | `JRN-FAT-42` | `S-COM-036` | `COM:و` | ChoreAI — عدالة وتنويع ومراعاة جداول الأبناء | VERIFIED EXISTING |
| `SCR-FAT-083` | `JRN-FAT-37` | `S-AIC-027` | `AIC:هـ` | الوضع الصوتي لاسأل العقل — نفس قواعد الصدق و«لا أعلم» | VERIFIED EXISTING |
| `SCR-FAT-084` | `JRN-FAT-43` | `S-EDU-062` | `EDU:ط` | مشروع تعليمي بمعالم ومكافآت مرحلية | VERIFIED EXISTING |
| `SCR-CHD-032` | `JRN-CHD-18` | `S-EDU-040;S-AIC-023` | `AIC:د, EDU:ز` | تصحيح التلاوة بالعقل — لطيف وتحت القفل الديني | VERIFIED EXISTING |
| `SCR-CHD-033` | `JRN-CHD-17` | `S-EDU-024` | `EDU:د` | الابن بطل الحكاية — قراراته تغير المسار | VERIFIED EXISTING |
| `SCR-CHD-034` | `JRN-CHD-17` | `S-EDU-036` | `EDU:و` | تنافس ودي عائلي — لا ترتيب مذل | VERIFIED EXISTING |
| `SCR-CHD-035` | `JRN-CHD-17` | `S-EDU-047` | `EDU:ح` | مطر وأمواج وهدوء — يتكامل مع وضع التركيز | VERIFIED EXISTING |
| `SCR-CHD-036` | `JRN-CHD-17` | `S-COM-015` | `COM:ب` | ألعاب ورسم مشترك أثناء مكالمة العائلة | VERIFIED EXISTING |
| `SCR-CHD-037` | `JRN-CHD-17` | `S-COM-020` | `COM:ج` | تخصيص المحادثة — ضمن الدائرة الآمنة فقط | VERIFIED EXISTING |
| `SCR-FAT-085` | `JRN-FAT-44` | `S-SEC-001;S-SEC-002;S-SEC-003;S-SEC-006` | `SEC:أ` | رمضان/امتحانات/إجازة/أعمار — لمسة واحدة تضبط كل شيء مع معاينة قبل التطبيق | VERIFIED EXISTING |
| `SCR-FAT-086` | `JRN-FAT-45` | `S-AIC-019;S-EDU-030;S-COM-016` | `AIC:د, COM:ج, EDU:و` | ملخص الجمعة الاحتفالي + بطاقة فخر قابلة للمشاركة — محرك الاحتفاظ الأسبوعي | VERIFIED EXISTING |

## Notes

- Do **not** invent ScreenBuild for FS-008 — DESIGN GAP only.  
- Tombstone SCR-FAT-039 remains in CSV; not a live product screen.
