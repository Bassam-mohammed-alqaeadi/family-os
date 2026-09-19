# 11 — MASTER DISCOVERY COMMAND (Family OS Edition)
> Owner-approved adaptation of the generic "MASTER COMMAND — PROJECT DISCOVERY" prompt.
> The generic text is reproduced in full below Section B. **Section A overrides it wherever they conflict.**

---

## SECTION A — FAMILY OS BINDING OVERRIDES (READ FIRST, THESE WIN ON ANY CONFLICT)

### A1. Governance is already established — you are NOT starting from zero
Before executing any phase below, read IN THIS ORDER:
1. `handoff/01_CURSOR_CONSTITUTION.md` — 26 rules. **All 26 remain in force during this discovery mission.**
2. `handoff/04_POLICY_REGISTER_EN.md` — **SUPREME LAW.** Any conflict between the generic prompt below and this register resolves in favor of the register.
3. `handoff/00_START_HERE.md` through `handoff/10_PREFLIGHT_CHECKLIST.md` — full handoff package.
4. `family-os/40_POLICY_REGISTER_FOR_FLUTTER.md`, `family-os/02_DECISION_LOG.md` (ADR-001…033), `family-os/_REGISTRY/` (services/journeys/screens CSVs), `family-os/_CONTRACTS/schema.sql`, `GAP_LOG.md`, `API_CONTRACT.md`.

### A2. Frozen decisions are INPUT, not questions
The following are SEALED. Discovery must treat them as fixed constraints. If your analysis finds a conflict with them, FLAG it in the decision register as `CONFLICT-WITH-FROZEN` — do NOT re-decide:
- Prototype `family-os/family_os_app.html` is **v1.0 FROZEN** = UI ground truth (129 screens: FAT 85 / CHD 37 / SHR 7).
- Canonical counts: **240 services / 73 journeys / 129 screens** per `_REGISTRY` — trust these over your own re-count; if your count differs, flag the delta, don't overwrite.
- Rewards = **minutes only**, amount set by father at task creation. The 5 earning channels must never be weakened.
- Child can never bypass father limits; expired allowance ⇒ auto-lock; father-blocked apps stay hard-locked.
- Offline-first with last-synced family state.
- Per-app time wallets on child devices (ق-٢ rulings).
- AI = "Family Advisor": gateways only, **no in-app inference, AiSuggestion has no execute()** (ADR-033, charter `family-os/08_AI_CORE_CHARTER.md`).
- Repository-interface architecture: mock/ and api/ behind identical interfaces, swap = zero changes in features/ (ADR-032, `API_CONTRACT.md`).
- Cancelled forever: OTP, v1 green design, two-app model, SCR-SHR-004 role picker.

### A3. Actor model (owner directive 2026-09-19 — matches schema.sql CHECKs)
- **3 PRIMARY actors**: Father (OWNER, permission FULL), Mother (PARENT, delegated within `family-os/20_MOTHER_PERMISSIONS.md`), Child.
- **2 SECONDARY**: Guardian/Grandfather (GUARDIAN = OBSERVER, initiates no transactional use case), Family Advisor (SYSTEM actor: proposes, father approves).
Every matrix, flow, and diagram plan uses this model. Never promote a secondary actor to primary.

### A4. Output location & repo hygiene
- All output goes to **`docs/project-plan/`** (new directory) — the 22 files named in the generic prompt (00-MASTER-PLAN.md … 21-release-readiness.md).
- One branch: `discovery/master-plan`. Conventional commits, one logical doc-set per commit. Open a PR at the end; do NOT merge yourself.
- Do NOT touch: `family-os/` (spec history), `handoff/` (law), `family_os_app.html` (frozen), production code paths.
- Mock data in the prototype is DELIBERATE (constitution rule 23); do not log it as a defect — the dynamic-data requirement is already law.

### A5. Relationship to existing artifacts (do not duplicate — extend)
- `GAP_LOG.md` exists: your PHASE 13 master gap list must IMPORT its entries (keep IDs) and extend, not fork.
- `API_CONTRACT.md` exists: PHASE 9/12 API specs extend it in place-compatible format.
- `schema.sql` (20 tables) exists: PHASE 10 validates services against it; propose deltas as `ALTER`-style suggestions, never a parallel schema.
- Decision register (PHASE 14): continue our ADR numbering — next free ID is **ADR-034**. Anything you cannot resolve = `REQUIRES PRODUCT DECISION` for the owner.
- PHASE 11 diagrams: produce the **diagram STRATEGY document only** (13-diagram-strategy.md). The canonical Arabic academic diagrams are produced separately by the owner's side (plan `family-os/44_ACADEMIC_DOCUMENTATION_PLAN.md`); your strategy must stay consistent with its actor model and scope, and your engineering diagrams (if any) are English working artifacts, not the academic deliverable.

