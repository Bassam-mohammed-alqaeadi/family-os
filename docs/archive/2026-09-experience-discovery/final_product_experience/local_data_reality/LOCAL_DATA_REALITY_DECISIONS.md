# LOCAL DATA REALITY — DECISIONS LOG

Append-only. Every changed technical default or schema choice.

| ID | Date | Decision | Why | Blast radius |
|---|---|---|---|---|
| LDR-D-00 | 2026-09-26 | Campaign authorized (Owner 1C + 2A). D-FINAL paused until LDR-EXIT. | Owner | Plan markers, UX verification timing |
| LDR-D-01 | 2026-09-26 | REAL_LOCAL bind+seed only; NC/RC stay empty/honest — no fake GPS/AI/calls/FCM/billing. | Owner 1C | All seeds, Advisor boot, device health |
| LDR-D-02 | 2026-09-26 | Roster seed strips location/battery/lastSeen fake telemetry; identity fields remain. | Align seed with 1C | FAT-012/013/010 display; tests expecting demo labels |
| LDR-D-03 | 2026-09-26 | Production boot rebinds `EmptyAdvisorRepository` (returns `[]`). `MockAdvisorRepository` remains for explicit tests / Rule 26 prototype harness. | 1C overrides planted AI as live | Advisor screens empty until Gateway |
| LDR-D-04 | 2026-09-26 | Location map/history stage1 → domain adapters over `Stage1LocationRuntime` + roster. Decorative pin layout OK; no trail samples seeded. | Close unbound UX split-brain | FAT-014/015 |
| LDR-D-05 | 2026-09-26 | Quran `LocalQuranBridgeStore` hydrate+persist at boot via main. | Close unused KV | Quran/athkar/day-board blessings |
| LDR-D-07 | 2026-09-26 | Child apps: REAL_LOCAL managed package catalog seed (usedMins=0); OS usage remains NC; bind to AC accessRules at boot. | Populate FAT-034 without fake OS telemetry | FAT-034, AC, ST axes |
| LDR-D-09 | 2026-09-26 | Seed tasks (2), calendar (2 events), outer circle (relative+friend+pending) when empty. | Populate ops surfaces for UX verification | FAT-054/052/outer |
| LDR-D-11 | 2026-09-26 | Rebind `stage1TimeRequestService` + child repo to Stage1TimeRequestRuntime Local KV at ScreenTimeRuntime boot; seed one pending request for demo-child. | Day board/alerts were reading Memory Prefs lag | FAT-010/019/033 CHD-020 |
| LDR-D-13 | 2026-09-26 | Generation outputs, Child Tutor, Quran progress, Learn home defaults → empty fixtures (not prototype AI content). | Owner 1C | FAT-043 CHD-017 FAT-072 CHD-012 |
| LDR-D-15 | 2026-09-26 | `stage1DeviceHealthSeam` defaults to empty (not Fake.demo). Demo/atRisk fixtures remain for explicit tests. | Owner 1C — no fake battery/heartbeat as live | FAT-025/026 |
| LDR-D-16 | 2026-09-26 | Adult invite stays InMemory session-local: empty until father creates invite; no planted tokens; QR/remote delivery remains RC. | Owned create/accept loop only; no fake pending mothers | FAT-006/007 invite |
| LDR-D-17 | 2026-09-26 | Child device management already `RuntimeChildDeviceManagementRepository` — no further InMemory swap. | Local-owned link state already | Linking / add-child |
| LDR-D-18 | 2026-09-26 | Remaining InMemory stage1 defaults → `*EmptyFixture()` (not Prototype). Prototype fixtures stay for widget tests that inject seed. | Close LDR-G-22 planted AI/NC content | n07/n14/n17 + call-play/road |
| LDR-D-19 | 2026-09-26 | Matrix `data_source` refreshed for LDR binds + EMPTY-HONEST; cross-screen harness proves roster IDs align map/profile/zones/tasks/chat/board. | Close LDR-G-23/24 | FINAL_VISUAL_UX_JOURNEY_MATRIX.json · test/ldr/ldr_b8 |

*(Further decisions appended per batch.)*
