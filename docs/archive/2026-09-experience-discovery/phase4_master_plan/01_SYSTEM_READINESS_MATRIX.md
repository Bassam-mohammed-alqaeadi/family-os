# PHASE 4 — System Readiness Matrix (01)

**Date:** 2026-09-25  
**Coverage:** all 42 systems + FS-008 virtual row  
**READY = future-wave candidacy only (Phase 5+ Owner gate required)**

## Schema

`system_key` · `name` · `services` · `owner` · `plane` · `wave` · `readiness` · `notes`

## 42-system matrix

| system_key | name | services | owner | plane | wave | readiness | notes |
|---|---|---:|---|---|---|---|---|
| `ADM:أ` | الإعداد الأول | 7 | Identity | LOCAL_DEEPEN | W0 | READY FOR IMPLEMENTATION | Identity already Local; deepen restart honesty / RBAC tests |
| `ADM:ب` | العائلة والأعضاء | 6 | Identity | LOCAL_DEEPEN | W0 | READY FOR IMPLEMENTATION | Roster Local seeded; deepen empty/error states |
| `ADM:ج` | الأجهزة | 5 | ADM devices | LOCAL_CONVERT | W1 | READY FOR IMPLEMENTATION | Device registry prefs → durable local |
| `ADM:ح` | الإعدادات والدعم | 3 | ADM settings | LOCAL_CONVERT | W1 | READY FOR IMPLEMENTATION | Settings/support local prefs |
| `ADM:د` | الاشتراك والفوترة | 6 | Billing | REM_GATE | W7 | BLOCKED BY REMOTE | Subscription/billing cloud |
| `ADM:ز` | لوحة اليوم | 4 | Day board | LOCAL_CONVERT | W1 | READY FOR IMPLEMENTATION | Day board bind to Identity roster (no mock numerals) |
| `ADM:هـ` | الإشعارات | 5 | Prefs-misc | LOCAL_DEEPEN | W1 | READY FOR IMPLEMENTATION | Notification prefs Local exist |
| `ADM:و` | الخصوصية والبيانات | 6 | Privacy/Audit | LOCAL_DEEPEN | W1 | READY FOR IMPLEMENTATION | Privacy + audit Local exist |
| `AIC:أ` | محرك الرصد | 6 | FS-007 | LOCAL_DEEPEN | W3 | READY FOR IMPLEMENTATION | FS-007 local classify exists; cloud separate |
| `AIC:ب` | محرك الأنماط والشذوذ | 5 | Insights | REM_GATE | W7 | BLOCKED BY REMOTE | Insights cloud |
| `AIC:ج` | مخزن المعرفة العائلية | 6 | Knowledge | REM_GATE | W7 | BLOCKED BY REMOTE | Knowledge store cloud |
| `AIC:د` | المستشار والتقارير | 6 | Advisor/Reports | POLICY_GATE | W4 | BLOCKED BY POLICY | Advisor mock + FS-009 weekly host; PDF/REP + Gateway |
| `AIC:هـ` | المساعد التفاعلي | 6 | Assistant | REM_GATE | W7 | BLOCKED BY REMOTE | Interactive assistant Gateway |
| `AIC:و` | الوكيل المفوَّض | 5 | Agent | REM_GATE | W7 | BLOCKED BY REMOTE | Delegated agent suggest-only Gateway |
| `COM:أ` | المحادثات | 9 | FS-010 | POLICY_GATE | W4 | BLOCKED BY POLICY | FS-010 Local durable store CONVERT candidate; CHAT-C1/C2 block edit/delete audit depth |
| `COM:ب` | المكالمات | 6 | Calls | NAT_GATE | W5 | BLOCKED BY NATIVE | Calls require telephony native |
| `COM:ج` | الوسائط والملفات | 5 | Media | DEFER | W6+ | DEFERRED | Media — no FS pack; defer after chat Local |
| `COM:د` | دائرة الاتصال الآمنة | 5 | Safe circle | DEFER | W6+ | DEFERRED | Safe circle — no FS pack |
| `COM:ز` | الموقع في التواصل | 3 | Loc-in-COM | DEFER | W6+ | DEFERRED | Location-in-comms; needs FS-001 facts |
| `COM:هـ` | التقويم العائلي | 6 | Calendar | DEFER | W6+ | DEFERRED | Family calendar — no FS pack |
| `COM:و` | المهام والمسؤوليات | 5 | Tasks | DEFER | W6+ | DEFERRED | Tasks — no FS pack |
| `EDU:أ` | المواد والدروس | 6 | EDU materials | REM_GATE | W7 | BLOCKED BY REMOTE | Materials / licensed content boundary |
| `EDU:ب` | الواجبات | 6 | EDU assign | LOCAL_DEEPEN | W3 | READY FOR IMPLEMENTATION | Assignments Local persist shipped |
| `EDU:ج` | الاختبارات والتقييم | 6 | EDU assess | LOCAL_CONVERT | W3 | READY FOR IMPLEMENTATION | Assessments local deepen |
| `EDU:ح` | التركيز وبيئة الدراسة | 6 | EDU focus | LOCAL_CONVERT | W3 | READY FOR IMPLEMENTATION | Focus environment local |
| `EDU:د` | المعلم الذكي | 6 | Tutor | REM_GATE | W7 | BLOCKED BY REMOTE | TutorRepository — AI Gateway Rule 26 |
| `EDU:ز` | القرآن والتربية الإسلامية | 5 | Quran | REM_GATE | W7 | BLOCKED BY REMOTE | Quran licensed source |
| `EDU:ط` | استوديو الأب | 18 | Studio | LOCAL_CONVERT | W3 | READY FOR IMPLEMENTATION | Father studio local |
| `EDU:هـ` | التعلّم التكيفي | 5 | EDU adaptive | LOCAL_CONVERT | W3 | READY FOR IMPLEMENTATION | Adaptive local |
| `EDU:و` | التحفيز والمكافآت | 7 | EDU rewards | LOCAL_DEEPEN | W3 | READY FOR IMPLEMENTATION | Rewards via PolicyEngine.earn only |
| `SEC:أ` | إدارة وقت الشاشة | 7 | Screen Time | LOCAL_DEEPEN | W2 | READY FOR IMPLEMENTATION | ST Local persist shipped; deepen loop closure + exemptions |
| `SEC:ب` | التحكم بالتطبيقات | 6 | FS-003 | LOCAL_DEEPEN | W2 | READY FOR IMPLEMENTATION | AC Domain Local; OS intercept remains NAT |
| `SEC:ج` | فلترة الإنترنت | 5 | FS-002 | LOCAL_DEEPEN | W2 | READY FOR IMPLEMENTATION | WF Domain Local; VPN remains NAT |
| `SEC:ح` | مقاومة التحايل | 5 | Alerts hub | LOCAL_CONVERT | W3 | READY FOR IMPLEMENTATION | Anti-cheat / alerts hub local |
| `SEC:د` | الموقع والمناطق الآمنة | 7 | FS-001 | LOCAL_DEEPEN | W2 | READY FOR IMPLEMENTATION | Location Domain Local; GPS remains NAT; residual host-bind honesty |
| `SEC:ز` | مراقبة منصات التواصل | 4 | Prefs-misc | LOCAL_CONVERT | W3 | READY FOR IMPLEMENTATION | Platform monitoring / anti-tamper prefs deepen |
| `SEC:ط` | القفل الفوري | 3 | Device lock | LOCAL_DEEPEN | W3 | READY FOR IMPLEMENTATION | Instant lock prefs Local; OS lock NAT |
| `SEC:ك` | السلامة الحركية والقيادة | 3 | Road safety | OOS | — | OUT OF SCOPE | Road safety — no FS pack; consumes location later |
| `SEC:ل` | وضع المدرسة | 3 | FS-005 | LOCAL_DEEPEN | W2 | READY FOR IMPLEMENTATION | Modes Local; OS wake NAT |
| `SEC:هـ` | الطوارئ والاستغاثة | 6 | FS-006 | LOCAL_DEEPEN | W2 | READY FOR IMPLEMENTATION | SOS Local; FCM/SMS remains REM/NAT |
| `SEC:و` | مراقبة المحتوى الذكية | 6 | FS-004 | LOCAL_DEEPEN | W2 | READY FOR IMPLEMENTATION | SC Domain Local; capture pipeline NAT |
| `SEC:ي` | التقارير والتحليلات | 5 | FS-009 | POLICY_GATE | W4 | BLOCKED BY POLICY | FS-009 local aggregator possible; PDF mandate REP-C1 blocks PDF plane |

## FS-008 (not in CSV)

| virtual | owner | plane | wave | readiness | notes |
|---|---|---|---|---|---|
| S-PAR-030 / One-Way Audio | FS-008 | POLICY_GATE (+ later NAT) | W4 | BLOCKED BY POLICY | AUD-C* + S-PAR-030 registry + no SCR/JRN; mic NAT |

## Rollup

| readiness | systems (of 42) |
|-----------|----------------:|
| READY FOR IMPLEMENTATION | 24 |
| BLOCKED BY POLICY | 3 |
| BLOCKED BY NATIVE | 1 |
| BLOCKED BY REMOTE | 8 |
| DEFERRED | 5 |
| OUT OF SCOPE | 1 |

Plus FS-008 virtual: BLOCKED BY POLICY.
