# FS-001…FS-007 Change Ledger

**Campaign:** Master Implementation Commission  
**Plan:** [`FS_001_007_IMPLEMENTATION_MASTER_PLAN.md`](FS_001_007_IMPLEMENTATION_MASTER_PLAN.md)  
**Started:** 2026-09-24  

Status vocabulary: `IMPLEMENTED` · `MOCK-REMOTE` · `DEGRADED` · `UNSUPPORTED` · `NOT IMPLEMENTED`

---

## CHECKPOINT-FS-A (foundations)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-A-FOUND | Added `app/lib/core/fs_foundation/` — CapabilityStatus/Registry, PolicyDeliveryPhase machine, FamilyLocalDatabase (Memory + SQLite), MockRemoteAdapter outbox, schema v1 tables. Shared `CapabilityHonestyBadge`. Deps: sqflite, path, path_provider (+ sqflite_common_ffi dev). |

### Capability baseline after FS-A-FOUND

| Id | Status |
|---|---|
| fs_a.sqlite_kernel | IMPLEMENTED |
| fs_a.mock_remote | MOCK-REMOTE |
| fs_a.delivery_pipeline | IMPLEMENTED |
| fs001.* (domain/gps) | NOT IMPLEMENTED |
| fs002.web_lists | DEGRADED |
| fs002.native_block | MOCK-REMOTE |
| fs003.* | DEGRADED / MOCK-REMOTE |
| fs004.* | NOT IMPLEMENTED / MOCK-REMOTE |
| fs005.modes_scheduler | DEGRADED |
| fs006.sos_lifecycle | DEGRADED |
| fs006.remote_delivery | MOCK-REMOTE |
| fs007.local_classifier | NOT IMPLEMENTED |
| fs007.cloud_classify | UNSUPPORTED |

### Out of scope this checkpoint

- No backend / Firebase / FCM  
- No FS-001…007 product UX beyond honesty badge  
- No native GPS / VPN / Device Admin  

---

## CHECKPOINT-FS-001-DOM (location domain)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-001-DOM | Added `app/lib/core/location/` — SafeZoneDefinition (circle+polygon), assignment law Q-LOC-12=B, LocationFix acquisition honesty, GeofenceEvent ENTER/EXIT/NO_SHOW, GeofenceEvaluator, LocalLocationStore on FamilyLocalDatabase. Schema **v2** location tables. Capability: location_domain + geofence_eval → IMPLEMENTED; native_gps stays NOT IMPLEMENTED. |

### Capability after FS-001-DOM

| Id | Status |
|---|---|
| fs001.location_domain | IMPLEMENTED |
| fs001.geofence_eval | IMPLEMENTED |
| fs001.native_gps | NOT IMPLEMENTED |

### Out of scope this checkpoint

- No FAT-014…017 UX ADAPT (next: FS-001-UX)  
- No device GPS / map SDK  
- No Policy Kernel notification wiring  
- No Road Safety FAT-077 merge  

---

## CHECKPOINT-FS-001-UX (location screens ADAPT)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-001-UX | KEEP/REFINE FAT-014/015/016/017 + CHD-024: GPS NOT IMPLEMENTED honesty banners + CapabilityHonestyBadge; FAT-017 child multi-select (Q-LOC-12); DomainSafeZonesRepository + SilentLocateSheet/Service; map Silent locate CTA; CHD-024 live map card → silent check-in banner. native_gps remains NOT IMPLEMENTED. |

### Capability after FS-001-UX

| Id | Status |
|---|---|
| fs001.location_domain | IMPLEMENTED |
| fs001.geofence_eval | IMPLEMENTED |
| fs001.native_gps | NOT IMPLEMENTED |

### Out of scope this checkpoint

- No real map SDK / device GPS  
- No FS-001-XSYS SOS handoff polish (next card)  
- No Road Safety merge  

---

## CHECKPOINT-FS-001-XSYS (SOS handoff + Modes fact feed)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-001-XSYS | `SosLocationHandoff` attaches Domain fixes to incidents with honesty vocabulary (never blocks SOS fire); `ModesLocationFactFeed` publishes ENTER/EXIT/NO_SHOW/presence facts only (no Mode activation); schema **v3** `loc_sos_evidence` + `loc_mode_fact`; mapper to SOS UI tokens; capabilities `fs001.sos_location_handoff` + `fs001.modes_fact_feed` → IMPLEMENTED; `native_gps` stays NOT IMPLEMENTED. |