### A6. Mission boundary & reporting protocol
- This is a DISCOVERY mission: rules 2/9/13 of the constitution apply (no production code, no scope creep, stop on ambiguity).
- Work phase by phase. After completing phases 0–2 (inventory + product model + role matrix), STOP and post a checkpoint summary for owner audit before continuing to phases 3+.
- End with `00-MASTER-PLAN.md` including the IMPLEMENTATION READINESS verdict (NOT READY / READY FOR FOUNDATION / READY FOR IMPLEMENTATION) — justified against the release model in `handoff/10_PREFLIGHT_CHECKLIST.md`.

---

## SECTION B — GENERIC MASTER COMMAND (verbatim; subordinate to Section A)

 MASTER COMMAND — PROJECT DISCOVERY, PRODUCT COMPLETION & IMPLEMENTATION PLAN

ROLE

You are not acting as a normal coding assistant.

You are acting as the combined:

- Product Owner
- Business Analyst
- UX/Product Designer
- System Analyst
- Solution Architect
- Flutter Architect
- Backend Architect
- Database Architect
- QA/Test Architect
- Technical Project Manager
- Documentation & Diagram Architect

You are working on an existing software project.

You have access to the entire project repository and all available files.

Your mission at this stage is NOT to implement the application.

Your mission is to completely understand the product, discover every missing or inconsistent part, make the necessary product and technical decisions, and produce a complete implementation blueprint that another development phase can execute.

DO NOT start implementing Flutter UI.
DO NOT start implementing backend APIs.
DO NOT modify production source code.
DO NOT delete existing work.
DO NOT redesign existing screens merely because you prefer another design.

First understand the product.

---

PRIMARY OBJECTIVE

Transform the current project from:

"Existing but incomplete UI/prototype/project files"

into:

"A fully specified, internally consistent, implementation-ready product specification and technical execution plan."

The final plan must be detailed enough that implementation can begin afterward with minimal ambiguity.

The final system must ensure consistency between:

Requirements
→ Roles
→ Permissions
→ Services
→ Screens
→ Settings
→ User interactions
→ State
→ Backend
→ Database
→ APIs
→ Notifications
→ Business rules
→ Security
→ Testing
→ Documentation
→ Diagrams

---

CORE PRINCIPLE

Never assume that an existing UI means the feature is complete.

A visible setting may have:

- no business rule
- no state
- no backend support
- no database field
- no effect on another role
- no API
- no validation
- no permission logic
- no notification behavior
- no testing
- no documentation

Therefore, every service must be traced end-to-end.

Use this model:

UI
↓
Interaction
↓
State
↓
Business Logic
↓
API
↓
Backend
↓
Database
↓
Other affected roles/screens
↓
Notifications/events
↓
Testing

---

PHASE 0 — FREEZE IMPLEMENTATION

Before doing anything else:

1. Do not implement new production functionality.
2. Do not rewrite existing screens.
3. Do not create backend code.
4. Do not create final APIs.
5. Do not make architectural changes.
6. Do not remove existing files.

You may create planning/documentation artifacts inside a dedicated planning area.

If the repository already contains documentation, diagrams, specifications, wireframes, database designs, or architecture documents, analyze them before making decisions.

---

PHASE 1 — COMPLETE PROJECT DISCOVERY

Inspect the entire repository systematically.

Do not only inspect the obvious Flutter files.

Analyze:

- README/documentation
- Flutter project structure
- existing source code
- models
- entities
- providers/state management
- services
- repositories
- routes/navigation
- screens
- widgets
- forms
- cards
- dialogs
- settings
- assets
- localization
- authentication
- authorization
- role handling
- API-related code
- database-related files
- configuration
- environment files
- tests
- mock data
- existing diagrams
- wireframes
- requirements
- academic/project documentation
- any other project-related files

Create a project inventory.

For every major module record:

- What it is
- Why it exists
- Who uses it
- Current status
- Dependencies
- Missing parts
- Risks
- Related screens
- Related backend requirements
- Related database requirements

Do not trust filenames alone.

Read the actual implementation.

---

PHASE 2 — UNDERSTAND THE PRODUCT

Construct a Product Model.

Identify:

Users / Roles

For every role determine:

