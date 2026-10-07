# سجل الـmock — الوثيقة الملزِمة الوحيدة

> **المهمة:** ص٠-د من `docs/00_MASTER_PLAN.md` · **السياسة:** «لا mock ولا وصلة معاينة» (شرط مالك دائم)
> **حالة السجل:** مفتوح — الدين مُقاس، والدين لم يُسدَّ بعد
> **الحارس:** `app/test/app/mock_isolation_test.dart` — يُسقط البناء إن صار أي mock **جديد** واصلاً لكود الإنتاج، ويُسقطه أيضاً إن حُذف واحد ولم يُحدَّث هذا السجل. العدد ينزل ولا يصعد خفيةً.

---

## ١) كيف يُقاس — بالكود لا بالرأي

الحارس يفحص كل ملف تحت `app/lib`، ويعتبره **سطح mock** إذا:

- **اسمه** يحمل كلمة وهمية: `_mock` · `mock_` · `_fake` · `_seed` · `_demo` · `_stub` · `_fixture`؛ أو
- **يُعلن رمزاً** فيه `Mock` أو `Fake`: `MockEntitlementService` · `FakeDeviceHealthSeam` · `kChildModeLockMockPassword` · `DayChildMock`.

و**«يصله كود الإنتاج»** تعني: ملف تحت `lib/` يستورده. و`lib/main.dart` إنتاجٌ بحكم كونه نقطة الدخول.

**القياس الحالي (2026-10-07):**

| القياس | العدد |
|---|---|
| ملفات `lib` تصل مسار الإنتاج | **٢٠** ← الدين المفتوح (نزل ثلاثة: `family_members_mock` في و١، و`location_real_local_seed_mock` في و٣، و`core/policy/sos_fire.dart` في و٤) |
| ملفات mock لا يستوردها إلا اختبار | **١٣** ← وسائط اختبار مشروعة |
| ملفات mock لا يشير إليها أحد | **٠** ← لا موتى |

---

## ٢) الدين المفتوح — ٢٠ ملفاً يصلها الإنتاج

مرتّبة بالخطورة. **لا يُحذف صفّ إلا بأن يصير الملف غير واصل — أي بحذفه أو باستبدال الوهمي بحقيقي، لا بتحسين صياغته.**

### 🔴 سلامة

| # | الملف | ما هو الوهمي | يصلها | الأثر الصادق | الإغلاق |
|---|---|---|---|---|---|
| ١ | `features/n12_devices/device_health_seam.dart` | `FakeDeviceHealthSeam` + لقطة صحة مزروعة | ٣ شاشات صحة جهاز + مركز الإعدادات | نظام الأجهزة نفسه يعرض صحة مزروعة بدل حكم الخادم — وقد صار الخادم يقوله فعلاً في هذه الجلسة | احذف الوصلة واقرأ `FoundationGateGuardianDevice` عبر مسار القراءة الحقيقي |
| ٢ | `features/n05_lock/child_mode_lock_service.dart` | `kChildModeLockMockPassword = 'parent-account'` | شاشتا القفل | **كلمة سر ثابتة في كود المنتج** لقفل وضع الطفل: من يقرأ المستودع يعرفها | استبدلها بتحقق من حساب الوالد عبر الخادم؛ والقفل الحقيقي في و٥ |
| ٣ | `features/n01_linking/camera_permission_seam.dart` | `FakeCameraPermissionSeam` | مسح QR للربط + التقاط الاستوديو | صلاحية الكاميرا تُعلَن ممنوحة بلا نظام، فيمرّ مسار الربط كأنه تحقق | صلّها بـ`permission_handler` الحقيقي |

### 🟠 ثقة وكذب على المستخدم

| # | الملف | ما هو الوهمي | يصلها | الأثر الصادق | الإغلاق |
|---|---|---|---|---|---|
| ٤ | `core/policy/entitlement_service.dart` | `MockEntitlementService` | شاشتا الاشتراك | شاشات الخطط تُظهر استحقاقاً محلياً بلا خادم | و١١ (فوترة) أو حذف الشاشة حتى يوجد مزوّد |
| ٥ | `core/policy/advisor_repository.dart` | `MockAdvisorRepository` | ٤ ملفات | المستشار العائلي يعرض اقتراحات مُصنَّعة | و١٠/و١٣ حين يوجد مصدر حقيقي |
| ٦ | `core/policy/ai_suggestion_repository.dart` | `MockAiSuggestionRepository` | شاشتا المستشار | كذلك | نفسه |
| ٧ | `core/policy/ai_stage_flags_repository.dart` | `MockRemoteAiStageFlags` | شاشة تحكم الدماغ | أعلام مراحل تُقرأ من ذاكرة محلية بلا خادم | نفسه |
| ٨ | `main.dart` | `MockAdvisorRepository` يُبنى في نقطة الإقلاع | نقطة الدخول | **المنتج يُقلع بمستشار وهمي** | نفسه |

### 🟡 بذور محلية — مقصودة اليوم، ويجب أن تُسمّى

