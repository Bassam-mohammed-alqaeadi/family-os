# PHASE 4 — Service Ownership & Journey Coverage (02)

**Date:** 2026-09-25  
**Services:** 240  
**Never on any journey:** 18 (REGISTRY GAP — track, do not invent)

## Schema

`service_id` · `system` · `name` · `owner` · `system_readiness` · `on_journey`

## Full service map

| service_id | system | name | owner | system_readiness | on_journey |
|---|---|---|---|---|---|
| `S-SEC-001` | `SEC:أ` | حد يومي للشاشة | Screen Time | READY FOR IMPLEMENTATION | yes |
| `S-SEC-002` | `SEC:أ` | جداول ذكية | Screen Time | READY FOR IMPLEMENTATION | yes |
| `S-SEC-003` | `SEC:أ` | جدول وقت النوم | Screen Time | READY FOR IMPLEMENTATION | yes |
| `S-SEC-004` | `SEC:أ` | طلب وقت إضافي | Screen Time | READY FOR IMPLEMENTATION | yes |
| `S-SEC-005` | `SEC:أ` | مكافأة وقت بالإنجاز | Screen Time | READY FOR IMPLEMENTATION | yes |
| `S-SEC-006` | `SEC:أ` | حد لكل تطبيق على حدة | Screen Time | READY FOR IMPLEMENTATION | yes |
| `S-SEC-007` | `SEC:أ` | وقت التعليم لا يُحتسب | Screen Time | READY FOR IMPLEMENTATION | yes |
| `S-SEC-008` | `SEC:ب` | حظر/سماح تطبيق | FS-003 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-009` | `SEC:ب` | قواعد فئات التطبيقات | FS-003 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-010` | `SEC:ب` | موافقة على التطبيقات الجديدة | FS-003 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-011` | `SEC:ب` | تنبيه تثبيت تطبيق | FS-003 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-012` | `SEC:ب` | تنبيهات الألعاب | FS-003 | READY FOR IMPLEMENTATION | NO |
| `S-SEC-013` | `SEC:ب` | بطاقة معلومات التطبيق | FS-003 | READY FOR IMPLEMENTATION | NO |
| `S-SEC-014` | `SEC:ج` | فلترة ٢٩ فئة | FS-002 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-015` | `SEC:ج` | استثناءات | FS-002 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-016` | `SEC:ج` | فرض البحث الآمن | FS-002 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-017` | `SEC:ج` | حجب التصفح الخفي | FS-002 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-018` | `SEC:ج` | فلترة الراوتر | FS-002 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-019` | `SEC:د` | تتبع لحظي | FS-001 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-020` | `SEC:د` | سجل المواقع | FS-001 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-021` | `SEC:د` | مناطق آمنة | FS-001 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-022` | `SEC:د` | تنبيه وصول/مغادرة | FS-001 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-023` | `SEC:د` | الأماكن المتكررة | FS-001 | READY FOR IMPLEMENTATION | NO |
| `S-SEC-024` | `SEC:د` | تنبيه عدم الوصول | FS-001 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-025` | `SEC:د` | مستوى البطارية | FS-001 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-026` | `SEC:هـ` | زر الاستغاثة | FS-006 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-027` | `SEC:هـ` | بث الموقع اللحظي | FS-006 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-028` | `SEC:هـ` | اتصال تلقائي بالأب | FS-006 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-029` | `SEC:هـ` | جهات اتصال خارج العائلة | FS-006 | READY FOR IMPLEMENTATION | NO |
| `S-SEC-030` | `SEC:هـ` | ربط الطوارئ الوطنية | FS-006 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-031` | `SEC:هـ` | الاستغاثة تعمل دائمًا | FS-006 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-032` | `SEC:و` | كشف الكلمات المريبة | FS-004 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-033` | `SEC:و` | تحليل المشاعر | FS-004 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-034` | `SEC:و` | كشف العامية والعربيزي | FS-004 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-035` | `SEC:و` | كشف الصور الحساسة | FS-004 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-036` | `SEC:و` | منع الرسائل الجنسية | FS-004 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-037` | `SEC:و` | قائمة مراقبة جهات الاتصال | FS-004 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-038` | `SEC:ز` | مراقبة واتساب | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-SEC-039` | `SEC:ز` | مراقبة سناب شات | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-SEC-040` | `SEC:ز` | مراقبة إنستغرام | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-SEC-041` | `SEC:ز` | مراقبة تيك توك | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-SEC-042` | `SEC:ح` | منع إلغاء التثبيت | Alerts hub | READY FOR IMPLEMENTATION | yes |
| `S-SEC-043` | `SEC:ح` | كشف VPN | Alerts hub | READY FOR IMPLEMENTATION | yes |
| `S-SEC-044` | `SEC:ح` | كشف تعطيل الأذونات | Alerts hub | READY FOR IMPLEMENTATION | yes |
| `S-SEC-045` | `SEC:ح` | كشف تغيير وقت الجهاز | Alerts hub | READY FOR IMPLEMENTATION | yes |
| `S-SEC-046` | `SEC:ح` | كشف الوضع الآمن / المستخدم الثانوي | Alerts hub | READY FOR IMPLEMENTATION | yes |
| `S-SEC-047` | `SEC:ط` | قفل فوري للجهاز | Device lock | READY FOR IMPLEMENTATION | yes |
| `S-SEC-048` | `SEC:ط` | إيقاف الإنترنت فقط | Device lock | READY FOR IMPLEMENTATION | yes |
| `S-SEC-049` | `SEC:ط` | قفل مؤقت بمؤقت | Device lock | READY FOR IMPLEMENTATION | yes |
| `S-SEC-050` | `SEC:ي` | تقارير الاستخدام | FS-009 | BLOCKED BY POLICY | yes |
| `S-SEC-051` | `SEC:ي` | تحليلات متقدمة | FS-009 | BLOCKED BY POLICY | yes |
| `S-SEC-052` | `SEC:ي` | الاحتفاظ ٣٠ يومًا | FS-009 | BLOCKED BY POLICY | yes |
| `S-SEC-053` | `SEC:ي` | الملخص الأسبوعي بالبريد | FS-009 | BLOCKED BY POLICY | yes |
| `S-SEC-054` | `SEC:ي` | المقارنة مع الأقران | FS-009 | BLOCKED BY POLICY | yes |
| `S-SEC-055` | `SEC:ك` | كشف الحوادث | Road safety | OUT OF SCOPE | yes |
| `S-SEC-056` | `SEC:ك` | تقرير القيادة | Road safety | OUT OF SCOPE | yes |
| `S-SEC-057` | `SEC:ك` | تنبيه استخدام الجوال أثناء القيادة | Road safety | OUT OF SCOPE | yes |
| `S-SEC-058` | `SEC:ل` | جدول وضع المدرسة | FS-005 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-059` | `SEC:ل` | التفعيل التلقائي بالموقع | FS-005 | READY FOR IMPLEMENTATION | yes |
| `S-SEC-060` | `SEC:ل` | حالة Focus | FS-005 | READY FOR IMPLEMENTATION | yes |
| `S-COM-001` | `COM:أ` | محادثة عائلية جماعية | FS-010 | BLOCKED BY POLICY | yes |
| `S-COM-002` | `COM:أ` | محادثة فردية | FS-010 | BLOCKED BY POLICY | yes |
| `S-COM-003` | `COM:أ` | مجموعات فرعية | FS-010 | BLOCKED BY POLICY | NO |
| `S-COM-004` | `COM:أ` | الرد على رسالة | FS-010 | BLOCKED BY POLICY | yes |
| `S-COM-005` | `COM:أ` | تأكيد القراءة | FS-010 | BLOCKED BY POLICY | yes |
| `S-COM-006` | `COM:أ` | تعديل الرسالة | FS-010 | BLOCKED BY POLICY | yes |
| `S-COM-007` | `COM:أ` | حذف للجميع | FS-010 | BLOCKED BY POLICY | yes |
| `S-COM-008` | `COM:أ` | تثبيت رسالة | FS-010 | BLOCKED BY POLICY | NO |
| `S-COM-009` | `COM:أ` | قفل المحادثة | FS-010 | BLOCKED BY POLICY | NO |
| `S-COM-010` | `COM:ب` | مكالمة صوتية | Calls | BLOCKED BY NATIVE | yes |
| `S-COM-011` | `COM:ب` | مكالمة فيديو | Calls | BLOCKED BY NATIVE | yes |
| `S-COM-012` | `COM:ب` | مكالمة جماعية | Calls | BLOCKED BY NATIVE | NO |
| `S-COM-013` | `COM:ب` | سجل المكالمات | Calls | BLOCKED BY NATIVE | yes |
| `S-COM-014` | `COM:ب` | الاتصال يعمل دائمًا | Calls | BLOCKED BY NATIVE | yes |
| `S-COM-015` | `COM:ب` | ألعاب ورسم أثناء المكالمة | Calls | BLOCKED BY NATIVE | yes |
| `S-COM-016` | `COM:ج` | صور وفيديو | Media | DEFERRED | yes |
| `S-COM-017` | `COM:ج` | الملفات | Media | DEFERRED | yes |
| `S-COM-018` | `COM:ج` | الرسائل الصوتية | Media | DEFERRED | yes |
| `S-COM-019` | `COM:ج` | تفريغ الرسالة الصوتية نصًا | Media | DEFERRED | yes |
| `S-COM-020` | `COM:ج` | الملصقات والخلفيات | Media | DEFERRED | yes |
| `S-COM-021` | `COM:د` | جهات اتصال خارجية بموافقة الأب | Safe circle | DEFERRED | yes |
| `S-COM-022` | `COM:د` | طلب إضافة صديق | Safe circle | DEFERRED | yes |
| `S-COM-023` | `COM:د` | حظر المجهولين تمامًا | Safe circle | DEFERRED | yes |
| `S-COM-024` | `COM:د` | دائرة الأقارب | Safe circle | DEFERRED | yes |
| `S-COM-025` | `COM:د` | جدول التواصل | Safe circle | DEFERRED | yes |
| `S-COM-026` | `COM:هـ` | إضافة حدث | Calendar | DEFERRED | yes |
| `S-COM-027` | `COM:هـ` | تعديل/حذف حدث | Calendar | DEFERRED | yes |
| `S-COM-028` | `COM:هـ` | التقويم الهجري + الميلادي | Calendar | DEFERRED | yes |
| `S-COM-029` | `COM:هـ` | ألوان لكل فرد | Calendar | DEFERRED | yes |
| `S-COM-030` | `COM:هـ` | مواقيت الصلاة في التقويم | Calendar | DEFERRED | yes |
| `S-COM-031` | `COM:هـ` | الملخص اليومي/الأسبوعي | Calendar | DEFERRED | yes |
| `S-COM-032` | `COM:و` | إنشاء مهمة وتذكير | Tasks | DEFERRED | yes |
| `S-COM-033` | `COM:و` | إسناد مهمة لابن | Tasks | DEFERRED | yes |
| `S-COM-034` | `COM:و` | تأكيد الإنجاز | Tasks | DEFERRED | yes |
| `S-COM-035` | `COM:و` | ربط المهمة بمكافأة | Tasks | DEFERRED | yes |
| `S-COM-036` | `COM:و` | ChoreAI | Tasks | DEFERRED | yes |
| `S-COM-037` | `COM:ز` | بث الموقع اللحظي | Loc-in-COM | DEFERRED | yes |
| `S-COM-038` | `COM:ز` | «أنا وصلت» بضغطة | Loc-in-COM | DEFERRED | yes |
| `S-COM-039` | `COM:ز` | طلب موقع | Loc-in-COM | DEFERRED | yes |
| `S-EDU-001` | `EDU:أ` | إضافة مادة | EDU materials | BLOCKED BY REMOTE | yes |
| `S-EDU-002` | `EDU:أ` | عرض المواد | EDU materials | BLOCKED BY REMOTE | yes |
| `S-EDU-003` | `EDU:أ` | إضافة درس | EDU materials | BLOCKED BY REMOTE | yes |
| `S-EDU-004` | `EDU:أ` | عرض درس | EDU materials | BLOCKED BY REMOTE | yes |
| `S-EDU-005` | `EDU:أ` | استيراد درس من مصدر خارجي | EDU materials | BLOCKED BY REMOTE | yes |
| `S-EDU-006` | `EDU:أ` | مكتبة فيديو | EDU materials | BLOCKED BY REMOTE | NO |
| `S-EDU-007` | `EDU:ب` | إنشاء واجب | EDU assign | READY FOR IMPLEMENTATION | yes |
| `S-EDU-008` | `EDU:ب` | عرض واجب | EDU assign | READY FOR IMPLEMENTATION | yes |
| `S-EDU-009` | `EDU:ب` | إرسال واجب | EDU assign | READY FOR IMPLEMENTATION | yes |
| `S-EDU-010` | `EDU:ب` | تصحيح تلقائي بالعقل | EDU assign | READY FOR IMPLEMENTATION | NO |
| `S-EDU-011` | `EDU:ب` | حالة الواجب | EDU assign | READY FOR IMPLEMENTATION | yes |
| `S-EDU-012` | `EDU:ب` | تنبيه الواجب المتأخر | EDU assign | READY FOR IMPLEMENTATION | yes |
| `S-EDU-013` | `EDU:ج` | إنشاء اختبار | EDU assess | READY FOR IMPLEMENTATION | yes |
| `S-EDU-014` | `EDU:ج` | أداء اختبار | EDU assess | READY FOR IMPLEMENTATION | yes |
| `S-EDU-015` | `EDU:ج` | نتائج الاختبار | EDU assess | READY FOR IMPLEMENTATION | yes |
| `S-EDU-016` | `EDU:ج` | اختبار تحديد المستوى | EDU assess | READY FOR IMPLEMENTATION | yes |
| `S-EDU-017` | `EDU:ج` | توليد أسئلة من الدرس | EDU assess | READY FOR IMPLEMENTATION | yes |
| `S-EDU-018` | `EDU:ج` | تقارير فجوات المهارات | EDU assess | READY FOR IMPLEMENTATION | yes |
| `S-EDU-019` | `EDU:د` | معلم خصوصي ذكي | Tutor | BLOCKED BY REMOTE | yes |
| `S-EDU-020` | `EDU:د` | شرح بالتدرّج لا بالجواب | Tutor | BLOCKED BY REMOTE | yes |
| `S-EDU-021` | `EDU:د` | حل مسألة بالكاميرا | Tutor | BLOCKED BY REMOTE | yes |
| `S-EDU-022` | `EDU:د` | توصيات مهارات | Tutor | BLOCKED BY REMOTE | yes |
| `S-EDU-023` | `EDU:د` | كتابة إبداعية | Tutor | BLOCKED BY REMOTE | yes |
| `S-EDU-024` | `EDU:د` | قصص تفاعلية | Tutor | BLOCKED BY REMOTE | yes |
| `S-EDU-025` | `EDU:هـ` | تعلّم تكيفي | EDU adaptive | READY FOR IMPLEMENTATION | yes |
| `S-EDU-026` | `EDU:هـ` | تمارين متدرجة | EDU adaptive | READY FOR IMPLEMENTATION | yes |
| `S-EDU-027` | `EDU:هـ` | مسارات بصرية | EDU adaptive | READY FOR IMPLEMENTATION | yes |
| `S-EDU-028` | `EDU:هـ` | المراجعة المتباعدة | EDU adaptive | READY FOR IMPLEMENTATION | yes |
| `S-EDU-029` | `EDU:هـ` | كشف المفهوم المفقود | EDU adaptive | READY FOR IMPLEMENTATION | yes |
| `S-EDU-030` | `EDU:و` | نقاط | EDU rewards | READY FOR IMPLEMENTATION | yes |
| `S-EDU-031` | `EDU:و` | شارات | EDU rewards | READY FOR IMPLEMENTATION | yes |
| `S-EDU-032` | `EDU:و` | استبدال النقاط بوقت شاشة | EDU rewards | READY FOR IMPLEMENTATION | yes |
| `S-EDU-033` | `EDU:و` | XP ومستويات | EDU rewards | READY FOR IMPLEMENTATION | yes |
| `S-EDU-034` | `EDU:و` | سلسلة الأيام المتتالية | EDU rewards | READY FOR IMPLEMENTATION | yes |
| `S-EDU-035` | `EDU:و` | تحديات يومية | EDU rewards | READY FOR IMPLEMENTATION | yes |
| `S-EDU-036` | `EDU:و` | أقسام تنافسية | EDU rewards | READY FOR IMPLEMENTATION | yes |
| `S-EDU-037` | `EDU:ز` | تحفيظ القرآن | Quran | BLOCKED BY REMOTE | yes |
| `S-EDU-038` | `EDU:ز` | تلاوة القرآن | Quran | BLOCKED BY REMOTE | yes |
| `S-EDU-039` | `EDU:ز` | متابعة الحفظ ومراجعته | Quran | BLOCKED BY REMOTE | yes |
| `S-EDU-040` | `EDU:ز` | تصحيح التلاوة بالعقل | Quran | BLOCKED BY REMOTE | yes |
| `S-EDU-041` | `EDU:ز` | الأذكار والعبادات اليومية | Quran | BLOCKED BY REMOTE | yes |
| `S-EDU-042` | `EDU:ح` | وضع التركيز | EDU focus | READY FOR IMPLEMENTATION | yes |
| `S-EDU-043` | `EDU:ح` | مؤقّت التركيز | EDU focus | READY FOR IMPLEMENTATION | yes |
| `S-EDU-044` | `EDU:ح` | وقت التعليم مجاني دائمًا | EDU focus | READY FOR IMPLEMENTATION | yes |
| `S-EDU-045` | `EDU:ح` | جدول المذاكرة | EDU focus | READY FOR IMPLEMENTATION | yes |
| `S-EDU-046` | `EDU:ح` | تقرير التركيز للأب | EDU focus | READY FOR IMPLEMENTATION | NO |
| `S-EDU-047` | `EDU:ح` | صوت خلفي للتركيز | EDU focus | READY FOR IMPLEMENTATION | yes |
| `S-EDU-048` | `EDU:ط` | إنشاء من الكاميرا — تصوير صفحة الكتاب | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-049` | `EDU:ط` | إنشاء من رابط | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-050` | `EDU:ط` | إنشاء من ملف | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-051` | `EDU:ط` | إنشاء من موضوع فقط | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-052` | `EDU:ط` | إنشاء من شرح صوتي | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-053` | `EDU:ط` | استيراد من مكتبة المجتمع | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-054` | `EDU:ط` | توليد درس | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-055` | `EDU:ط` | توليد واجب | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-056` | `EDU:ط` | توليد اختبار | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-057` | `EDU:ط` | توليد بطاقات حفظ | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-058` | `EDU:ط` | توليد تحدٍّ بمكافأة | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-059` | `EDU:ط` | توليد لعبة مراجعة | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-060` | `EDU:ط` | توليد ورد حفظ قرآني | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-061` | `EDU:ط` | بناء مسار تعليمي | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-062` | `EDU:ط` | إنشاء مشروع بمراحل | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-063` | `EDU:ط` | النشر في مكتبة المجتمع | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-064` | `EDU:ط` | شاشة «اقتراحات العقل اليوم» | Studio | READY FOR IMPLEMENTATION | yes |
| `S-EDU-065` | `EDU:ط` | إسناد المحتوى وتحديد المكافأة | Studio | READY FOR IMPLEMENTATION | yes |
| `S-AIC-001` | `AIC:أ` | مصنّف الكلمات الخطرة | FS-007 | READY FOR IMPLEMENTATION | yes |
| `S-AIC-002` | `AIC:أ` | رصد الأحداث من كل المجالات | FS-007 | READY FOR IMPLEMENTATION | yes |
| `S-AIC-003` | `AIC:أ` | تقييم درجة الخطورة | FS-007 | READY FOR IMPLEMENTATION | yes |
| `S-AIC-004` | `AIC:أ` | كشف الصور الحساسة | FS-007 | READY FOR IMPLEMENTATION | NO |
| `S-AIC-005` | `AIC:أ` | قائمة القواعد القابلة للتحديث | FS-007 | READY FOR IMPLEMENTATION | NO |
| `S-AIC-006` | `AIC:أ` | مقتطف التنبيه لا الأرشيف | FS-007 | READY FOR IMPLEMENTATION | yes |
| `S-AIC-007` | `AIC:ب` | بناء خط الأساس | Insights | BLOCKED BY REMOTE | yes |
| `S-AIC-008` | `AIC:ب` | كشف شذوذ النوم والنشاط | Insights | BLOCKED BY REMOTE | yes |
| `S-AIC-009` | `AIC:ب` | كشف شذوذ التواصل | Insights | BLOCKED BY REMOTE | yes |
| `S-AIC-010` | `AIC:ب` | كشف شذوذ التعليم | Insights | BLOCKED BY REMOTE | yes |
| `S-AIC-011` | `AIC:ب` | مؤشر الثقة | Insights | BLOCKED BY REMOTE | yes |
| `S-AIC-012` | `AIC:ج` | الخط الزمني الموحّد لكل فرد | Knowledge | BLOCKED BY REMOTE | yes |
| `S-AIC-013` | `AIC:ج` | ملف الأنماط السلوكية | Knowledge | BLOCKED BY REMOTE | yes |
| `S-AIC-014` | `AIC:ج` | خريطة الشبكة الاجتماعية | Knowledge | BLOCKED BY REMOTE | yes |
| `S-AIC-015` | `AIC:ج` | خريطة المسار التعليمي | Knowledge | BLOCKED BY REMOTE | yes |
| `S-AIC-016` | `AIC:ج` | الربط عبر المجالات | Knowledge | BLOCKED BY REMOTE | yes |
| `S-AIC-017` | `AIC:ج` | زر النسيان | Knowledge | BLOCKED BY REMOTE | yes |
| `S-AIC-018` | `AIC:د` | المعلم الذكي | Advisor/Reports | BLOCKED BY POLICY | yes |
| `S-AIC-019` | `AIC:د` | التقرير الأسبوعي بتوصية | Advisor/Reports | BLOCKED BY POLICY | yes |
| `S-AIC-020` | `AIC:د` | تصحيح الواجبات | Advisor/Reports | BLOCKED BY POLICY | yes |
| `S-AIC-021` | `AIC:د` | توليد محتوى الاستوديو | Advisor/Reports | BLOCKED BY POLICY | NO |
| `S-AIC-022` | `AIC:د` | تنبيه النمط الخطر | Advisor/Reports | BLOCKED BY POLICY | yes |
| `S-AIC-023` | `AIC:د` | تحليل تلاوة القرآن | Advisor/Reports | BLOCKED BY POLICY | yes |
| `S-AIC-024` | `AIC:هـ` | سؤال العقل بلغة طبيعية | Assistant | BLOCKED BY REMOTE | yes |
| `S-AIC-025` | `AIC:هـ` | الاسترجاع من مخزن المعرفة | Assistant | BLOCKED BY REMOTE | yes |
| `S-AIC-026` | `AIC:هـ` | «لا أعلم» عند نقص البيانات | Assistant | BLOCKED BY REMOTE | yes |
| `S-AIC-027` | `AIC:هـ` | محادثة صوتية | Assistant | BLOCKED BY REMOTE | yes |
| `S-AIC-028` | `AIC:هـ` | اقتراحات استباقية للأب | Assistant | BLOCKED BY REMOTE | yes |
| `S-AIC-029` | `AIC:هـ` | إخطار الأم بالتحليلات | Assistant | BLOCKED BY REMOTE | yes |
| `S-AIC-030` | `AIC:و` | بناء قاعدة تفويض | Agent | BLOCKED BY REMOTE | yes |
| `S-AIC-031` | `AIC:و` | التنفيذ التلقائي ضمن التفويض | Agent | BLOCKED BY REMOTE | yes |
| `S-AIC-032` | `AIC:و` | إشعار فوري بكل تصرّف | Agent | BLOCKED BY REMOTE | yes |
| `S-AIC-033` | `AIC:و` | زر التراجع خلال ١٠ دقائق | Agent | BLOCKED BY REMOTE | yes |
| `S-AIC-034` | `AIC:و` | سجل تدقيق دائم | Agent | BLOCKED BY REMOTE | yes |
| `S-ADM-001` | `ADM:أ` | إنشاء حساب | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-002` | `ADM:أ` | معالج الإعداد المتدرج | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-003` | `ADM:أ` | ربط جهاز الابن بـQR | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-004` | `ADM:أ` | شرح الصلاحيات بالفيديو | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-005` | `ADM:أ` | مؤشر اكتمال الإعداد | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-006` | `ADM:أ` | وضع التجربة قبل الربط | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-007` | `ADM:أ` | استئناف الإعداد لاحقًا | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-008` | `ADM:ب` | لوحة الإدارة | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-009` | `ADM:ب` | دعوة أعضاء | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-010` | `ADM:ب` | إدارة الأدوار | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-011` | `ADM:ب` | قبول/رفض دعوة | Identity | READY FOR IMPLEMENTATION | yes |
| `S-ADM-012` | `ADM:ب` | حدود متدرجة حسب الباقة | Identity | READY FOR IMPLEMENTATION | NO |
| `S-ADM-013` | `ADM:ب` | الوصي البديل | Identity | READY FOR IMPLEMENTATION | NO |
| `S-ADM-014` | `ADM:ج` | ربط جهاز الابن | ADM devices | READY FOR IMPLEMENTATION | yes |
| `S-ADM-015` | `ADM:ج` | إدارة الأجهزة | ADM devices | READY FOR IMPLEMENTATION | yes |
| `S-ADM-016` | `ADM:ج` | صحة الجهاز | ADM devices | READY FOR IMPLEMENTATION | yes |
| `S-ADM-017` | `ADM:ج` | تنبيه فقدان الاتصال | ADM devices | READY FOR IMPLEMENTATION | yes |
| `S-ADM-018` | `ADM:ج` | فصل جهاز | ADM devices | READY FOR IMPLEMENTATION | yes |
| `S-ADM-019` | `ADM:د` | الباقات الثلاث | Billing | BLOCKED BY REMOTE | yes |
| `S-ADM-020` | `ADM:د` | الخطة السنوية | Billing | BLOCKED BY REMOTE | yes |
| `S-ADM-021` | `ADM:د` | صفحة الاشتراك | Billing | BLOCKED BY REMOTE | yes |
| `S-ADM-022` | `ADM:د` | تجربة ١٤ يومًا بلا خصم تلقائي | Billing | BLOCKED BY REMOTE | yes |
| `S-ADM-023` | `ADM:د` | الترقية والتخفيض | Billing | BLOCKED BY REMOTE | yes |
| `S-ADM-024` | `ADM:د` | استرجاع المشتريات | Billing | BLOCKED BY REMOTE | yes |
| `S-ADM-025` | `ADM:هـ` | تفضيلات الإشعارات | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-ADM-026` | `ADM:هـ` | قنوات الإشعارات | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-ADM-027` | `ADM:هـ` | جدولة الإشعارات | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-ADM-028` | `ADM:هـ` | ثلاث درجات إلحاح | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-ADM-029` | `ADM:هـ` | ملخص بدل تكرار | Prefs-misc | READY FOR IMPLEMENTATION | yes |
| `S-ADM-030` | `ADM:و` | إعدادات الخصوصية | Privacy/Audit | READY FOR IMPLEMENTATION | yes |
| `S-ADM-031` | `ADM:و` | خصوصية الطفل | Privacy/Audit | READY FOR IMPLEMENTATION | yes |
| `S-ADM-032` | `ADM:و` | تصدير وحذف البيانات | Privacy/Audit | READY FOR IMPLEMENTATION | yes |
| `S-ADM-033` | `ADM:و` | لوحة تحكم العقل | Privacy/Audit | READY FOR IMPLEMENTATION | NO |
| `S-ADM-034` | `ADM:و` | سجل التدقيق | Privacy/Audit | READY FOR IMPLEMENTATION | yes |
| `S-ADM-035` | `ADM:و` | شاشة «ماذا يُجمع عني» للابن | Privacy/Audit | READY FOR IMPLEMENTATION | NO |
| `S-ADM-036` | `ADM:ز` | لوحة اليوم | Day board | READY FOR IMPLEMENTATION | yes |
| `S-ADM-037` | `ADM:ز` | جدول المدرسة | Day board | READY FOR IMPLEMENTATION | yes |
| `S-ADM-038` | `ADM:ز` | بطاقة لكل ابن | Day board | READY FOR IMPLEMENTATION | yes |
| `S-ADM-039` | `ADM:ز` | اقتراحات العقل اليوم | Day board | READY FOR IMPLEMENTATION | yes |
| `S-ADM-040` | `ADM:ح` | اللغة | ADM settings | READY FOR IMPLEMENTATION | yes |
| `S-ADM-041` | `ADM:ح` | مركز المساعدة بالعربية | ADM settings | READY FOR IMPLEMENTATION | yes |
| `S-ADM-042` | `ADM:ح` | التواصل مع الدعم | ADM settings | READY FOR IMPLEMENTATION | yes |

## Journey orphans (no journey lists this service)

- `S-ADM-012`
- `S-ADM-013`
- `S-ADM-033`
- `S-ADM-035`
- `S-AIC-004`
- `S-AIC-005`
- `S-AIC-021`
- `S-COM-003`
- `S-COM-008`
- `S-COM-009`
- `S-COM-012`
- `S-EDU-006`
- `S-EDU-010`
- `S-EDU-046`
- `S-SEC-012`
- `S-SEC-013`
- `S-SEC-023`
- `S-SEC-029`

**Planning rule:** orphan ≠ delete. Sequence inventory repair as DEFERRED registry work, not product invention.
