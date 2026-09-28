# Learning Reliability, Quality & Operations — Gate G3

> **Status:** Product-readiness technical design complete
> **Purpose:** Define what makes education trustworthy, supportive, globally usable, and operationally safe before any family-facing learning claim is made.

## 1. Quality philosophy

A learning product can harm trust by being confidently wrong, losing work, rewarding the wrong behavior, pushing unreviewed content, or turning uncertainty into a judgement about a child. Reliability therefore includes pedagogical quality, content provenance, child wellbeing, capability truth, data integrity, and support operations—not only application uptime.

## 2. Verification layers

| Layer | What it verifies | Examples |
|---|---|---|
| Domain unit tests | Plan, assignment, approval, attempt, result, reward, and focus state transitions. | Expired assignment, withdrawn artifact, repeated reward, plan conflict. |
| Content lifecycle tests | Artifact provenance, revision, approval, assignment, withdrawal, archive/reuse. | A generated draft cannot reach a child before approval. |
| Contract tests | Client/API/event/AI/native integrations agree on schemas/error states. | Assignment receipt, result quality, focus confirmation, capability downgrade. |
| Widget/accessibility tests | Parent and child see the right state with clear language. | RTL, large text, child retry, unsupported AI, empty learning home. |
| Assessment quality tests | Question/version/feedback/rubric behavior is valid for the intended learning purpose. | Partial attempt, accommodation, uncertain auto-grade, retry/review policy. |
| AI safety/evaluation tests | Tutor follows guided-help policy and source/age guardrails. | Refuses direct answer for assessment, flags unsafe/uncertain output, exposes limitation. |
| Device/integration tests | Focus/security/time, media, storage, offline delivery and capability reporting. | Focus rule confirmed/limited, device reconnect, local-download truth. |
| End-to-end family tests | Guardian→child→result→support loop closes. | Studio approval/assignment, child work, guardian result, reward with time expiry. |
| Operations tests | Support, withdrawal, source report, data request, and incident recovery. | Remove problematic artifact, reconstruct assignment chain, answer privacy request. |

## 3. High-risk scenarios that must be tested

### Content and Studio

- Source rights/provenance are absent, invalid, disputed, or later withdrawn.
- A file/link/camera/voice import fails midway without losing the guardian’s draft.
- Generated content is wrong, unsuitable, duplicated, or unreviewed.
- An approved artifact is edited after a child started it.
- Community content is reported, removed, or access changes after assignment.

### Assignment, assessment, and progress

- Child is offline during a lesson, submission, or test.
- Guardian changes a due date/plan while child is working.
- A submission is duplicated, delayed, incomplete, or conflicts with a newer artifact revision.
- A scoring model is uncertain or cannot assess an answer fairly.
- A report has insufficient evidence or partial data.
- Child needs an accommodation, retry, pause, or recovery without losing dignity/progress.

### AI and adaptation

- Tutor is asked to complete assessed work or provide a direct answer.
- Tutor output is ungrounded, unsuitable for age/language, or harmful.
- Recommendation lacks enough evidence, is rejected by the child/guardian, or becomes stale.
- Parent Studio generation has no reliable source/quality basis.
- Tutor/history visibility differs between guardian, co-guardian, child, and support role.

### Focus, rewards, and family coordination

- Focus conflicts with a sleep/school/time policy or device capability.
- A reward is earned multiple times, revoked by error, or creates an expired privilege.
- Co-guardians create competing assignments/rewards.
- A learning reminder overlaps with a family event, quiet period, or urgent safety event.

## 4. Observability without surveillance

Operational signals should reveal system health and learning-loop effectiveness without exposing raw child work/content unnecessarily.

| Signal | Question it answers |
|---|---|
| Assignment lifecycle | Are approved assignments delivered, seen, started, submitted, reviewed, or failing? |
| Content lifecycle | Are drafts stuck, approvals delayed, sources failing, or withdrawals affecting children? |
| Assessment quality | Are attempts/results failing, incomplete, or frequently marked uncertain? |
| Tutor/adaptive safety | Are guardrails, feedback, limitations, and escalation pathways working? |
| Focus/security integration | Does requested focus become confirmed, queued, limited, or unsupported? |
| Reward integrity | Are recognition events/reward exceptions valid, duplicated, or expiring correctly? |
| Support/recovery | Are families completing recovery paths or repeatedly blocked by setup/capability issues? |
| Accessibility/localization | Are language/layout/accessibility variants creating failures or abandonment? |

## 5. Content, AI, and support operations

### Content operations

- Maintain source provenance, rights/attribution, age/level metadata, review status, availability, and removal/withdrawal capability.
- Define a moderation/reporting/removal workflow before any community publication is enabled.
- Keep a child-safe explanation when content is withdrawn after assignment.

### AI operations

- Maintain model/provider version, approved prompt/context policy, evaluation set, guardrail events, user feedback, and fallback/disable ability.
- Test educational helpfulness, not just output fluency.
- Provide an incident path when AI produces unsuitable, unsafe, wrong, or biased content.

### Support operations

A support-safe diagnostic record should provide only what is needed: family/child/artifact references, lifecycle states, capability/setup state, source/approval chain, user-visible recovery step, and audited support access. It should not expose unrestricted child work or tutor content by default.

## 6. Release progression

| Ring | Purpose | Required evidence |
|---|---|---|
| Internal simulation | Validate state models, content lifecycle, and failure cases with fixtures. | Automated tests and reviewed scenarios. |
| Controlled content/device lab | Validate media/storage/focus/security and curated content paths. | Capability matrix and source-quality evidence. |
| Invited family pilot | Validate child clarity, guardian support usefulness, assignment completion, recovery and trust. | Consentful feedback, support triage, no inflated AI/content claims. |
| Limited rollout | Observe lifecycle/recovery/quality data under controlled exposure. | Monitoring, moderation/support/rollback readiness. |
| General availability | Offer only verifiable learning, AI, and content promises. | Release checklist and operational sign-off. |

## 7. Learning release checklist

No learning slice reaches general availability without approved UX/state coverage; content provenance and child suitability; revision/approval/delivery traceability; valid assessment/feedback behavior; AI/source capability truth; offline/conflict/recovery behavior; focus/security/reward integration; accessibility/localization/time-zone checks; support/privacy/audit model; monitoring/rollback; and pilot/device evidence appropriate to the claim.