### Capability after FS-001-XSYS

| Id | Status |
|---|---|
| fs001.location_domain | IMPLEMENTED |
| fs001.geofence_eval | IMPLEMENTED |
| fs001.sos_location_handoff | IMPLEMENTED |
| fs001.modes_fact_feed | IMPLEMENTED |
| fs001.native_gps | NOT IMPLEMENTED |

### Ownership boundary (unchanged)

| Owner | Scope |
|---|---|
| FS-001 | Location facts, geometry, trail, handoff/feed contracts |
| SOS Final (FS-006) | Incident lifecycle, ACK/RESOLVE, delivery, Break-glass |
| Modes (FS-005) | Mode activation / scheduler — consumes facts only |

### Out of scope this checkpoint

- No SOS Final lifecycle completion (FS-006-LIFE)  
- No Modes scheduler ownership (FS-005)  
- No device GPS / map SDK  
- No Road Safety merge  

---

## CHECKPOINT-FS-002-OWN (Web Filter lists ownership)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-002-OWN | `core/web_filter/` — WebFilterDocument (family baseline + child override Q-WF-01), LocalWebFilterStore on schema **v4** `wf_document`, WebFilterEngine WF-OD-08 precedence (blocklist→temp→allow→dict→category), source-of-deny tokens; Stage-1 WebFilterPolicy additive blockList/dictionary; DomainWebFilterPolicyRepository adapter; FAT-036 KEEP/REFINE list editors + taxonomy/native honesty badges. Capabilities: fs002.web_lists → IMPLEMENTED; taxonomy DEGRADED (T-WF-02 TBD); native_block MOCK-REMOTE. |

### Capability after FS-002-OWN

| Id | Status |
|---|---|
| fs002.web_lists | IMPLEMENTED |
| fs002.taxonomy | DEGRADED |
| fs002.native_block | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-002 | Lists, categories policy docs, domain verdict |
| FS-002-ENF | Delivery plane, timed unlock approve, interstitial — **done** |
| FS-003 | Package/App Control — not URL allow |
| FS-005 | Modes tighten-only context — no WF scheduler |

### Out of scope this checkpoint

- No VPN/DNS native enforcement  
- No Modes chip deep-link polish  
- No App Control intersection UI  

---

## CHECKPOINT-FS-002-ENF (Web Filter delivery + unlock honesty)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-002-ENF | Delivery plane Configured→Verified (never claims native enforced); timed temp allow store schema **v5** `wf_temp_allow` (Q-WF-09 — approve never silent allowList); WebUnlockService → temp allow; interstitial source-of-deny + feedback (Q-WF-15); campaign baseline honest MOCK-REMOTE for native_block. Capabilities: fs002.delivery → IMPLEMENTED; fs002.timed_unlock → IMPLEMENTED; fs002.native_block stays MOCK-REMOTE. |

### Capability after FS-002-ENF

| Id | Status |
|---|---|
| fs002.web_lists | IMPLEMENTED |
| fs002.taxonomy | DEGRADED |
| fs002.delivery | IMPLEMENTED |
| fs002.timed_unlock | IMPLEMENTED |
| fs002.native_block | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-002 | Lists + delivery honesty + timed unlock domain |
| FS-003 (next) | Package/App Control dispositions — not URL allow |
| FS-005 | Modes tighten-only context |

### Out of scope this checkpoint

- No VPN/DNS/native device block (still MOCK-REMOTE)  
- No permanent allowList via unlock approve  
- No App Control / Modes ownership  

---

## CHECKPOINT-FS-003-OWN (App Control dispositions ownership)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-003-OWN | `core/app_control/` — PackageId + Allow/Block/Exempt dispositions; family baseline/child override schema **v6** (`ac_document` + `ac_exception`/`ac_lock_now`/`ac_install`); protected SOS/Family OS/Chat/Quran (APP-OD-09); timed Exception (never rewrites Permanent Block); Lock Now overlay; deny-until-approved install (child-scoped approve); DomainAppAccessRulesRepository (AC owns blocked; ST keeps limit/unlimited/countable); FAT-034 honesty banner. Capabilities: fs003.app_dispositions/protected_packages/app_exception → IMPLEMENTED; fs003.os_intercept MOCK-REMOTE. |

