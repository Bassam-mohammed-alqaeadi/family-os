# 11 — FS-007 Cross-System Dependencies

**Mode:** Boundary map — FS-007 must not absorb siblings.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Dependency matrix

| System | FS-007 may… | FS-007 must not… | Evidence today |
|---|---|---|---|
| **Policy Kernel** | Emit typed facts/signals w/ confidence + provenance | Become hidden policy engine | No safety-signal fact type |
| **Identity / AuthZ** | Respect Primary / Co-Parent / Child | Bypass RoleGuard | No FS-007 RBAC matrix |
| **Offline-first / Sync** | Queue signal-safe results; ack versions | Fake connectivity or silent drop | No outbox |
| **Audit / Events / Notifications** | Append classify + review evidence | Soft-delete audit; SOS-channel spam | Schema only |
| **FS-002 Web Filter** | Suggest categories / keywords for human approve | Silently rewrite URL/dict lists | Heuristic classify is **FS-002** owned |
| **FS-003 App Control** | Suggest app classifications | Silently block packages | No coupling |
| **FS-004 Screen & Camera** | Process **approved** capture inputs if later allowed | Unapproved surveillance pipeline; duplicate P-7 policy | FS-004 owns P-7 screenshot policy (SC-OD-09) |
| **FS-005 Modes** | Suggest Mode configuration | Own Mode schedule; silent tighten without human/Mode contract | No coupling |
| **FS-006 SOS** | Suggest/signal **only if** frozen SOS contract permits | Autonomously trigger/escalate SOS | SOS Final: no on-device AI triage |
| **Screen Time Final** | Suggest patterns (Advisor-like) | Mutate minutes/wallets | Advisor mocks only |
| **FS-001 Location** | Consume location **facts** if product allows contextual risk | Own geofences; silent tracking AI | No coupling |
| **Family Advisor (Rule 26 gateways)** | Remain adjacent suggest UX | Confuse Advisor LLM with offline safety classifier | Shared sovereignty law; different mission |
| **RulesEngine** | Feed **approved** consequents only | Auto-execute as AI | ADR-038 separation |

---

## 2. FS-002 detail

- Discovery map already labels **FS-007 Offline AI: no coupling found**.
- Keyword dictionary = **FS-002 L2**.
- Host heuristic `classifyHost` is **not** FS-007 ML.
- Risk: Smart Alerts “search scan” marketing could be confused with WF — keep ownership crisp in L2.

---

## 3. FS-003 detail

- No app-category ML in repo.
- Any future “this app looks like social” suggestion requires **human approval** before package policy mutation.

---

## 4. FS-004 detail

- **SC-OD-09:** FS-004 owns P-7 screenshot monitoring policy; Smart Alerts presentation-only.
- FS-007 classification of captures is a **downstream consumer**, not a second monitoring policy store.
- Transparency rules of FS-004 apply to any capture→classify path.

---

## 5. FS-005 detail

- Modes may tighten planes under sibling L2.
- AI may suggest Mode setup; approval mandatory.
- No Mode↔AI code binding found.

---

## 6. FS-006 detail

- SOS Final product contract lists **on-device AI triage of SOS** as out of scope / non-goal.
- Discovery stance: **AI cannot fire or escalate SOS**.
- EventBus note in SOS docs is for AI hooks generally — not permission to triage emergencies.

---

## 7. Policy Kernel boundary

| Today | Needed later (not designed here) |
|---|---|
| TimeEngine / access flags | Typed `SafetySignalFact` (name TBD) |
| No confidence inputs | Explicit contract if Kernel ever consumes scores |
| No silent AI→deny | Keep deny authorship human / Mode / WF / AC |

---

## 8. Anti-absorption rule

Do **not** invent a giant AI platform inside FS-007.  
Keep scope = **offline AI safety classification signals** + governance.  
Advisor chat, Tutor, Insights stages, Education packs, and competitive “brain that knows everything” charter language are **adjacent** — schedule under STAGE3-AI / other cards, not smuggled into FS-007 L2.
