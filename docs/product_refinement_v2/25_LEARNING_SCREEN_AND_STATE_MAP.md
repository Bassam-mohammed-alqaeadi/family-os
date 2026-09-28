# Learning Screen & State Map — Gate G2

> **Status:** Accepted under standing Owner trust
> **Purpose:** Define the full learning surface before implementation. Existing Flutter screens are evidence and candidates for retention/refinement; this map defines the approved product role.

## 1. Parent and guardian learning surfaces

| ID | Surface | Primary job | Existing evidence relationship |
|---|---|---|---|
| P-LEARN-01 | Learning Hub | Understand family learning state and take one supportive action. | New organizing surface over Today, parent Studio, focus, reports, and child data. |
| P-LEARN-02 | Learning Attention Queue | Review overdue, blocked, awaiting-approval, or support-needed items. | Reconciles assignment/result/report patterns. |
| P-LEARN-03 | Child Learning Profile | Understand one child’s plan, next action, progress, and support needs. | Connects child profile, child learning screens, and parent follow-up. |
| P-LEARN-04 | Learning Plan | Set/adjust subject/path/goal and due rhythm. | `SCR-FAT-047` path and materials evidence. |
| P-LEARN-05 | Materials & Lessons | Organize approved material and lesson context. | `SCR-FAT-048` evidence. |
| P-LEARN-06 | Assignment Builder | Create/assign an activity with due context and review policy. | `SCR-FAT-049`, Studio assignment evidence. |
| P-LEARN-07 | Assessment Builder | Create/review formative assessment and feedback intent. | Existing test/generation/preview evidence. |
| P-LEARN-08 | Results & Follow-up | Understand a result, learning gap, or next supportive action. | `SCR-FAT-050`, results/follow-up evidence. |
| P-LEARN-09 | Focus Overview | See verified focus/routine context and support a study session. | `SCR-FAT-051`, child focus, modes evidence. |
| P-LEARN-10 | Rewards & Privileges | Set recognition/reward policy and inspect source/expiry of privileges. | Attribution/reward and child wallet evidence. |
| P-LEARN-11 | Quran Progress | Support optional Quran plan/progress/review respectfully. | `SCR-FAT-072`, Quran progress evidence. |
| P-LEARN-12 | Parent Studio Board | Start a reviewed creation/approval/assignment lifecycle. | `SCR-FAT-040` evidence. |
| P-LEARN-13 | Studio Source Intake | Choose a real supported source or manual draft path. | `SCR-FAT-041` / camera UI evidence; unsupported inputs remain clear. |
| P-LEARN-14 | Studio Review & Approval | Edit, approve, assign, withdraw, or archive a content artifact. | `SCR-FAT-043` to `SCR-FAT-045` evidence. |
| P-LEARN-15 | Learning Project | Create/review staged project and milestones. | `SCR-FAT-084` evidence. |
| P-LEARN-16 | Learning Activity & Audit | See assignment, result, approval, and policy history. | Uses shared timeline/audit foundation. |
| P-LEARN-17 | Learning Settings | Guardian/co-guardian permission, focus, tutor, reward, data/notification settings. | New settings-desk organizing surface. |

## 2. Child learning surfaces

| ID | Surface | Child job | Existing evidence relationship |
|---|---|---|---|
| C-LEARN-01 | Learn Home | See one next step and today’s manageable plan. | `SCR-CHD-012`, child learn home evidence. |
| C-LEARN-02 | Lesson | Read/watch/practice an assigned or selected lesson. | `SCR-CHD-013`, child lesson evidence. |
| C-LEARN-03 | Assignment | Understand, do, submit, and recover work. | `SCR-CHD-014`, child task/assignment evidence. |
| C-LEARN-04 | Assessment | Take a formative check with clear attempt/feedback state. | `SCR-CHD-015`, child quiz evidence. |
| C-LEARN-05 | Result & Next Step | Understand progress and choose retry/review/next activity. | `SCR-CHD-016`, result/daily-review evidence. |
| C-LEARN-06 | Guided Tutor | Ask for hints and step-by-step support. | `SCR-CHD-017`, child tutor evidence. |
| C-LEARN-07 | Focus | Start/continue focus and understand time/safety context. | `SCR-CHD-018`, child focus evidence. |
| C-LEARN-08 | My Wins | See points/badges/streak/recognition and permitted privileges. | `SCR-CHD-019`, wallet/challenges evidence. |
| C-LEARN-09 | Quran Today | Follow optional ward, recitation, review, and adhkar routine. | `SCR-CHD-025` to `SCR-CHD-027` evidence. |
| C-LEARN-10 | Adaptive Plan | Understand the next practice/review recommendation and why. | `SCR-CHD-028`, `SCR-CHD-029` evidence. |
| C-LEARN-11 | Story / Challenge | Engage with approved creative activity without public-pressure defaults. | `SCR-CHD-033`, `SCR-CHD-034` evidence. |
| C-LEARN-12 | Focus Sounds | Choose available focus environment with playback truth. | `SCR-CHD-035` evidence. |

## 3. Required state coverage

Every learning screen evaluates the applicable states below:

- Loading, empty/new child, and first useful action.
- Draft, awaiting guardian approval, assigned, seen, started, submitted, reviewed, completed, withdrawn, expired.
- Calm success/progress and constructive retry/review states.
- Needs guardian support, co-guardian permission restriction, or child request state.
- Offline/locally available versus delivery waiting/failure.
- Data-quality insufficient/partial/stale for reports and adaptation.
- Capability limited/unsupported for camera, source import, AI, recitation, sound/media, grading, or content retrieval.
- Focus/time/safety conflict or essential-access explanation.

## 4. Screen reconciliation rule

Existing screens are not removed merely because the Learning Hub becomes the product front door. During later implementation readiness each current learning screen is assigned one outcome:

- **Retain:** already serves the approved surface and needs only hardening.
- **Refine:** retains its purpose but receives UX/state/design improvements.
- **Merge:** content moves under an approved surface without breaking a user journey.
- **Defer:** remains registered but is outside the first implementation sequence.
- **Retire:** only with a documented replacement and explicit decision.

## 5. G2 completion test

Learning UX is locked when every Core or capability-gated learning action has a guardian entry, a child consequence/next step, a content/assignment lifecycle state, a focus/time/safety relationship where relevant, a capability truth state, and a traceable activity/audit relationship.