### Capability after FS-003-OWN

| Id | Status |
|---|---|
| fs003.app_dispositions | IMPLEMENTED |
| fs003.protected_packages | IMPLEMENTED |
| fs003.app_exception | IMPLEMENTED |
| fs003.os_intercept | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-003 | Package Allow/Block/Exempt/Lock Now/Install/Exception |
| Screen Time | Limit / Unlimited / Countable / Temporary Grant |
| FS-003-UX (next) | Hub/inventory/deny/disclosure ADAPT |
| FS-002 | URL plane only |
| FS-005 | Modes schedule tighten-only |

### Out of scope this checkpoint

- No Device Admin / Accessibility OS intercept (MOCK-REMOTE)  
- No ST authorship of Limit/Unlimited  
- No Modes scheduler  

---

## CHECKPOINT-FS-003-UX (App Control hub/inventory/deny ADAPT)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-003-UX | KEEP/REFINE FAT-034/035: bind optional `AppControlService`; Primary+Full configure Permanent Block; Partner tickets-only + hint; protected badges (APP-OD-09); child `AppDenyPage` (source-of-deny + Exception Request ≠ Minutes + SOS/Chat/Quran reachable); FAT-035 child-scoped install honesty; os_intercept MOCK-REMOTE unchanged. |

### Capability after FS-003-UX

| Id | Status |
|---|---|
| fs003.app_dispositions | IMPLEMENTED |
| fs003.protected_packages | IMPLEMENTED |
| fs003.app_exception | IMPLEMENTED |
| fs003.os_intercept | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-003 | Package access UX + domain (done OWN+UX) |
| FS-004 (next) | Screen & Camera Prevent/Monitor/Protect |
| Screen Time | Limit/Unlimited/Countable/Grant surfaces |

### Out of scope this checkpoint

- No new SCR ids (deny hosted like WebBlockPage)  
- No OS intercept claims  
- No Screen/Camera policy  

---

## CHECKPOINT-FS-004-OWN (Screen & Camera Prevent/Monitor/Protect store)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-004-OWN | `core/screen_camera/` — ScreenCameraDocument (Prevent camera OS + capture; Monitor screenshots P-7 + package picker set; Protect sensitive surfaces); family baseline + child override schema **v7** `sc_document`; Modes tighten-only (never silent monitor); mic/SOS audio out of scope; evaluate never claims enforcement on MOCK-REMOTE planes. Capabilities: fs004.screen_camera_policy → IMPLEMENTED; capture_pipeline + camera_os_plane MOCK-REMOTE. DesiredMonitoringPrefs (web/app/notif/location) **not** absorbed. |

### Capability after FS-004-OWN

| Id | Status |
|---|---|
| fs004.screen_camera_policy | IMPLEMENTED |
| fs004.capture_pipeline | MOCK-REMOTE |
| fs004.camera_os_plane | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-004 | Prevent/Monitor/Protect policy + P-7 screenshot monitoring semantics |
| Smart Alerts FAT-065 | Presentation/entry only — no second screenshot policy |
| FS-003 | Package Allow/Block (≠ OS camera) |
| SET-016 DesiredMonitoringPrefs | web/app/notif/location only |
| FS-004-UX (next) | Parent configure + child transparency surfaces |

### Out of scope this checkpoint

- No MediaProjection / screenshot agent  
- No MDM OS camera kill claims  
- No mic / SOS audio  
- No UX screen ADAPT (FS-004-UX)  

---

## CHECKPOINT-FS-004-UX (Parent + child Screen & Camera transparency)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-004-UX | KEEP/REFINE FAT-065: `ScreenCameraParentPanel` binds Prevent/Monitor/Protect to SC domain (screenshot tool no longer a second store); policy-owned honesty banner; child preview when monitoring on; Partner read-only. CHD-010: `ScreenCameraTransparencyCard` (W-C01/W-C02) with MOCK-REMOTE plane badges. Shared components under `core/design/components/`. capture/camera_os MOCK-REMOTE unchanged. |