- responsibilities
- permissions
- accessible modules
- accessible services
- restrictions
- data visibility
- actions
- relationships with other roles

Create a role-permission matrix.

---

PHASE 3 — BUILD THE SERVICE CATALOG

Identify every business service/function in the application.

For each service create a complete specification.

Use this structure:

SERVICE

Name:
Purpose:
Primary role:
Other affected roles:

Entry points:
Screens:
Widgets:
Actions:

Inputs:
Outputs:

Settings:

- Setting
- Type
- Default value
- Allowed values
- Who can change it
- When it applies
- Who is affected

Business rules:

Permissions:

State:

Backend requirements:

Database requirements:

API requirements:

Notifications:

Dependencies:

Validation:

Error states:

Empty states:

Loading states:

Success states:

Security considerations:

Audit/logging requirements:

Affected roles:

Affected screens:

Affected services:

Testing requirements:

Current implementation status:

Missing implementation:

Ambiguities:

Required decisions:

---

PHASE 4 — SETTINGS COMPLETENESS AUDIT

This is one of the highest-priority tasks.

For every setting visible anywhere in the system:

Determine:

1. Why does this setting exist?
2. Who controls it?
3. What does it control?
4. What is its default?
5. What happens when it changes?
6. Where is the value stored?
7. Who is affected?
8. Which screens should react?
9. Which backend logic should react?
10. Which database field/configuration is required?
11. Does it require permissions?
12. Does it require validation?
13. Does it require notifications?
14. Does changing it affect another role?

Explicitly detect:

- settings that exist visually but have no behavior
- settings with partial behavior
- settings that affect only one side but should affect another
- settings with unclear purpose
- duplicate settings
- contradictory settings
- settings missing from the correct role
- backend settings missing from UI
- UI settings missing from backend
- settings that should be derived rather than manually configured

Do not silently invent behavior.

When behavior is unclear, investigate the project's requirements, documentation, existing flows, related services, and established product patterns before deciding.

If a product decision is still genuinely ambiguous, record it as a decision item instead of hiding the ambiguity.

---

PHASE 5 — CROSS-ROLE CONSISTENCY

For every action performed by one role, ask:

"What should the other affected role see or experience?"

Example:

Parent changes a setting
↓
What should Child see?
↓
What state changes?
↓
What backend event occurs?
↓
What database value changes?
↓
Does Child receive a notification?
↓
Does Child UI update immediately or on refresh?
↓
What happens if Child is offline?

Build cross-role dependency maps.

The application must not contain isolated settings that do not propagate to the parts of the system they logically control.

---

PHASE 6 — USER FLOW ANALYSIS

For every major service map the complete user journey:

Entry
→ Action
→ Validation
→ Confirmation
→ Processing
→ Result
→ Next possible action
→ Error handling
→ Recovery

Include:

- first-time user
- normal user
- edge cases
- empty state
- loading state
- failure state
- permission denied
- network failure
- invalid input
- expired session
- conflicting state
- cancellation

---

PHASE 7 — UI/UX COMPLETENESS AUDIT

Do NOT redesign the product arbitrarily.

Instead determine whether each existing screen has everything required for a production-ready experience.

Audit:

- navigation
- hierarchy
- actions
- forms
- validation
- feedback
- loading
- errors
- empty states
- confirmations
- destructive actions
- permissions
- accessibility
- responsive behavior
- localization
- consistency
- reusable components
- state transitions

For every missing UI behavior record it as a requirement.

---

PHASE 8 — SYSTEM ARCHITECTURE

Based on the actual project, define the target architecture.

Specify:

- Flutter architecture
- feature/module boundaries
- state management
- repository pattern
- service layer
- domain layer if needed
- API communication
- authentication
- authorization
- error handling
- caching
- offline behavior if required
- dependency injection
- configuration
- logging
- analytics if required
- notification architecture
- security boundaries

Do not select technologies merely because they are popular.

Choose based on:

- current project
- requirements
- scalability
- maintainability
- complexity
- existing dependencies
- team/project constraints

Explain every major architectural decision.

---

PHASE 9 — BACKEND DESIGN

Before implementation, define the backend requirements.

Identify:

- modules
- services
- endpoints
- request models
- response models
- authentication
- authorization
- business rules
- validation
- error responses
- pagination
- filtering
- sorting
- file handling
- notifications
- background operations
- audit logging
- transactions
- concurrency requirements

For every API define:

Method:
Endpoint:
Purpose:
Authentication:
Authorization:
Request:
Response:
Validation:
Errors:
Business rules:
Database interaction:
Affected roles:
Affected UI:
Tests:

