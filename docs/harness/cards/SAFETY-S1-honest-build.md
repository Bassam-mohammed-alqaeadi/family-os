# `SAFETY-S1` — نسخة تجريبية صادقة: APK release من CI، وإعلان Play، وإزالة بقايا التجربة من كود المنتج

> **النوع:** الشريحة الأولى في مرحلة السلامة — [`../../safety_phase/01_SAFETY_PHASE_PLAN.md`](../../safety_phase/01_SAFETY_PHASE_PLAN.md) §٦. تُغلق [`RESCUE-002`](RESCUE-002-android-apk-workflow-keystore-guard.md).
> **الحالة:** الكود والاختبارات المحلية منجزة · CI ينتظر الدفع وطلب الدمج · **لم يُفحص على هاتف حقيقي بعد** (ف١ في [`PHONE_CHECKS.md`](../../safety_phase/PHONE_CHECKS.md)).

---

## ١) الهوية

| الحقل | القيمة |
|---|---|
| **المعرّف** | `SAFETY-S1` |
| **النظام** | أدوات الصدق المشتركة لمرحلة السلامة (لا يغلق عموداً لنظام بعينه) |
| **الموجة** | المرحلة الثانية — السلامة (إكمال على الهاتف) |
| **المرحلة** | `REAL_ENGINE` |
| **المالك** | جلسة واحدة (Viktor) |
| **الملفات المملوكة** | `.github/workflows/{android_build,android_native_ci,credential_guard}.yml` · `scripts/verify-no-service-account-keys{,.test}.mjs` · `tools/android/check_manifest_policy.mjs` · `app/android/app/src/main/AndroidManifest.xml` · `backend/src/web-filter.js` (`classifyHost`) · `backend/test/web-filter.test.js` · `app/lib/core/web_filter/web_filter_engine.dart` · `app/lib/features/n05_lock/child_mode_lock_{service,screen}.dart` · `app/lib/app/ux_local_seed.dart` · `app/lib/core/i18n/app_{ar,en}.arb` والمولَّدات · الاختبارات المقابلة · `docs/safety_phase/*` · `docs/CURRENT_EXECUTION_PLAN.md` · `docs/harness/{LOOP_STATE,MOCK_INVENTORY}.md` |
| **تاريخ الفتح** | 2026-10-10 |

## ٢) مشكلة المستخدم

**جملة واحدة:** المالك لا يستطيع تثبيت نسخة من التطبيق الحالي على هاتفه دون بناء محلي، ولا شيء يضمن أن ما يثبّته نسخة إصدار بلا بيانات تجريبية ومعلنة لـGoogle Play كأداة متابعة أطفال.

**الأدوار:** المالك (المختبِر)، وكل أسرة لاحقاً (عبر الامتثال).

**القيمة:** كل طلب دمج يمسّ `app/` ينتج APK release قابلاً للتثبيت ومفحوصاً في ملفه نفسه، فتبدأ فحوص الهاتف الصغيرة بعد كل شريحة.

**ما لا تهدف إليه:** مفتاح توقيع إصدار حقيقي (قرار المالك قبل ش٦)؛ النشر على Play؛ اسم وأيقونة التطبيق؛ إزالة كل بذور `MOCK_INVENTORY` (ش١٥/ش١٦)؛ أي تغيير في سلوك الخادم أو الهاتف خارج ما يلي.

## ٣) ما تغيّر