### Capability after FS-004-UX

| Id | Status |
|---|---|
| fs004.screen_camera_policy | IMPLEMENTED |
| fs004.capture_pipeline | MOCK-REMOTE |
| fs004.camera_os_plane | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-004 | Policy + UX entry/transparency (done OWN+UX) |
| Smart Alerts | Notify/entry shell only |
| FS-005 (next) | Modes scheduler tighten-only |

### Out of scope this checkpoint

- No new SCR hub id  
- No MediaProjection agent  
- No mic / SOS audio  

---

## CHECKPOINT-FS-005-OWN (Modes lifestyle scheduler ownership)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-005-OWN | `core/modes/` — ModeDefinition (catalog Sleep/School/Study/Ramadan/Vacation/Family Time/Custom; exams→study, famtime→familyTime); family/all or selected children (no silent expand); clock·manual·location·seasonal channels; multi-mode stricter overlay stack (tighten-only; Vacation widen rejected); ModeException ≠ AC/ST; consume FS-001 `ModesLocationFactFeed` only; schema **v8** `mode_document`/`mode_activation`/`mode_exception`. Capabilities: fs005.modes_scheduler → IMPLEMENTED; fs005.os_wake MOCK-REMOTE. ScheduleWindow remains ST legacy — not Mode authority. |

### Capability after FS-005-OWN

| Id | Status |
|---|---|
| fs005.modes_scheduler | IMPLEMENTED |
| fs005.os_wake | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-005 | Lifestyle Mode schedule + activation + overlay facts |
| FS-001 | Geofence truth / location facts (consumed) |
| ST | Minutes/grants/wallets — not Mode schedule |
| FS-002/003/004 | Permanent stores — Modes tighten overlay only |
| SOS | Never gated |
| FS-005-UX (next) | FAT-085 ADAPT + child disclosure |

### Out of scope this checkpoint

- No OS wake / Focus / AlarmManager  
- No FAT-085 UX ADAPT  
- No permanent mutation of WF/AC/SC stores  

---

## CHECKPOINT-FS-005-UX (FAT-085 + child Mode disclosure ADAPT)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-005-UX | KEEP/REFINE FAT-085: optional/Stage-1 `ModesService` bind (multi-mode activate + school clock → FS-005 store); ownership banner; os_wake MOCK-REMOTE badge; exams→study hint. CHD-004: `ModeDisclosureCard` (W-C01/W-C02) when Modes injected — no child cancel. Prefs path retained when repository injected (SET-018 tests). |

### Capability after FS-005-UX

| Id | Status |
|---|---|
| fs005.modes_scheduler | IMPLEMENTED |
| fs005.os_wake | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-005 | Lifestyle schedule UX + domain (done OWN+UX) |
| ST | Minutes/grants surfaces |
| FS-006 (next) | SOS Final lifecycle |

### Out of scope this checkpoint

- No OS wake plane  
- No Vacation widen  
- No new SCR hub  

---

## CHECKPOINT-FS-006-LIFE (SOS Final lifecycle / evidence / readiness)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-006-LIFE | `core/sos_final/`: durable `SosIncident` + indefinite lifecycle audit + 90d ops samples + Break-glass allowlist (Q-SOS-RD-02B) + OD-21 readiness evaluator; schema v9; Observer cannot ack (sos_final §06). remote_delivery stays MOCK-REMOTE. |

### Capability after FS-006-LIFE

| Id | Status |
|---|---|
| fs006.sos_lifecycle | IMPLEMENTED |
| fs006.evidence_retention | IMPLEMENTED |
| fs006.readiness | IMPLEMENTED |
| fs006.break_glass | IMPLEMENTED |
| fs006.remote_delivery | MOCK-REMOTE |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-006 | Incident lifecycle, evidence layers, readiness, Break-glass |
| FS-001 | Location facts only (handoff attach) |
| FS-006-XSYS (next) | Cross-check exemptions + location honesty UX |

### Out of scope this checkpoint

- No live FCM/SMS/telephony  
- No national emergency dial / audio  
- No FAT-018/028 full screen rebind (XSYS/KEEP)  

