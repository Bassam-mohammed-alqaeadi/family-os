# FINAL USER EXPERIENCE TEST MATRIX

**Date:** 2026-09-26 · **Type:** PLAN-ONLY · **Authority:** `FINAL_VISUAL_UX_JOURNEY_MATRIX.json` + `journeys.csv` + Owner decisions D1–D12 / OD-13/14
**Classifications:** PASS | FAIL | BLOCKED-NATIVE | BLOCKED-REMOTE | OWNER-DECISION | NOT-APPLICABLE
**Rule:** No invented screens/controls. Interactive depth uses Screen Interaction Protocol (SIP) in the Plan; each screen gets SIP case bundle IDs below.

| Inventory | Count |
|---|---|
| Systems (matrix groups) | 42 |
| Journeys | 73 |
| Catalog screens | 130 |
| Non-catalog surfaces | 15 |
| Total surfaces | 145 |

## 0. Case ID scheme

| Prefix | Meaning |
|---|---|
| `UXV-LC-*` | Application lifecycle |
| `UXV-JRN-<id>-Snn` | Journey step |
| `UXV-SCR-<id>-SIP` | Screen Interaction Protocol bundle |
| `UXV-SCR-<id>-ST-<state>` | Screen state (E/L/Er/Off/NC/RC) |
| `UXV-SCR-<id>-VIS` | Visual/RTL/device variant pack |
| `UXV-SCR-<id>-CTL-<n>` | Observed control (recorded live; not invented) |
| `UXV-X-*` | Cross-screen consistency |
| `UXV-HON-*` | Capability honesty |
| `UXV-FD-<finding>` | Finding remapping from FVX-* |
| `UXV-DEV-*` | Device §13 / D-FINAL |

## 1. Systems → journeys → screens

| System | Screens (n) | Journeys |
|---|---|---|
| ADM:أ | 14 | JRN-CHD-01, JRN-CHD-05, JRN-FAT-01, JRN-FAT-02, JRN-FAT-03, JRN-MOT-01 |
| ADM:ب | 6 | JRN-FAT-02, JRN-FAT-04, JRN-FAT-06, JRN-MOT-01, JRN-MOT-03 |
| ADM:ج | 6 | JRN-CHD-01, JRN-FAT-02, JRN-FAT-13, JRN-FAT-14, JRN-SHR-01 |
| ADM:ح | 1 | JRN-FAT-30 |
| ADM:د | 2 | JRN-FAT-26 |
| ADM:ز | 4 | JRN-CHD-02, JRN-FAT-05, JRN-FAT-06, JRN-MOT-02, JRN-MOT-03 |
| ADM:هـ | 1 | JRN-FAT-27 |
| ADM:و | 3 | JRN-CHD-05, JRN-FAT-28 |
| AIC:أ | 3 | JRN-FAT-10 |
| AIC:ب | 1 | JRN-FAT-29 |
| AIC:ج | 2 | JRN-FAT-29 |
| AIC:د | 5 | JRN-FAT-21, JRN-FAT-36, JRN-FAT-38, JRN-FAT-45 |
| AIC:هـ | 3 | JRN-FAT-37, JRN-MOT-09 |
| AIC:و | 2 | JRN-FAT-41 |
| COM:أ | 4 | JRN-CHD-04, JRN-FAT-11, JRN-MOT-04 |
| COM:ب | 5 | JRN-CHD-04, JRN-CHD-16, JRN-CHD-17, JRN-FAT-12, JRN-MOT-04 |
| COM:ج | 2 | JRN-CHD-11, JRN-CHD-17 |
| COM:د | 3 | JRN-CHD-13, JRN-FAT-34 |
| COM:ز | 1 | JRN-CHD-11 |
| COM:هـ | 2 | JRN-FAT-24, JRN-MOT-08 |
| COM:و | 4 | JRN-CHD-12, JRN-FAT-25, JRN-FAT-42, JRN-MOT-08 |
| EDU:أ | 3 | JRN-CHD-07, JRN-FAT-23 |
| EDU:ب | 2 | JRN-CHD-07, JRN-FAT-23 |
| EDU:ج | 3 | JRN-CHD-07, JRN-FAT-23 |
| EDU:ح | 3 | JRN-CHD-09, JRN-CHD-17, JRN-FAT-23 |
| EDU:د | 2 | JRN-CHD-08, JRN-CHD-17 |
| EDU:ز | 5 | JRN-CHD-14, JRN-CHD-18, JRN-FAT-35 |
| EDU:ط | 7 | JRN-FAT-21, JRN-FAT-22, JRN-FAT-23, JRN-FAT-43 |
| EDU:هـ | 2 | JRN-CHD-15 |
| EDU:و | 2 | JRN-CHD-10, JRN-CHD-17 |
| SEC:أ | 5 | JRN-CHD-06, JRN-FAT-15, JRN-FAT-44, JRN-MOT-07 |
| SEC:ب | 2 | JRN-FAT-16 |
| SEC:ج | 2 | JRN-FAT-17, JRN-FAT-40 |
| SEC:ح | 1 | JRN-FAT-19 |
| SEC:د | 4 | JRN-FAT-07, JRN-FAT-08, JRN-MOT-06 |
| SEC:ز | 1 | JRN-FAT-32 |
| SEC:ط | 1 | JRN-FAT-18 |
| SEC:ك | 1 | JRN-FAT-39 |
| SEC:ل | 1 | JRN-FAT-20 |
| SEC:هـ | 4 | JRN-CHD-03, JRN-FAT-08, JRN-FAT-09, JRN-MOT-05 |
| SEC:و | 3 | JRN-FAT-31, JRN-FAT-32 |
| SEC:ي | 2 | JRN-FAT-33 |

## 2. Journey cases (all 73)