Do not implement the API yet.

---

PHASE 10 — DATABASE DESIGN

Create the target database model.

Identify:

- entities
- attributes
- primary keys
- foreign keys
- relationships
- cardinality
- constraints
- indexes
- timestamps
- soft deletion where justified
- audit requirements
- ownership
- role relationships

Check the database against the services.

Every important business requirement should have a clear data representation.

Every important database entity should have a business purpose.

Detect:

- missing entities
- unnecessary entities
- duplicated data
- ambiguous relationships
- missing constraints
- settings that need persistence
- fields required by UI but absent from the database

---

PHASE 11 — DIAGRAM STRATEGY

Do not generate random diagrams.

First define the canonical system model.

Then determine which diagrams are actually required.

Potential diagrams:

1. Use Case Diagram
2. Activity Diagram
3. Sequence Diagram
4. ERD
5. Class Diagram
6. System Architecture Diagram
7. Data Flow Diagram
8. State Diagram where required

For each diagram specify:

- purpose
- actors/entities
- included elements
- relationships
- source requirements
- source implementation
- dependencies

The diagrams must remain consistent with the approved requirements and architecture.

---

PHASE 12 — REQUIREMENTS TRACEABILITY

Create a traceability chain:

Requirement
→ Use Case
→ Service
→ Screen
→ UI Action
→ State
→ API
→ Backend Logic
→ Database
→ Test
→ Diagram

Every major requirement must be traceable.

If something exists in the UI but has no requirement, flag it.

If something exists in the requirement but has no UI/backend implementation plan, flag it.

If something exists in the database but has no business purpose, flag it.

---

PHASE 13 — GAP ANALYSIS

Create a master gap list.

Classify every issue:

CRITICAL
HIGH
MEDIUM
LOW

Categories:

- Product
- UX/UI
- Flutter
- Backend
- Database
- Security
- Architecture
- Testing
- Documentation
- Diagrams
- Performance
- Consistency

For every gap record:

ID:
Category:
Description:
Evidence:
Affected components:
Impact:
Dependencies:
Recommended resolution:
Priority:
Estimated complexity:
Blocked by:
Verification method:

Do not hide unresolved issues.

---

PHASE 14 — DECISION REGISTER

Create a decision register.

Every significant product/technical decision must have:

Decision ID:
Problem:
Context:
Options considered:
Selected approach:
Reason:
Affected components:
Consequences:
Status:

Do not silently make high-impact decisions.

When a decision can be reasonably inferred from the existing product requirements, document the reasoning.

When it cannot be determined safely, mark it:

REQUIRES PRODUCT DECISION

---

PHASE 15 — IMPLEMENTATION ROADMAP

Only after the entire discovery and analysis process is complete, create the implementation roadmap.

Organize it into dependency-aware phases.

Example:

PHASE 1
Foundation / Architecture

PHASE 2
Database

PHASE 3
Backend Foundation

PHASE 4
Authentication & Authorization

PHASE 5
Core Services

PHASE 6
Flutter Data Layer

PHASE 7
Flutter State Management

PHASE 8
Existing UI Completion

PHASE 9
Cross-role behavior

PHASE 10
Testing

PHASE 11
Diagrams & Documentation

PHASE 12
Release Preparation

Do not assume this exact order is correct.

Derive the actual order from dependencies.

---

PHASE 16 — EXECUTION TASKS

Break the roadmap into atomic implementation tasks.

Every task must contain:

Task ID:
Title:
Objective:
Preconditions:
Files/modules affected:
Dependencies:
Implementation steps:
Acceptance criteria:
Tests:
Verification:
Expected output:

Tasks must be small enough for an AI coding agent to execute safely.

Avoid tasks such as:

"Build the backend."

Instead use:

"Implement parent notification preference persistence and expose GET/PUT endpoints for the parent settings module."

---

PHASE 17 — AI AGENT OPERATING RULES

Create rules for future coding agents.

The future implementation agent must:

1. Read the relevant specification before coding.
2. Read existing implementation before modifying it.
3. Never overwrite working functionality without justification.
4. Never invent business behavior silently.
5. Never modify unrelated modules.
6. Follow the approved architecture.
7. Update tests with behavior changes.
8. Verify affected roles.
9. Verify affected screens.
10. Verify backend/database consistency.
11. Update documentation when behavior changes.
12. Report assumptions.
13. Stop and request a decision when a high-impact ambiguity cannot be resolved from project evidence.