---

## CHECKPOINT-FS-006-XSYS (OD-14 exemptions + FS-001 location honesty)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-006-XSYS | `SosPermanentExemptions` audits Modes/ST/AC/locks/notifications/SC audio + never-gate fire; `SosLocationHonestyBridge` + `SosCrossSystemCoordinator` consume FS-001 handoff after fire (OD-16); Break-glass≠Find; `native_gps` stays NOT IMPLEMENTED; `remote_delivery` MOCK-REMOTE. |

### Capability after FS-006-XSYS

| Id | Status |
|---|---|
| fs006.permanent_exemptions | IMPLEMENTED |
| fs006.location_honesty_bridge | IMPLEMENTED |
| fs006.remote_delivery | MOCK-REMOTE |
| fs001.native_gps | NOT IMPLEMENTED (unchanged) |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-006 | Lifecycle (LIFE) + exemption/honesty seams (XSYS) |
| FS-001 | Location facts / handoff attach |
| FS-007 (next) | Offline AI signal only — never fires SOS |

### Out of scope this checkpoint

- No live GPS / FCM  
- No second SOS lifecycle store  
- No FS-007 classifier  

---

## CHECKPOINT-FS-007-SIG (classifier signal + ticket + suggest-only)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-007-SIG | `core/offline_ai_safety/`: typed SafetySignal (AI-OD-07/08), signed model gate (AI-OD-11), B1 ticket gate, suggest-only (no auto WF/AC/Modes), preview purge on close, never SOS, cloud classify UNSUPPORTED; schema **v10**. |

### Capability after FS-007-SIG

| Id | Status |
|---|---|
| fs007.local_classifier | IMPLEMENTED |
| fs007.safety_tickets | IMPLEMENTED |
| fs007.suggest_only | IMPLEMENTED |
| fs007.cloud_classify | UNSUPPORTED |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-007 | Signal / ticket / suggest-only |
| FS-002/003/005 | Human approve of suggestions |
| FS-006 | SOS — AI must never fire |
| FS-007-UX (next) | Parent review + child transparency UI |

### Out of scope this checkpoint

- No cloud classify  
- No real NN weights (heuristic stub honesty)  
- No parent/child screen ADAPT (FS-007-UX)  

---

## CHECKPOINT-FS-007-UX (parent review + child transparency)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-007-UX | KEEP/REFINE hosts: FAT-065 `AiSafetyTicketReviewPanel` (redacted preview, non-numeric certainty/severity, resolve/dismiss/suggest-only; Observer view-only); CHD-010 `AiSafetyChildTransparencyCard` (on-device honesty). Empty alerts inventory preserves FAT-003 CTA unless injected seam / open tickets. Transparency cards co-mounted in one ListView child. |

### Capability after FS-007-UX

| Id | Status |
|---|---|
| fs007.parent_ticket_review | IMPLEMENTED |
| fs007.child_transparency | IMPLEMENTED |
| fs007.ai_as_executor | FORBIDDEN (UI copy + no execute path) |

### Ownership boundary

| Owner | Scope |
|---|---|
| FS-007 | Signal review UX + child honesty |
| FS-002/003/005 | Human approve of suggestions (unchanged) |
| FS-I-RECON (next) | Campaign closure + cross-system reconcile |

### Out of scope this checkpoint

- No backend / cloud classify  
- No visual redesign of FAT-065 / CHD-010 shells  

---

## CHECKPOINT-FS-I-RECON (campaign closure)

| Date | Card | Change |
|---|---|---|
| 2026-09-24 | FS-I-RECON | Cross-system ownership rollup + honesty capability table + KEEP/REFINE host confirmation; residual mock debt listed; closure report `docs/experience_discovery/FS_001_007_CLOSURE_REPORT.md`. Lane FS CLOSED. |

### Campaign status

| Lane | Status |
|---|---|
| FS-001…FS-007 implementation | **CLOSED** (local/domain + honesty UX) |
| Native / cloud Stage 3 planes | Explicitly **not** claimed |
| P15-QUR park | unchanged (`deferred_campaign`) |

---

*End of FS-001…FS-007 campaign ledger checkpoints.*
