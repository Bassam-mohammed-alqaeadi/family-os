# سجل تغييرات العقود والأنظمة المحمية (Contract Changes Log)

> **القاعدة الحاكمة:** أي تعديل في أي ملف مملوك لنظام محمي مسجل في `docs/safety_phase/PROTECTED_SYSTEMS.json` يتطلب سطراً موثقاً هنا باسم النظام والتاريخ ومبرر التعديل، وإلا يفشل حارس `check_protected.mjs`.

## سجل التعديلات المعتمدة

- **2026-10-23 | w2_child_device_lifecycle, w5_screen_time:** جسر الجهاز الأصلي يقرأ «الوصول إلى الاستخدام» (PACKAGE_USAGE_STATS، يُمنح من إعدادات النظام لا من نافذة صلاحية) ويقرأ زمن استخدام كل تطبيق اليوم ويصنّفه بمفردات الخادم (games/social/edu/tools)، ثم يرسل تقريراً واحداً بمفتاح ثابت لكل يوم. أُضيفت ثلاث دوال للقناة: usageStatsSnapshot و openUsageAccessSettings و screenTimeReportRequest. لم يُضف أي مسار جديد: نفس مسار الجهاز POST /v1/devices/{deviceId}/screen-time. ولم يعد اعتماد الجهاز ولا معرّفه إلى Dart — يظلان في TelemetryConfigStore، والوسيط الأصلي يضع الترويسة.
- **2026-10-23 | w2_child_device_lifecycle, w5_screen_time:** إصلاح في نفس التغيير: مُتحقّق جسم الطلب القديم (validJsonObject) يحدّ الطول بـ 4096 حرفاً وهو حد رسالة دردشة؛ تقرير 200 تطبيق يتجاوزه، فأُضيف حد مستقل MAX_USAGE_REPORT_CHARS = 262144 لتقرير الاستخدام وحده دون تغيير حد الدردشة.
- **2026-10-23 | s3_minutes_economy, w5_screen_time:** استبعاد أسطر تقارير استخدام الهاتف (source_type = 'device_report') من حساب رصيد المحافظ في balanceAt (قرار المالك: استهلاك الهاتف لا يخصم من المحافظ).
- **2026-10-23 | w5_screen_time, s3_minutes_economy:** إضافة فلتر source_type = 'device_report' و wallet_scope = 'daily' في readPhoneConsumption لضمان عدم احتساب استهلاك المحفظة كاستهلاك للهاتف (استهلاك المحفظة ليس قياس الهاتف).
- **2026-10-22 | w5_screen_time, s3_minutes_economy:** دمج تصنيفات التطبيقات في حساب الدقائق المحتسبة لتقرير استخدام الهاتف وتصحيح قيد credit_ref في الهجرة 134 لدعم استهلاك الجلسات واستهلاك الحد اليومي.
- **2026-10-22 | w5_screen_time, s3_minutes_economy:** دعم الحالات الخمس (loading, empty, error, stale, success) وإيضاح تمديد الحد بالدقائق المكتسبة في واجهة الطفل ChildScreenTimeScreen (Step 6).
- **2026-10-22 | w5_screen_time, s3_minutes_economy:** إضافة مفتاح التبديل earnedMinutesExtendLimit في نماذج العميل ScreenTimePolicy وFoundationGateScreenPolicy وعميل HTTP ولوحة تحكم ولي الأمر (Step 5).
- **2026-10-22 | w5_screen_time, s3_minutes_economy:** إضافة عمود ومفتاح earned_minutes_extend_limit (الهجرة 133) في سياسة وقت الشاشة لدعم جسر D4.
- **2026-10-22 | w5_screen_time, s3_minutes_economy:** تسجيل رصيد الائتمان المؤقت في جدول family_minutes_ledger عند موافقة ولي الأمر على طلب الوقت (Step 2 - time_request_grant).
- **2026-10-22 | w5_screen_time, s3_minutes_economy:** تسجيل استهلاك وقت الشاشة للهاتف كـ consumption في family_minutes_ledger بحساب الـ delta (الهجرة 134 لتعديل قيد credit_ref).
- **2026-10-22 | w5_screen_time, s3_minutes_economy:** توحيد معادلة رصيد الشاشة المتبقي Remaining = max(0, dailyLimitMinutes + activeGrants - phoneConsumption) وقراءة الرصيد الممنوح والاستهلاك من سجل الدقائق (Step 4).
- **2026-10-20 | app_shell_and_gate, w2_child_device_lifecycle:** إغلاق ثغرات الاختبارات وإضافة حارس mounted ونقل مستمع الإبطال إلى ما بعد تحميل الإطار (commit `8f0417f`).
- **2026-10-21 | w2_child_device_lifecycle:** debug builds no longer send mock-location heartbeats, matching release.