| Journey | User | Name | Screens | Step case IDs | Related findings | Batch | Matrix result |
|---|---|---|---|---|---|---|---|
| JRN-CHD-01 | الابن | ربط جهازي وفهم القواعد | SCR-CHD-001, SCR-CHD-002, SCR-CHD-003, SCR-CHD-011 | `UXV-JRN-JRN-CHD-01-S01` `UXV-JRN-JRN-CHD-01-S02` `UXV-JRN-JRN-CHD-01-S03` `UXV-JRN-JRN-CHD-01-S04` | FVX-G-13 | VX-B4 | PENDING |
| JRN-CHD-02 | الابن | يومي في لمحة | SCR-CHD-004 | `UXV-JRN-JRN-CHD-02-S01` | FVX-G-03 | VX-B2 | PENDING |
| JRN-CHD-03 | الابن | طلب النجدة | SCR-CHD-005, SCR-CHD-006 | `UXV-JRN-JRN-CHD-03-S01` `UXV-JRN-JRN-CHD-03-S02` | FVX-G-06 | VX-B2 | PENDING |
| JRN-CHD-04 | الابن | التواصل مع عائلتي | SCR-CHD-007, SCR-CHD-008, SCR-CHD-009 | `UXV-JRN-JRN-CHD-04-S01` `UXV-JRN-JRN-CHD-04-S02` `UXV-JRN-JRN-CHD-04-S03` | FVX-S-01 | VX-B6 | OD |
| JRN-CHD-05 | الابن | معرفة ما يُجمع عني | SCR-CHD-003, SCR-CHD-010 | `UXV-JRN-JRN-CHD-05-S01` `UXV-JRN-JRN-CHD-05-S02` | FVX-G-03 | VX-B2 | PENDING |
| JRN-CHD-06 | الابن | طلب وقت إضافي | SCR-CHD-020, SCR-CHD-021 | `UXV-JRN-JRN-CHD-06-S01` `UXV-JRN-JRN-CHD-06-S02` | FVX-G-03, FVX-G-02 | VX-B2,VX-B3 | PENDING |
| JRN-CHD-07 | الابن | يوم دراسي كامل | SCR-CHD-012, SCR-CHD-013, SCR-CHD-014, SCR-CHD-015, SCR-CHD-016 | `UXV-JRN-JRN-CHD-07-S01` `UXV-JRN-JRN-CHD-07-S02` `UXV-JRN-JRN-CHD-07-S03` `UXV-JRN-JRN-CHD-07-S04` `UXV-JRN-JRN-CHD-07-S05` | FVX-G-03, FVX-C-06 | VX-B2,VX-B3 | PENDING |
| JRN-CHD-08 | الابن | سؤال المعلم الذكي | SCR-CHD-017 | `UXV-JRN-JRN-CHD-08-S01` | FVX-G-02 | VX-B3 | PENDING |
| JRN-CHD-09 | الابن | جلسة تركيز للمذاكرة | SCR-CHD-018 | `UXV-JRN-JRN-CHD-09-S01` | — | VX-B7 | PENDING |
| JRN-CHD-10 | الابن | نقاطي ومكافآتي | SCR-CHD-019 | `UXV-JRN-JRN-CHD-10-S01` | FVX-G-11 | VX-B4 | PENDING |
| JRN-CHD-11 | الابن | مشاركة لحظة مع العائلة | SCR-CHD-023, SCR-CHD-024 | `UXV-JRN-JRN-CHD-11-S01` `UXV-JRN-JRN-CHD-11-S02` | FVX-G-02 | VX-B3 | PENDING |
| JRN-CHD-12 | الابن | مهامي المنزلية | SCR-CHD-022 | `UXV-JRN-JRN-CHD-12-S01` | — | VX-B7 | PENDING |
| JRN-CHD-13 | الابن | طلب إضافة صديق | SCR-CHD-030 | `UXV-JRN-JRN-CHD-13-S01` | FVX-G-02 | VX-B3 | PENDING |
| JRN-CHD-14 | الابن | وردي اليومي — قرآن وأذكار | SCR-CHD-025, SCR-CHD-026, SCR-CHD-027 | `UXV-JRN-JRN-CHD-14-S01` `UXV-JRN-JRN-CHD-14-S02` `UXV-JRN-JRN-CHD-14-S03` | FVX-G-03 | VX-B2 | PENDING |
| JRN-CHD-15 | الابن | خطتي الذكية ومراجعة اليوم | SCR-CHD-028, SCR-CHD-029 | `UXV-JRN-JRN-CHD-15-S01` `UXV-JRN-JRN-CHD-15-S02` | — | VX-B7 | PENDING |
| JRN-CHD-16 | الابن | استكشاف المرح القادم | SCR-CHD-031 | `UXV-JRN-JRN-CHD-16-S01` | — | VX-B7 | PENDING |
| JRN-CHD-17 | الابن | مرح وإبداع متقدم | SCR-CHD-033, SCR-CHD-034, SCR-CHD-035, SCR-CHD-036, SCR-CHD-037 | `UXV-JRN-JRN-CHD-17-S01` `UXV-JRN-JRN-CHD-17-S02` `UXV-JRN-JRN-CHD-17-S03` `UXV-JRN-JRN-CHD-17-S04` `UXV-JRN-JRN-CHD-17-S05` | FVX-G-12 | VX-B4 | PENDING |
| JRN-CHD-18 | الابن | تلاوتي الذكية | SCR-CHD-032 | `UXV-JRN-JRN-CHD-18-S01` | FVX-G-02 | VX-B3 | PENDING |
| JRN-FAT-01 | الأب | التسجيل وإنشاء العائلة | SCR-SHR-001, SCR-SHR-002, SCR-SHR-003, SCR-FAT-001, SCR-SHR-007, SCR-SHR-008, SCR-FAT-030 | `UXV-JRN-JRN-FAT-01-S01` `UXV-JRN-JRN-FAT-01-S02` `UXV-JRN-JRN-FAT-01-S03` `UXV-JRN-JRN-FAT-01-S04` `UXV-JRN-JRN-FAT-01-S05` `UXV-JRN-JRN-FAT-01-S06` `UXV-JRN-JRN-FAT-01-S07` | FVX-G-01, FVX-C-01, FVX-C-02 | VX-B1,VX-B6 | PENDING |
| JRN-FAT-02 | الأب | ربط جهاز الابن الأول | SCR-FAT-002, SCR-FAT-003, SCR-FAT-004, SCR-FAT-005, SCR-FAT-006 | `UXV-JRN-JRN-FAT-02-S01` `UXV-JRN-JRN-FAT-02-S02` `UXV-JRN-JRN-FAT-02-S03` `UXV-JRN-JRN-FAT-02-S04` `UXV-JRN-JRN-FAT-02-S05` | FVX-S-04 | VX-B6 | PENDING |
| JRN-FAT-03 | الأب | تجربة التطبيق قبل الربط | SCR-FAT-002, SCR-FAT-007 | `UXV-JRN-JRN-FAT-03-S01` `UXV-JRN-JRN-FAT-03-S02` | FVX-G-11 | VX-B4 | PENDING |
| JRN-FAT-04 | الأب | دعوة الأم وتحديد صلاحيتها | SCR-FAT-008, SCR-FAT-027, SCR-FAT-031 | `UXV-JRN-JRN-FAT-04-S01` `UXV-JRN-JRN-FAT-04-S02` `UXV-JRN-JRN-FAT-04-S03` | FVX-G-02 | VX-B3 | PENDING |
| JRN-FAT-05 | الأب | نظرة الصباح على العائلة | SCR-FAT-010, SCR-FAT-011 | `UXV-JRN-JRN-FAT-05-S01` `UXV-JRN-JRN-FAT-05-S02` | FVX-S-03, FVX-G-05, FVX-G-17 | VX-B5,VX-B2 | PENDING |
| JRN-FAT-06 | الأب | متابعة ابن بعينه | SCR-FAT-012, SCR-FAT-013 | `UXV-JRN-JRN-FAT-06-S01` `UXV-JRN-JRN-FAT-06-S02` | FVX-S-04 | VX-B6 | PENDING |
| JRN-FAT-07 | الأب | معرفة موقع ابنه الآن | SCR-FAT-014, SCR-FAT-015 | `UXV-JRN-JRN-FAT-07-S01` `UXV-JRN-JRN-FAT-07-S02` | FVX-G-08, FVX-G-12 | VX-B4 | PENDING |
| JRN-FAT-08 | الأب | ضبط منطقة آمنة | SCR-FAT-016, SCR-FAT-017, SCR-FAT-028 | `UXV-JRN-JRN-FAT-08-S01` `UXV-JRN-JRN-FAT-08-S02` `UXV-JRN-JRN-FAT-08-S03` | FVX-S-05, FVX-G-09 | VX-B6,VX-B1 | PENDING |
| JRN-FAT-09 | الأب | استقبال بلاغ استغاثة | SCR-FAT-018, SCR-FAT-028 | `UXV-JRN-JRN-FAT-09-S01` `UXV-JRN-JRN-FAT-09-S02` | FVX-G-06, FVX-S-09 | VX-B2,VX-B5 | PENDING |
| JRN-FAT-10 | الأب | استقبال تنبيه أمني | SCR-FAT-019, SCR-FAT-020, SCR-FAT-029 | `UXV-JRN-JRN-FAT-10-S01` `UXV-JRN-JRN-FAT-10-S02` `UXV-JRN-JRN-FAT-10-S03` | FVX-S-02 | VX-B5 | PENDING |
| JRN-FAT-11 | الأب | محادثة العائلة | SCR-FAT-021, SCR-FAT-022 | `UXV-JRN-JRN-FAT-11-S01` `UXV-JRN-JRN-FAT-11-S02` | FVX-S-01 | VX-B6 | OD |
| JRN-FAT-12 | الأب | مكالمة بابنه | SCR-FAT-023, SCR-FAT-024 | `UXV-JRN-JRN-FAT-12-S01` `UXV-JRN-JRN-FAT-12-S02` | FVX-G-06, FVX-G-10 | VX-B2,VX-B4 | PENDING |
| JRN-FAT-13 | الأب | إدارة أجهزة العائلة | SCR-FAT-025, SCR-FAT-026 | `UXV-JRN-JRN-FAT-13-S01` `UXV-JRN-JRN-FAT-13-S02` | FVX-S-06, FVX-S-09 | VX-B2,VX-B5 | PENDING |
| JRN-FAT-14 | الأب | معالجة انقطاع جهاز | SCR-FAT-025, SCR-FAT-026 | `UXV-JRN-JRN-FAT-14-S01` `UXV-JRN-JRN-FAT-14-S02` | FVX-S-06 | VX-B2 | PENDING |
| JRN-FAT-15 | الأب | ضبط وقت الشاشة لابن | SCR-FAT-032, SCR-FAT-033 | `UXV-JRN-JRN-FAT-15-S01` `UXV-JRN-JRN-FAT-15-S02` | FVX-S-03 | VX-B5 | PENDING |
| JRN-FAT-16 | الأب | إدارة تطبيقات الابن | SCR-FAT-034, SCR-FAT-035 | `UXV-JRN-JRN-FAT-16-S01` `UXV-JRN-JRN-FAT-16-S02` | FVX-G-02, FVX-G-17 | VX-B3,VX-B4 | PENDING |
| JRN-FAT-17 | الأب | ضبط فلترة الإنترنت | SCR-FAT-036 | `UXV-JRN-JRN-FAT-17-S01` | FVX-G-04, FVX-G-03 | VX-B2 | PENDING |
| JRN-FAT-18 | الأب | قفل فوري لحظة العشاء | SCR-FAT-037 | `UXV-JRN-JRN-FAT-18-S01` | FVX-G-04, FVX-G-03 | VX-B2 | PENDING |
| JRN-FAT-19 | الأب | معالجة محاولة تحايل | SCR-FAT-038 | `UXV-JRN-JRN-FAT-19-S01` | FVX-S-02 | VX-B5 | PENDING |
| JRN-FAT-20 | الأب | ضبط وضع المدرسة | SCR-FAT-039 | `UXV-JRN-JRN-FAT-20-S01` | — | None | NA |
| JRN-FAT-21 | الأب | صناعة محتوى في الاستوديو | SCR-FAT-040, SCR-FAT-041, SCR-FAT-042, SCR-FAT-043, SCR-FAT-044, SCR-FAT-045 | `UXV-JRN-JRN-FAT-21-S01` `UXV-JRN-JRN-FAT-21-S02` `UXV-JRN-JRN-FAT-21-S03` `UXV-JRN-JRN-FAT-21-S04` `UXV-JRN-JRN-FAT-21-S05` `UXV-JRN-JRN-FAT-21-S06` | FVX-C-03, FVX-G-02 | VX-B1,VX-B3 | PENDING |
| JRN-FAT-22 | الأب | الاستفادة من مكتبة المجتمع | SCR-FAT-046 | `UXV-JRN-JRN-FAT-22-S01` | — | VX-B7 | PENDING |
| JRN-FAT-23 | الأب | إدارة تعليم ابنه | SCR-FAT-047, SCR-FAT-048, SCR-FAT-049, SCR-FAT-050, SCR-FAT-051 | `UXV-JRN-JRN-FAT-23-S01` `UXV-JRN-JRN-FAT-23-S02` `UXV-JRN-JRN-FAT-23-S03` `UXV-JRN-JRN-FAT-23-S04` `UXV-JRN-JRN-FAT-23-S05` | FVX-G-04 | VX-B2 | PENDING |
| JRN-FAT-24 | الأب | تنظيم التقويم العائلي | SCR-FAT-052, SCR-FAT-053 | `UXV-JRN-JRN-FAT-24-S01` `UXV-JRN-JRN-FAT-24-S02` | FVX-G-15 | VX-B3 | PENDING |
| JRN-FAT-25 | الأب | إسناد مهمة بمكافأة | SCR-FAT-054, SCR-FAT-055 | `UXV-JRN-JRN-FAT-25-S01` `UXV-JRN-JRN-FAT-25-S02` | FVX-G-17 | VX-B5 | PENDING |
| JRN-FAT-26 | الأب | إدارة الاشتراك | SCR-FAT-056, SCR-FAT-057 | `UXV-JRN-JRN-FAT-26-S01` `UXV-JRN-JRN-FAT-26-S02` | — | VX-B7 | PENDING |
| JRN-FAT-27 | الأب | ضبط الإشعارات | SCR-FAT-058 | `UXV-JRN-JRN-FAT-27-S01` | FVX-G-09 | VX-B1 | PENDING |
| JRN-FAT-28 | الأب | الخصوصية والبيانات | SCR-FAT-059, SCR-FAT-060 | `UXV-JRN-JRN-FAT-28-S01` `UXV-JRN-JRN-FAT-28-S02` | FVX-G-03, FVX-G-06 | VX-B2 | PENDING |
| JRN-FAT-29 | الأب | مراجعة أنماط العقل | SCR-FAT-062, SCR-FAT-063, SCR-FAT-064 | `UXV-JRN-JRN-FAT-29-S01` `UXV-JRN-JRN-FAT-29-S02` `UXV-JRN-JRN-FAT-29-S03` | — | VX-B7 | PENDING |
| JRN-FAT-30 | الأب | اللغة والمساعدة | SCR-FAT-061 | `UXV-JRN-JRN-FAT-30-S01` | FVX-S-07 | VX-B3 | OD |
| JRN-FAT-31 | الأب | استقبال تنبيه ذكي والتصرف بحوار | SCR-FAT-065, SCR-FAT-066 | `UXV-JRN-JRN-FAT-31-S01` `UXV-JRN-JRN-FAT-31-S02` | FVX-G-04, FVX-G-02 | VX-B2,VX-B3 | PENDING |
| JRN-FAT-32 | الأب | ضبط الرقابة الذكية والمنصات | SCR-FAT-067, SCR-FAT-068 | `UXV-JRN-JRN-FAT-32-S01` `UXV-JRN-JRN-FAT-32-S02` | FVX-G-04, FVX-G-03 | VX-B2 | PENDING |
| JRN-FAT-33 | الأب | مراجعة تقرير الاستخدام | SCR-FAT-069, SCR-FAT-081 | `UXV-JRN-JRN-FAT-33-S01` `UXV-JRN-JRN-FAT-33-S02` | FVX-G-04 | VX-B2 | PENDING |
| JRN-FAT-34 | الأب | إدارة الدائرة الخارجية | SCR-FAT-070, SCR-FAT-071 | `UXV-JRN-JRN-FAT-34-S01` `UXV-JRN-JRN-FAT-34-S02` | FVX-S-03 | VX-B5 | PENDING |
| JRN-FAT-35 | الأب | متابعة حفظ القرآن | SCR-FAT-072 | `UXV-JRN-JRN-FAT-35-S01` | FVX-G-03, FVX-G-04 | VX-B2 | PENDING |
| JRN-FAT-36 | الأب | قراءة التقرير الأسبوعي بتوصية | SCR-FAT-073 | `UXV-JRN-JRN-FAT-36-S01` | FVX-G-02 | VX-B3 | PENDING |
| JRN-FAT-37 | الأب | سؤال العقل بلغة طبيعية | SCR-FAT-074, SCR-FAT-083 | `UXV-JRN-JRN-FAT-37-S01` `UXV-JRN-JRN-FAT-37-S02` | — | VX-B7 | PENDING |
| JRN-FAT-38 | الأب | استكشاف الميزات القادمة | SCR-FAT-075 | `UXV-JRN-JRN-FAT-38-S01` | FVX-G-08 | VX-B4 | PENDING |
| JRN-FAT-39 | الأب | متابعة السلامة على الطريق | SCR-FAT-077 | `UXV-JRN-JRN-FAT-39-S01` | FVX-C-05 | OD-11 | OD |
| JRN-FAT-40 | الأب | حماية شبكة المنزل | SCR-FAT-078 | `UXV-JRN-JRN-FAT-40-S01` | FVX-G-02 | VX-B3 | PENDING |
| JRN-FAT-41 | الأب | تفويض الوكيل الذكي | SCR-FAT-079, SCR-FAT-080 | `UXV-JRN-JRN-FAT-41-S01` `UXV-JRN-JRN-FAT-41-S02` | FVX-C-04 | VX-B1 | PENDING |
| JRN-FAT-42 | الأب | توزيع المهام بذكاء | SCR-FAT-082 | `UXV-JRN-JRN-FAT-42-S01` | — | VX-B7 | PENDING |
| JRN-FAT-43 | الأب | إطلاق مشروع تعليمي بمراحل | SCR-FAT-084 | `UXV-JRN-JRN-FAT-43-S01` | — | VX-B7 | PENDING |
| JRN-FAT-44 | الأب | ضبط وضع ذكي بلمسة | SCR-FAT-085 | `UXV-JRN-JRN-FAT-44-S01` | FVX-G-04 | VX-B2 | PENDING |
| JRN-FAT-45 | الأب | لحظة الفخر الأسبوعية | SCR-FAT-086 | `UXV-JRN-JRN-FAT-45-S01` | FVX-G-02 | VX-B3 | PENDING |
| JRN-MOT-01 | الأم | الانضمام بدعوة الأب | SCR-SHR-003, SCR-FAT-009 | `UXV-JRN-JRN-MOT-01-S01` `UXV-JRN-JRN-MOT-01-S02` | FVX-S-09 | VX-B5 | PENDING |
| JRN-MOT-02 | الأم | نظرة الصباح | SCR-FAT-010 | `UXV-JRN-JRN-MOT-02-S01` | FVX-S-03 | VX-B5 | PENDING |
| JRN-MOT-03 | الأم | متابعة ابن بعينه | SCR-FAT-012, SCR-FAT-013 | `UXV-JRN-JRN-MOT-03-S01` `UXV-JRN-JRN-MOT-03-S02` | FVX-S-04 | VX-B6 | PENDING |
| JRN-MOT-04 | الأم | التواصل مع الأبناء | SCR-FAT-021, SCR-FAT-022, SCR-FAT-023 | `UXV-JRN-JRN-MOT-04-S01` `UXV-JRN-JRN-MOT-04-S02` `UXV-JRN-JRN-MOT-04-S03` | FVX-S-01 | VX-B6 | OD |
| JRN-MOT-05 | الأم | استقبال بلاغ استغاثة | SCR-FAT-018 | `UXV-JRN-JRN-MOT-05-S01` | FVX-G-06 | VX-B2 | PENDING |
| JRN-MOT-06 | الأم | متابعة موقع ابنها | SCR-FAT-014 | `UXV-JRN-JRN-MOT-06-S01` | FVX-G-08 | VX-B4 | PENDING |
| JRN-MOT-07 | الأم | الموافقة على طلب وقت إضافي | SCR-FAT-033 | `UXV-JRN-JRN-MOT-07-S01` | FVX-S-03 | VX-B5 | PENDING |
| JRN-MOT-08 | الأم | متابعة التقويم والمهام | SCR-FAT-052, SCR-FAT-054 | `UXV-JRN-JRN-MOT-08-S01` `UXV-JRN-JRN-MOT-08-S02` | — | VX-B7 | PENDING |
| JRN-MOT-09 | الأم | استقبال إخطارات التحليلات | SCR-FAT-076 | `UXV-JRN-JRN-MOT-09-S01` | FVX-G-13 | VX-B4 | PENDING |
| JRN-SHR-01 | مشترك | معالجة خطأ أو انقطاع شبكة | SCR-SHR-005, SCR-SHR-006 | `UXV-JRN-JRN-SHR-01-S01` `UXV-JRN-JRN-SHR-01-S02` | — | VX-B7 | PENDING |

