# LOCAL DATA REALITY — GAP REGISTER

**Authority:** Matrix JSON + code inventory 2026-09-26 · Owner 1C/2A  
**Statuses:** OPEN · IN_PROGRESS · CLOSED · EMPTY-HONEST · N/A-STATIC

| ID | Domain / surface | Current | Target | Batch | Status |
|---|---|---|---|---|---|
| LDR-G-01 | Roster children seed | Fake GPS/battery/time labels in seed | Identity fields only; NC metrics empty | B1 | CLOSED |
| LDR-G-02 | Quran `quran_local` | Store exists; not boot-bound | Hydrate+persist at boot | B1 | CLOSED |
| LDR-G-03 | Location map UX | InMemory stage1 | Domain + roster pins; no fake trails | B1 | CLOSED |
| LDR-G-04 | Location history UX | InMemory stage1 | Domain trail/events; empty if none | B1 | CLOSED |
| LDR-G-05 | Child profile | InMemory (roster fallback) | Explicit bind after roster | B1 | CLOSED |
| LDR-G-06 | Advisor production | MockAdvisor planted suggestions | EmptyAdvisor at boot; Mock for tests | B1 | CLOSED |
| LDR-G-07 | Child apps UI | InMemory inventory | Project AC + st_app_axes + REAL_LOCAL managed catalog (usedMins=0) | B2 | CLOSED |
| LDR-G-08 | Safe zones list | Dual path risk | Always DomainSafeZones | B2 | CLOSED |
| LDR-G-09 | Safe zone seed | Often empty | Seed 1–2 zones prefs (no GPS) | B2 | CLOSED |
| LDR-G-10 | Tasks/calendar/circle seed | Empty-first | Coherent REAL_LOCAL rows | B3 | CLOSED |
| LDR-G-11 | Family chat messages | Thread only | Small local message sample | B3 | CLOSED |
| LDR-G-12 | Day board projection | Mixed demo telemetry | Local producers only | B4 | CLOSED |
| LDR-G-13 | Alerts detail | InMemory | Empty-honest (no planted stranger/battery stories) | B4 | CLOSED |
| LDR-G-14 | Time/app/friend pending | Partial | Time+friend from Local KV/seed; app when tickets exist | B4 | CLOSED |
| LDR-G-15 | Studio InMemory repos | Many unbound | Generation empty-honest; board already empty | B5 | CLOSED |
| LDR-G-16 | Child learn / Tutor | InMemory + mock AI | Learn home empty base + Local assignment seed; Tutor empty | B5 | CLOSED |
| LDR-G-17 | Insights / patterns / weekly | Mock/local mix | Advisor empty (B1); generation empty | B5 | CLOSED |
| LDR-G-18 | Call history / active call | InMemory (empty default) | Locked empty-honest + NC/RC copy | B6 | CLOSED |
| LDR-G-19 | Device health Fake.demo | LOCAL_DEMO production | Empty-honest NC | B6 | CLOSED |
| LDR-G-20 | Adult invite memory | InMemory session | Empty until create; remote delivery RC | B7 | EMPTY-HONEST |
| LDR-G-21 | Child device link memory | Runtime already | Keep RuntimeChildDeviceManagement | B7 | CLOSED |
| LDR-G-22 | Remaining unbound stage1 | Prototype defaults | EmptyFixture defaults; fixtures for tests | B7 | EMPTY-HONEST |
| LDR-G-23 | Matrix data_source stale | Pre-LDR text | Refresh after binds | B8 | CLOSED |
| LDR-G-24 | Cross-screen consistency | Partial | Harness cases | B8 | CLOSED |

**STATIC (N/A):** SHR-001, FAT-005, CHD-001 — ARB only.
