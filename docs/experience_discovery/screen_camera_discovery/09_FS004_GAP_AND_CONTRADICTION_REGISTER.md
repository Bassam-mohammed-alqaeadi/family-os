# 09 — FS-004 Gap and Contradiction Register

**Mode:** Record gaps and contradictions. Do not resolve with silent Owner choices.  
**Master:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Major gaps

| ID | Gap | Class |
|---|---|---|
| SC-GAP-01 | No prior FS-004 system pack / symbol | **MISSING** |
| SC-GAP-02 | No OS camera disable / screenshot block / MediaProjection agent | **MISSING** |
| SC-GAP-03 | P-7 screenshot monitoring: toggle mock only; no capture pipeline; no app picker in Flutter | **MOCK** + **MISSING** |
| SC-GAP-04 | Child transparency for screenshot tools not in MonitoringFeature set | **PARTIAL/MISSING** vs P-7 |
| SC-GAP-05 | No schema for camera/screen-capture policy or perm keys | **MISSING** |
| SC-GAP-06 | No sync/ack/outbox for FS-004 | **MISSING** |
| SC-GAP-07 | No FLAG_SECURE / content protection impl | **MISSING** |
| SC-GAP-08 | Device health omits camera/mic/capture | **MISSING** |
| SC-GAP-09 | `docs/family_os_blueprint/` absent in workspace | **UNKNOWN/MISSING** |
| SC-GAP-10 | Ambient Domain 1 recording undocumented-as-code | **DOCUMENTED ONLY** |

---

## 2. Contradictions

| ID | Contradiction | Handling |
|---|---|---|
| SC-C-01 | Policy Register **P-4 SOS audio broadcast** vs **SOS Final: audio excluded** | **Q-SC-08** — do not implement mic under FS-004 until resolved |
| SC-C-02 | Prototype/P-7 require screenshot **app picker** + transparency; Flutter has toggle only | Gap SC-GAP-03/04 |
| SC-C-03 | Stage-1 Partner may edit FAT-034 (incl. Camera app) vs FS-003 frozen Primary+Full configure | FS-003 law wins for App Control; FS-004 AuthZ still **Q-SC-11** |
| SC-C-04 | Naming: “Screen Time” (minutes) vs “Screen & Camera Control” (FS-004) | Clarify in L2 mission — discovery keeps them separate |
| SC-C-05 | FAT-065 “screenshot” tool may be read as enforced monitoring | Honesty: **MOCK only** |
| SC-C-06 | Domain 1 “prevent screenshot” on playback vs no FLAG_SECURE code | Doc-only vs MISSING impl |

---

## 3. Closed gaps that do **not** close FS-004

| Closed item | Why not FS-004 |
|---|---|
| UI-003 QR camera repair (GAP_LOG) | Class **(A)** Family OS camera UX only |

---

## 4. Owner questions index

See [04](04_FS004_POLICY_AND_AUTHZ_DISCOVERY.md): **Q-SC-01…12** — all **OPEN**.

---

## 5. Technical questions index

See [05](05_FS004_ENFORCEMENT_AND_PLATFORM_DISCOVERY.md): **T-SC-01…12** — all **OPEN**.

---

## 6. Recommended L2 freeze order (advisory only)

1. Q-SC-01 scope (prevent/monitor/protect)  
2. Q-SC-03 screen meaning · Q-SC-04 camera package vs OS  
3. Q-SC-09 FAT-065 ownership  
4. Q-SC-11/12 AuthZ + scope model  
5. Q-SC-05/08 mic  
6. Q-SC-06/07 honesty + exceptions  
Then T-SC verification — **no mechanism selection in discovery**.
