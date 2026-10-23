# العقد: وقت الشاشة والقفل الفوري (W5 Screen Time & Instant Lock)

## Scope
نظام إدارة حدود وقت الشاشة للتطبيقات وقواعد الحجب والقفل الفوري للجهاز من قبل الأولياء.

> **حالة النظام: القياس مبني، والفرض غير مبني (Measurement built, enforcement not built)**
>
> **صحيح حتى 2026-10-23:**
> * **القياس موجود.** `UsageStatsAggregator.kt` (طبقة نقية، تُختبر على JVM) و`UsageStatsReader.kt` (قراءة `UsageStatsManager` والتحقق من `PACKAGE_USAGE_STATS` عبر `AppOpsManager`) يعملان، ويعرض `child_screen_time_report_client.dart` نتيجتهما عبر `POST /v1/devices/{id}/screen-time`. الكوتلن المذكور مُدرَج في `tools/android/run_native_protocol_tests.sh`، فتترجمه بوابة Android Native وتشغّل اختباراته.
> * **الطلب موجود.** طلب الوقت الإضافي يخرج من الهاتف داخل جسم التقرير نفسه (`{usage, apps, request}`) عبر `child_time_request_client.dart`، ويقرأه ولي الأمر من `GET /v1/families/{familyId}/children/{childId}/time-requests` ويجيب عليه.
> * **الفرض غير مبني — وهذا مقصود ومؤجَّل إلى S11.** لا يوجد `SYSTEM_ALERT_WINDOW` ولا حجب فعلي لأي تطبيق؛ الأرقام تُقاس وتُعرض وتُحسب، لكن هاتف الطفل لا يُغلق تطبيقاً بعد. لا يجوز لأي شاشة أن تقول otherwise.
> * **الرحلة الخلفية محدودة.** الإرسال التراكمي يحدث والتطبيق في المقدمة (أو لحظة عودته)، بإيقاع محدود في `usage_report_rhythm.dart`. لا `WorkManager` بعد: هذا قيد معروف لا ادّعاء مُنجز.

## Invariants
1. [غير مبني / untested] قياس استخدام التطبيقات بالدقائق على نظام أندرويد وإرسالها للخادم دورياً.
2. [غير مبني / untested] فرض القفل الفوري وحجب شاشات التطبيقات عند استنفاد الرصيد أو تلقي أمر القفل.

## Owned Files
- `backend/src/screen-time.js`

## Enforcing Tests
- لا توجد اختبارات تطبيق على الهاتف (none).

## Phone Evidence
- لا يوجد (none). عمود "على الهاتف" مُعلّم بـ `❌` في `docs/CURRENT_EXECUTION_PLAN.md`.

## Change Rule
يتطلب بناء وكيل التنفيذ الأصلي على أندرويد لخدمات الاستخدام وإذن النوافذ المنبثقة، وموافقة المالك.
