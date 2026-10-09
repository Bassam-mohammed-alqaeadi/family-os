# PHASE 3 — System Map (01)

**Date:** 2026-09-25  
**Source:** `services.csv` → 42 unique `(domain, subsystem_letter)`  
**Counts:** 42 systems · 240 services  

## Schema

`system_key` · `subsystem_name` · `service_count` · `service_ids` · `fs_or_domain` · `owner_fact` · `class`

## Full 42-system map

| system_key | subsystem_name | service_count | service_ids | fs_or_domain | owner_fact | class |
|---|---|---:|---|---|---|---|
| `ADM:أ` | الإعداد الأول | 7 | `S-ADM-001, S-ADM-002, S-ADM-003, S-ADM-004, S-ADM-005, S-ADM-006, S-ADM-007` | Identity / onboarding Domain | Family context + session | VERIFIED EXISTING |
| `ADM:ب` | العائلة والأعضاء | 6 | `S-ADM-008, S-ADM-009, S-ADM-010, S-ADM-011, S-ADM-012, S-ADM-013` | Identity / roster Domain | Children roster seed | VERIFIED EXISTING |
| `ADM:ج` | الأجهزة | 5 | `S-ADM-014, S-ADM-015, S-ADM-016, S-ADM-017, S-ADM-018` | Domain ADM devices | Device registry prefs | VERIFIED EXISTING |
| `ADM:ح` | الإعدادات والدعم | 3 | `S-ADM-040, S-ADM-041, S-ADM-042` | Domain ADM settings/support | Prefs/support | VERIFIED EXISTING |
| `ADM:د` | الاشتراك والفوترة | 6 | `S-ADM-019, S-ADM-020, S-ADM-021, S-ADM-022, S-ADM-023, S-ADM-024` | Domain ADM subscription | Owner-only billing surfaces | REMOTE DEPENDENCY |
| `ADM:ز` | لوحة اليوم | 4 | `S-ADM-036, S-ADM-037, S-ADM-038, S-ADM-039` | Domain ADM day board | Children list / day overview | VERIFIED EXISTING |
| `ADM:هـ` | الإشعارات | 5 | `S-ADM-025, S-ADM-026, S-ADM-027, S-ADM-028, S-ADM-029` | Domain ADM notifications prefs | Prefs-misc notification | VERIFIED EXISTING |
| `ADM:و` | الخصوصية والبيانات | 6 | `S-ADM-030, S-ADM-031, S-ADM-032, S-ADM-033, S-ADM-034, S-ADM-035` | Domain ADM privacy + audit | Audit append-only; privacy collection | VERIFIED EXISTING |
| `AIC:أ` | محرك الرصد | 6 | `S-AIC-001, S-AIC-002, S-AIC-003, S-AIC-004, S-AIC-005, S-AIC-006` | FS-007 Offline AI Safety (local classify) + Rule 26 cloud | Local classifier vs Advisor Gateway | VERIFIED EXISTING |
| `AIC:ب` | محرك الأنماط والشذوذ | 5 | `S-AIC-007, S-AIC-008, S-AIC-009, S-AIC-010, S-AIC-011` | Rule 26 Insights (cloud) | Mock until AI Gateway | REMOTE DEPENDENCY |
| `AIC:ج` | مخزن المعرفة العائلية | 6 | `S-AIC-012, S-AIC-013, S-AIC-014, S-AIC-015, S-AIC-016, S-AIC-017` | Rule 26 knowledge store (cloud) | Mock until AI Gateway | REMOTE DEPENDENCY |
| `AIC:د` | المستشار والتقارير | 6 | `S-AIC-018, S-AIC-019, S-AIC-020, S-AIC-021, S-AIC-022, S-AIC-023` | FS-009 weekly text host + Rule 26 Advisor | FS-009 aggregates; Advisor owns recommendations | DESIGN GAP |
| `AIC:هـ` | المساعد التفاعلي | 6 | `S-AIC-024, S-AIC-025, S-AIC-026, S-AIC-027, S-AIC-028, S-AIC-029` | Rule 26 interactive assistant | Mock until AI Gateway | REMOTE DEPENDENCY |
| `AIC:و` | الوكيل المفوَّض | 5 | `S-AIC-030, S-AIC-031, S-AIC-032, S-AIC-033, S-AIC-034` | Rule 26 delegated agent (suggest-only) | AiSuggestion has no execute() | REMOTE DEPENDENCY |
| `COM:أ` | المحادثات | 9 | `S-COM-001, S-COM-002, S-COM-003, S-COM-004, S-COM-005, S-COM-006, S-COM-007, S-COM-008, S-COM-009` | FS-010 Ephemeral Family Chat | Durable chat; S-COM-050 deleted forever | VERIFIED EXISTING |
| `COM:ب` | المكالمات | 6 | `S-COM-010, S-COM-011, S-COM-012, S-COM-013, S-COM-014, S-COM-015` | Domain-only (calls) | Native telephony boundary | NATIVE DEPENDENCY |
| `COM:ج` | الوسائط والملفات | 5 | `S-COM-016, S-COM-017, S-COM-018, S-COM-019, S-COM-020` | Domain-only (media) | No FS yet | OUT OF SCOPE |
| `COM:د` | دائرة الاتصال الآمنة | 5 | `S-COM-021, S-COM-022, S-COM-023, S-COM-024, S-COM-025` | Domain-only (safe circle) | No FS yet | OUT OF SCOPE |
| `COM:ز` | الموقع في التواصل | 3 | `S-COM-037, S-COM-038, S-COM-039` | Domain-only (location-in-comms) | Consumes location; no FS yet | OUT OF SCOPE |
| `COM:هـ` | التقويم العائلي | 6 | `S-COM-026, S-COM-027, S-COM-028, S-COM-029, S-COM-030, S-COM-031` | Domain-only (family calendar) | No FS yet | OUT OF SCOPE |
| `COM:و` | المهام والمسؤوليات | 5 | `S-COM-032, S-COM-033, S-COM-034, S-COM-035, S-COM-036` | Domain-only (tasks) | No FS yet | OUT OF SCOPE |
| `EDU:أ` | المواد والدروس | 6 | `S-EDU-001, S-EDU-002, S-EDU-003, S-EDU-004, S-EDU-005, S-EDU-006` | Domain EDU (materials) | Licensed/content boundary | REMOTE DEPENDENCY |
| `EDU:ب` | الواجبات | 6 | `S-EDU-007, S-EDU-008, S-EDU-009, S-EDU-010, S-EDU-011, S-EDU-012` | Domain EDU (assignments) | Local persist candidate (Phase 1.75) | VERIFIED EXISTING |
| `EDU:ج` | الاختبارات والتقييم | 6 | `S-EDU-013, S-EDU-014, S-EDU-015, S-EDU-016, S-EDU-017, S-EDU-018` | Domain EDU (assessments) | Local persist candidate | VERIFIED EXISTING |
| `EDU:ح` | التركيز وبيئة الدراسة | 6 | `S-EDU-042, S-EDU-043, S-EDU-044, S-EDU-045, S-EDU-046, S-EDU-047` | Domain EDU (focus) | Local persist candidate | VERIFIED EXISTING |
| `EDU:د` | المعلم الذكي | 6 | `S-EDU-019, S-EDU-020, S-EDU-021, S-EDU-022, S-EDU-023, S-EDU-024` | Domain EDU (Tutor seam Rule 26) | TutorRepository; no on-device LLM | REMOTE DEPENDENCY |
| `EDU:ز` | القرآن والتربية الإسلامية | 5 | `S-EDU-037, S-EDU-038, S-EDU-039, S-EDU-040, S-EDU-041` | Domain EDU (Quran) | Licensed source only | REMOTE DEPENDENCY |
| `EDU:ط` | استوديو الأب | 18 | `S-EDU-048, S-EDU-049, S-EDU-050, S-EDU-051, S-EDU-052, S-EDU-053, S-EDU-054, S-EDU-055, S-EDU-056, S-EDU-057, S-EDU-058, S-EDU-059, S-EDU-060, S-EDU-061, S-EDU-062, S-EDU-063, S-EDU-064, S-EDU-065` | Domain EDU (father studio) | Local persist candidate | VERIFIED EXISTING |
| `EDU:هـ` | التعلّم التكيفي | 5 | `S-EDU-025, S-EDU-026, S-EDU-027, S-EDU-028, S-EDU-029` | Domain EDU (adaptive) | Local persist candidate | VERIFIED EXISTING |
| `EDU:و` | التحفيز والمكافآت | 7 | `S-EDU-030, S-EDU-031, S-EDU-032, S-EDU-033, S-EDU-034, S-EDU-035, S-EDU-036` | Domain EDU (rewards/minutes) | PolicyEngine.earn; Minutes VO | VERIFIED EXISTING |
| `SEC:أ` | إدارة وقت الشاشة | 7 | `S-SEC-001, S-SEC-002, S-SEC-003, S-SEC-004, S-SEC-005, S-SEC-006, S-SEC-007` | FS-ST / Screen Time (prefs axis; related FS-003 ST axes) | Screen Time policy + schedules + time requests | VERIFIED EXISTING |
| `SEC:ب` | التحكم بالتطبيقات | 6 | `S-SEC-008, S-SEC-009, S-SEC-010, S-SEC-011, S-SEC-012, S-SEC-013` | FS-003 App Control | App allow/block policy | VERIFIED EXISTING |
| `SEC:ج` | فلترة الإنترنت | 5 | `S-SEC-014, S-SEC-015, S-SEC-016, S-SEC-017, S-SEC-018` | FS-002 Web Filter | Web filter policy + unlock | VERIFIED EXISTING |
| `SEC:ح` | مقاومة التحايل | 5 | `S-SEC-042, S-SEC-043, S-SEC-044, S-SEC-045, S-SEC-046` | Domain-only (anti-cheat / alerts hub) | Notifications/alerts hub prefs | VERIFIED EXISTING |
| `SEC:د` | الموقع والمناطق الآمنة | 7 | `S-SEC-019, S-SEC-020, S-SEC-021, S-SEC-022, S-SEC-023, S-SEC-024, S-SEC-025` | FS-001 Location | Zones / history / locate facts | VERIFIED EXISTING |
| `SEC:ز` | مراقبة منصات التواصل | 4 | `S-SEC-038, S-SEC-039, S-SEC-040, S-SEC-041` | Domain-only (platform monitoring / anti-tamper prefs) | Prefs-misc anti-tamper / platform | VERIFIED EXISTING |
| `SEC:ط` | القفل الفوري | 3 | `S-SEC-047, S-SEC-048, S-SEC-049` | Domain-only (instant lock) | Device lock prefs | VERIFIED EXISTING |
| `SEC:ك` | السلامة الحركية والقيادة | 3 | `S-SEC-055, S-SEC-056, S-SEC-057` | Domain-only (road safety) | Consumes location facts; no FS pack yet | OUT OF SCOPE |
| `SEC:ل` | وضع المدرسة | 3 | `S-SEC-058, S-SEC-059, S-SEC-060` | FS-005 Modes | School/mode schedules (≠ ST ScheduleWindow) | VERIFIED EXISTING |
| `SEC:هـ` | الطوارئ والاستغاثة | 6 | `S-SEC-026, S-SEC-027, S-SEC-028, S-SEC-029, S-SEC-030, S-SEC-031` | FS-006 SOS | SOS ladder / break-glass / alerts | VERIFIED EXISTING |
| `SEC:و` | مراقبة المحتوى الذكية | 6 | `S-SEC-032, S-SEC-033, S-SEC-034, S-SEC-035, S-SEC-036, S-SEC-037` | FS-004 Screen/Camera | Monitoring + screenshot policy (mic ≠ this) | VERIFIED EXISTING |
| `SEC:ي` | التقارير والتحليلات | 5 | `S-SEC-050, S-SEC-051, S-SEC-052, S-SEC-053, S-SEC-054` | FS-009 PDF Activity Reports (partial) | Usage/weekly reports; PDF mandate OPEN REP-C1 | DESIGN GAP |

## Extra: FS-008 (Domain-approved, not in CSV)

| virtual_row | fs_or_domain | owner_fact | class |
|---|---|---|---|
| *(no subsystem letter for S-PAR-030)* | FS-008 One-Way Audio | Domain-approved ambient mic (S-PAR-030) — **missing from services.csv** | REGISTRY GAP |

## Hard flags

| Item | Class | Notes |
|------|-------|-------|
| `S-PAR-030` missing from CSV | REGISTRY GAP | AUD-C7 carry-in; approved Domain 1 fact without inventory row |
| `S-COM-050` | CLOSED / OUT OF SCOPE | Deleted forever; must not reappear under FS-010 |
| Screen↔service link integrity | VERIFIED EXISTING | Extract: 0 screens without services; 0 unknown service IDs on screens |
| 18 services not listed on any journey | REGISTRY GAP | See map 06 / gap register — coverage hole, not invented product |

## Method notes

- Bindings refresh Phase 1.75 §11 migration matrix + Phase 2 cross-FS; they do **not** invent new product law.  
- Where audit §11 “Current form” text conflicts with Arabic subsystem name, **registry name + FS pack title** win; copy-paste drift in prior audit is noted as documentation debt (not a new authority).