## 3. Screen / surface cases (145)

| Screen | System | Role | Journeys | Route | Entry | Exit | Data source | Native | Remote | Case IDs | Evidence anchor |
|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-SHR-001 | ADM:أ | Any | JRN-FAT-01 | `/scr-shr-001` | initial route | SHR-007/SHR-002/SHR-003 | ARB static | — | — | `UXV-SCR-SCR-SHR-001-SIP` · `UXV-SCR-SCR-SHR-001-ST-*` · `UXV-SCR-SCR-SHR-001-VIS` | welcome screen test |
| SCR-SHR-002 | ADM:أ | Any | JRN-FAT-01 | `/scr-shr-002` | SHR-001 | FAT-001 | Identity runtime (local) | — | Account backend | `UXV-SCR-SCR-SHR-002-SIP` · `UXV-SCR-SCR-SHR-002-ST-*` · `UXV-SCR-SCR-SHR-002-VIS` | create_account screen test |
| SCR-SHR-003 | ADM:أ | Any | JRN-FAT-01, JRN-MOT-01 | `/scr-shr-003` | SHR-001/SHR-007 | FAT-010/FAT-009 | Identity/session kernel (credentials ignored) | Biometric NC | Auth backend | `UXV-SCR-SCR-SHR-003-SIP` · `UXV-SCR-SCR-SHR-003-ST-*` · `UXV-SCR-SCR-SHR-003-VIS` | app/test/features/shared_onboarding/login_screen_test.dart |
| SCR-SHR-007 | ADM:أ | Any | JRN-FAT-01 | `/scr-shr-007` | SHR-001 | SHR-003/CHD-001 | RoleController/device mode prefs | — | — | `UXV-SCR-SCR-SHR-007-SIP` · `UXV-SCR-SCR-SHR-007-ST-*` · `UXV-SCR-SCR-SHR-007-VIS` | device_mode screen test |
| SCR-SHR-008 | ADM:أ | Parent | JRN-FAT-01 | `/scr-shr-008` | Settings other shortcut | role home | unbound stage1DeviceUserSwitchRepository | — | — | `UXV-SCR-SCR-SHR-008-SIP` · `UXV-SCR-SCR-SHR-008-ST-*` · `UXV-SCR-SCR-SHR-008-VIS` | device_user_switch screen test |
| SCR-FAT-001 | ADM:أ | Parent | JRN-FAT-01 | `/scr-fat-001` | SHR-002 | FAT-002 | FamilyContextStore (SQLite) | — | — | `UXV-SCR-SCR-FAT-001-SIP` · `UXV-SCR-SCR-FAT-001-ST-*` · `UXV-SCR-SCR-FAT-001-VIS` | create_family screen test |
| SCR-FAT-002 | ADM:أ | Parent | JRN-FAT-02, JRN-FAT-03 | `/scr-fat-002` | FAT-001 | FAT-003/FAT-007/FAT-010 | local wizard + identity | — | — | `UXV-SCR-SCR-FAT-002-SIP` · `UXV-SCR-SCR-FAT-002-ST-*` · `UXV-SCR-SCR-FAT-002-VIS` | setup_wizard screen test |
| SCR-FAT-003 | ADM:ب | Parent | JRN-FAT-02 | `/scr-fat-003` | FAT-002/FAT-012 | FAT-004 | stage1ChildDeviceManagementRepository + roster | — | — | `UXV-SCR-SCR-FAT-003-SIP` · `UXV-SCR-SCR-FAT-003-ST-*` · `UXV-SCR-SCR-FAT-003-VIS` | app/test/features/n01_linking/add_child_screen_test.dart |
| SCR-FAT-004 | ADM:ج | Parent | JRN-FAT-02 | `/scr-fat-004` | FAT-003 | FAT-005/FAT-006 | child device management | Camera on child NC | — | `UXV-SCR-SCR-FAT-004-SIP` · `UXV-SCR-SCR-FAT-004-ST-*` · `UXV-SCR-SCR-FAT-004-VIS` | link_qr screen test |
| SCR-FAT-005 | ADM:أ | Parent | JRN-FAT-02 | `/scr-fat-005` | FAT-004 | FAT-006 | ARB static | OS permission NC | — | `UXV-SCR-SCR-FAT-005-SIP` · `UXV-SCR-SCR-FAT-005-ST-*` · `UXV-SCR-SCR-FAT-005-VIS` | permissions_explainer screen test |
| SCR-FAT-006 | ADM:أ | Parent | JRN-FAT-02 | `/scr-fat-006` | FAT-005 | FAT-010 | roster + decorative map | GPS NC | — | `UXV-SCR-SCR-FAT-006-SIP` · `UXV-SCR-SCR-FAT-006-ST-*` · `UXV-SCR-SCR-FAT-006-VIS` | app/test/features/n01_linking/link_success_screen_test.dart |
| SCR-FAT-007 | ADM:أ | Parent | JRN-FAT-03 | `/scr-fat-007` | FAT-002 | FAT-010 | LOCAL_DEMO | — | — | `UXV-SCR-SCR-FAT-007-SIP` · `UXV-SCR-SCR-FAT-007-ST-*` · `UXV-SCR-SCR-FAT-007-VIS` | trial_mode screen test |
| SCR-FAT-030 | ADM:أ | Parent | JRN-FAT-01 | `/scr-fat-030` | CHD-011 request | Back | stage1ChildModeLockService | — | Push RC | `UXV-SCR-SCR-FAT-030-SIP` · `UXV-SCR-SCR-FAT-030-ST-*` · `UXV-SCR-SCR-FAT-030-VIS` | parent_second_key screen test |
| SCR-CHD-001 | ADM:أ | Child | JRN-CHD-01 | `/scr-chd-001` | SHR-007 | CHD-002 | ARB static | — | — | `UXV-SCR-SCR-CHD-001-SIP` · `UXV-SCR-SCR-CHD-001-ST-*` · `UXV-SCR-SCR-CHD-001-VIS` | child_welcome screen test |
| SCR-CHD-002 | ADM:ج | Child | JRN-CHD-01 | `/scr-chd-002` | CHD-001 | CHD-003 | child device management | Camera NC | — | `UXV-SCR-SCR-CHD-002-SIP` · `UXV-SCR-SCR-CHD-002-ST-*` · `UXV-SCR-SCR-CHD-002-VIS` | child_qr_scan screen test |
| SCR-CHD-003 | ADM:أ | Child | JRN-CHD-01, JRN-CHD-05 | `/scr-chd-003` | CHD-002 | CHD-004 | local consent | — | — | `UXV-SCR-SCR-CHD-003-SIP` · `UXV-SCR-SCR-CHD-003-ST-*` · `UXV-SCR-SCR-CHD-003-VIS` | transparency_consent screen test |
| SCR-CHD-011 | ADM:أ | Child | JRN-CHD-01 | `/scr-chd-011` | Hub:me | FAT-030 request | stage1ChildModeLockService | — | Father approval RC | `UXV-SCR-SCR-CHD-011-SIP` · `UXV-SCR-SCR-CHD-011-ST-*` · `UXV-SCR-SCR-CHD-011-VIS` | child_mode_lock screen test |
| SCR-FAT-008 | ADM:ب | Parent | JRN-FAT-04 | `/scr-fat-008` | Hub:settings/FAT-027 | FAT-027 | stage1AdultInviteRepository | — | Invite delivery RC | `UXV-SCR-SCR-FAT-008-SIP` · `UXV-SCR-SCR-FAT-008-ST-*` · `UXV-SCR-SCR-FAT-008-VIS` | app/test/features/n01_linking/invite_mother_screen_test.dart |
| SCR-FAT-009 | ADM:ب | Mother | JRN-MOT-01 | `/scr-fat-009` | Login invite link; Settings shortcut (wrong) | FAT-010 | identity invite token | — | Backend join RC | `UXV-SCR-SCR-FAT-009-SIP` · `UXV-SCR-SCR-FAT-009-ST-*` · `UXV-SCR-SCR-FAT-009-VIS` | accept_mother_invite_screen_test |
| SCR-FAT-027 | ADM:ب | Parent | JRN-FAT-04 | `/scr-fat-027` | Hub:settings | FAT-008/FAT-031 | identity adults + local children | — | — | `UXV-SCR-SCR-FAT-027-SIP` · `UXV-SCR-SCR-FAT-027-ST-*` · `UXV-SCR-SCR-FAT-027-VIS` | family_members_screen_test |
| SCR-FAT-031 | ADM:ب | Parent | JRN-FAT-04 | `/scr-fat-031` | FAT-027 | FAT-027 | identity mother level | — | — | `UXV-SCR-SCR-FAT-031-SIP` · `UXV-SCR-SCR-FAT-031-ST-*` · `UXV-SCR-SCR-FAT-031-VIS` | mother_permission_level_screen_test |
| SCR-FAT-025 | ADM:ج | Parent | JRN-FAT-13, JRN-FAT-14 | `/scr-fat-025` | Tab settings | FAT-026, hubs, shortcuts | device health seam (LOCAL_DEMO) + identity | Heartbeat NC | — | `UXV-SCR-SCR-FAT-025-SIP` · `UXV-SCR-SCR-FAT-025-ST-*` · `UXV-SCR-SCR-FAT-025-VIS` | settings_hub_screen_test |
| SCR-FAT-026 | ADM:ج | Parent | JRN-FAT-13, JRN-FAT-14 | `/scr-fat-026` | FAT-025 list; FAT-013 (wrong id); Hub:settings (no id) | Back | stage1DeviceHealthSeam (FakeDeviceHealthSeam.demo) | OS settings NC | — | `UXV-SCR-SCR-FAT-026-SIP` · `UXV-SCR-SCR-FAT-026-ST-*` · `UXV-SCR-SCR-FAT-026-VIS` | device_health_detail_screen_test |
| SCR-FAT-061 | ADM:ح | Parent | JRN-FAT-30 | `/scr-fat-061` | Hub:settings | Back | local prefs (locale not applied) | — | Support channel RC | `UXV-SCR-SCR-FAT-061-SIP` · `UXV-SCR-SCR-FAT-061-ST-*` · `UXV-SCR-SCR-FAT-061-VIS` | app/test/features/n12_devices/language_help_screen_test.dart |
| SCR-FAT-010 | ADM:ز | Parent | JRN-FAT-05, JRN-MOT-02 | `/scr-fat-010` | Tab today | FAT-013, pending inbox, quick actions | RosterDayBoardProjectionRepository (famStage1 default) | GPS/battery NC (demo) | — | `UXV-SCR-SCR-FAT-010-SIP` · `UXV-SCR-SCR-FAT-010-ST-*` · `UXV-SCR-SCR-FAT-010-VIS` | app/test/features/n02_day/day_board_screen_test.dart |
| SCR-FAT-011 | ADM:ز | Parent | JRN-FAT-05 | `/scr-fat-011` | Hub:today | Approve → rule | stage1RulesEngineRuleRepository (unbound) + Advisor mock | — | Advisor RC | `UXV-SCR-SCR-FAT-011-SIP` · `UXV-SCR-SCR-FAT-011-ST-*` · `UXV-SCR-SCR-FAT-011-VIS` | advisor_suggestions screen test |
| SCR-FAT-056 | ADM:د | Parent | JRN-FAT-26 | `/scr-fat-056` | Hub:settings | FAT-057 | stage1EntitlementService | — | Billing RC | `UXV-SCR-SCR-FAT-056-SIP` · `UXV-SCR-SCR-FAT-056-ST-*` · `UXV-SCR-SCR-FAT-056-VIS` | plans screen test |
| SCR-FAT-057 | ADM:د | Parent | JRN-FAT-26 | `/scr-fat-057` | FAT-056 | Back | entitlement (local) | — | Billing RC | `UXV-SCR-SCR-FAT-057-SIP` · `UXV-SCR-SCR-FAT-057-ST-*` · `UXV-SCR-SCR-FAT-057-VIS` | manage_subscription screen test |
| SCR-FAT-058 | ADM:هـ | Parent | JRN-FAT-27 | `/scr-fat-058` | Hub:settings | Back | PrefsMisc notification (local KV) | — | FCM RC | `UXV-SCR-SCR-FAT-058-SIP` · `UXV-SCR-SCR-FAT-058-ST-*` · `UXV-SCR-SCR-FAT-058-VIS` | notification_prefs screen test |
| SCR-FAT-059 | ADM:و | Parent | JRN-FAT-28 | `/scr-fat-059` | Hub:settings | FAT-060 | stage1PrivacyCollectionSyncBus + lifecycle | — | AI Gateway RC | `UXV-SCR-SCR-FAT-059-SIP` · `UXV-SCR-SCR-FAT-059-ST-*` · `UXV-SCR-SCR-FAT-059-VIS` | privacy_data screen test |
| SCR-FAT-060 | ADM:و | Parent | JRN-FAT-28 | `/scr-fat-060` | FAT-059/Hub:settings | Back | stage1AuditLogRepository (local) | — | — | `UXV-SCR-SCR-FAT-060-SIP` · `UXV-SCR-SCR-FAT-060-ST-*` · `UXV-SCR-SCR-FAT-060-VIS` | audit_log screen test |
| SCR-FAT-012 | ADM:ب | Parent | JRN-FAT-06, JRN-MOT-03 | `/scr-fat-012` | Tab kids | FAT-013/FAT-003 | ChildrenListLocalRepository (SQLite, LOCAL_DEMO seed) | Telemetry NC (demo) | — | `UXV-SCR-SCR-FAT-012-SIP` · `UXV-SCR-SCR-FAT-012-ST-*` · `UXV-SCR-SCR-FAT-012-VIS` | app/test/features/n02_day/children_list_screen_test.dart |
| SCR-FAT-013 | ADM:ز | Parent | JRN-FAT-06, JRN-MOT-03 | `/scr-fat-013` | FAT-010/FAT-012 | per-child tools, FAT-026 | unbound stage1ChildProfileRepository → roster fallback | GPS NC | — | `UXV-SCR-SCR-FAT-013-SIP` · `UXV-SCR-SCR-FAT-013-ST-*` · `UXV-SCR-SCR-FAT-013-VIS` | app/test/features/n02_day/child_profile_screen_test.dart |
| SCR-FAT-014 | SEC:د | Parent | JRN-FAT-07, JRN-MOT-06 | `/scr-fat-014` | FAT-013; Hub:kids (no child); FAT-010 quick action (no child) | FAT-015/FAT-016 | unbound stage1LocationMapRepository; FamilyId pinned | GPS NC | — | `UXV-SCR-SCR-FAT-014-SIP` · `UXV-SCR-SCR-FAT-014-ST-*` · `UXV-SCR-SCR-FAT-014-VIS` | location_map_screen_test |
| SCR-FAT-015 | SEC:د | Parent | JRN-FAT-07 | `/scr-fat-015` | FAT-014 | Back | unbound stage1LocationHistoryRepository; FamilyId pinned | GPS NC | — | `UXV-SCR-SCR-FAT-015-SIP` · `UXV-SCR-SCR-FAT-015-ST-*` · `UXV-SCR-SCR-FAT-015-VIS` | location_history screen test |
| SCR-FAT-016 | SEC:د | Parent | JRN-FAT-08 | `/scr-fat-016` | FAT-013/Hub:kids | FAT-017 | DomainSafeZonesRepository(fam_stage1) | Geofence NC | — | `UXV-SCR-SCR-FAT-016-SIP` · `UXV-SCR-SCR-FAT-016-ST-*` · `UXV-SCR-SCR-FAT-016-VIS` | safe_zones_screen_test |
| SCR-FAT-017 | SEC:د | Parent | JRN-FAT-08 | `/scr-fat-017` | FAT-016/Hub:kids | FAT-016 | domain safe zones (fam_stage1) | Geofence NC | — | `UXV-SCR-SCR-FAT-017-SIP` · `UXV-SCR-SCR-FAT-017-ST-*` · `UXV-SCR-SCR-FAT-017-VIS` | create_safe_zone_screen_test |
| SCR-FAT-018 | SEC:هـ | Parent | JRN-FAT-09, JRN-MOT-05 | `/scr-fat-018` | SOS fire events; Settings shortcut (no alert) | FAT-023/resolve | SOS final service (local) | Telephony NC | FCM/SMS RC | `UXV-SCR-SCR-FAT-018-SIP` · `UXV-SCR-SCR-FAT-018-ST-*` · `UXV-SCR-SCR-FAT-018-VIS` | sos_alert_screen_test |
| SCR-FAT-028 | SEC:هـ | Parent | JRN-FAT-08, JRN-FAT-09 | `/scr-fat-028` | Hub:settings | Back | stage1SosSettingsStore (rebound) | Telephony NC | SMS RC | `UXV-SCR-SCR-FAT-028-SIP` · `UXV-SCR-SCR-FAT-028-ST-*` · `UXV-SCR-SCR-FAT-028-VIS` | emergency_setup_screen_test |
| SCR-CHD-005 | SEC:هـ | Child | JRN-CHD-03 | `/scr-chd-005` | Child SOS FAB | CHD-006 | SOS fire service | Telephony NC | FCM/SMS RC | `UXV-SCR-SCR-CHD-005-SIP` · `UXV-SCR-SCR-CHD-005-ST-*` · `UXV-SCR-SCR-CHD-005-VIS` | child_sos_button screen test |
| SCR-CHD-006 | SEC:هـ | Child | JRN-CHD-03 | `/scr-chd-006` | CHD-005 | CHD-004 | SOS final service | Telephony/GPS NC | FCM RC | `UXV-SCR-SCR-CHD-006-SIP` · `UXV-SCR-SCR-CHD-006-ST-*` · `UXV-SCR-SCR-CHD-006-VIS` | child_sos_in_progress_screen_test |
| SCR-CHD-024 | COM:ز | Child | JRN-CHD-11 | `/scr-chd-024` | Hub:cfam | Back | child arrival local repository | GPS NC | FCM RC | `UXV-SCR-SCR-CHD-024-SIP` · `UXV-SCR-SCR-CHD-024-ST-*` · `UXV-SCR-SCR-CHD-024-VIS` | child_arrival_screen_test |
| SCR-FAT-077 | SEC:ك | Parent | JRN-FAT-39 | `/scr-fat-077` | deep link only | Back | road safety screen | Motion NC | — | `UXV-SCR-SCR-FAT-077-SIP` · `UXV-SCR-SCR-FAT-077-ST-*` · `UXV-SCR-SCR-FAT-077-VIS` | road_safety_screen_test |
| SCR-FAT-032 | SEC:أ | Parent | JRN-FAT-15 | `/scr-fat-032` | FAT-013 tools | Back | ScreenTime local KV + stage1PolicySyncBus | OS enforce NC | — | `UXV-SCR-SCR-FAT-032-SIP` · `UXV-SCR-SCR-FAT-032-ST-*` · `UXV-SCR-SCR-FAT-032-VIS` | child_screen_time_screen_test; ce_b3_control_spine_test |
| SCR-FAT-033 | SEC:أ | Parent | JRN-FAT-15, JRN-MOT-07 | `/scr-fat-033` | FAT-013 tools; FAT-010 pending fallback | Back | stage1 time request runtime (local) | — | Push RC | `UXV-SCR-SCR-FAT-033-SIP` · `UXV-SCR-SCR-FAT-033-ST-*` · `UXV-SCR-SCR-FAT-033-VIS` | request_inbox screen test |
| SCR-FAT-034 | SEC:ب | Parent | JRN-FAT-16 | `/scr-fat-034` | FAT-013 tools | FAT-035 | stage1ChildAppsRepository (local AC) | OS intercept NC | — | `UXV-SCR-SCR-FAT-034-SIP` · `UXV-SCR-SCR-FAT-034-ST-*` · `UXV-SCR-SCR-FAT-034-VIS` | child_apps_screen_test |
| SCR-FAT-035 | SEC:ب | Parent | JRN-FAT-16 | `/scr-fat-035` | FAT-034 | Back | app control local | OS intercept NC | — | `UXV-SCR-SCR-FAT-035-SIP` · `UXV-SCR-SCR-FAT-035-ST-*` · `UXV-SCR-SCR-FAT-035-VIS` | new_app_approval_screen_test |
| SCR-FAT-036 | SEC:ج | Parent | JRN-FAT-17 | `/scr-fat-036` | FAT-013 tools | Back | web filter local prefs | VPN/DNS NC | — | `UXV-SCR-SCR-FAT-036-SIP` · `UXV-SCR-SCR-FAT-036-ST-*` · `UXV-SCR-SCR-FAT-036-VIS` | app/test/features/n04_web_filter/web_filter_screen_test.dart |
| SCR-FAT-037 | SEC:ط | Parent | JRN-FAT-18 | `/scr-fat-037` | FAT-013 tools; FAT-010 quick action | Back | device lock prefs + stage1AntiTamperAlertBus | Device Admin NC | — | `UXV-SCR-SCR-FAT-037-SIP` · `UXV-SCR-SCR-FAT-037-ST-*` · `UXV-SCR-SCR-FAT-037-VIS` | app/test/features/n05_lock/instant_lock_screen_test.dart |
| SCR-FAT-038 | SEC:ح | Parent | JRN-FAT-19 | `/scr-fat-038` | FAT-013 tools | Back | stage1TamperAlertsRepository | OS signals NC | — | `UXV-SCR-SCR-FAT-038-SIP` · `UXV-SCR-SCR-FAT-038-ST-*` · `UXV-SCR-SCR-FAT-038-VIS` | tamper_alerts screen test |
| SCR-FAT-085 | SEC:أ | Parent | JRN-FAT-44 | `/scr-fat-085` | Hub:kids (no child) | Back | modes runtime + stage1SmartModeActivationBus | OS wake NC | — | `UXV-SCR-SCR-FAT-085-SIP` · `UXV-SCR-SCR-FAT-085-ST-*` · `UXV-SCR-SCR-FAT-085-VIS` | smart_modes_screen_test |
| SCR-CHD-004 | ADM:ز | Child | JRN-CHD-02 | `/scr-chd-004` | Tab myday | CHD-020/CHD-022/CHD-027 | smart mode + policy sync bus (child_demo) | GPS NC | — | `UXV-SCR-SCR-CHD-004-SIP` · `UXV-SCR-SCR-CHD-004-ST-*` · `UXV-SCR-SCR-CHD-004-VIS` | child_day_board screen test |
| SCR-CHD-020 | SEC:أ | Child | JRN-CHD-06 | `/scr-chd-020` | CHD-004/CHD-021 | CHD-004 | stage1ChildTimeRequestRepository | — | Push RC | `UXV-SCR-SCR-CHD-020-SIP` · `UXV-SCR-SCR-CHD-020-ST-*` · `UXV-SCR-SCR-CHD-020-VIS` | child_time_request_screen_test |
| SCR-CHD-021 | SEC:أ | Child | JRN-CHD-06 | `/scr-chd-021` | ST expiry event | CHD-020/CHD-008/CHD-025 | ScreenTime local (demo-child) | OS lock NC | — | `UXV-SCR-SCR-CHD-021-SIP` · `UXV-SCR-SCR-CHD-021-ST-*` · `UXV-SCR-SCR-CHD-021-VIS` | time_expiry screen test |
| SCR-FAT-065 | SEC:و | Parent | JRN-FAT-31 | `/scr-fat-065` | FAT-013 tools | FAT-066 | stage1SmartAlertsRepository (demo-child) | MediaProjection NC | Advisor RC | `UXV-SCR-SCR-FAT-065-SIP` · `UXV-SCR-SCR-FAT-065-ST-*` · `UXV-SCR-SCR-FAT-065-VIS` | smart_alerts_screen_test |
| SCR-FAT-066 | SEC:و | Parent | JRN-FAT-31 | `/scr-fat-066` | FAT-065 | Back | stage1SmartAlertDetailRepository | Capture NC | Advisor RC | `UXV-SCR-SCR-FAT-066-SIP` · `UXV-SCR-SCR-FAT-066-ST-*` · `UXV-SCR-SCR-FAT-066-VIS` | smart_alert_detail_screen_test |
| SCR-FAT-067 | SEC:و | Parent | JRN-FAT-32 | `/scr-fat-067` | FAT-013 tools | Back | stage1DesiredMonitoringSyncBus (child_1) | Capture NC | — | `UXV-SCR-SCR-FAT-067-SIP` · `UXV-SCR-SCR-FAT-067-ST-*` · `UXV-SCR-SCR-FAT-067-VIS` | smart_supervision screen test |
| SCR-FAT-068 | SEC:ز | Parent | JRN-FAT-32 | `/scr-fat-068` | FAT-067/FAT-013 (noHub) | Back | desired monitoring sync bus | Platform NC | — | `UXV-SCR-SCR-FAT-068-SIP` · `UXV-SCR-SCR-FAT-068-ST-*` · `UXV-SCR-SCR-FAT-068-VIS` | platform_monitoring screen test; ce_b5_mock_hardening_test |
| SCR-FAT-069 | SEC:ي | Parent | JRN-FAT-33 | `/scr-fat-069` | FAT-013 tools | FAT-081 | stage1ChildUsageReportRepository | — | Email/PDF RC | `UXV-SCR-SCR-FAT-069-SIP` · `UXV-SCR-SCR-FAT-069-ST-*` · `UXV-SCR-SCR-FAT-069-VIS` | child_usage_report_screen_test |
| SCR-FAT-081 | SEC:ي | Parent | JRN-FAT-33 | `/scr-fat-081` | FAT-069 (noHub) | Back | stage1PeerCompareRepository | — | Email/PDF RC | `UXV-SCR-SCR-FAT-081-SIP` · `UXV-SCR-SCR-FAT-081-ST-*` · `UXV-SCR-SCR-FAT-081-VIS` | peer_compare_screen_test |
| SCR-FAT-073 | AIC:د | Parent | JRN-FAT-36 | `/scr-fat-073` | Hub:today | Approve suggestion | weekly report local (empty-first) | — | Email/PDF + Gateway RC | `UXV-SCR-SCR-FAT-073-SIP` · `UXV-SCR-SCR-FAT-073-ST-*` · `UXV-SCR-SCR-FAT-073-VIS` | weekly_report_screen_test; ce_b2_reports_empty_first_test |
| SCR-FAT-021 | COM:أ | Parent | JRN-FAT-11, JRN-MOT-04 | `/scr-fat-021` | Tab family | FAT-022 | unbound stage1ConversationsListRepository | — | Multi-device RC | `UXV-SCR-SCR-FAT-021-SIP` · `UXV-SCR-SCR-FAT-021-ST-*` · `UXV-SCR-SCR-FAT-021-VIS` | conversations_list_screen_test; ce_b0_chat_delivery_honesty_test |
| SCR-FAT-022 | COM:أ | Parent | JRN-FAT-11, JRN-MOT-04 | `/scr-fat-022` | FAT-021 | FAT-023 | unbound stage1ConversationRepository + ChatAvailability | — | Relay RC | `UXV-SCR-SCR-FAT-022-SIP` · `UXV-SCR-SCR-FAT-022-ST-*` · `UXV-SCR-SCR-FAT-022-VIS` | conversation_screen_test |
| SCR-FAT-023 | COM:ب | Parent | JRN-FAT-12, JRN-MOT-04 | `/scr-fat-023` | FAT-022/FAT-018 | Back | unbound stage1ActiveCallRepository | LiveKit NC | — | `UXV-SCR-SCR-FAT-023-SIP` · `UXV-SCR-SCR-FAT-023-ST-*` · `UXV-SCR-SCR-FAT-023-VIS` | active_call screen test |
| SCR-FAT-024 | COM:ب | Parent | JRN-FAT-12 | `/scr-fat-024` | Hub:family | FAT-023 | unbound stage1CallHistoryRepository | Telephony NC | — | `UXV-SCR-SCR-FAT-024-SIP` · `UXV-SCR-SCR-FAT-024-ST-*` · `UXV-SCR-SCR-FAT-024-VIS` | call_history screen test |
| SCR-CHD-007 | COM:أ | Child | JRN-CHD-04 | `/scr-chd-007` | Tab cfam | CHD-008 | unbound stage1ChildChatsRepository | — | Relay RC | `UXV-SCR-SCR-CHD-007-SIP` · `UXV-SCR-SCR-CHD-007-ST-*` · `UXV-SCR-SCR-CHD-007-VIS` | child_chats_screen_test |
| SCR-CHD-008 | COM:أ | Child | JRN-CHD-04 | `/scr-chd-008` | CHD-007/CHD-021 | CHD-009 | child conversation (in-memory) | — | Relay RC | `UXV-SCR-SCR-CHD-008-SIP` · `UXV-SCR-SCR-CHD-008-ST-*` · `UXV-SCR-SCR-CHD-008-VIS` | child_conversation_screen_test |
| SCR-CHD-009 | COM:ب | Child | JRN-CHD-04 | `/scr-chd-009` | CHD-008 | Back | child active call (unbound) | LiveKit NC | — | `UXV-SCR-SCR-CHD-009-SIP` · `UXV-SCR-SCR-CHD-009-ST-*` · `UXV-SCR-SCR-CHD-009-VIS` | child_active_call screen test |
| SCR-CHD-036 | COM:ب | Child | JRN-CHD-17 | `/scr-chd-036` | CHD-031/CHD-009 | Back | stage1ChildCallPlayRepository | LiveKit NC | — | `UXV-SCR-SCR-CHD-036-SIP` · `UXV-SCR-SCR-CHD-036-ST-*` · `UXV-SCR-SCR-CHD-036-VIS` | child_call_play_screen_test |
| SCR-CHD-023 | COM:ج | Child | JRN-CHD-11 | `/scr-chd-023` | Hub:cfam | Back | stage1ChildMediaShareRepository | Camera/mic/files NC | Chat RC | `UXV-SCR-SCR-CHD-023-SIP` · `UXV-SCR-SCR-CHD-023-ST-*` · `UXV-SCR-SCR-CHD-023-VIS` | child_media_share_screen_test |
| SCR-CHD-037 | COM:ج | Child | JRN-CHD-17 | `/scr-chd-037` | Hub:cfam | Back | stage1ChildStickersBackgroundsRepository | — | Chat apply RC | `UXV-SCR-SCR-CHD-037-SIP` · `UXV-SCR-SCR-CHD-037-ST-*` · `UXV-SCR-SCR-CHD-037-VIS` | child_stickers_backgrounds_screen_test |
| SCR-FAT-070 | COM:د | Parent | JRN-FAT-34 | `/scr-fat-070` | FAT-013/Hub:family (noHub) | FAT-071 | stage1OuterCircleRepository | — | — | `UXV-SCR-SCR-FAT-070-SIP` · `UXV-SCR-SCR-FAT-070-ST-*` · `UXV-SCR-SCR-FAT-070-VIS` | outer_circle_screen_test |
| SCR-FAT-071 | COM:د | Parent | JRN-FAT-34, JRN-CHD-13 | `/scr-fat-071` | FAT-070/child request | Back | stage1FriendApprovalRepository → outer circle | — | — | `UXV-SCR-SCR-FAT-071-SIP` · `UXV-SCR-SCR-FAT-071-ST-*` · `UXV-SCR-SCR-FAT-071-VIS` | friend_approval_screen_test |
| SCR-CHD-030 | COM:د | Child | JRN-CHD-13 | `/scr-chd-030` | CHD-007 (noHub) | Back | stage1ChildFriendsRepository | Telephony NC | Chat RC | `UXV-SCR-SCR-CHD-030-SIP` · `UXV-SCR-SCR-CHD-030-ST-*` · `UXV-SCR-SCR-CHD-030-VIS` | child_friends_screen_test |
| SCR-FAT-052 | COM:هـ | Parent | JRN-FAT-24, JRN-MOT-08 | `/scr-fat-052` | Hub:family | FAT-053 | stage1FamilyCalendarRepository | — | — | `UXV-SCR-SCR-FAT-052-SIP` · `UXV-SCR-SCR-FAT-052-ST-*` · `UXV-SCR-SCR-FAT-052-VIS` | family_calendar screen test |
| SCR-FAT-053 | COM:هـ | Parent | JRN-FAT-24 | `/scr-fat-053` | FAT-052/Hub:family | FAT-052 | stage1AddEventRepository | — | — | `UXV-SCR-SCR-FAT-053-SIP` · `UXV-SCR-SCR-FAT-053-ST-*` · `UXV-SCR-SCR-FAT-053-VIS` | add_event screen test |
| SCR-FAT-054 | COM:و | Parent | JRN-FAT-25, JRN-MOT-08 | `/scr-fat-054` | Hub:family/FAT-010 quick action | FAT-055 | stage1FamilyTasksRepository (local persistence) | — | — | `UXV-SCR-SCR-FAT-054-SIP` · `UXV-SCR-SCR-FAT-054-ST-*` · `UXV-SCR-SCR-FAT-054-VIS` | family_tasks screen test; ce_b1_family_tasks_local_test |
| SCR-FAT-055 | COM:و | Parent | JRN-FAT-25 | `/scr-fat-055` | FAT-054/Hub:family | FAT-054 | create task repository → family tasks | — | — | `UXV-SCR-SCR-FAT-055-SIP` · `UXV-SCR-SCR-FAT-055-ST-*` · `UXV-SCR-SCR-FAT-055-VIS` | create_task screen test |
| SCR-FAT-082 | COM:و | Parent | JRN-FAT-42 | `/scr-fat-082` | Hub:family | FAT-054 | stage1SmartChoreDistributorRepository | — | — | `UXV-SCR-SCR-FAT-082-SIP` · `UXV-SCR-SCR-FAT-082-ST-*` · `UXV-SCR-SCR-FAT-082-VIS` | smart_chore_distributor_screen_test |
| SCR-CHD-022 | COM:و | Child | JRN-CHD-12 | `/scr-chd-022` | Hub:myday | Back | stage1ChildTasksRepository (family-bound) | — | — | `UXV-SCR-SCR-CHD-022-SIP` · `UXV-SCR-SCR-CHD-022-ST-*` · `UXV-SCR-SCR-CHD-022-VIS` | child_tasks_screen_test |
| SCR-FAT-040 | EDU:ط | Parent | JRN-FAT-21 | `/scr-fat-040` | Tab studio | FAT-041/FAT-043 | stage1StudioBoardRepository | — | Advisor RC | `UXV-SCR-SCR-FAT-040-SIP` · `UXV-SCR-SCR-FAT-040-ST-*` · `UXV-SCR-SCR-FAT-040-VIS` | studio_board screen test |
| SCR-FAT-041 | EDU:ط | Parent | JRN-FAT-21 | `/scr-fat-041` | FAT-040/Hub:studio | FAT-042/FAT-043 | screen-local sheet | Camera/voice NC | Generate RC | `UXV-SCR-SCR-FAT-041-SIP` · `UXV-SCR-SCR-FAT-041-ST-*` · `UXV-SCR-SCR-FAT-041-VIS` | add_from_source screen test |
| SCR-FAT-042 | EDU:ط | Parent | JRN-FAT-21 | `/scr-fat-042` | FAT-041/Hub:studio | FAT-043 | staged local | Camera NC | — | `UXV-SCR-SCR-FAT-042-SIP` · `UXV-SCR-SCR-FAT-042-ST-*` · `UXV-SCR-SCR-FAT-042-VIS` | studio_camera_capture screen test |
| SCR-FAT-043 | AIC:د | Parent | JRN-FAT-21 | `/scr-fat-043` | FAT-041/FAT-042 | FAT-044 | stage1GenerationOutputsRepository | — | Advisor RC | `UXV-SCR-SCR-FAT-043-SIP` · `UXV-SCR-SCR-FAT-043-ST-*` · `UXV-SCR-SCR-FAT-043-VIS` | generation_outputs_screen_test |
| SCR-FAT-044 | AIC:د | Parent | JRN-FAT-21 | `/scr-fat-044` | FAT-043 | FAT-045 | stage1PreviewApproveRepository | — | Advisor RC | `UXV-SCR-SCR-FAT-044-SIP` · `UXV-SCR-SCR-FAT-044-ST-*` · `UXV-SCR-SCR-FAT-044-VIS` | preview_approve_screen_test |
| SCR-FAT-045 | EDU:ط | Parent | JRN-FAT-21 | `/scr-fat-045` | FAT-044 | FAT-040 | attribution reward repository | — | — | `UXV-SCR-SCR-FAT-045-SIP` · `UXV-SCR-SCR-FAT-045-ST-*` · `UXV-SCR-SCR-FAT-045-VIS` | attribution_reward screen test |
| SCR-FAT-046 | EDU:ط | Parent | JRN-FAT-22 | `/scr-fat-046` | Hub:studio | Import | community library (local) | — | — | `UXV-SCR-SCR-FAT-046-SIP` · `UXV-SCR-SCR-FAT-046-ST-*` · `UXV-SCR-SCR-FAT-046-VIS` | community_library screen test |
| SCR-FAT-047 | EDU:ط | Parent | JRN-FAT-23 | `/scr-fat-047` | Hub:studio | Back | stage1LearningPathRepository | — | — | `UXV-SCR-SCR-FAT-047-SIP` · `UXV-SCR-SCR-FAT-047-ST-*` · `UXV-SCR-SCR-FAT-047-VIS` | learning_path screen test |
| SCR-FAT-048 | EDU:أ | Parent | JRN-FAT-23 | `/scr-fat-048` | Hub:studio | FAT-049 | stage1MaterialsLessonsRepository | — | Licensed materials RC | `UXV-SCR-SCR-FAT-048-SIP` · `UXV-SCR-SCR-FAT-048-ST-*` · `UXV-SCR-SCR-FAT-048-VIS` | materials_lessons_screen_test |
| SCR-FAT-049 | EDU:ب | Parent | JRN-FAT-23 | `/scr-fat-049` | FAT-048/Hub:studio | FAT-050 | stage1CreateAssignmentRepository (EDU local) | — | — | `UXV-SCR-SCR-FAT-049-SIP` · `UXV-SCR-SCR-FAT-049-ST-*` · `UXV-SCR-SCR-FAT-049-VIS` | create_assignment screen test; dom_edu_local_a_assignment_restart_proof_test |
| SCR-FAT-050 | EDU:ج | Parent | JRN-FAT-23 | `/scr-fat-050` | Hub:studio/FAT-010 pending | Back | learning results (EDU local) | — | — | `UXV-SCR-SCR-FAT-050-SIP` · `UXV-SCR-SCR-FAT-050-ST-*` · `UXV-SCR-SCR-FAT-050-VIS` | results_followup screen test; dom_edu_local_b_result_restart_proof_test |
| SCR-FAT-051 | EDU:ح | Parent | JRN-FAT-23 | `/scr-fat-051` | FAT-013 tools | Back | stage1FocusReportRepository | — | — | `UXV-SCR-SCR-FAT-051-SIP` · `UXV-SCR-SCR-FAT-051-ST-*` · `UXV-SCR-SCR-FAT-051-VIS` | focus_report screen test |
| SCR-FAT-084 | EDU:ط | Parent | JRN-FAT-43 | `/scr-fat-084` | Hub:studio | Back | staged project local | — | — | `UXV-SCR-SCR-FAT-084-SIP` · `UXV-SCR-SCR-FAT-084-ST-*` · `UXV-SCR-SCR-FAT-084-VIS` | staged_project_screen_test |
| SCR-CHD-012 | EDU:أ | Child | JRN-CHD-07 | `/scr-chd-012` | Tab learn | CHD-013..019 | stage1ChildLearnHomeRepository (child_a) | — | Materials RC | `UXV-SCR-SCR-CHD-012-SIP` · `UXV-SCR-SCR-CHD-012-ST-*` · `UXV-SCR-SCR-CHD-012-VIS` | child_learn_home_screen_test |
| SCR-CHD-013 | EDU:أ | Child | JRN-CHD-07 | `/scr-chd-013` | CHD-012 | Back | stage1ChildLessonRepository | — | Materials RC | `UXV-SCR-SCR-CHD-013-SIP` · `UXV-SCR-SCR-CHD-013-ST-*` · `UXV-SCR-SCR-CHD-013-VIS` | child_lesson_screen_test |
| SCR-CHD-014 | EDU:ب | Child | JRN-CHD-07 | `/scr-chd-014` | CHD-012 | CHD-016 | stage1ChildFlashcardsRepository | — | Advisor RC | `UXV-SCR-SCR-CHD-014-SIP` · `UXV-SCR-SCR-CHD-014-ST-*` · `UXV-SCR-SCR-CHD-014-VIS` | child_flashcards_screen_test |
| SCR-CHD-015 | EDU:ج | Child | JRN-CHD-07 | `/scr-chd-015` | CHD-012 | CHD-016 | stage1ChildQuizRepository + results (child_a) | — | — | `UXV-SCR-SCR-CHD-015-SIP` · `UXV-SCR-SCR-CHD-015-ST-*` · `UXV-SCR-SCR-CHD-015-VIS` | child_quiz_screen_test |
| SCR-CHD-016 | EDU:ج | Child | JRN-CHD-07 | `/scr-chd-016` | CHD-015 | CHD-012 | learning result (local) | — | Parent notify RC | `UXV-SCR-SCR-CHD-016-SIP` · `UXV-SCR-SCR-CHD-016-ST-*` · `UXV-SCR-SCR-CHD-016-VIS` | child_result_screen_test |
| SCR-CHD-017 | EDU:د | Child | JRN-CHD-08 | `/scr-chd-017` | CHD-012 | Back | stage1ChildTutorRepository | — | Tutor RC | `UXV-SCR-SCR-CHD-017-SIP` · `UXV-SCR-SCR-CHD-017-ST-*` · `UXV-SCR-SCR-CHD-017-VIS` | child_tutor_screen_test |
| SCR-CHD-018 | EDU:ح | Child | JRN-CHD-09 | `/scr-chd-018` | Hub:learn | CHD-035 | stage1ChildFocusRepository | OS wake NC | — | `UXV-SCR-SCR-CHD-018-SIP` · `UXV-SCR-SCR-CHD-018-ST-*` · `UXV-SCR-SCR-CHD-018-VIS` | child_focus_screen_test |
| SCR-CHD-035 | EDU:ح | Child | JRN-CHD-17 | `/scr-chd-035` | Hub:learn/CHD-018 | Back | focus sounds local repository | Audio playback | — | `UXV-SCR-SCR-CHD-035-SIP` · `UXV-SCR-SCR-CHD-035-ST-*` · `UXV-SCR-SCR-CHD-035-VIS` | child_focus_sounds_screen_test |
| SCR-FAT-072 | EDU:ز | Parent | JRN-FAT-35 | `/scr-fat-072` | FAT-013 tools/FAT-010 quick action | Back | Quran progress via QuranLocalBridge (child_a) | — | Licensed audio RC | `UXV-SCR-SCR-FAT-072-SIP` · `UXV-SCR-SCR-FAT-072-ST-*` · `UXV-SCR-SCR-FAT-072-VIS` | quran_progress_screen_test; ce_b4_quran_local_test |
| SCR-CHD-025 | EDU:ز | Child | JRN-CHD-14 | `/scr-chd-025` | Hub:learn | CHD-026 | stage1ChildQuranWardRepository (child_a) | — | Licensed RC | `UXV-SCR-SCR-CHD-025-SIP` · `UXV-SCR-SCR-CHD-025-ST-*` · `UXV-SCR-SCR-CHD-025-VIS` | child_quran_ward_screen_test; ce_b4_quran_local_test |
| SCR-CHD-026 | EDU:ز | Child | JRN-CHD-14 | `/scr-chd-026` | CHD-025 | Back | stage1ChildMemorizationRepository | — | Licensed RC | `UXV-SCR-SCR-CHD-026-SIP` · `UXV-SCR-SCR-CHD-026-ST-*` · `UXV-SCR-SCR-CHD-026-VIS` | child_memorization_screen_test |
| SCR-CHD-027 | EDU:ز | Child | JRN-CHD-14 | `/scr-chd-027` | Hub:myday; father via FAT-010 pending (wrong) | Back | child athkar repository | — | — | `UXV-SCR-SCR-CHD-027-SIP` · `UXV-SCR-SCR-CHD-027-ST-*` · `UXV-SCR-SCR-CHD-027-VIS` | child_athkar screen test |
| SCR-CHD-032 | EDU:ز | Child | JRN-CHD-18 | `/scr-chd-032` | Hub:learn | Back | stage1ChildSmartTilawahRepository | Mic NC | Licensed + Advisor RC | `UXV-SCR-SCR-CHD-032-SIP` · `UXV-SCR-SCR-CHD-032-ST-*` · `UXV-SCR-SCR-CHD-032-VIS` | child_smart_tilawah_screen_test |
| SCR-CHD-028 | EDU:هـ | Child | JRN-CHD-15 | `/scr-chd-028` | Hub:learn | CHD-029 | smart plan local | — | — | `UXV-SCR-SCR-CHD-028-SIP` · `UXV-SCR-SCR-CHD-028-ST-*` · `UXV-SCR-SCR-CHD-028-VIS` | child_smart_plan_screen_test |
| SCR-CHD-029 | EDU:هـ | Child | JRN-CHD-15 | `/scr-chd-029` | CHD-028/Hub:learn | Back | stage1ChildDailyReviewRepository | — | — | `UXV-SCR-SCR-CHD-029-SIP` · `UXV-SCR-SCR-CHD-029-ST-*` · `UXV-SCR-SCR-CHD-029-VIS` | child_daily_review_screen_test |
| SCR-CHD-019 | EDU:و | Child | JRN-CHD-10 | `/scr-chd-019` | Hub:me | Back | stage1ChildWalletRepository (Minutes) | — | — | `UXV-SCR-SCR-CHD-019-SIP` · `UXV-SCR-SCR-CHD-019-ST-*` · `UXV-SCR-SCR-CHD-019-VIS` | child_wallet_screen_test |
| SCR-CHD-033 | EDU:د | Child | JRN-CHD-17 | `/scr-chd-033` | Hub:learn | Back | stage1ChildInteractiveStoriesRepository | — | Tutor RC | `UXV-SCR-SCR-CHD-033-SIP` · `UXV-SCR-SCR-CHD-033-ST-*` · `UXV-SCR-SCR-CHD-033-VIS` | child_interactive_stories_screen_test |
| SCR-CHD-034 | EDU:و | Child | JRN-CHD-17 | `/scr-chd-034` | Hub:me | Back | stage1ChildFamilyChallengesRepository | — | — | `UXV-SCR-SCR-CHD-034-SIP` · `UXV-SCR-SCR-CHD-034-ST-*` · `UXV-SCR-SCR-CHD-034-VIS` | child_family_challenges_screen_test |
| SCR-CHD-031 | COM:ب | Child | JRN-CHD-16 | `/scr-chd-031` | Hub:me | live fun screens | local catalog | LiveKit NC | Tutor RC | `UXV-SCR-SCR-CHD-031-SIP` · `UXV-SCR-SCR-CHD-031-ST-*` · `UXV-SCR-SCR-CHD-031-VIS` | child_coming_gifts_screen_test |
| SCR-FAT-019 | AIC:أ | Parent | JRN-FAT-10 | `/scr-fat-019` | Hub:today | FAT-020 | unbound stage1AlertsHubRepository | — | — | `UXV-SCR-SCR-FAT-019-SIP` · `UXV-SCR-SCR-FAT-019-ST-*` · `UXV-SCR-SCR-FAT-019-VIS` | alerts_hub screen test |
| SCR-FAT-020 | AIC:أ | Parent | JRN-FAT-10 | `/scr-fat-020` | FAT-019 (noHub) | Back | unbound stage1AlertDetailRepository | — | — | `UXV-SCR-SCR-FAT-020-SIP` · `UXV-SCR-SCR-FAT-020-ST-*` · `UXV-SCR-SCR-FAT-020-VIS` | alert_detail screen test |
| SCR-FAT-029 | AIC:أ | Parent | JRN-FAT-10 | `/scr-fat-029` | Hub:settings | Back | local stage flags | — | Gateway RC | `UXV-SCR-SCR-FAT-029-SIP` · `UXV-SCR-SCR-FAT-029-ST-*` · `UXV-SCR-SCR-FAT-029-VIS` | brain_control screen test |
| SCR-FAT-062 | AIC:ب | Parent | JRN-FAT-29 | `/scr-fat-062` | Hub:today | FAT-063 | Insights mock (local) | — | Insights RC | `UXV-SCR-SCR-FAT-062-SIP` · `UXV-SCR-SCR-FAT-062-ST-*` · `UXV-SCR-SCR-FAT-062-VIS` | family_patterns screen test |
| SCR-FAT-063 | AIC:ج | Parent | JRN-FAT-29 | `/scr-fat-063` | FAT-062 (noHub) | Back | stage1IndividualTimelineRepository | — | Knowledge RC | `UXV-SCR-SCR-FAT-063-SIP` · `UXV-SCR-SCR-FAT-063-ST-*` · `UXV-SCR-SCR-FAT-063-VIS` | individual_timeline screen test |
| SCR-FAT-064 | AIC:ج | Parent | JRN-FAT-29 | `/scr-fat-064` | FAT-062 (noHub) | Back | knowledge mock | — | Knowledge RC | `UXV-SCR-SCR-FAT-064-SIP` · `UXV-SCR-SCR-FAT-064-ST-*` · `UXV-SCR-SCR-FAT-064-VIS` | knowledge_maps screen test |
| SCR-FAT-074 | AIC:هـ | Parent | JRN-FAT-37 | `/scr-fat-074` | AI FAB | FAT-083 | AdvisorRepository mock | — | Assistant RC | `UXV-SCR-SCR-FAT-074-SIP` · `UXV-SCR-SCR-FAT-074-ST-*` · `UXV-SCR-SCR-FAT-074-VIS` | family_advisor_hub_screen_test |
| SCR-FAT-083 | AIC:هـ | Parent | JRN-FAT-37 | `/scr-fat-083` | FAT-074 (noHub) | Back | Advisor mock | Mic NC | Assistant RC | `UXV-SCR-SCR-FAT-083-SIP` · `UXV-SCR-SCR-FAT-083-ST-*` · `UXV-SCR-SCR-FAT-083-VIS` | advisor_voice_screen_test |
| SCR-FAT-076 | AIC:هـ | Mother | JRN-MOT-09 | `/scr-fat-076` | Hub:today | Back | stage1MotherAiFeedRepository | — | Assistant RC | `UXV-SCR-SCR-FAT-076-SIP` · `UXV-SCR-SCR-FAT-076-ST-*` · `UXV-SCR-SCR-FAT-076-VIS` | mother_ai_feed_screen_test |
| SCR-FAT-079 | AIC:و | Parent | JRN-FAT-41 | `/scr-fat-079` | Hub:today | FAT-080 | stage1RulesEngineRuleRepository (unbound) | — | Agent RC | `UXV-SCR-SCR-FAT-079-SIP` · `UXV-SCR-SCR-FAT-079-ST-*` · `UXV-SCR-SCR-FAT-079-VIS` | my_advisor screen test |
| SCR-FAT-080 | AIC:و | Parent | JRN-FAT-41 | `/scr-fat-080` | FAT-079 (noHub) | Back | stage1AgentActionLogRepository | — | Agent RC | `UXV-SCR-SCR-FAT-080-SIP` · `UXV-SCR-SCR-FAT-080-ST-*` · `UXV-SCR-SCR-FAT-080-VIS` | agent_action_log_screen_test |
| SCR-FAT-075 | AIC:د | Parent | JRN-FAT-38 | `/scr-fat-075` | Hub:settings | live screens | local catalog | VPN/DNS NC | Gateways RC | `UXV-SCR-SCR-FAT-075-SIP` · `UXV-SCR-SCR-FAT-075-ST-*` · `UXV-SCR-SCR-FAT-075-VIS` | coming_soon screen test |
| SCR-FAT-078 | SEC:ج | Parent | JRN-FAT-40 | `/scr-fat-078` | Hub:settings | Back | stage1HomeRouterFilterRepository | DNS NC | — | `UXV-SCR-SCR-FAT-078-SIP` · `UXV-SCR-SCR-FAT-078-ST-*` · `UXV-SCR-SCR-FAT-078-VIS` | home_router_filter_screen_test |
| SCR-FAT-086 | AIC:د | Parent | JRN-FAT-45 | `/scr-fat-086` | Hub:today | Back | stage1FamilyMomentsRepository | — | Chat share RC | `UXV-SCR-SCR-FAT-086-SIP` · `UXV-SCR-SCR-FAT-086-ST-*` · `UXV-SCR-SCR-FAT-086-VIS` | family_moments_screen_test |
| SCR-CHD-010 | ADM:و | Child | JRN-CHD-05 | `/scr-chd-010` | Tab me | Back | privacy collection (demo-child) | — | — | `UXV-SCR-SCR-CHD-010-SIP` · `UXV-SCR-SCR-CHD-010-ST-*` · `UXV-SCR-SCR-CHD-010-VIS` | what_is_collected screen test |
| SCR-SHR-005 | ADM:ج | Any | JRN-SHR-01 | `/scr-shr-005` | error event | Retry | AppErrorState | — | — | `UXV-SCR-SCR-SHR-005-SIP` · `UXV-SCR-SCR-SHR-005-ST-*` · `UXV-SCR-SCR-SHR-005-VIS` | network_error_template_screen_test |
| SCR-SHR-006 | ADM:ج | Any | JRN-SHR-01 | `/scr-shr-006` | empty event | CTA | AppEmptyState | — | — | `UXV-SCR-SCR-SHR-006-SIP` · `UXV-SCR-SCR-SHR-006-ST-*` · `UXV-SCR-SCR-SHR-006-VIS` | empty_state_template_screen_test |
| SCR-FAT-039 | SEC:ل | None | JRN-FAT-20 | `/scr-fat-039` | tombstone redirect | FAT-085 | None | — | — | `UXV-SCR-SCR-FAT-039-SIP` · `UXV-SCR-SCR-FAT-039-ST-*` · `UXV-SCR-SCR-FAT-039-VIS` | router_routes_test |
| sys3:session-restore | SYS3/DEV | Any | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:session-restore-SIP` · `UXV-SCR-sys3:session-restore-VIS` | — |
| sys3:session-expired | SYS3/DEV | Any | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:session-expired-SIP` · `UXV-SCR-sys3:session-expired-VIS` | — |
| sys3:logout | SYS3/DEV | Any | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:logout-SIP` · `UXV-SCR-sys3:logout-VIS` | — |
| sys3:recovery | SYS3/DEV | Any | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:recovery-SIP` · `UXV-SCR-sys3:recovery-VIS` | — |
| sys3:deactivate | SYS3/DEV | Owner | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:deactivate-SIP` · `UXV-SCR-sys3:deactivate-VIS` | — |
| sys3:family-select | SYS3/DEV | Parent | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:family-select-SIP` · `UXV-SCR-sys3:family-select-VIS` | — |
| sys3:remove-adult | SYS3/DEV | Owner | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:remove-adult-SIP` · `UXV-SCR-sys3:remove-adult-VIS` | — |
| sys3:ownership-transfer | SYS3/DEV | Owner | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:ownership-transfer-SIP` · `UXV-SCR-sys3:ownership-transfer-VIS` | — |
| sys3:leave-family | SYS3/DEV | Non-owner adult | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:leave-family-SIP` · `UXV-SCR-sys3:leave-family-VIS` | — |
| sys3:invite-status | SYS3/DEV | Father | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:invite-status-SIP` · `UXV-SCR-sys3:invite-status-VIS` | — |
| sys3:adult-sessions | SYS3/DEV | Parent | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:adult-sessions-SIP` · `UXV-SCR-sys3:adult-sessions-VIS` | — |
| sys3:child-sessions | SYS3/DEV | Parent | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:child-sessions-SIP` · `UXV-SCR-sys3:child-sessions-VIS` | — |
| sys3:remote-end | SYS3/DEV | Parent | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:remote-end-SIP` · `UXV-SCR-sys3:remote-end-VIS` | — |
| sys3:revoke-confirm | SYS3/DEV | Parent | — | sys3 | — | — | local | — | — | `UXV-SCR-sys3:revoke-confirm-SIP` · `UXV-SCR-sys3:revoke-confirm-VIS` | — |
| dev:/gallery | SYS3/DEV | dev | — | sys3 | — | — | local | — | — | `UXV-SCR-dev:/gallery-SIP` · `UXV-SCR-dev:/gallery-VIS` | — |

## 4. Lifecycle cases

| Case ID | Flow | Anchor |
|---|---|---|
| `UXV-LC-01` | First / cold launch | SHR-001 or session restore |
| `UXV-LC-02` | Fresh install empty local DB | empty family / empty chat seed rules |
| `UXV-LC-03` | Existing local data relaunch | roster/chat/tasks persist |
| `UXV-LC-04` | Authenticated session active | FAT-010 / CHD-004 |
| `UXV-LC-05` | Session expired / recovery | sys3 session-expired / recovery |
| `UXV-LC-06` | Role resolution father | Today FAT-010 |
| `UXV-LC-07` | Role resolution mother | Today + level-limited controls |
| `UXV-LC-08` | Role resolution child | My Day CHD-004 |
| `UXV-LC-09` | Family select / switch | sys3 family-select if multi |
| `UXV-LC-10` | Child select / switch | profile / SHR-008 / active child |
| `UXV-LC-11` | Language AR→EN | FAT-061 + shell labels |
| `UXV-LC-12` | Language EN→AR | FAT-061 + RTL |
| `UXV-LC-13` | RTL→LTR transition | shell FABs/chevrons |
| `UXV-LC-14` | LTR→RTL transition | shell FABs/chevrons |
| `UXV-LC-15` | Offline start | honest offline / local |
| `UXV-LC-16` | Online→offline during use | no fake sync success |
| `UXV-LC-17` | Offline→online | no false delivered claims |
| `UXV-LC-18` | Kill→relaunch persistence | VX-B6 D6 + Program §13.5 |
| `UXV-LC-19` | Back chain drill-down | push not go (G-17) |
| `UXV-LC-20` | Repeated open/close sheets | dialogs dismiss clean |
| `UXV-LC-21` | Empty family/data states | empty components |
| `UXV-LC-22` | Populated states | lists render |
| `UXV-LC-23` | Loading states | AppLoadingState |
| `UXV-LC-24` | Error states | AppErrorState + retry |
| `UXV-LC-25` | Native-closed honesty | BN classification |
| `UXV-LC-26` | Remote-closed honesty | BR classification |
| `UXV-LC-27` | Local-only honesty | glossary OD-02 |

## 5. Device / variant cases (D-FINAL §13)

- `UXV-DEV-A-01` Device A ≤360 · Cold start welcome→login→Today
- `UXV-DEV-B-01` Device B normal · Cold start welcome→login→Today
- `UXV-DEV-A-02` Device A ≤360 · Tabs + Back
- `UXV-DEV-B-02` Device B normal · Tabs + Back
- `UXV-DEV-A-03` Device A ≤360 · Keyboard forms
- `UXV-DEV-B-03` Device B normal · Keyboard forms
- `UXV-DEV-A-04` Device A ≤360 · Touch targets
- `UXV-DEV-B-04` Device B normal · Touch targets
- `UXV-DEV-A-05` Device A ≤360 · Kill relaunch
- `UXV-DEV-B-05` Device B normal · Kill relaunch
- `UXV-DEV-A-06` Device A ≤360 · Role switch SHR-008
- `UXV-DEV-B-06` Device B normal · Role switch SHR-008
- `UXV-DEV-A-07` Device A ≤360 · SOS actor
- `UXV-DEV-B-07` Device B normal · SOS actor
- `UXV-DEV-A-08` Device A ≤360 · Contrast outdoors
- `UXV-DEV-B-08` Device B normal · Contrast outdoors
- `UXV-DEV-A-09` Device A ≤360 · Small vs normal layout
- `UXV-DEV-B-09` Device B normal · Small vs normal layout
- `UXV-DEV-AR` Arabic RTL pack on system homes
- `UXV-DEV-EN` English LTR pack on system homes
- `UXV-DEV-F10` Font scale 1.0
- `UXV-DEV-F13` Font scale 1.3

## 6. Cross-screen consistency cases

| Case ID | Check |
|---|---|
| `UXV-X-01` | Active child same on profile tools vs child My Day |
| `UXV-X-02` | Family scope same on Today vs Kids vs Chat |
| `UXV-X-03` | Child display name after Add Child on Kids/Today/profile |
| `UXV-X-04` | Family chat message father→child after relaunch |
| `UXV-X-05` | Time request approve reflects on child minutes |
| `UXV-X-06` | Language setting reflected on hub labels AR/EN |
| `UXV-X-07` | SOS subject child matches alert screen |
| `UXV-X-08` | Safe zone saved appears on zones list |
| `UXV-X-09` | Alerts hub reflects SOS/tamper/time/app/friend local producers |
| `UXV-X-10` | Device health from profile uses linked device id |

## 7. Capability honesty cases

| Case ID | Check |
|---|---|
| `UXV-HON-01` | Fingerprint never fake-success (C-01) |
| `UXV-HON-02` | Login local-account honesty line (C-02) |
| `UXV-HON-03` | Chat multi-device delivery not claimed (S-01/OD-09) |
| `UXV-HON-04` | GPS/battery demo bannered LOCAL_DEMO |
| `UXV-HON-05` | Native OS lock/filter closed honest |
| `UXV-HON-06` | AI suggests never auto-executes |
| `UXV-HON-07` | No MOCK/Native/Remote jargon in AR user strings (G-02) |
| `UXV-HON-08` | Billing never gates SOS/chat/location |
| `UXV-HON-09` | Empty SOS screen designed empty not crash (C-08) |
| `UXV-HON-10` | Settings no dead invite/SOS shortcuts (S-09/OD-10) |

## 8. Finding remapping (FVX → UXV-FD)

| Finding | Verification case |
|---|---|
| FVX-C-01 | `UXV-FD-FVX-C-01` |
| FVX-C-02 | `UXV-FD-FVX-C-02` |
| FVX-C-03 | `UXV-FD-FVX-C-03` |
| FVX-C-04 | `UXV-FD-FVX-C-04` |
| FVX-C-05 | `UXV-FD-FVX-C-05` |
| FVX-C-06 | `UXV-FD-FVX-C-06` |
| FVX-C-07 | `UXV-FD-FVX-C-07` |
| FVX-C-08 | `UXV-FD-FVX-C-08` |
| FVX-G-01 | `UXV-FD-FVX-G-01` |
| FVX-G-02 | `UXV-FD-FVX-G-02` |
| FVX-G-03 | `UXV-FD-FVX-G-03` |
| FVX-G-04 | `UXV-FD-FVX-G-04` |
| FVX-G-05 | `UXV-FD-FVX-G-05` |
| FVX-G-06 | `UXV-FD-FVX-G-06` |
| FVX-G-08 | `UXV-FD-FVX-G-08` |
| FVX-G-09 | `UXV-FD-FVX-G-09` |
| FVX-G-10 | `UXV-FD-FVX-G-10` |
| FVX-G-11 | `UXV-FD-FVX-G-11` |
| FVX-G-12 | `UXV-FD-FVX-G-12` |
| FVX-G-13 | `UXV-FD-FVX-G-13` |
| FVX-G-15 | `UXV-FD-FVX-G-15` |
| FVX-G-17 | `UXV-FD-FVX-G-17` |
| FVX-S-01 | `UXV-FD-FVX-S-01` |
| FVX-S-02 | `UXV-FD-FVX-S-02` |
| FVX-S-03 | `UXV-FD-FVX-S-03` |
| FVX-S-04 | `UXV-FD-FVX-S-04` |
| FVX-S-05 | `UXV-FD-FVX-S-05` |
| FVX-S-06 | `UXV-FD-FVX-S-06` |
| FVX-S-07 | `UXV-FD-FVX-S-07` |
| FVX-S-08 | `UXV-FD-FVX-S-08` |
| FVX-S-09 | `UXV-FD-FVX-S-09` |
| N-01 | `UXV-FD-N-01` |
| N-16 | `UXV-FD-N-16` |
| local-reality | `UXV-FD-local-reality` |

## 9. Screen Interaction Protocol (SIP)

For every `UXV-SCR-*-SIP`, apply Plan §SIP to **only controls actually visible** on that screen. Record each as `UXV-SCR-<id>-CTL-<n>` in the Evidence Template. Do not invent controls.