| البند | التغيير | الدليل |
|---|---|---|
| APK في CI | `android_build.yml`: `flutter build apk --release` بـ`--dart-define=FAMILY_OS_API_ORIGIN` و`FAMILY_OS_SHOWCASE=false`؛ سرّ `GOOGLE_SERVICES_JSON` (JSON خام أو base64) يُتحقق أنه JSON فيه عميل أندرويد للحزمة `com.familyos.family_os` **دون طباعة شيء منه**؛ فشل باسم واضح عند غياب السرّ أو المتغيّر؛ فحص `aapt2` للـAPK نفسه (`isMonitoringTool=child_monitoring`، غير قابل للتصحيح)؛ مفتاح توقيع اختبار ثابت عبر cache؛ artifact ٧ أيام؛ حذف الملف من الـrunner | بناء محلي ناجح بإعداد Firebase **وهمي** (Flutter 3.35.7، JDK 17، SDK 36، NDK 27): `app-release.apk` ٨٦٫٧ م.ب، ومنطق الفحص نفسه على مانيفستها: العلم موجود و`debuggable` غائب. **لم يُشغَّل على GitHub بعد** |
| حارس الاعتماد | يرفض `*.jks|*.keystore|*.p12|*.pfx` و`key.properties` | `scripts/verify-no-service-account-keys.test.mjs` ٦/٦ (نظيف ينجح؛ keystore وkey.properties وp12 وgoogle-services.json تُرفض ولا يُطبع محتواها) — يعمل في Credential Guard |
| إعلان Play | `<meta-data android:name="isMonitoringTool" android:value="child_monitoring" />` داخل `<application>` (صيغة [Play Help 12955211](https://support.google.com/googleplay/android-developer/answer/12955211)) | `tools/android/check_manifest_policy.mjs` في Android Native CI؛ تجربة سلبية (`value="other"`) ⇒ exit 1 |
| مصنّف الويب | حُذف جدول `*.example` من `classifyHost` (الخادم) و`WebFilterEngine.classifyHost` (العميل). كل مضيف فيه كان يُصنَّف بنفس الفئة عبر الكلمات، فالسلوك لم يتغير | `web-filter.test.js` (اختبار جديد) و`test/core/web_filter/web_filter_classify_host_test.dart` |
| قفل وضع الطفل | حُذفت `kChildModeLockMockPassword` من `lib` إلى `test/.../support/`. الإنتاج بلا متحقق ⇒ `ChildModeUnlockOutcome.unavailable`: لا محاولة تُعدّ، ولا «إخطار» مزعوم، والشاشة تعرض لافتة صادقة بدل حقل كلمة السر وتُخفي تحذير «كل محاولة تصل والدك». الطوارئ ظاهرة دائماً | اختباران جديدان في `child_mode_lock_screen_test.dart`؛ `mock_isolation_test` والسجل ٢٠ ← ١٩ |
| بذرة UX | `applyUxLocalSeed({bool? isReleaseMode})` لإثبات فرع release بلا بناء release | `ux_local_seed_test.dart`: release يزرع ٠ ولا يغيّر الصفوف |
| التوثيق | `docs/safety_phase/{01_SAFETY_PHASE_PLAN,RESUME,PHONE_CHECKS}.md`؛ عمود «على الهاتف» في المؤشر؛ `LOOP_STATE` | — |

## ٤) الأدلة المحلية (2026-10-10، على الفرع قبل الدفع)

- `backend`: `npm run check` نظيف؛ `npm test` ٣٥٢ (٣١٩ نجح، ٠ فشل، ٣٣ تُخطّي لغياب `DATABASE_URL`).
- `app`: `flutter analyze --fatal-infos` بلا مشكلات؛ `flutter test` كاملاً — العدد في تقرير الشريحة وفي وصف طلب الدمج.
- حراس: `verify-no-service-account-keys` نجح؛ اختباره ٦/٦؛ `check_manifest_policy` نجح؛ `check_dart_imports` و`harness_check.sh` و`check_migration_range.sh`.
- بناء APK release محلي بإعداد وهمي: نجح.

## ٥) ما بقي مفتوحاً

- أول تشغيل لـ`android_build.yml` على GitHub بالسرّ الحقيقي (يكشف أيضاً إن كان متغيّر `FAMILY_OS_API_ORIGIN` ما زال موجوداً).
- فحص الهاتف ف١.
- **وُجد أثناء الشريحة:** قائمة أطفال محلية («ابن 1»، «ابن 2») تُزرع في release عبر `IdentityLocalPersistence.openChildrenListRepository()` — الخطة §٨.

## ٦) معيار الإغلاق

CI أخضر على طلب الدمج بكل بواباته **ومنها «Android Build»** مع artifact، ثم صفّ ف١ في `PHONE_CHECKS.md` (نجح أو نتائج مسجّلة بصدق).
