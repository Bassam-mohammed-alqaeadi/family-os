# العقد: متانة هاتف الطفل الأصلية (S2 Native Handset Resilience)

## Scope
ينظم هذا النظام بقاء ومقاومة هاتف الطفل الأصلية عبر طابور نقاط الموقع المشفّر (AES-GCM محلياً)، والحد الأقصى للطابور (2000 نقطة أو 48 ساعة) مع طرد الأقدم عند الامتلاء، وتسامح انحراف ساعة الهاتف عن الخادم، وإرشاد إعدادات البطارية المخصصة لكل شركة مصنعة (OEM)، والعودة التلقائية بعد إعادة تشغيل الهاتف (`BOOT_COMPLETED`) بشرط إذن الخلفية.

## Invariants
1. تُشفر نقاط الموقع سطراً بسطر في الطابور المحلي بمفتاح GCM مشفر لا يُحفظ في الذاكرة المجردة.
2. لا يتجاوز الطابور سعة 2000 نقطة أو عمر 48 ساعة؛ وعند الامتلاء يُطرد الأقدم ويُسجل عداد النقاط المفقودة في الدفتر بصدق.
3. التسامح مع تقديم أو تأخير ساعة الهاتف حتى 60 دقيقة دون رفض النقاط، مع وسم نقاط الماضي بـ `stored_out_of_order`.
4. بطاقة حالة الحماية في الشاشة تعكس الواقع الصادق: "الحماية متوقفة" فور سحب الإذن أو إيقاف التطبيق ولا تتظاهر بالنشاط.
5. إرشاد البطارية يقدم تعليمات خاصة بالشركة المصنعة للجهاز (Samsung, Xiaomi, Huawei, etc.) ويفتح صفحة الإعدادات الخاصة بها.

## Owned Files
- `app/android/app/src/main/kotlin/com/familyos/family_os/ResilientFixQueue.kt`
- `app/android/app/src/main/kotlin/com/familyos/family_os/EncryptedFixQueueStore.kt`
- `app/android/app/src/main/kotlin/com/familyos/family_os/ServerTimeOffset.kt`
- `app/android/app/src/main/kotlin/com/familyos/family_os/ProtectionStateMachine.kt`
- `app/android/app/src/main/kotlin/com/familyos/family_os/BatteryOemMap.kt`
- `app/android/app/src/main/kotlin/com/familyos/family_os/BootBackoff.kt`

## Enforcing Tests
- `tools/android/run_native_protocol_tests.sh`:
  - `com.familyos.family_os.ResilientFixQueueTest`
  - `com.familyos.family_os.ServerTimeOffsetTest`
  - `com.familyos.family_os.ProtectionStateMachineTest`
  - `com.familyos.family_os.BootBackoffTest`
  - `com.familyos.family_os.BatteryOemMapTest`
  - `com.familyos.family_os.EncryptedFixQueueStoreTest`
- `app/test/s2_protection_card_test.dart`:
  - `fully protected renders green state, no battery button`
  - `degraded with battery reason shows queue line and button`
  - `stopped renders the stopped state`
  - `live grant loss distrusts the verdict on screen`
- `app/test/s2_battery_guidance_test.dart`

## Phone Evidence
- `docs/safety_phase/PHONE_CHECKS.md` ف٥ بنود 0–8 (معلقة `⬜` بانتظار فحص هاتف المالك للسيناريوهات الميدانية كوضع الطيران وإعادة التشغيل).

## Change Rule
أي تعديل على كود Kotlin في طابور التشفير أو إدارة الإقلاع يتطلب تشغيل اختبارات JVM بنجاح وفحص خلو الكود من أي مكتبات تكسر التوافق وموافقة المالك.