هذه ليست تظاهراً بالخادم: هي بيانات محلية لتشغيل الأسطح قبل وجود واجهات بعينها. لكنها تعيش تحت `lib/` وتُشحن في الحزمة، فتُسجَّل صريحةً لا مسكوتاً عنها.

| # | الملف | ما هو | يصلها |
|---|---|---|---|
| ٩ | `app/ux_local_seed.dart` | بذرة تجربة المستخدم المحلية | `main.dart` |
| ١٠ | `core/fs_foundation/mock_remote_adapter.dart` | محوّل بعيد وهمي في نواة الجلسة | `local_event_emitter` · `fs_session_kernel` |
| ١١ | `core/policy/chat_mock_store.dart` | مخزن محادثات محلي | `family_data_lifecycle` |
| ١٢ | `core/policy/family_data_lifecycle.dart` | يعرّف `ChatMockStore` داخله | `privacy_data_screen` |
| ١٣ | `features/n02_day/children_list_local_seed_mock.dart` | بذرة قائمة الأبناء | `children_list_local_repository` · `child_apps_local_persistence` |
| ١٤ | `features/n02_day/day_child_mock.dart` | بذرة يوم الطفل | **٢١ ملفاً** |
| ١٥ | `features/n02_day/day_board_screen.dart` | يعرّف `DayChildMock` داخل الشاشة نفسها | `router.dart` |
| ١٦ | `features/n02_day/alert_detail_mock.dart` | بذرة تفصيل التنبيه | `audit_population` |
| ١٧ | `features/n02_day/alerts_hub_mock.dart` | بذرة مركز التنبيهات | `audit_population` |
| ١٨ | `features/n02_day/family_chat_local_seed_mock.dart` | بذرة محادثة العائلة | `family_chat_local_store` |
| ١٩ | `features/n03_screen_time/child_apps_mock.dart` | بذرة تطبيقات الطفل | `child_apps_repository` |
| ٢٠ | `features/n03_screen_time/child_apps_real_local_seed_mock.dart` | بذرة تطبيقات محلية | `audit_population` · `child_apps_local_persistence` |

---

## ٣) وسائط اختبار — لا تُحذف، ولا تُقترب من الإنتاج

`active_call_mock` · `call_history_mock` · `child_active_call_mock` · `child_chats_mock` · `child_conversation_mock` · `child_profile_mock` · `children_list_mock` · `conversation_mock` · `conversations_list_mock` · `location_history_mock` · `location_map_mock` · `safe_zones_mock` (كلها في `features/n02_day/`) — تشير إليها اختبارات فقط.

**ملاحظة صادقة:** وجودها تحت `lib/` يعني أنها تُشحن داخل حزمة التطبيق ولو لم تُستدعَ. نقلها إلى `test/` هو التنظيف الصحيح، وهو تغيير ميكانيكي ينتظر دفعة واحدة مخصّصة له مع تحديث مسارات الاستيراد في اختباراتها.

---

## ٤) ما لا يفعله هذا السجل

لا يحكم على **قبول** أي mock بعينه. ذلك قرار منتج له كلفة، موضعه الصفّ نفسه بسبب مكتوب بجانبه — لا تعبير نمطي.

---

## ٤) سجل الإغلاق — كل صفٍّ خرج من الدين، ولماذا

| التاريخ | الملف | كيف أُغلق | الدليل |
|---|---|---|---|
| 2026-10-07 | `core/policy/sos_fire.dart` | **استُبدل بحقيقي**: كان يحمل `MockSosFireService` (نجاح دائم، ويحاكي وصول الرسائل). حلّ محله `activeSosFireService` المربوط عند الإقلاع بـ`SosServerAuthority` عبر `bindSosServerAuthority`، ومن لا سيرفر له يقرأ `UnwiredSosFireService` الذي يقول `fired:false` بلا تسليمات؛ والمحاكي انتقل إلى `app/test/support/recording_sos_fire_service.dart` خارج `lib/` | `sos_server_authority.dart` + `family_sos_api_client.dart` + رحلة و٤ على PostgreSQL |
| 2026-10-07 | `features/n02_day/location_real_local_seed_mock.dart` | **أُزيل**: كان يزرع منطقتين وهميتين (المنزل/المدرسة) في مخزن الجهاز عند الإقلاع، فصار السطح يقرأ المناطق من الخادم عبر `ServerSafeZonesRepository` ويكتبها عبر `SafeZoneServerWriter`؛ والحارسان `mock_isolation_test.dart` و`ldr_b2/b8` حُدِّثا معه | `location_server_authority.dart` + `family_location_api_client_test.dart` + رحلة و٣ على PostgreSQL |
| 2026-10-07 | `features/n12_devices/family_members_mock.dart` | **أُزيل**: وسوم الأدوار انتقلت إلى `family_members_role_labels.dart` (كود إنتاج)، والحمولات صارت وسيط اختبار داخل ملف الاختبار نفسه، وسرد الأعضاء صار من الخادم عبر `family_members_remote_repository.dart` | العدد ٢٢ في الحارس `mock_isolation_test.dart`، والاختبارات الجديدة على الواجهة والخادم |
