# PHASE 3 — Backend Capability Map (08)

**Date:** 2026-09-25  
**Sources:** Phase 1.75 §10 · Rule 26 · Phase 2 REM columns  

## Schema

`capability` · `honesty_state` · `rule_26_seam` · `class`

## Map

| capability | honesty_state | rule_26_seam | class |
|------------|---------------|--------------|-------|
| Cloud auth / account sync | Absent (mock identity local) | N/A | REMOTE DEPENDENCY |
| Multi-device policy sync | Local outbox / journal only | N/A | REMOTE DEPENDENCY |
| AI Gateway — AdvisorRepository | MOCK-REMOTE / InMemory mock | **Yes — sole Advisor path** | REMOTE DEPENDENCY |
| AI Gateway — InsightsRepository | MOCK-REMOTE | **Yes** | REMOTE DEPENDENCY |
| AI Gateway — TutorRepository | MOCK-REMOTE | **Yes** | REMOTE DEPENDENCY |
| Cloud AI classify (beyond FS-007 local) | UNSUPPORTED | Must not bypass Rule 26 repos | REMOTE DEPENDENCY |
| Push notification fanout | MOCK-REMOTE | N/A | REMOTE DEPENDENCY |
| SOS remote delivery (FCM/SMS/telephony) | MOCK-REMOTE | N/A | REMOTE DEPENDENCY |
| Chat relay / E2E transport | Analysis target; not live | N/A | REMOTE DEPENDENCY |
| Email report delivery | Not live; PDF mandate OPEN | N/A | POLICY DECISION REQUIRED |
| Licensed Quran remote content | Boundary until licensed path | N/A | REMOTE DEPENDENCY |
| Router-level parental web appliance (S-SEC-018) | Catalog remote | N/A | REMOTE DEPENDENCY |
| Subscription / billing backend | Mock / later | N/A | REMOTE DEPENDENCY |
| Mic listen sync / E2E seal (FS-008) | Analysis only | N/A | REMOTE DEPENDENCY |

## Rule 26 structural law (unchanged)

- No on-device inference for Advisor/Insights/Tutor.  
- AiSuggestion has **approve/reject only** — no `execute()`.  
- Inactive AI stages show designed coming-soon UI — not fake completion.
