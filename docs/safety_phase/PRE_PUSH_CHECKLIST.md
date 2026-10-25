# قائمة التحقق الصارمة قبل الرفع (Pre-Push Checklist)

> **القاعدة الذهبية الدستورية:**
> **«ممنوع الرفع نهائياً قبل أن تكون جميع البوابات خضراء 100%»**
> **(No push before gate green)**
>
> أي كسر لأي بوابة في CI أو أي تجاهل للأخطاء يُعد خرقاً لدستور المنصة (`AGENTS.md`).

---

## خطوات الفحص الإلزامية بالترتيب

### 1. فحص سلامة المستودع والفرع (Git Hygiene)
تأكد من أنك تعمل على الفرع المخصص، وأنه لا توجد ملفات مهملة مضافة:
```bash
tools/git/git-doctor.sh check
```
- **ممنوع قطعيّاً:** استخدام `git add .` أو إضافة ملفات السجلات أو مجلدات المؤقتات `.ua/tmp*`.

---

### 2. فحص استيرادات Dart الميتة (Dead Imports Guard)
```bash
node tools/harness/check_dart_imports.mjs .
```
- يجب أن يُرجع: `PASS: zero dead imports found`.

---

### 3. فحص الأنظمة المحمية وسجل العقود (Protected Systems Guard)
```bash
node tools/harness/check_protected.mjs HEAD~1
```
- يتحقق من أن أي تعديل في الملفات المملوكة لأنظمة محمية مسجل في `docs/safety_phase/CONTRACT_CHANGES.md`.

---

### 4. فحص التحليل الساكن لـ Flutter (Flutter Analyze)
```bash
cd app
flutter analyze --fatal-infos
```
- يجب أن يكون الناتج: **صفر أخطاء وصفر تحذيرات** على كافة ملفات المستودع المتتبعة.

---

### 5. فحص الخادم والعقد والانحراف (Backend Check & Contract Tests)
```bash
cd backend
npm run check
npm test
```
- يتحقق من سلامة نصوص المصدر وعدم وجود أي انحراف (Drift) بين عقد `foundation.v1.json` ومسارات `app.js`.

---

### 6. فحص اختبارات أندرويد الأصلية (Android Native Protocol JVM)
```bash
tools/android/run_native_protocol_tests.sh
node tools/android/check_manifest_policy.mjs
```
- يتحقق من سلامة طابور التليميتري المشفّر، وتسامح الساعة، وحالات الحماية في Kotlin على الـ JVM.

---

### 7. تشغيل اختبارات Flutter (Flutter Tests)
```bash
cd app
flutter test
```
- الفشل الوحيد المستثنى والمقبول من المالك هو: `test/app/mock_isolation_test.dart`.

---

### 8. الإيداع والرفع الموثّق (Explicit Commit & Push)
- إدراج الملفات بالاسم الصريح فقط:
  ```bash
  git add <path/to/file1> <path/to/file2>
  git commit -m "feat/fix: explicit description"
  git push origin arena/53f92bb1-family-os
  ```
