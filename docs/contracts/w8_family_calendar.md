# العقد: التقويم العائلي ومناسبات الأسبوع (W8 Family Calendar)

## Scope
ينظم هذا النظام تقويم العائلة الأسبوعي، ودعوة الأبناء، وتسجيل الحضور البشري بعد انتهاء المناسبة، وإلغاء المناسبات مع توثيق السبب والمؤلف وتجميد التعديل، مع اشتراط الصدق في قراءة الأسبوع من الخادم دون اختراع محلي.

## Invariants
1. لا يمكن تسجيل حضور قبل بدء المناسبة، ولا يمكن تسجيل حضور لمناسبة تم إلغاؤها.
2. تسجيل الحضور يتم بشرياً من قبل الولي حصراً، ولا يعتمد على أي استنتاج موقع مكاني آلي من الهاتف.
3. إلغاء المناسبة فعل موثق يحمل المؤلف والسبب واللحظة الزمنية، ويبقى الحدث الملغى معروضاً بسببه ولا يختفي سراً.
4. هاتف الطفل يجيب حصراً عن الطفل المرتبط به، ولا يمكنه الإجابة بالنيابة عن إخوته.
5. لا يمكن تعديل مناسبة تم إلغاؤها، وتمنع قاعدة البيانات أي تعارض متزامن عبر فحص `expectedVersion`.

## Owned Files
- `backend/migrations/108_family_calendar.sql`
- `backend/src/calendar.js`
- `app/lib/features/n15_calendar/family_calendar_screen.dart`
- `app/lib/foundation_gate/family_calendar_api_client.dart`

## Enforcing Tests
- `backend/test/event-cycles.test.js`:
  - `attendance cannot exist before the event, and cannot exist for a cancelled one`
  - `the family calendar shows what was called off, with the reason`
  - `a handset answers for its own child, and cannot answer for a sibling`
  - `cancelling is an act with an author, a reason and a moment - and it happens once`
  - `a handset reads the events its own child is invited to, and nothing else`
- `app/test/foundation_gate/family_calendar_api_client_test.dart`

## Phone Evidence
- لا يلزمه عمل أصلي على الهاتف (none).

## Change Rule
أي تغيير في جداول المناسبات أو قيود الحضور يتطلب هجرة SQL جديدة واجتياز اختبارات `event-cycles.test.js` وموافقة المالك.
