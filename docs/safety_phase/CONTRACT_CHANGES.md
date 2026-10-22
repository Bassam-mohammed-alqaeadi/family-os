# سجل تغييرات العقود والأنظمة المحمية (Contract Changes Log)

> **القاعدة الحاكمة:** أي تعديل في أي ملف مملوك لنظام محمي مسجل في `docs/safety_phase/PROTECTED_SYSTEMS.json` يتطلب سطراً موثقاً هنا باسم النظام والتاريخ ومبرر التعديل، وإلا يفشل حارس `check_protected.mjs`.

## سجل التعديلات المعتمدة

- **2026-10-22 | w5_screen_time, s3_minutes_economy:** إضافة عمود ومفتاح earned_minutes_extend_limit (الهجرة 133) في سياسة وقت الشاشة لدعم جسر D4.
- **2026-10-22 | w5_screen_time, s3_minutes_economy:** تسجيل رصيد الائتمان المؤقت في جدول family_minutes_ledger عند موافقة ولي الأمر على طلب الوقت (Step 2 - time_request_grant).
- **2026-10-20 | app_shell_and_gate, w2_child_device_lifecycle:** إغلاق ثغرات الاختبارات وإضافة حارس mounted ونقل مستمع الإبطال إلى ما بعد تحميل الإطار (commit `8f0417f`).
- **2026-10-21 | w2_child_device_lifecycle:** debug builds no longer send mock-location heartbeats, matching release.