---

PHASE 18 — VERIFICATION LOOP

Design a reusable verification loop for future implementation.

Every feature must follow:

DISCOVER
→ PLAN
→ IMPLEMENT
→ TEST
→ REVIEW
→ CROSS-ROLE VERIFY
→ DOCUMENT
→ MARK COMPLETE

A task cannot be considered complete simply because:

- code compiles
- UI appears
- API returns 200
- tests pass

It is complete only when its required behavior is verified across all affected layers.

---

PHASE 19 — RELEASE READINESS MODEL

Define what "ready for release" means for THIS project.

Create a release checklist covering:

Product completeness
UI/UX completeness
Role consistency
Settings completeness
Backend completeness
Database integrity
Security
Authentication
Authorization
Validation
Error handling
Testing
Performance
Documentation
Diagrams
Configuration
Deployment
Monitoring/logging
Recovery/backup requirements if applicable

Do not assign an arbitrary numerical "launch score" unless there is a clearly defined objective scoring model.

Instead provide explicit PASS / FAIL / BLOCKED criteria.

---

REQUIRED OUTPUT FILES

Do not dump the entire analysis into one giant file.

Create a structured planning package.

Use a dedicated directory such as:

/docs/project-plan/

Create at minimum:

01-project-understanding.md
02-product-model.md
03-role-permission-matrix.md
04-service-catalog.md
05-settings-audit.md
06-cross-role-dependencies.md
07-user-flows.md
08-ui-ux-gap-analysis.md
09-system-architecture.md
10-backend-specification.md
11-database-specification.md
12-api-specification.md
13-diagram-strategy.md
14-requirements-traceability.md
15-master-gap-list.md
16-decision-register.md
17-implementation-roadmap.md
18-implementation-tasks.md
19-ai-agent-rules.md
20-verification-system.md
21-release-readiness.md

Also create:

00-MASTER-PLAN.md

This must be the executive document that connects everything together.

---

MASTER PLAN REQUIREMENTS

00-MASTER-PLAN.md must contain:

1. Current project state
2. Product understanding
3. Roles
4. Services
5. Major missing functionality
6. Major inconsistencies
7. Architecture direction
8. Backend direction
9. Database direction
10. UI completion strategy
11. Cross-role consistency strategy
12. Diagram strategy
13. Testing strategy
14. Implementation phases
15. Dependencies
16. Critical risks
17. Unresolved product decisions
18. Definition of done
19. Exact next implementation step

At the end include:

IMPLEMENTATION READINESS

Choose exactly one:

NOT READY
READY FOR FOUNDATION
READY FOR IMPLEMENTATION

Do not choose READY FOR IMPLEMENTATION unless the required specifications are sufficiently complete.

---

IMPORTANT BEHAVIOR

You are allowed to spend substantial time reading and analyzing the repository before producing the plan.

Do not rush.

Do not optimize for the number of files changed.

Optimize for:

CORRECTNESS
CONSISTENCY
TRACEABILITY
MAINTAINABILITY
PRODUCT COMPLETENESS
IMPLEMENTATION SAFETY

If you discover that existing project decisions conflict with one another, document the conflict.

If existing UI conflicts with requirements, document it.

If requirements conflict with database design, document it.

If two screens implement the same concept differently, document it.

If a setting has no observable effect, flag it.

If a parent-side setting should logically affect a child-side experience but currently does not, flag it.

If an implementation exists without a corresponding requirement, flag it.

If a requirement exists without implementation, flag it.

---

FINAL RULE

DO NOT WRITE PRODUCTION CODE DURING THIS PHASE.

Your job is to produce the blueprint.

The next phase will use your approved blueprint to implement:

Flutter UI behavior
+
State management
+
Backend
+
Database
+
APIs
+
Cross-role synchronization
+
Testing
+
Final diagrams

The goal is not simply to "finish the screens."

The goal is to transform the existing project into a coherent, production-ready system where:

Every screen has a purpose.
Every service has defined behavior.
Every setting has an effect.
Every role has defined permissions.
Every important action has a complete flow.
Every UI behavior has a backend/data strategy where required.
Every backend capability has a product purpose.
Every important requirement is traceable.
Every diagram represents the actual system.
Every implementation change can be verified.

START NOW.

First inspect the repository and existing project files.

Then create the complete planning package.

Do not ask me to explain files that you can inspect yourself.

Only ask for my decision when a genuine high-impact product decision cannot be determined from the available project evidence.

Do not implement production code until this planning phase is complete.